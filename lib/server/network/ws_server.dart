import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../world/world_manager.dart';
import '../../shared/network_messages.dart';

class ServerPlayer {
  final String id;
  final String name;
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

  AngryPlanetServer({
    this.port = 3333,
    this.seed = 12345,
  }) {
    world = WorldManager(seed);
  }

  Future<void> start() async {
    final http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print("🌍 Server running at ws://0.0.0.0:$port/ws (seed: $seed)");

    await for (var req in http) {
      if (req.uri.path == '/ws') {
        final socket = await WebSocketTransformer.upgrade(req);
        _handleClient(socket);
      }
    }
  }

  void _handleClient(WebSocket socket) {
    final playerId = 'player_${_nextPlayerId++}';
    final playerName = 'Player ${_nextPlayerId}';
    
    final player = ServerPlayer(playerId, playerName, socket);
    _players[playerId] = player;
    
    print("👤 $playerName joined (${_players.length} players)");

    // Send player their ID
    socket.add(jsonEncode({
      'type': NetworkMessage.playerJoined,
      'id': playerId,
      'name': playerName,
    }));

    // Send existing players
    for (final p in _players.values) {
      if (p.id != playerId) {
        socket.add(jsonEncode({
          'type': NetworkMessage.positionSync,
          'players': [p.toJson()],
        }));
      }
    }

    socket.listen(
      (data) {
        final msg = jsonDecode(data);

        if (msg['type'] == NetworkMessage.getChunk) {
          final cx = msg['cx'];
          final cy = msg['cy'];
          final chunk = world.generateChunk(cx, cy);
          socket.add(jsonEncode({
            'type': NetworkMessage.chunkData,
            'data': chunk.toJson(),
          }));
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
}