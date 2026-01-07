import 'package:flame/components.dart';
import '../../shared/machines/machine_type.dart';
import '../../shared/game/game_manager.dart';
import '../components/machines/base_machine.dart';

/// Tracks all placed machines on the map
class MachineRegistry extends Component {
  final Map<String, BaseMachine> _placedMachines = {};
  final Map<String, BaseMachine> _machinesById = {};
  final GameManager gameManager;

  MachineRegistry({required this.gameManager});

  @override
  Future<void> onLoad() async {
    // Register self with game manager
    gameManager.registerMachineRegistry(this);
  }

  /// Register a new machine
  void registerMachine(Vector2 tilePos, BaseMachine machine) {
    final key = _tileKey(tilePos);
    _placedMachines[key] = machine;
    _machinesById[machine.machineId] = machine;
    
    // Register with game manager (energy + pollution)
    gameManager.registerMachine(machine);
    
    print('Registered ${machine.machineType.displayName} at $tilePos (ID: ${machine.machineId})');
  }

  /// Unregister machine
  void unregisterMachine(Vector2 tilePos) {
    final key = _tileKey(tilePos);
    final machine = _placedMachines.remove(key);
    if (machine != null) {
      _machinesById.remove(machine.machineId);
      // Unregister from game manager
      gameManager.unregisterMachine(machine);
      print('🗑️ Unregistered ${machine.machineType.displayName} from $tilePos');
    }
  }

  // void createMachine(BaseMachine machine)

  /// Remove machine directly (used for network sync)
  void removeMachine(BaseMachine machine) {
    // Remove from both maps
    final key = _tileKey(machine.tilePosition);
    _placedMachines.remove(key);
    _machinesById.remove(machine.machineId);
    
    // Remove from game world
    machine.removeFromParent();
    
    // Unregister from game systems
    gameManager.unregisterMachine(machine);
    
    print('🗑️ Machine removed: ${machine.machineType.displayName} at ${machine.tilePosition}');
  }

  /// Check if machine exists at tile
  bool hasMachineAt(Vector2 tilePos) {
    return _placedMachines.containsKey(_tileKey(tilePos));
  }

  /// Get machine at tile
  BaseMachine? getMachineAt(Vector2 tilePos) {
    return _placedMachines[_tileKey(tilePos)];
  }

  /// Get machine by ID (for network sync)
  BaseMachine? getMachineById(String machineId) {
    return _machinesById[machineId];
  }

  /// Get all machines
  List<BaseMachine> getAllMachines() {
    return _placedMachines.values.toList();
  }

  /// Get machines by type
  List<BaseMachine> getMachinesByType(MachineType type) {
    return _placedMachines.values
        .where((m) => m.machineType == type)
        .toList();
  }

  /// Tick all machines
  void tickAllMachines() {
    for (final machine in _placedMachines.values) {
      // Update powered state from energy node
      if (machine.energyNode != null) {
        machine.isPowered = machine.energyNode!.isPowered;
      }
      
      // Tick the machine
      machine.tick();
    }
  }

  /// Clear all
  void clear() {
    // Unregister all machines
    for (final machine in _placedMachines.values) {
      gameManager.unregisterMachine(machine);
    }
    _placedMachines.clear();
    _machinesById.clear();
  }

  String _tileKey(Vector2 tilePos) {
    return "${tilePos.x.toInt()},${tilePos.y.toInt()}";
  }
}