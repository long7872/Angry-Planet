import 'package:flame/components.dart';
import '../../server/world/chunk.dart';
import '../render/chunk_renderer.dart';

class ClientWorld extends World {
  final Map<String, ChunkRenderer> _renderedChunks = {};

  /// Add chunk to be rendered
  void addChunk(Chunk chunk) {
    final key = "${chunk.cx},${chunk.cy}";
    
    if (_renderedChunks.containsKey(key)) return;

    final renderer = ChunkRenderer(chunk);
    add(renderer);
    _renderedChunks[key] = renderer;
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