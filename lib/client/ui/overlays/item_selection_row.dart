import 'package:flutter/material.dart';
import '../../../shared/items/item_type.dart';
import '../../../shared/items/item_definition.dart';
import '../../../shared/inventory/inventory.dart';
import '../../utils/icon_data.dart';

class ItemSelectionRow extends StatelessWidget {
  final List<ItemDefinition> placeableItems;
  final Inventory inventory;
  final Function(ItemType) onItemSelected;
  final VoidCallback onClose;

  const ItemSelectionRow({
    Key? key,
    required this.placeableItems,
    required this.inventory,
    required this.onItemSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Container(
        height: 100,
        color: Colors.black87,
        child: Column(
          children: [
            // Hint text
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Select an item to place',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            // Item list
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 10),
                itemCount: placeableItems.length + 1, // +1 for close button
                itemBuilder: (context, index) {
                  if (index == placeableItems.length) {
                    return _buildCloseButton();
                  }
                  final item = placeableItems[index];
                  return _buildItemSlot(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSlot(ItemDefinition item) {
    final quantity = inventory.getQuantity(item.type);
    final hasItem = quantity > 0;

    return GestureDetector(
      onTap: hasItem ? () => onItemSelected(item.type) : null,
      child: Container(
        width: 70,
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: hasItem ? Color(0xFF3D3020) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasItem ? Colors.orange : Colors.grey,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                getItemIcon(item.type),
                size: 35,
                color: hasItem ? Colors.white : Colors.grey.shade600,
              ),
            ),
            if (hasItem)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        width: 70,
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(
          Icons.close,
          size: 35,
          color: Colors.white,
        ),
      ),
    );
  }
}