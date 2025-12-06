import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../server/world/chunk.dart';
import '../../shared/tile_type.dart';
import 'sprite_manager.dart';

class ChunkRenderer extends Component {
  static const double tileSize = 16.0; // pixels per tile

  final Chunk chunk;
  final SpriteManager spriteManager;
  final Paint _paint = Paint();
  final Paint _resourcePaint = Paint();

  ChunkRenderer({
    required this.chunk,
    required this.spriteManager,
  });

  @override
  void render(Canvas canvas) {
    final worldX = chunk.cx * Chunk.size * tileSize;
    final worldY = chunk.cy * Chunk.size * tileSize;

    for (int ty = 0; ty < Chunk.size; ty++) {
      for (int tx = 0; tx < Chunk.size; tx++) {
        final tile = chunk.tiles[ty * Chunk.size + tx];

        final position = Vector2(
          worldX + tx * tileSize,
          worldY + ty * tileSize,
        );

        // Draw biome
        final biomeSprite = spriteManager.getBiomeSprite(tile.biome);
        if (biomeSprite != null) {
          biomeSprite.render(
            canvas,
            position: position,
            size: Vector2.all(tileSize),
          );
        }
        
        // Draw resource with correct state
        if (tile.resource != ResourceType.none) {
          final resourceSprite = spriteManager.getResourceSprite(
            tile.resource,
            tile.resourceState,
          );
          
          if (resourceSprite != null) {
            resourceSprite.render(
              canvas,
              position: position,
              size: Vector2.all(tileSize),
            );
          }
        }
      }
    }
  }
}