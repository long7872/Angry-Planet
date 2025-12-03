import 'dart:convert';
import '../network/ws_client.dart';
import '../world/client_world.dart';
import '../../server/world/chunk.dart';
import 'package:flame/components.dart';

class ChunkLoader extends Component {
  final ClientSocket socket;
  final ClientWorld world;
  final CameraComponent camera;

  static const int viewDistance = 2; // chunks around camera
  static const double tileSize = 16.0;
  static const int chunkSize = 32;

  final Set<String> _requestedChunks = {};
  final Set<String> _loadedChunks = {};

  ChunkLoader({
    required this.socket,
    required this.world,
    required this.camera,
  });

  @override
  void onMount() {
    super.onMount();
    
    // Listen for chunk data
    socket.messages.listen((data) {
      final msg = jsonDecode(data);
      
      if (msg["type"] == "chunk_data") {
        final chunk = Chunk.fromJson(msg["chunk"]);
        world.addChunk(chunk);
        
        final key = "${chunk.cx},${chunk.cy}";
        _loadedChunks.add(key);
        _requestedChunks.remove(key);
      }
    });
  }

  @override
  void update(double dt) {
    // Get camera position in chunk coords
    final camPos = camera.viewfinder.position;
    final centerChunkX = (camPos.x / (tileSize * chunkSize)).floor();
    final centerChunkY = (camPos.y / (tileSize * chunkSize)).floor();

    // Request chunks around camera
    for (int cy = centerChunkY - viewDistance; 
         cy <= centerChunkY + viewDistance; 
         cy++) {
      for (int cx = centerChunkX - viewDistance; 
           cx <= centerChunkX + viewDistance; 
           cx++) {
        final key = "$cx,$cy";
        
        if (!_loadedChunks.contains(key) && 
            !_requestedChunks.contains(key)) {
          _requestChunk(cx, cy);
        }
      }
    }
  }

  void _requestChunk(int cx, int cy) {
    final key = "$cx,$cy";
    _requestedChunks.add(key);
    socket.getChunk(cx, cy);
  }
}