import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final VoidCallback onBaloPressed;
  final VoidCallback onItemPressed;

  const HudOverlay({
    Key? key,
    required this.onBaloPressed,
    required this.onItemPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom-right buttons
        Positioned(
          right: 20,
          bottom: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item Button
              _buildButton(
                onPressed: onItemPressed,
                icon: Icons.build,
                color: Colors.orange,
              ),
              SizedBox(width: 12),
              // Balo (Inventory) Button
              _buildButton(
                onPressed: onBaloPressed,
                icon: Icons.inventory_2,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}