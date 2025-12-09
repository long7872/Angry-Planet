import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'dart:convert';
import '../network/ws_client.dart';
import '../world/client_world.dart';
import '../player/remote_player_component.dart';
import '../../shared/network_messages.dart';

class MultiplayerManager extends Component {
  final ClientSocket socket;
  final ClientWorld world;
  final FlameGame game;
  String? localPlayerId;
  
  final Map<String, RemotePlayerComponent> _remotePlayers = {};

  MultiplayerManager({
    required this.socket,
    required this.world,
    required this.game,
  });

  @override
  void onMount() {
    super.onMount();
    
    socket.onMessage((data) {
      final msg = jsonDecode(data);
      
      if (msg['type'] == NetworkMessage.playerJoined) {
        localPlayerId = msg['id'];
        print("🎮 You are: ${msg['name']} (${msg['id']})");
      }
      else if (msg['type'] == NetworkMessage.positionSync) {
        _handlePositionSync(msg);
      }
    });
  }

  void _handlePositionSync(Map<String, dynamic> msg) {
    final players = msg['players'] as List;
    
    for (final playerData in players) {
      final state = PlayerStateMessage.fromJson(playerData);
      
      if (state.id == localPlayerId) continue; // Skip self
      
      if (_remotePlayers.containsKey(state.id)) {
        _remotePlayers[state.id]!.updateFromServer(state);
      } else {
        _addRemotePlayer(state);
      }
    }
  }

  Future<void> _addRemotePlayer(PlayerStateMessage state) async {
    final remotePlayer = RemotePlayerComponent(
      game: game,
      initialState: state,
    );
    
    await world.add(remotePlayer);
    _remotePlayers[state.id] = remotePlayer;
    
    print("👥 Remote player ${state.name} joined");
  }
}