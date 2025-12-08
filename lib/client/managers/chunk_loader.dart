import 'package:flame/components.dart';
import 'dart:async';
import 'dart:convert';

import '../network/ws_client.dart';
import '../world/client_world.dart';
import '../../server/world/chunk.dart';

class ChunkLoader extends Component {
  final ClientSocket wsClient;
  final ClientWorld clientWorld;
  final CameraComponent camera;
  final Vector2 Function() playerPosition;
  
  static const int viewDistance = 2;
  static const double checkInterval = 0.5;
  
  double _timeSinceLastCheck = 0;
  final Set<String> _requestedChunks = {};

  ChunkLoader({
    required this.wsClient,
    required this.clientWorld,
    required this.camera,
    required this.playerPosition,
  });

  @override
  void onMount() {
    super.onMount();
    
    print("📦 ChunkLoader mounted");
    
    wsClient.onMessage((data) {
      print("📨 Raw message received (${data.length} bytes)");
      
      try {
        final msg = jsonDecode(data);
        print("📨 Message type: ${msg['type']}");
        
        if (msg['type'] == 'chunk_data') {
          print("✅ Received chunk_data!");
          final chunk = Chunk.fromJson(msg['data']);
          clientWorld.addChunk(chunk);
          print("✅ Chunk (${chunk.cx}, ${chunk.cy}) added to world");
        }
      } catch (e) {
        print("❌ Error parsing message: $e");
      }
    });
    
    print("📦 Requesting initial chunks...");
    _checkAndRequestChunks();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _timeSinceLastCheck += dt;
    if (_timeSinceLastCheck >= checkInterval) {
      _checkAndRequestChunks();
      _timeSinceLastCheck = 0;
    }
  }

  void _checkAndRequestChunks() {
    final playerPos = playerPosition();
    final playerChunkX = (playerPos.x / (Chunk.size * 16)).floor();
    final playerChunkY = (playerPos.y / (Chunk.size * 16)).floor();

    print("🎮 Player at world (${playerPos.x.toStringAsFixed(1)}, ${playerPos.y.toStringAsFixed(1)}) = chunk ($playerChunkX, $playerChunkY)");

    var requestCount = 0;
    for (int dy = -viewDistance; dy <= viewDistance; dy++) {
      for (int dx = -viewDistance; dx <= viewDistance; dx++) {
        final cx = playerChunkX + dx;
        final cy = playerChunkY + dy;
        final key = "$cx,$cy";

        if (!_requestedChunks.contains(key)) {
          _requestChunk(cx, cy);
          _requestedChunks.add(key);
          requestCount++;
        }
      }
    }
    
    if (requestCount > 0) {
      print("📤 Requested $requestCount new chunks");
    }
  }

  void _requestChunk(int cx, int cy) {
    final message = jsonEncode({
      'type': 'get_chunk',
      'cx': cx,
      'cy': cy,
    });
    
    print("📤 Requesting chunk ($cx, $cy)");
    wsClient.send(message);
  }
}