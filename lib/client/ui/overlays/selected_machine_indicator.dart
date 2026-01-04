import 'package:flutter/material.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/machines/machine_stats.dart';
import '../../../shared/resources/resource_type.dart';
import '../../utils/icon_data.dart';

class SelectedMachineIndicator extends StatelessWidget {  // ✓ Renamed class
  final MachineType selectedMachine;
  final ValueNotifier<bool> hasValidTilesNotifier;
  final ValueNotifier<int> validTileCountNotifier;
  final VoidCallback? onFindResource;
  final VoidCallback? onCancel;

  const SelectedMachineIndicator({  // ✓ Renamed constructor
    Key? key,
    required this.selectedMachine,
    required this.hasValidTilesNotifier,
    required this.validTileCountNotifier,
    this.onFindResource,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = getMachineStats(selectedMachine);

    return ValueListenableBuilder<bool>(
      valueListenable: hasValidTilesNotifier,
      builder: (context, hasValidTiles, child) {
        return ValueListenableBuilder<int>(
          valueListenable: validTileCountNotifier,
          builder: (context, validCount, child) {
            print('🔧 Selected Machine Indicator rebuilt. Machine: ${stats.type.displayName}, ValidTiles: $hasValidTiles, Count: $validCount');
            
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
                          getMachineIcon(selectedMachine),
                          size: 30,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              stats.type.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              hasValidTiles 
                                  ? 'Tap yellow tile ($validCount nearby)'
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
                        'Needs: ${stats.validPlacements.map((r) => r.displayName).join(', ')}',
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (onFindResource != null)
                        ElevatedButton.icon(
                          onPressed: onFindResource,
                          icon: Icon(Icons.location_searching, size: 16),
                          label: Text('Find Resource (Debug)', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                    // Show build cost
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cost: ${stats.buildCost}',
                        style: TextStyle(
                          color: Colors.yellow.shade300,
                          fontSize: 11,
                        ),
                      ),
                    ),
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