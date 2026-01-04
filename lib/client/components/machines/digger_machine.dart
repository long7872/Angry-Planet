import 'base_machine.dart';
import 'package:flame/game.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/resources/resource_type.dart';

/// Digger - Extracts ore from resource nodes
class DiggerMachine extends BaseMachine {
  final ResourceType resourceNode;  // What this digger extracts
  double extractionProgress = 0;
  static const double extractionTime = 5;  // 5 seconds per item

  DiggerMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
    required this.resourceNode,  // coal, ironOre, or energyCatalyst
  }) : super(
          machineType: MachineType.digger,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  void operate() {
    // Check if it have enough energy to work
    if (!canOperate()) {
      print('⛏️ Digger: No energy (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
      return;
    }
    
    // Check if output has space
    if (outputStorage.getResourceQuantity(resourceNode) >= stats.storageCapacity) {
      print('⛏️ Digger output full');
      return;
    }
    
    // Consume energy for this tick
    if (!consumeEnergy()) {
      print('⛏️ Digger: Failed to consume energy');
      return;
    }

    // Extract progress
    extractionProgress += 1;  // 1 second per tick

    if (extractionProgress >= extractionTime) {
      // Produce one item
      outputStorage.addResource(resourceNode, 1);
      extractionProgress = 0;
      print('⛏️ Digger extracted: 1 ${resourceNode.displayName}');
    }
  }

  /// Get extraction progress (0-1)
  double get progress => extractionProgress / extractionTime;
}