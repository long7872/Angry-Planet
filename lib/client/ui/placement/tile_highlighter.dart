import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class TileHighlighter extends PositionComponent {
  final Vector2 tilePosition;
  final bool isValid;
  late RectangleComponent glow;

  TileHighlighter({
    required this.tilePosition,
    this.isValid = true,
  }) : super(
          position: tilePosition * 16,
          size: Vector2.all(16),
          priority: 50,
        );

  @override
  Future<void> onLoad() async {
    // Color based on validity
    final color = isValid 
        ? Colors.yellow.withOpacity(0.5)   // Valid = Yellow/Green
        : Colors.red.withOpacity(0.5);     // Invalid = Red

    // Yellow pulsing glow
    glow = RectangleComponent(
      size: Vector2.all(16),
      paint: Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Add pulse effect
    glow.add(
      OpacityEffect.fadeOut(
        EffectController(
          duration: 0.8,
          alternate: true,
          infinite: true,
        ),
      ),
    );

    add(glow);
  }
}