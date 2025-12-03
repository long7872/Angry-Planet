import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../server/world/chunk.dart';
import '../../shared/tile_type.dart';
import 'tile_colors.dart';

class ChunkRenderer extends Component {
  static const double tileSize = 16.0; // pixels per tile

  final Chunk chunk;
  final Paint _paint = Paint();
  final Paint _resourcePaint = Paint();

  ChunkRenderer(this.chunk);

  @override
  void render(Canvas canvas) {
    final worldX = chunk.cx * Chunk.size * tileSize;
    final worldY = chunk.cy * Chunk.size * tileSize;

    for (int ty = 0; ty < Chunk.size; ty++) {
      for (int tx = 0; tx < Chunk.size; tx++) {
        final tile = chunk.tiles[ty * Chunk.size + tx];

        // Draw biome
        _paint.color = TileColors.getBiome(tile.biome);
        
        final rect = Rect.fromLTWH(
          worldX + tx * tileSize,
          worldY + ty * tileSize,
          tileSize,
          tileSize,
        );
        
        canvas.drawRect(rect, _paint);

        // Draw resource if present
        if (tile.resource != ResourceType.none) {
          final resourceColor = TileColors.getResource(tile.resource);
          if (resourceColor != null) {
            _resourcePaint.color = resourceColor;
            
            // Draw small circle in center
            final center = Offset(
              worldX + tx * tileSize + tileSize / 2,
              worldY + ty * tileSize + tileSize / 2,
            );
            
            canvas.drawCircle(center, tileSize * 0.3, _resourcePaint);
          }
        }
      }
    }
  }
}