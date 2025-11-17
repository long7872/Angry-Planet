import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';

class Player extends RectangleComponent {
  Player()
      : super(
          size: Vector2.all(50),           // nhân vật là hình vuông 50x50
          paint: Paint()..color = const Color(0xFF00FF00),
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Vẽ thêm mắt cho dễ nhìn :)
    final eyePaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(const Offset(15, 15), 5, eyePaint);
    canvas.drawCircle(const Offset(35, 15), 5, eyePaint);
  }
}