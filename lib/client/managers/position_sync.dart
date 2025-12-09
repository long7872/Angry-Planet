import 'package:flame/components.dart';
import 'dart:convert';
import '../player/player_component.dart';
import '../network/ws_client.dart';
import '../../shared/network_messages.dart';

class PositionSync extends Component {
  final PlayerComponent player;
  final ClientSocket socket;
  
  static const double syncRate = 1 / 60; // 60 updates/sec
  double _timeSinceSync = 0;

  PositionSync({
    required this.player,
    required this.socket,
  });

  @override
  void update(double dt) {
    super.update(dt);
    
    _timeSinceSync += dt;
    if (_timeSinceSync >= syncRate) {
      _sendUpdate();
      _timeSinceSync = 0;
    }
  }

  void _sendUpdate() {
    final message = PlayerUpdateMessage(
      x: player.data.x,
      y: player.data.y,
      direction: player.currentDirection.name,
      state: player.currentState.name,
    );
    
    socket.send(jsonEncode(message.toJson()));
  }
}