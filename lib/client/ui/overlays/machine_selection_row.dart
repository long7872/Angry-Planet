import 'package:flutter/material.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/machines/machine_stats.dart';
import '../../../shared/inventory/inventory.dart';
import '../../utils/icon_data.dart';

class MachineSelectionRow extends StatelessWidget {
  final List<MachineType> placeableMachines;
  final Inventory inventory;
  final Function(MachineType) onMachineSelected;
  final VoidCallback onClose;

  const MachineSelectionRow({
    Key? key,
    required this.placeableMachines,
    required this.inventory,
    required this.onMachineSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Container(
        height: 120,
        color: Colors.black87,
        child: Column(
          children: [
            // Hint text
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Select a machine to place',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            // Machine list
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 10),
                itemCount: placeableMachines.length + 1, // +1 for close button
                itemBuilder: (context, index) {
                  if (index == placeableMachines.length) {
                    return _buildCloseButton();
                  }
                  final machineType = placeableMachines[index];
                  return _buildMachineSlot(machineType);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineSlot(MachineType machineType) {
    final stats = getMachineStats(machineType);
    final canAfford = inventory.canAfford(stats.buildCost.toMap());

    return GestureDetector(
      onTap: canAfford ? () => onMachineSelected(machineType) : null,
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: canAfford ? Color(0xFF3D3020) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canAfford ? Colors.orange : Colors.grey,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  getMachineIcon(machineType),
                  size: 35,
                  color: canAfford ? Colors.white : Colors.grey.shade600,
                ),
                SizedBox(height: 4),
                Text(
                  machineType.displayName,
                  style: TextStyle(
                    color: canAfford ? Colors.white : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
            if (!canAfford)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.lock,
                  color: Colors.red,
                  size: 16,
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