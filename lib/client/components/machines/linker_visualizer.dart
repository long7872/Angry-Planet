import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'base_machine.dart';
import 'energy_linker_machine.dart';
import 'item_linker_machine.dart';

/// Visualizes connections for linkers
class LinkerVisualizer extends Component {
  final BaseMachine linker;
  
  LinkerVisualizer({required this.linker});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (linker is EnergyLinkerMachine) {
      _renderEnergyLinker(canvas, linker as EnergyLinkerMachine);
    } else if (linker is ItemLinkerMachine) {
      _renderItemLinker(canvas, linker as ItemLinkerMachine);
    }
  }

  void _renderEnergyLinker(Canvas canvas, EnergyLinkerMachine energyLinker) {
    final source = energyLinker.sourceMachine;
    // final target = energyLinker.targetMachine;

    // Draw line from source to linker (if source exists)
    if (source != null) {
      final sourceCenter = source.position + Vector2.all(8);
      final sourceRelative = sourceCenter - linker.position;

      _drawConnectionLine(
        canvas,
        sourceRelative, 
        Vector2.all(8),  
        Colors.lightBlue,
        energyLinker.isTransferring,
      );
    }

    // Draw line from linker to target (if target exists)
    for (int i = 0; i < 4; i++) {
      final target = energyLinker.targetMachines[i];
      if (target != null) {
        final targetCenter = target.position + Vector2.all(8);
        final targetRelative = targetCenter - linker.position;
        
        _drawConnectionLine(
          canvas,
          Vector2.all(8),
          targetRelative,
          Colors.lightBlue,
          energyLinker.isTransferring,
        );
      }
    }
  }

  void _renderItemLinker(Canvas canvas, ItemLinkerMachine itemLinker) {
    final source = itemLinker.sourceMachine;
    // final target = itemLinker.targetMachine;

    // Draw line from source to linker (if source exists)
    if (source != null) {
      final sourceCenter = source.position + Vector2.all(8);
      final sourceRelative = sourceCenter - linker.position;
      
      _drawConnectionLine(
        canvas,
        sourceRelative,
        Vector2.all(8),
        Colors.orange.shade300,
        itemLinker.isTransferring,
      );
    }

    // Draw line from linker to target (if target exists)
    for (int i = 0; i < 4; i++) {
      final target = itemLinker.targetMachines[i];
      if (target != null) {
        final targetCenter = target.position + Vector2.all(8);
        final targetRelative = targetCenter - linker.position;
        
        _drawConnectionLine(
          canvas,
          Vector2.all(8),
          targetRelative,
          Colors.orange.shade300,
          itemLinker.isTransferring,
        );
      }
    }
  }

  void _drawConnectionLine(
    Canvas canvas,
    Vector2 start,
    Vector2 end,
    Color color,
    bool isActive,
  ) {
    final paint = Paint()
      ..color = isActive ? color : color.withOpacity(0.3)
      ..strokeWidth = isActive ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;

    // Draw main line
    canvas.drawLine(
      start.toOffset(),
      end.toOffset(),
      paint,
    );

    // Draw arrow at end
    _drawArrow(canvas, start, end, paint);
    
    // Draw pulsing effect when active
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawLine(
        start.toOffset(),
        end.toOffset(),
        glowPaint,
      );
    }
  }

  void _drawArrow(Canvas canvas, Vector2 start, Vector2 end, Paint paint) {
    // Calculate arrow direction
    final direction = (end - start).normalized();
    final perpendicular = Vector2(-direction.y, direction.x);
    
    // Arrow size
    const arrowSize = 6.0;
    
    // Arrow points
    final arrowTip = end;
    final arrowLeft = end - (direction * arrowSize) + (perpendicular * arrowSize * 0.5);
    final arrowRight = end - (direction * arrowSize) - (perpendicular * arrowSize * 0.5);
    
    // Draw arrow
    final arrowPath = Path()
      ..moveTo(arrowTip.x, arrowTip.y)
      ..lineTo(arrowLeft.x, arrowLeft.y)
      ..lineTo(arrowRight.x, arrowRight.y)
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }
}