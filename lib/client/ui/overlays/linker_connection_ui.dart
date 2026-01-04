import 'package:flutter/material.dart';
import '../../components/machines/base_machine.dart';
import '../../components/machines/energy_linker_machine.dart';
import '../../components/machines/item_linker_machine.dart';
import '../../../shared/machines/machine_type.dart';
import '../../utils/icon_data.dart';
import '../dialogs/machine_selector_dialog.dart';

class LinkerConnectionUI extends StatelessWidget {
  final BaseMachine linker;
  final List<BaseMachine> availableMachines;
  final Function(BaseMachine?) onSetSource;
  final Function(BaseMachine?, int) onSetTarget;

  const LinkerConnectionUI({
    Key? key,
    required this.linker,
    required this.availableMachines,
    required this.onSetSource,
    required this.onSetTarget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnergyLinker = linker is EnergyLinkerMachine;
    final source = isEnergyLinker 
        ? (linker as EnergyLinkerMachine).sourceMachine
        : (linker as ItemLinkerMachine).sourceMachine;
    final targets = isEnergyLinker
        ? (linker as EnergyLinkerMachine).targetMachines
        : (linker as ItemLinkerMachine).targetMachines;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnergyLinker ? Colors.lightBlue : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          
          // Source selection
          _buildConnectionSection(
            context,
            'Source (Pull From)',
            source,
            Icons.upload,
            Colors.green,
            (machine) => onSetSource(machine),
          ),
          
          SizedBox(height: 5),
          
          // Visual flow indicator
          Center(
            child: Icon(
              Icons.arrow_downward,
              color: isEnergyLinker ? Colors.lightBlue : Colors.orange.shade300,
              size: 15,
            ),
          ),
          
          SizedBox(height: 5),

          // ✓ Target slots (4)
          Text(
            'Targets (Push To)',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),

          ...List.generate(4, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _buildTargetSlot(
                context,
                index,
                targets[index],
                (machine) => onSetTarget(machine, index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnectionSection(
    BuildContext context,
    String title,
    BaseMachine? connectedMachine,
    IconData icon,
    Color color,
    Function(BaseMachine?) onSelect,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF4D4030),
        borderRadius: BorderRadius.circular(8),
        border: connectedMachine != null 
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          
          if (connectedMachine != null)
            Row(
              children: [
                Icon(
                  getMachineIcon(connectedMachine.machineType),
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connectedMachine.machineType.displayName,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        'at (${connectedMachine.tilePosition.x.toInt()}, ${connectedMachine.tilePosition.y.toInt()})',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () => onSelect(null),
                  tooltip: 'Disconnect',
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () => _showMachineSelector(context, onSelect),
              icon: Icon(Icons.add, size: 18),
              label: Text('Select Machine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Build target slot
  Widget _buildTargetSlot(
    BuildContext context,
    int slot,
    BaseMachine? target,
    Function(BaseMachine?) onSelect,
  ) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF4D4030),
        borderRadius: BorderRadius.circular(8),
        border: target != null 
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Row(
        children: [
          // Slot number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: target != null ? Colors.blue : Colors.grey.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${slot + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // Target info or select button
          if (target != null)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    getMachineIcon(target.machineType),
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target.machineType.displayName,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 18),
                    onPressed: () => onSelect(null),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showMachineSelector(context, onSelect),
                icon: Icon(Icons.add, size: 16, color: Colors.blue),
                label: Text(
                  'Add Target',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMachineSelector(BuildContext context, Function(BaseMachine?) onSelect) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MachineSelectorDialog(
          availableMachines: availableMachines,
          onSelect: onSelect,
          linker: linker,
        );
      },
    );
  }
}