import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';  // ← Thêm import này cho BasicPalette
import 'package:flutter/material.dart';
import 'player.dart';

class MyGame extends FlameGame {  // ← Không cần mixin nào cả
  late Player player;
  late JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Tạo nhân vật (giữ nguyên)
    player = Player()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;

    add(player);

    // 2. Tạo joystick (không cần DragCallbacks - nó tự handle drag)
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();  // Màu xanh đậm cho knob
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();  // Màu xanh nhạt cho background

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    // Add joystick vào viewport (HUD layer) để nó luôn ở trên cùng
    camera.viewport.add(joystick);
  }

  static const double speed = 50; // pixel/giây

  @override
  void update(double dt) {
    super.update(dt);

    // Di chuyển nhân vật theo joystick (giữ nguyên logic)
    if (joystick.direction != Vector2.zero()) {
      final delta = joystick.delta * speed * dt;  // delta = direction * intensity
      player.position += delta;

      // Giới hạn không cho ra khỏi màn hình
      player.position.clamp(Vector2.zero(), Vector2(size.x, size.y));
    }
  }
}