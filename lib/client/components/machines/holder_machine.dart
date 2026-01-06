import '../../../shared/inventory/item_stack.dart';
import '../../../shared/resources/resource_type.dart';
import 'base_machine.dart';
import 'package:flame/game.dart';
import '../../../shared/machines/machine_type.dart';

/// Holder - Storage container
class HolderMachine extends BaseMachine {
  HolderMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.holder,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  void operate() {
    // Holder consumes minimal energy just to stay powered
    if (!canOperate()) {
      print('📦 Holder: No energy (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
      return;
    }

    // Consume energy for this tick
    consumeEnergy();
  }

  /// Get total items stored
  int get totalItemsStored {
    return inputStorage.getAllStacks().fold(0, (sum, stack) => sum + stack.quantity);
  }

  /// Get storage usage percentage
  double get storageUsage {
    return (totalItemsStored / stats.storageCapacity) * 100;
  }

  @override
  bool addToInput(ResourceType resource, int amount) {
    // ✓ Check if powered - if not, reject
    if (!isPowered) {
      print('📦 Holder: No power - cannot accept items');
      return false;
    }

    // Check if we have space for the items
    final currentTotal = totalItemsStored;
    final spaceAvailable = stats.storageCapacity - currentTotal;
    
    if (spaceAvailable <= 0) {
      print('📦 Holder storage full: $currentTotal / ${stats.storageCapacity}');
      return false;
    }
    
    // Only add what fits
    final amountToAdd = amount.clamp(0, spaceAvailable);
    
    if (amountToAdd < amount) {
      print('📦 Holder can only accept $amountToAdd / $amount items (${currentTotal + amountToAdd} / ${stats.storageCapacity})');
    }
    
    if (amountToAdd > 0) {
      final success = inputStorage.addResource(resource, amountToAdd);
      if (success) {
        print('📦 Holder stored $amountToAdd ${resource.displayName} ($totalItemsStored / ${stats.storageCapacity})');
      }
      return success;
    }
    
    return false;
  }

  /// Override takeFromOutput for consistency (Holder uses inputStorage as main storage)
  @override
  bool takeFromOutput(ResourceType resource, int amount) {
    // Check if powered - if not, reject
    if (!isPowered) {
      print('📦 Holder: No power - cannot take items');
      return false;
    }
    
    // For holder, "output" is also the inputStorage
    return inputStorage.removeResource(resource, amount);
  }

  /// Holder uses inputStorage for everything
  @override
  List<ItemStack> getAvailableOutputStacks() {
    return inputStorage.getAllStacks();
  }

  // @override
  // double getCurrentEnergyConsumption() {
  //   // Only report consumption when powered
  //   if (!isPowered) return 0;
  //   return stats.energyConsumption;
  // }

  // @override
  // double getCurrentPollutionRate() {
  //   // Holder doesn't pollute
  //   return 0;
  // }
}