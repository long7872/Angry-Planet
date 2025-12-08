import 'package:flame/components.dart';
import '../../server/world/chunk.dart';
import '../render/chunk_renderer.dart';
import '../render/sprite_manager.dart';

class ClientWorld extends World {
  final Map<String, ChunkRenderer> _renderedChunks = {};
  final SpriteManager spriteManager;

  ClientWorld({required this.spriteManager});

  @override
  void onMount() {
    super.onMount();
    print("🌍 ClientWorld mounted! Parent: ${parent?.runtimeType}");
  }

  /// Add chunk to be rendered
  void addChunk(Chunk chunk) {
    final key = "${chunk.cx},${chunk.cy}";
    
    if (_renderedChunks.containsKey(key)) {
      print("⚠️ Chunk $key already exists");
      return;
    }

    print("➕ Adding chunk $key to ClientWorld");
    
    final renderer = ChunkRenderer(
      chunk: chunk,
      spriteManager: spriteManager,
    );
    
    add(renderer);
    _renderedChunks[key] = renderer;
    
    print("✅ Chunk $key added (total chunks: ${_renderedChunks.length})");
  }

  /// Remove chunk from rendering
  void removeChunk(int cx, int cy) {
    final key = "$cx,$cy";
    final renderer = _renderedChunks.remove(key);
    
    if (renderer != null) {
      remove(renderer);
    }
  }

  /// Clear all chunks
  void clear() {
    for (var renderer in _renderedChunks.values) {
      remove(renderer);
    }
    _renderedChunks.clear();
  }

  /// Check if chunk is loaded
  bool hasChunk(int cx, int cy) {
    return _renderedChunks.containsKey("$cx,$cy");
  }
}