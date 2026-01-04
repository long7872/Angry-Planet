import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../shared/resources/resource_type.dart';
import '../../shared/tile_type.dart';

class SpriteManager {
  final Map<BiomeType, List<Sprite>> biomeVariations = {};
  final Map<ResourceType, Map<ResourceState, Sprite>> resourceSprites = {};

  Future<void> loadAll(FlameGame game) async {
    print("📦 Loading sprites...");
    
    await _loadBiomeTilesets(game);
    await _loadResourceSprites(game);
    
    print("✅ All sprites loaded!");
  }

  Future<void> _loadBiomeTilesets(FlameGame game) async {
    for (final biome in BiomeType.values) {
      biomeVariations[biome] = [];

      try {
        final image = await game.images.load('tiles/${biome.name}_tileset.png');

        print("  📐 ${biome.name}: ${image.width}×${image.height}px");

        if (image.width != 80 || image.height != 48) {
          print("  ⚠️ Warning: Expected 80×48, got ${image.width}×${image.height}");
        }

        const tileSize = 16.0;

        // Physical positions in sprite sheet
        final physicalLayout = [
          (0, 0),  // Pos 0:  inner_se
          (1, 0),  // Pos 1:  edge_n
          (2, 0),  // Pos 2:  inner_sw
          (3, 0),  // Pos 3:  outer_ne
          (4, 0),  // Pos 4:  outer_nw
          (0, 1),  // Pos 5:  edge_w
          (1, 1),  // Pos 6:  center
          (2, 1),  // Pos 7:  edge_e
          (3, 1),  // Pos 8:  outer_se
          (4, 1),  // Pos 9:  outer_sw
          (0, 2),  // Pos 10: inner_ne
          (1, 2),  // Pos 11: edge_s
          (2, 2),  // Pos 12: inner_nw
        ];

        // FINAL CORRECTED MAPPING - All corners fixed
        final logicalToPhysical = [
          9,   // 0: outer_nw → load from position 9 (outer_sw)
          1,   // 1: edge_n → load from position 1
          8,   // 2: outer_ne → load from position 8 (outer_se) ✓ NEW
          5,   // 3: edge_w → load from position 5
          6,   // 4: center → load from position 6
          7,   // 5: edge_e → load from position 7
          4,   // 6: outer_sw → load from position 4 (outer_nw)
          11,  // 7: edge_s → load from position 11
          3,   // 8: outer_se → load from position 3 (outer_ne) ✓ NEW
          0,   // 9: inner_nw → load from position 0 (inner_se)
          2,   // 10: inner_ne → load from position 2 (inner_sw) ✓ NEW
          12,  // 11: inner_se → load from position 12 (inner_nw)
          10,  // 12: inner_sw → load from position 10 (inner_ne) ✓ NEW
        ];
        
        // Load sprites in correct logical order
        for (int logicalIndex = 0; logicalIndex < 13; logicalIndex++) {
          final physicalIndex = logicalToPhysical[logicalIndex];
          final (col, row) = physicalLayout[physicalIndex];
          
          final sprite = Sprite(
            image,
            srcPosition: Vector2(col * tileSize, row * tileSize),
            srcSize: Vector2.all(tileSize),
          );
          biomeVariations[biome]!.add(sprite);
        }

        print("  ✓ ${biome.name}: ${biomeVariations[biome]!.length} tiles loaded (all corners fixed)");
      } catch (e) {
        print("  ⚠️ Failed to load ${biome.name}: $e");
        
        for (int i = 0; i < 13; i++) {
          biomeVariations[biome]!.add(await _createColoredSprite(biome, i));
        }
      }
    }
  }

  Future<void> _loadResourceSprites(FlameGame game) async {
    resourceSprites[ResourceType.coal] = {
      ResourceState.intact: await game.loadSprite('resources/coal/intact.png'),
    };

    resourceSprites[ResourceType.iron] = {
      ResourceState.intact: await game.loadSprite('resources/iron/intact.png'),
    };

    resourceSprites[ResourceType.energyCatalyst] = {
      ResourceState.intact: await game.loadSprite('resources/energy_catalyst/intact.png'),
    };

    resourceSprites[ResourceType.wood] = {
      ResourceState.intact: await game.loadSprite('resources/forest/intact.png'),
    };
  }

  Sprite? getBiomeVariation(BiomeType biome, int index) {
    final variations = biomeVariations[biome];
    if (variations == null || variations.isEmpty) return null;
    
    final safeIndex = index.clamp(0, 12);
    return variations[safeIndex];
  }

  Sprite? getResourceSprite(ResourceType resource, ResourceState state) {
    return resourceSprites[resource]?[state];
  }

  Future<Sprite> _createColoredSprite(BiomeType biome, int tileIndex) async {
    const size = 16;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final baseColor = _getBiomeBaseColor(biome);
    final higherColor = _getHigherBiomeColor(biome);

    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), bgPaint);

    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), borderPaint);

    if (higherColor != null) {
      _drawTransitionPattern(canvas, tileIndex, higherColor);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    
    return Sprite(image);
  }

  Color _getBiomeBaseColor(BiomeType biome) {
    switch (biome) {
      case BiomeType.water: return Color(0xFF2E5C8A);
      case BiomeType.sand:  return Color(0xFFE8D4A2);
      case BiomeType.grass: return Color(0xFF5C8A3D);
      case BiomeType.tree:  return Color(0xFF2D5016);
      case BiomeType.stone: return Color(0xFF6B6B6B);
    }
  }

  Color? _getHigherBiomeColor(BiomeType biome) {
    switch (biome) {
      case BiomeType.water: return Color(0xFFE8D4A2);
      case BiomeType.sand:  return Color(0xFF5C8A3D);
      case BiomeType.grass: return Color(0xFF2D5016);
      case BiomeType.tree:  return Color(0xFF6B6B6B);
      case BiomeType.stone: return null;
    }
  }

  void _drawTransitionPattern(Canvas canvas, int tileIndex, Color higherColor) {
    final paint = Paint()..color = higherColor;

    switch (tileIndex) {
      case 0: canvas.drawCircle(Offset(4, 4), 3, paint); break;
      case 1: canvas.drawRect(Rect.fromLTWH(4, 0, 8, 4), paint); break;
      case 2: canvas.drawCircle(Offset(12, 4), 3, paint); break;
      case 3: canvas.drawRect(Rect.fromLTWH(0, 4, 4, 8), paint); break;
      case 4: break;
      case 5: canvas.drawRect(Rect.fromLTWH(12, 4, 4, 8), paint); break;
      case 6: canvas.drawCircle(Offset(4, 12), 3, paint); break;
      case 7: canvas.drawRect(Rect.fromLTWH(4, 12, 8, 4), paint); break;
      case 8: canvas.drawCircle(Offset(12, 12), 3, paint); break;
      case 9: canvas.drawRect(Rect.fromLTWH(8, 0, 8, 8), paint); break;
      case 10: canvas.drawRect(Rect.fromLTWH(0, 0, 8, 8), paint); break;
      case 11: canvas.drawRect(Rect.fromLTWH(0, 8, 8, 8), paint); break;
      case 12: canvas.drawRect(Rect.fromLTWH(8, 8, 8, 8), paint); break;
    }
  }
}