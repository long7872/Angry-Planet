import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../shared/machines/machine_type.dart';
import '../../render/icon_sprite_generator.dart';
import '../../utils/icon_data.dart';

/// Ghost preview for machine placement
class GhostPreview extends PositionComponent {
  final MachineType machineType; 
  final Vector2 tilePosition;
  final FlameGame game;
  
  late Sprite ghostSprite;

  GhostPreview({
    required this.machineType,
    required this.tilePosition,
    required this.game,
  }) : super(
          position: tilePosition * 16,
          size: Vector2.all(16),
          anchor: Anchor.topLeft,
          priority: 150,
        );

  @override
  Future<void> onLoad() async {
    
    try {
      // final image = await game.images.load('items/${machineType.name}.png')
      // print('Using icon for ${machineType.name}');
      final image = await IconSpriteGenerator.fromIcon(
        getMachineIcon(machineType),
        size: 16.0,  // Match your tile size
        color: getMachineColor(machineType),
      );;
      ghostSprite = image;
    } catch (e) {
      // Fallback to placeholder
      try {
        final image = await game.images.load('items/placeholder.png');
        ghostSprite = Sprite(image);
      } catch (e2) {
        // Create colored rectangle as last resort
        print('⚠️ Could not load sprite for ${machineType.name}');
      }
    }
  }

  @override
  void render(Canvas canvas) {
    
    // Draw at 30% opacity with slight tint
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..colorFilter = ColorFilter.mode(
        Colors.cyan.withOpacity(0.3),
        BlendMode.srcATop,
      );

    ghostSprite.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2.all(16),
      overridePaint: paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, 16, 16),
      borderPaint,
    );
  }
}