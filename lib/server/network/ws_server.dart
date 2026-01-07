import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../world/world_manager.dart';
import '../../shared/network_messages.dart';

class ServerPlayer {
  final String id;
  String name;
  final WebSocket socket;
  double x = 0;
  double y = 0;
  String direction = 'down';
  String state = 'idle';

  ServerPlayer(this.id, this.name, this.socket);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': x,
    'y': y,
    'direction': direction,
    'state': state,
  };
}

class AngryPlanetServer {
  final int port;
  final int seed;
  late final WorldManager world;
  final Map<String, ServerPlayer> _players = {};
  int _nextPlayerId = 0;

  final Map<String, Map<String, dynamic>> _machines = {};

  Timer? _stateSyncTimer;

  // per-machine lock to avoid concurrent modifications
  final Set<String> _machineLocks = {};

  bool isSentHost = false;

  AngryPlanetServer({
    this.port = 3333,
    this.seed = 12345,
  }) {
    world = WorldManager(seed);
  }

  Future<void> start() async {
    final http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print("🌍 Server running at ws://0.0.0.0:$port/ws (seed: $seed)");

    // Start periodic state sync (every 1 second)
    _startStateSyncTimer();

    await for (var req in http) {
      if (req.uri.path == '/ws') {
        final socket = await WebSocketTransformer.upgrade(req);
        _handleClient(socket);
      }
    }
  }

  // Periodic state sync
  void _startStateSyncTimer() {
    _stateSyncTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _syncAllMachineStates();
    });
  }

  // Sync all machine states to all clients
  void _syncAllMachineStates() {
    if (_machines.isEmpty) return;
    
    final machineStates = _machines.values.map((m) => m['state']).toList();
    
    final message = jsonEncode({
      'type': NetworkMessage.machineStateSync,
      'states': machineStates,
    });
    
    for (final player in _players.values) {
      try {
        player.socket.add(message);
      } catch (e) {
        // Ignore errors for disconnected players
      }
    }
  }

  void _handleClient(WebSocket socket) {
    final playerId = 'player_${_nextPlayerId++}';
    final playerName = 'Player ${_nextPlayerId}';
    
    final player = ServerPlayer(playerId, playerName, socket);
    _players[playerId] = player;
    
    // print("👤 $playerName joined (${_players.length} players)");

    // Send player their ID
    // socket.add(jsonEncode({
    //   'type': NetworkMessage.playerJoined,
    //   'id': playerId,
    //   'name': playerName,
    // }));

    // Send existing players
    for (final p in _players.values) {
      if (p.id != playerId) {
        socket.add(jsonEncode({
          'type': NetworkMessage.positionSync,
          'players': [p.toJson()],
        }));
      }
    }

    // Send existing machines to new player
    for (final machine in _machines.values) {
      socket.add(jsonEncode({
        'type': NetworkMessage.machineSync,
        'machines': [machine],
      }));
    }

    socket.listen(
      (data) {
        final msg = jsonDecode(data);

        if (msg['type'] == NetworkMessage.hello) {
          print("👤 $playerName joined (${_players.length} players)");
          socket.add(jsonEncode({
            'type': NetworkMessage.playerJoined,
            'id': playerId,
            'name': playerName,
          }));

          print('🤝 Handshake completed for $playerName');
          return;
        }
        else if (msg['type'] == NetworkMessage.machineAction) {
          // machineAction: { action: 'add_input'|'take_output', machineId, resource, amount }
          final action = msg['action'] as String?;
          final machineId = msg['machineId'] as String?;
          final resourceName = msg['resource'] as String?;
          final amount = (msg['amount'] as num?)?.toInt() ?? 0;

          if (action == null || machineId == null || resourceName == null || amount <= 0) {
            socket.add(jsonEncode({
              'type': NetworkMessage.machineActionResult,
              'success': false,
              'reason': 'invalid_request',
            }));
            return;
          }
           // Lock per-machine
            if (_machineLocks.contains(machineId)) {
              socket.add(jsonEncode({
                'type': NetworkMessage.machineActionResult,
                'success': false,
                'reason': 'busy',
                'machineId': machineId,
              }));
              return;
            }
            _machineLocks.add(machineId);
            try {
              if (!_machines.containsKey(machineId)) {
                socket.add(jsonEncode({
                  'type': NetworkMessage.machineActionResult,
                  'success': false,
                  'reason': 'not_found',
                  'machineId': machineId,
                }));
                return;
              }
              final machineData = _machines[machineId]!;
              final state = (machineData['state'] as Map<String, dynamic>? ) ?? {};

              // Helpers to read/modify storage format { stacks: [ {resource, amount}, ... ] }
              int getQty(Map<String, dynamic>? storageJson, String resource) {
                if (storageJson == null) return 0;
                final stacks = storageJson['stacks'] as List? ?? [];
                for (final s in stacks) {
                  if (s['resource'] == resource) return (s['amount'] as num).toInt();
                }
                return 0;
              }
              void setQty(Map<String, dynamic> storageJson, String resource, int qty) {
                final stacks = (storageJson['stacks'] as List?) ?? [];
                bool found = false;
                for (final s in stacks) {
                  if (s['resource'] == resource) {
                    s['amount'] = qty;
                    found = true;
                    break;
                  }
                }
                if (!found) {
                  stacks.add({'resource': resource, 'amount': qty});
                }
                // remove zero stacks
                storageJson['stacks'] = stacks.where((s) => (s['amount'] as num).toInt() > 0).toList();
              }
              // Ensure input/output storage shape
              state['inputStorage'] = state['inputStorage'] ?? {'stacks': []};
              state['outputStorage'] = state['outputStorage'] ?? {'stacks': []};

              if (action == 'add_input') {
                // Server accepts add to input: increase inputStorage
                final current = getQty(state['inputStorage'], resourceName);
                final newQty = current + amount;
                setQty(state['inputStorage'], resourceName, newQty);

                // Save back
                machineData['state'] = state;

                // Broadcast machine state update to everyone
                _broadcastMachineStateUpdateToAll(machineId, state);

                // Notify requesting player to remove items locally
                socket.add(jsonEncode({
                  'type': NetworkMessage.machineActionResult,
                  'success': true,
                  'action': 'add_input',
                  'machineId': machineId,
                  'inventoryDelta': {
                    'resource': resourceName,
                    'amount': -amount   // client should remove amount
                  },
                  'state': state,
                }));

                print('🔧 [ACTION] add_input $amount $resourceName to $machineId by $playerId');
                return;
                } else if (action == 'take_output') {
                final current = getQty(state['outputStorage'], resourceName);
                if (current < amount) {
                  socket.add(jsonEncode({
                    'type': NetworkMessage.machineActionResult,
                    'success': false,
                    'reason': 'not_enough_output',
                    'machineId': machineId,
                  }));
                  return;
                }

                final newQty = current - amount;
                setQty(state['outputStorage'], resourceName, newQty);

                // Save back
                machineData['state'] = state;

                // Broadcast machine state update to everyone
                _broadcastMachineStateUpdateToAll(machineId, state);

                // Notify requesting player to add items locally
                socket.add(jsonEncode({
                  'type': NetworkMessage.machineActionResult,
                  'success': true,
                  'action': 'take_output',
                  'machineId': machineId,
                  'inventoryDelta': {
                    'resource': resourceName,
                    'amount': amount   // client should add amount
                  },
                  'state': state,
                }));

                print('🔧 [ACTION] take_output $amount $resourceName from $machineId by $playerId');
                return;
              } else {
                socket.add(jsonEncode({
                  'type': NetworkMessage.machineActionResult,
                  'success': false,
                  'reason': 'unknown_action',
                }));
                return;
              }
            } finally {
              _machineLocks.remove(machineId);
            }
        }

        // Handle set_player_name
        else if (msg['type'] == NetworkMessage.setPlayerName) {
          final newName = msg['name'] as String?;
          if (newName != null && newName.isNotEmpty && newName.length <= 20) {
            final oldName = player.name;
            player.name = newName;
            print("👤 Player renamed: $oldName → $newName");
            _broadcastPlayerUpdate(playerId);
          }
        } else if (msg['type'] == NetworkMessage.getChunk) {
          final cx = msg['cx'];
          final cy = msg['cy'];
          final chunk = world.generateChunk(cx, cy);
          socket.add(jsonEncode({
            'type': NetworkMessage.chunkData,
            'data': chunk.toJson(),
          }));
        } 

        else if (msg['type'] == NetworkMessage.chatMessage) {
          final message = msg['message'] as String;
          
          // Broadcast to ALL players (including sender)
          _broadcastChatMessage(playerId, player.name, message);
        }
        // Handle machine placement
        else if (msg['type'] == NetworkMessage.machinePlace) {
          final machineData = {
            'id': msg['id'],
            'type': msg['machineType'],
            'x': msg['x'],
            'y': msg['y'],
            'placedBy': playerId,
            'state': msg['state'] ?? {},
          };
          
          _machines[msg['id']] = machineData;
          print("🔧 Machine placed: ${msg['machineType']} at (${msg['x']}, ${msg['y']})");
          
          // Broadcast to all OTHER players
          _broadcastMachinePlace(playerId, machineData);
        } 
        // Handle machine destruction
        else if (msg['type'] == NetworkMessage.machineDestroy) {
          final machineId = msg['id'];
          _machines.remove(machineId);
          print("💥 Machine destroyed: $machineId");
          
          // Broadcast to all OTHER players
          _broadcastMachineDestroy(playerId, machineId);
        }
        // Handle machine state updates (optional, for future)
        else if (msg['type'] == NetworkMessage.machineUpdate) {
          final machineId = msg['id'];
          if (_machines.containsKey(machineId)) {
            _machines[machineId]!['state'] = msg['state'];
            _broadcastMachineUpdate(playerId, machineId, msg['state']);
          }
        }
        // Handle machine state update from client
        else if (msg['type'] == NetworkMessage.machineStateUpdate) {
          final machineId = msg['id'] as String;
          final state = msg['state'] as Map<String, dynamic>;
          
          if (_machines.containsKey(machineId)) {
            _machines[machineId]!['state'] = state;
            
            // Broadcast to other players
            _broadcastMachineStateUpdate(playerId, machineId, state);
          }
        }
        // Handle game tick from host
        else if (msg['type'] == NetworkMessage.gameTick) {
          // Host sends tick, relay to all other players
          final tick = msg['tick'] as int;
          print('⏱️ Host tick: $tick');
          
          _broadcastGameTick(playerId, tick);
        }
        else if (msg['type'] == NetworkMessage.playerUpdate) {
          // Update player position
          player.x = (msg['x'] as num).toDouble();
          player.y = (msg['y'] as num).toDouble();
          player.direction = msg['direction'];
          player.state = msg['state'];
          
          // Broadcast to all other players
          _broadcastPlayerUpdate(playerId);
        }
      },
      onDone: () {
        _players.remove(playerId);
        print("👋 $playerName left (${_players.length} players)");
      },
      onError: (e) {
        print("❌ Error for $playerName: $e");
        _players.remove(playerId);
      },
    );
  }

  // Broadcast chat message to all players
  void _broadcastChatMessage(String fromPlayerId, String playerName, String message) {
    print('💬 Chat from $playerName: $message');
    
    final chatMessage = jsonEncode({
      'type': NetworkMessage.chatMessage,
      'playerId': fromPlayerId,
      'playerName': playerName,
      'message': message,
    });

    // Send to ALL players (including sender for confirmation)
    for (final p in _players.values) {
      try {
        p.socket.add(chatMessage);
      } catch (e) {
        // Ignore disconnected players
      }
    }
  }

  // Broadcast machine placement
  void _broadcastMachinePlace(String fromPlayerId, Map<String, dynamic> machineData) {
    final message = jsonEncode({
      'type': NetworkMessage.machinePlace,
      'machine': machineData,
    });

    for (final p in _players.values) {
      if (p.id != fromPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          print("❌ Error broadcasting machine place to ${p.name}: $e");
        }
      }
    }
  }

  // Broadcast machine destruction
  void _broadcastMachineDestroy(String fromPlayerId, String machineId) {
    final message = jsonEncode({
      'type': NetworkMessage.machineDestroy,
      'id': machineId,
    });

    for (final p in _players.values) {
      if (p.id != fromPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          print("❌ Error broadcasting machine destroy to ${p.name}: $e");
        }
      }
    }
  }

  // Broadcast machine updates (optional)
  void _broadcastMachineUpdate(String fromPlayerId, String machineId, Map<String, dynamic> state) {
    final message = jsonEncode({
      'type': NetworkMessage.machineUpdate,
      'id': machineId,
      'state': state,
    });

    for (final p in _players.values) {
      if (p.id != fromPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          print("Error broadcasting machine update to ${p.name}: $e");
        }
      }
    }
  }

  // Broadcast single machine state update
  void _broadcastMachineStateUpdate(String fromPlayerId, String machineId, Map<String, dynamic> state) {
    final message = jsonEncode({
      'type': NetworkMessage.machineStateUpdate,
      'id': machineId,
      'state': state,
    });
    
    for (final p in _players.values) {
      if (p.id != fromPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          // Ignore
        }
      }
    }
  }

  // Helper - broadcast to all (including the origin)
  void _broadcastMachineStateUpdateToAll(String machineId, Map<String, dynamic> state) {
    final message = jsonEncode({
      'type': NetworkMessage.machineStateUpdate,
      'id': machineId,
      'state': state,
    });

    for (final p in _players.values) {
      try {
        p.socket.add(message);
      } catch (e) {
        // Ignore
      }
    }
  }

  // Broadcast single machine state update (from client)
  void _broadcastMachineStateUpdateFromClient(String fromPlayerId, String machineId, Map<String, dynamic> state) {
    final message = jsonEncode({
      'type': NetworkMessage.machineStateUpdate,
      'id': machineId,
      'state': state,
    });

    for (final p in _players.values) {
      if (p.id != fromPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          // Ignore
        }
      }
    }
  }

  // Broadcast game tick from host to other players
  void _broadcastGameTick(String fromPlayerId, int tick) {
    final message = jsonEncode({
      'type': NetworkMessage.gameTick,
      'tick': tick,
    });

    for (final p in _players.values) {
      // Send to everyone EXCEPT the host
      if (p.id != fromPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          // Ignore disconnected players
        }
      }
    }
  }

  void _broadcastPlayerUpdate(String updatedPlayerId) {
    final player = _players[updatedPlayerId];
    if (player == null) return;

    final message = jsonEncode({
      'type': NetworkMessage.positionSync,
      'players': [player.toJson()],
    });

    // Send to all OTHER players
    for (final p in _players.values) {
      if (p.id != updatedPlayerId) {
        try {
          p.socket.add(message);
        } catch (e) {
          print("❌ Error broadcasting to ${p.name}: $e");
        }
      }
    }
  }

  void stop() {
    _stateSyncTimer?.cancel();
    _stateSyncTimer = null;
    print('🛑 Server stopped');
  }
}