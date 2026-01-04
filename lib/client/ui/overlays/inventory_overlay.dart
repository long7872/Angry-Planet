import 'package:flutter/material.dart';
import '../../../shared/inventory/inventory.dart';
import '../../utils/icon_data.dart';

class InventoryOverlay extends StatelessWidget {
  final Inventory inventory;
  final VoidCallback onClose;

  const InventoryOverlay({
    Key? key,
    required this.inventory,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2C2416),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF8B7355), width: 4),
              ),
              child: Column(
                children: [
                  // Header
                  Text(
                    'Inventory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Items grid
                  Expanded(
                    child: inventory.isEmpty
                        ? Center(
                            child: Text(
                              'No items',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                            ),
                            itemCount: inventory.getAllStacks().length,
                            itemBuilder: (context, index) {
                              final stack = inventory.getAllStacks()[index];
                              return _buildInventorySlot(stack);
                            },
                          ),
                  ),
                  // Close button
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventorySlot(stack) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B7355), width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStackIcon(stack),
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Text(
                  stack.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${stack.quantity}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStackIcon(stack) {
    if (stack.isResource) {
      return getResourceIcon(stack.asResource!);
    } else {
      return getMachineIcon(stack.asMachine!);
    }
  }

}