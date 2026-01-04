import 'package:flutter/material.dart';
import '../../../shared/machines/machine_type.dart';
import '../../components/machines/base_machine.dart';
import '../../utils/icon_data.dart';

class MachineSelectorDialog extends StatefulWidget {
  final List<BaseMachine> availableMachines;
  final Function(BaseMachine?) onSelect;
  final BaseMachine linker;

  const MachineSelectorDialog({
    Key? key,
    required this.availableMachines,
    required this.onSelect,
    required this.linker,
  }) : super(key: key);

  @override
  State<MachineSelectorDialog> createState() => _MachineSelectorDialogState();
}

class _MachineSelectorDialogState extends State<MachineSelectorDialog> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final filteredMachines = _filterMachines();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF2C2416),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF8B7355), width: 4),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF3D3020),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings_input_component, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Select Machine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search machines...',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: Color(0xFF3D3020),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // Machine count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${filteredMachines.length} machine${filteredMachines.length != 1 ? 's' : ''} available',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            
            SizedBox(height: 10),
            
            // Machine list
            Expanded(
              child: filteredMachines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, color: Colors.white38, size: 48),
                          SizedBox(height: 10),
                          Text(
                            'No machines found',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredMachines.length,
                      itemBuilder: (context, index) {
                        final machine = filteredMachines[index];
                        return _buildMachineCard(machine);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<BaseMachine> _filterMachines() {
    if (_searchQuery.isEmpty) {
      return widget.availableMachines;
    }
    
    return widget.availableMachines.where((machine) {
      final name = machine.machineType.displayName.toLowerCase();
      final position = '${machine.tilePosition.x.toInt()},${machine.tilePosition.y.toInt()}';
      return name.contains(_searchQuery) || position.contains(_searchQuery);
    }).toList();
  }

  Widget _buildMachineCard(BaseMachine machine) {
    // Calculate distance from linker
    final dx = (machine.tilePosition.x - widget.linker.tilePosition.x).abs();
    final dy = (machine.tilePosition.y - widget.linker.tilePosition.y).abs();
    final distance = (dx + dy).toInt();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onSelect(machine);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF3D3020),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getMachineColor(machine),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Machine icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getMachineColor(machine).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getMachineIcon(machine.machineType),
                    color: _getMachineColor(machine),
                    size: 28,
                  ),
                ),
                
                SizedBox(width: 15),
                
                // Machine info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine.machineType.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '(${machine.tilePosition.x.toInt()}, ${machine.tilePosition.y.toInt()})',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.straighten, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '$distance tiles',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Status indicators
                      Row(
                        children: [
                          _buildStatusBadge(
                            machine.isPowered ? 'Powered' : 'No Power',
                            machine.isPowered ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          if (machine.stats.isGenerator)
                            _buildStatusBadge('Generator', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Select button
                Icon(Icons.chevron_right, color: Colors.orange, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getMachineColor(BaseMachine machine) {
    switch (machine.machineType) {
      case MachineType.burner:
        return Colors.orange;
      case MachineType.digger:
        return Colors.brown;
      case MachineType.chopper:
        return Colors.green;
      case MachineType.smelter:
        return Colors.deepOrange;
      case MachineType.holder:
        return Colors.blue;
      case MachineType.greener:
        return Colors.lightGreen;
      case MachineType.energyLinker:
        return Colors.lightBlue;
      case MachineType.itemLinker:
        return Colors.amber;
    }
  }
}