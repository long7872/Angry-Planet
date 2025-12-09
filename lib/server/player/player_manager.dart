import 'dart:convert';
import 'dart:io';
import '../../shared/network_messages.dart';

class ServerPlayer {
  final String id;
  final String name;
  final WebSocket socket;
  
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  String direction = 'down';
  String state = 'idle';
  
  ServerPlayer({
    required this.id,
    required this.name,
    required this.socket,
  });
  
  PlayerStateMessage toState() => PlayerStateMessage(
    id: id,
    name: name,
    x: x,
    y: y,
    direction: direction,
    state: state,
  );
}

class PlayerManager {
  final Map<String, ServerPlayer> _players = {};
  static const double moveSpeed = 2.0;
  static const double updateRate = 1 / 20; // 20 updates/sec
  
  double _timeSinceUpdate = 0;

  void addPlayer(String id, String name, WebSocket socket) {
    _players[id] = ServerPlayer(id: id, name: name, socket: socket);
    print("👤 Player $name ($id) joined - Total: ${_players.length}");
  }

  void removePlayer(String id) {
    final player = _players.remove(id);
    if (player != null) {
      print("👋 Player ${player.name} ($id) left - Total: ${_players.length}");
    }
  }

  void handleInput(String playerId, double dx, double dy) {
    final player = _players[playerId];
    if (player == null) return;

    player.vx = dx * moveSpeed;
    player.vy = dy * moveSpeed;

    // Update state and direction
    if (dx != 0 || dy != 0) {
      player.state = 'running';
      
      if (dx.abs() > dy.abs()) {
        player.direction = dx > 0 ? 'right' : 'left';
      } else {
        player.direction = dy > 0 ? 'down' : 'up';
      }
    } else {
      player.state = 'idle';
    }
  }

  void update(double dt) {
    // Update positions
    for (final player in _players.values) {
      player.x += player.vx * dt;
      player.y += player.vy * dt;
    }

    // Broadcast positions at fixed rate
    _timeSinceUpdate += dt;
    if (_timeSinceUpdate >= updateRate) {
      _broadcastPositions();
      _timeSinceUpdate = 0;
    }
  }

  void _broadcastPositions() {
    if (_players.isEmpty) return;

    final states = _players.values.map((p) => p.toState().toJson()).toList();
    final message = {
      'type': NetworkMessage.playerUpdate,
      'players': states,
    };

    final encoded = jsonEncode(message);
    
    for (final player in _players.values) {
      try {
        player.socket.add(encoded);
      } catch (e) {
        print("❌ Error sending to ${player.name}: $e");
      }
    }
  }

  List<PlayerStateMessage> getAllPlayerStates() {
    return _players.values.map((p) => p.toState()).toList();
  }
}