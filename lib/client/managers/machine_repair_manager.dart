import 'package:angry_planet/shared/machines/machine_type.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../components/machines/base_machine.dart';
import '../../shared/inventory/inventory.dart';
import '../../shared/resources/resource_type.dart';
import '../world/client_world.dart';

/// Manages machine repair mode and interactions
class MachineRepairManager extends Component with TapCallbacks {
  final FlameGame game;
  final Inventory playerInventory;
  final ClientWorld world;
  
  static const int woodCostPerRepair = 2;
  static const double healthPerRepair = 4;
  
  // Repair mode state
  bool isRepairMode = false;

  MachineRepairManager({
    required this.game,
    required this.playerInventory,
    required this.world,
  });

  /// Toggle repair mode
  void toggleRepairMode() {
    isRepairMode = !isRepairMode;
    print(isRepairMode 
        ? '🔧 Repair mode ENABLED - Click damaged machines to repair' 
        : '🔧 Repair mode DISABLED');
  }

  /// Enable repair mode
  void enableRepairMode() {
    if (isRepairMode) return;
    isRepairMode = true;
    print('🔧 Repair mode ENABLED - Click damaged machines to repair');
  }

  /// Disable repair mode
  void disableRepairMode() {
    if (!isRepairMode) return;
    isRepairMode = false;
    print('🔧 Repair mode DISABLED');
  }

  /// Attempt to repair a machine at the tapped position
  @override
  void onTapDown(TapDownEvent event) {
    if (!isRepairMode) return;

    // Convert screen position to world position
    final screenPos = event.localPosition;
    final worldPos = game.camera.globalToLocal(screenPos);
    
    // Convert to tile position
    final tileX = (worldPos.x / 16).floor();
    final tileY = (worldPos.y / 16).floor();
    final tilePos = Vector2(tileX.toDouble(), tileY.toDouble());
    
    // Find machine at this position
    final machine = _findMachineAtTile(tilePos);
    
    if (machine != null && machine.isDamaged) {
      repairMachine(machine);
    } else if (machine != null && !machine.isDamaged) {
      print('🔧 Machine is already at full health');
    }
  }

  BaseMachine? _findMachineAtTile(Vector2 tilePos) {
    // Search all machines in world
    final machines = world.children.query<BaseMachine>();
    
    for (final machine in machines) {
      // Check if this machine's tile position matches
      if (machine.tilePosition.x.toInt() == tilePos.x.toInt() &&
          machine.tilePosition.y.toInt() == tilePos.y.toInt()) {
        return machine;
      }
    }
    
    return null;
  }

  /// Repair a specific machine
  void repairMachine(BaseMachine machine) {
    // Check if player has wood
    if (!playerInventory.hasResource(ResourceType.wood, woodCostPerRepair)) {
      final woodCount = playerInventory.getResourceQuantity(ResourceType.wood);
      print('🔧 Need $woodCostPerRepair wood to repair (You have $woodCount)');
      return;
    }
    
    // Check if machine needs repair
    if (machine.health >= machine.maxHealth) {
      print('🔧 Machine is already at full health');
      return;
    }
    
    // Consume wood
    playerInventory.removeResource(ResourceType.wood, woodCostPerRepair);
    
    // Repair machine
    final beforeHealth = machine.health;
    machine.repair(healthPerRepair);
    final afterHealth = machine.health;
    final actualRepair = afterHealth - beforeHealth;
    
    print('🔧 Repaired ${machine.machineType.displayName}: +${actualRepair.toInt()} HP (${afterHealth.toInt()}/${machine.maxHealth.toInt()}) [-$woodCostPerRepair Wood]');
  }
}