import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class MyGame extends FlameGame {
  late Player player;
  late JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    print('Game size: x=${size.x}, y=${size.y}');  // Debug screen size

    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;

    add(player);

    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    camera.viewport.add(joystick);
  }

  static const double speed = 200;

  @override
  void update(double dt) {
    super.update(dt);

    if (joystick.direction != Vector2.zero()) {
      final delta = joystick.delta * speed * dt;
      print('Joystick delta: ${delta.x.toStringAsFixed(1)}, ${delta.y.toStringAsFixed(1)}');  // Giữ debug

      player.position += delta;

      // Clamp sau +=, nhưng detect move trước clamp
      final preClampPos = player.position.clone();  // Clone pos trước clamp
      final moveDistance = preClampPos.distanceTo(player.position - delta);  // Distance từ pos cũ (trước +=)

      // Trigger gửi nếu intent move (delta hoặc distance > ngưỡng)
      if (moveDistance > 0.5 || delta.length > 1.0) {  // Detect intent, dù clamp
        print("Move intent detected! Pre-clamp distance: ${moveDistance.toStringAsFixed(2)}");
        player.sendPositionUpdate();  // Gọi hàm gửi từ player (thêm method này)
      }

      // Clamp sau
      final playerHalfSize = player.size / 2;
      player.position.clamp(playerHalfSize, size - playerHalfSize);
    }
  }
}