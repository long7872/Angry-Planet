import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../shared/items/item_type.dart';
import '../../../shared/items/item_definition.dart';

class GhostPreview extends PositionComponent {
  final ItemType itemType;
  final Vector2 tilePosition;
  final FlameGame game;
  
  late Sprite ghostSprite;

  GhostPreview({
    required this.itemType,
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
    final itemDef = getItemDefinition(itemType);
    final image = await game.images.load(itemDef.spritePath);
    ghostSprite = Sprite(image);
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