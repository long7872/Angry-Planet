import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'player.dart';

class MyGame extends FlameGame {
  late Player player;
  late JoystickComponent joystick;
  final Logger logger = Logger();

  @override
  Future<void> onLoad() async {
    logger.d('MyGame onLoad started');
    super.onLoad();
    logger.d('Screen size: ${size.x}x${size.y}');

    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;
    logger.d('Player created at position: ${player.position.x.toStringAsFixed(1)}, ${player.position.y.toStringAsFixed(1)}');

    add(player);
    logger.d('Player added to game');

    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    logger.d('Joystick created');

    camera.viewport.add(joystick);
    logger.d('Joystick added to viewport');

    logger.d('MyGame onLoad completed');
  }

  static const double speed = 120;

  @override
  void update(double dt) {
    // Comment log frame để chống lag - chỉ log nếu cần
    // logger.d('Update frame started (dt: ${dt.toStringAsFixed(4)})');
    super.update(dt);

    if (joystick.direction != Vector2.zero()) {
      final delta = joystick.relativeDelta * speed * dt;
      // logger.d('Joystick active - delta: ${delta.x.toStringAsFixed(1)}, ${delta.y.toStringAsFixed(1)}');  // Comment để giảm lag

      final newPosition = player.position + delta;
      // logger.d('Calculated new position: ${newPosition.x.toStringAsFixed(1)}, ${newPosition.y.toStringAsFixed(1)}');  // Comment

      if ((newPosition - player.position).length > 0.5) {
        player.position = newPosition;
        // logger.d('Position updated to: ${player.position.x.toStringAsFixed(1)}, ${player.position.y.toStringAsFixed(1)}');  // Comment
        // Bỏ gọi schedule - giờ throttle tự gửi
      } else {
        // logger.d('No update - movement too small');  // Comment
      }

      final halfSize = player.size / 2;
      player.position.x = player.position.x.clamp(halfSize.x, size.x - halfSize.x);
      player.position.y = player.position.y.clamp(halfSize.y, size.y - halfSize.y);
      // logger.d('Position clamped: ${player.position.x.toStringAsFixed(1)}, ${player.position.y.toStringAsFixed(1)}');  // Comment
    } else {
      // logger.d('Joystick idle - no movement');  // Comment
    }

    // logger.d('Update frame ended');  // Comment
  }
}