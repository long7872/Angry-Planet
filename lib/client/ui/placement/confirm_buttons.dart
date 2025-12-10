import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ConfirmButtons extends PositionComponent with TapCallbacks {
  final Vector2 tilePosition;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final FlameGame game;

  late CircleComponent cancelButton;
  late CircleComponent acceptButton;
  late TextComponent cancelIcon;
  late TextComponent acceptIcon;

  ConfirmButtons({
    required this.tilePosition,
    required this.onAccept,
    required this.onCancel,
    required this.game,
  }) : super(
          position: (tilePosition * 16) + Vector2(-8, -24),
          size: Vector2(32, 16),
          priority: 20,
        );

  @override
  Future<void> onLoad() async {
    // Cancel button (left) - Red X
    cancelButton = CircleComponent(
      radius: 8,
      paint: Paint()..color = Colors.red.withOpacity(0.8),
      position: Vector2(-4, 0),
    );
    add(cancelButton);

    cancelIcon = TextComponent(
      text: '✕',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(3, -2),
    );
    cancelButton.add(cancelIcon);

    // Accept button (right) - Green Check
    acceptButton = CircleComponent(
      radius: 8,
      paint: Paint()..color = Colors.green.withOpacity(0.8),
      position: Vector2(20, 0),
    );
    add(acceptButton);

    acceptIcon = TextComponent(
      text: '✓',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(4, -2),
    );
    acceptButton.add(acceptIcon);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final localPos = event.localPosition;
    print("🎯 Button tap at local: $localPos");

    // Check cancel button (left) - larger hit area
    if ((localPos - Vector2(0, 0)).length < 12) {
      print("❌ Cancel button tapped!");
      onCancel();
    }
    // Check accept button (right) - larger hit area
    else if ((localPos - Vector2(30, 0)).length < 12) {
      print("✅ Accept button tapped!");
      onAccept();
    }
  }
}