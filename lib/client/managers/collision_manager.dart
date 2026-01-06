import 'package:flame/components.dart';
import '../../shared/tile_type.dart';
import '../components/machines/base_machine.dart';
import '../../shared/resources/resource_type.dart';
import '../world/client_world.dart';

/// Manages collision detection between player, forest tiles, and machines
class CollisionManager {
  final ClientWorld world;
  final List<BaseMachine> Function() getMachines;
  
  CollisionManager({
    required this.world,
    required this.getMachines,
  });

  /// Check if player can move to a position
  bool canMoveTo(Vector2 position, Vector2 size) {
    // Check all corners and center of player hitbox
    final halfSize = size / 2;
    final checkPoints = [
      position,  // Center
      position + Vector2(-halfSize.x + 2, -halfSize.y + 2),  // Top-left (with margin)
      position + Vector2(halfSize.x - 2, -halfSize.y + 2),   // Top-right (with margin)
      position + Vector2(-halfSize.x + 2, halfSize.y - 2),   // Bottom-left (with margin)
      position + Vector2(halfSize.x - 2, halfSize.y - 2),    // Bottom-right (with margin)
    ];

    for (final point in checkPoints) {
      final tileX = (point.x / 16).floor();
      final tileY = (point.y / 16).floor();

      final tilePos = Vector2(
        tileX.toDouble(),
        tileY.toDouble(),
      );
      
      // Check forest collision
      if (_isForestTile(tilePos)) {
        return false;
      }
      
      // Check machine collision
      if (_hasMachineAt(tileX, tileY)) {
        return false;
      }
    }
    return true;
  }

  /// Check if a tile is a forest
  bool _isForestTile(Vector2 tilePos) {
    final tile = _getTileAt(tilePos);
    return tile?.resource == ResourceType.wood;
  }

  /// Check if a machine exists at tile position
  bool _hasMachineAt(int tileX, int tileY) {
    final machines = getMachines();
    final tilePos = Vector2(tileX.toDouble(), tileY.toDouble());
    
    for (final machine in machines) {
      if (machine.tilePosition == tilePos) {
        return true;
      }
    }
    
    return false;
  }

  TileData? _getTileAt(Vector2 tilePos) {
    final chunkX = (tilePos.x / 32).floor();
    final chunkY = (tilePos.y / 32).floor();
    final localX = tilePos.x.toInt() % 32;
    final localY = tilePos.y.toInt() % 32;

    // Get chunk from world
    final chunk = world.getChunk(chunkX, chunkY);
    if (chunk == null) {
      print("⚠️ Chunk not loaded at ($chunkX, $chunkY)");
      return null;
    }

    return chunk.getTileLocal(localX, localY);
  }

  /// Check if a rectangle collides with any obstacles
  // bool isRectangleBlocked(Vector2 topLeft, Vector2 size) {
  //   // Check all corners of the rectangle
  //   final corners = [
  //     topLeft,  // Top-left
  //     topLeft + Vector2(size.x, 0),  // Top-right
  //     topLeft + Vector2(0, size.y),  // Bottom-left
  //     topLeft + size,  // Bottom-right
  //   ];
    
  //   for (final corner in corners) {
  //     if (!canMoveTo(corner)) {
  //       return true;
  //     }
  //   }
    
  //   // Check center
  //   final center = topLeft + size / 2;
  //   if (!canMoveTo(center)) {
  //     return true;
  //   }
    
  //   return false;
  // }
}