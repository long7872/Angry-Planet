import 'base_machine.dart';
import 'package:flame/game.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/resources/resource_type.dart';

/// Chopper - Harvests wood from forest tiles
class ChopperMachine extends BaseMachine {
  double harvestProgress = 0;
  static const double harvestTime = 5;  // 5 seconds per wood

  ChopperMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.chopper,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  void operate() {
    // Check if we have enough energy to work
    if (!canOperate()) {
      print('🪓 Chopper: No energy (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
      return;
    }
    
    // Check if output has space
    if (outputStorage.getResourceQuantity(ResourceType.wood) >= stats.storageCapacity) {
      print('🪓 Chopper output full');
      return;
    }

    // Consume energy for this tick
    if (!consumeEnergy()) {
      print('🪓 Chopper: Failed to consume energy');
      return;
    }

    // Harvest progress
    harvestProgress += 1;  // 1 second per tick

    if (harvestProgress >= harvestTime) {
      // Produce one wood
      outputStorage.addResource(ResourceType.wood, 1);
      harvestProgress = 0;
      print('🪓 Chopper harvested: 1 Wood');
    }
  }

  /// Get harvest progress (0-1)
  double get progress => harvestProgress / harvestTime;
}