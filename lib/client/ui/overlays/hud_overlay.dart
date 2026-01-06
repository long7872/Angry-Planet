import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final VoidCallback onBaloPressed;
  final VoidCallback onItemPressed;
  final VoidCallback onRepairPressed;
  final bool isRepairMode;

  const HudOverlay({
    Key? key,
    required this.onBaloPressed,
    required this.onItemPressed,
    required this.onRepairPressed,
    required this.isRepairMode,
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
              // ✓ NEW: Repair Button
              _buildButton(
                onPressed: onRepairPressed,
                icon: Icons.build_circle,
                color: isRepairMode ? Colors.orange : Colors.green,
                isActive: isRepairMode,
              ),
              SizedBox(width: 12),
              // Item Button
              _buildButton(
                onPressed: onItemPressed,
                icon: Icons.build,
                color: Colors.orange,
                isActive: false,
              ),
              SizedBox(width: 12),
              // Balo (Inventory) Button
              _buildButton(
                onPressed: onBaloPressed,
                icon: Icons.inventory_2,
                color: Colors.blue,
                isActive: false,
              ),
            ],
          ),
        ),

        // Repair mode indicator
        if (isRepairMode)
          Positioned(
            right: 20,
            bottom: 110,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 28),
                  SizedBox(height: 6),
                  Text(
                    'REPAIR MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Click damaged machines',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.park, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '2 Wood = 4 HP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required bool isActive,
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
            border: Border.all(
              color: isActive ? Colors.yellow : Colors.white,  // Yellow border when active
              width: isActive ? 4 : 3,  // Thicker when active
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
              // Glow effect when active
              if (isActive)
                BoxShadow(
                  color: Colors.orange.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 3,
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