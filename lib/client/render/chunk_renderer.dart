import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../server/world/chunk.dart';
import '../../shared/tile_type.dart';
import '../../shared/autotile_config.dart';
import 'sprite_manager.dart';
import 'autotile_mapper.dart';

class ChunkRenderer extends Component {
  static const double tileSize = 16.0; // pixels per tile

  final Chunk chunk;
  final SpriteManager spriteManager;

  final List<_RenderOp> _cache = [];
  bool _built = false;

  ChunkRenderer({
    required this.chunk,
    required this.spriteManager,
  }) : super(
    priority: 0
  );

  @override
  void onMount() {
    super.onMount();
    print("🎨 ChunkRenderer mounted for chunk (${chunk.cx},${chunk.cy})");
    _buildCache();
    print("✅ Cache built with ${_cache.length} render ops");
  }

  void _buildCache() {
    if (_built) return;

    final worldX = chunk.cx * Chunk.size * tileSize;
    final worldY = chunk.cy * Chunk.size * tileSize;

    // Debug: Track unusual patterns
    final debugSamples = <String>[];

    for (int ty = 0; ty < Chunk.size; ty++) {
      for (int tx = 0; tx < Chunk.size; tx++) {
        final tile = chunk.tiles[ty * Chunk.size + tx];
        final pos = Vector2(
          worldX + tx * tileSize,
          worldY + ty * tileSize,
        );

        // 1. Calculate bitmask for this tile
        final bitmask = AutotileConfig.calculateBitmask((dx, dy) {
          final neighbor = _getNeighbor(tx, ty, dx, dy);
          return neighbor != null &&
            neighbor.biome != tile.biome &&
            tile.biome.shouldDrawTransitionTo(neighbor.biome);
        });

        // 2. Map to tile index (0-12)
        final tileIndex = AutotileMapper.mapBitmaskToTileIndex(bitmask);

        // Debug: Collect samples of different patterns
        if (bitmask != 0 && debugSamples.length < 10) {
          final explanation = AutotileMapper.explainBitmask(bitmask);
          if (!debugSamples.contains(explanation)) {
            debugSamples.add(explanation);
          }
        }

        // 3. Get sprite for this variation
        final sprite = spriteManager.getBiomeVariation(tile.biome, tileIndex);
        if (sprite != null) {
          _cache.add(_RenderOp(sprite, pos.clone()));
        }

        // 4. Cache resource (same as before)
        if (tile.resource != ResourceType.none) {
          final resSprite = spriteManager.getResourceSprite(
            tile.resource,
            tile.resourceState,
          );

          if (resSprite != null) {
            _cache.add(_RenderOp(resSprite, pos.clone()));
          }
        }
      }
    }

    // Print collected debug samples
    if (debugSamples.isNotEmpty) {
      print("🔍 Chunk (${chunk.cx},${chunk.cy}) patterns:");
      for (final sample in debugSamples) {
        print("  $sample");
      }
    }

    _built = true;
  }

  @override
  void render(Canvas canvas) {
    for (final op in _cache) {
      op.sprite.render(
        canvas,
        position: op.position,
        size: Vector2.all(tileSize),
      );
    }
    
    // Debug: Draw chunk boundary in red
    final debugPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final worldX = chunk.cx * Chunk.size * tileSize;
    final worldY = chunk.cy * Chunk.size * tileSize;
    
    canvas.drawRect(
      Rect.fromLTWH(
        worldX,
        worldY,
        Chunk.size * tileSize,
        Chunk.size * tileSize,
      ),
      debugPaint,
    );
  }

  void invalidate() {
    _built = false;
    _cache.clear();
    _buildCache();
  }

  TileData? _getNeighbor(int tx, int ty, int dx, int dy) {
    final nx = tx + dx;
    final ny = ty + dy;

    if (nx >= 0 && nx < Chunk.size && ny >= 0 && ny < Chunk.size) {
      return chunk.getTileLocal(nx, ny);
    }

    return null;
  }
}

class _RenderOp {
  final Sprite sprite;
  final Vector2 position;
  _RenderOp(this.sprite, this.position);
}