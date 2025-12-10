import 'package:flutter/material.dart';
import '../../../shared/items/item_type.dart';
import '../../../shared/items/item_definition.dart';
import '../../utils/icon_data.dart';

class SelectedItemIndicator extends StatelessWidget {
  final ItemType selectedItem;
  final ValueNotifier<bool> hasValidTilesNotifier;  // ✓ Changed to ValueNotifier
  final ValueNotifier<int> validTileCountNotifier;  // ✓ NEW
  final VoidCallback? onFindStone;
  final VoidCallback? onCancel;

  const SelectedItemIndicator({
    Key? key,
    required this.selectedItem,
    required this.hasValidTilesNotifier,  // ✓ Changed
    required this.validTileCountNotifier,  // ✓ NEW
    this.onFindStone,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemDef = getItemDefinition(selectedItem);

    return ValueListenableBuilder<bool>(  // ✓ Wrap in ValueListenableBuilder
      valueListenable: hasValidTilesNotifier,
      builder: (context, hasValidTiles, child) {
        return ValueListenableBuilder<int>(  // ✓ Nested for count
          valueListenable: validTileCountNotifier,
          builder: (context, validCount, child) {
            print("🔧 Selected Item Indicator rebuilt. Item: ${itemDef.name}, ValidTiles: $hasValidTiles, Count: $validCount");
            
            return Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: hasValidTiles ? Colors.orange : Colors.red,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getItemIcon(selectedItem),
                          size: 30,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              itemDef.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              hasValidTiles 
                                  ? 'Tap yellow tile ($validCount nearby)'  // ✓ Show count
                                  : 'No valid tiles nearby!',
                              style: TextStyle(
                                color: hasValidTiles ? Colors.white70 : Colors.red.shade300,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (onCancel != null) ...[
                          SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onCancel,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!hasValidTiles) ...[
                      SizedBox(height: 8),
                      Text(
                        'Needs: ${itemDef.validResources.map((r) => r.name).join(', ')}',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (onFindStone != null)
                        ElevatedButton.icon(
                          onPressed: onFindStone,
                          icon: Icon(Icons.location_searching, size: 16),
                          label: Text('Find Resource (Debug)', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}