import 'package:angry_planet/client/game.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'base_machine.dart';

/// Visual health bar shown above damaged machines
class MachineHealthBar extends PositionComponent {
  final BaseMachine machine;
  final AngryPlanetGame game;
  
  static const double barWidth = 16;
  static const double barHeight = 3;
  static const double offsetY = -4;  // Above machine

  MachineHealthBar({
    required this.machine,
    required FlameGame game,
  }) : game = game as AngryPlanetGame;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Only show if damaged
    if (!machine.isDamaged) return;
    
    final healthPercentage = machine.healthPercentage;

    // Highlight if in repair mode
    final isRepairMode = game.machineRepairManager.isRepairMode;
    
    // Background (black)
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, offsetY, barWidth, barHeight),
      bgPaint,
    );
    
    // Health bar (color based on health)
    final healthColor = _getHealthColor(healthPercentage);
    final healthPaint = Paint()
      ..color = healthColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, offsetY, barWidth * healthPercentage, barHeight),
      healthPaint,
    );
    
    // Border (white)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawRect(
      Rect.fromLTWH(0, offsetY, barWidth, barHeight),
      borderPaint,
    );

    // Show repair icon if in repair mode
    if (isRepairMode) {
      _renderRepairIcon(canvas);
    }
  }

  void _renderRepairIcon(Canvas canvas) {
    const icon = Icons.build; // wrench icon

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 10, // chỉnh kích thước icon
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.orange,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();

    // Vị trí: trên thanh máu
    canvas.translate(
      barWidth / 2 - textPainter.width / 2,
      offsetY - 10,
    );

    textPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }

  Color _getHealthColor(double percentage) {
    if (percentage > 0.6) {
      return Colors.green;
    } else if (percentage > 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}