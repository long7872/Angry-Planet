import 'base_machine.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/machines/recipe.dart';
import '../../../shared/resources/resource_type.dart';

/// Smelter - Processes materials using recipes
class SmelterMachine extends BaseMachine {
  Recipe? currentRecipe;      // Recipe currently being processed
  Recipe? selectedRecipe;     // Recipe selected by player in UI
  double processingProgress = 0;
  bool isProcessing = false;

  SmelterMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.smelter,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  /// Override to only accept recipe-required resources
  @override
  bool addToInput(ResourceType resource, int amount) {
    // If no recipe selected, reject everything
    if (selectedRecipe == null) {
      print('⚗️ Smelter: No recipe selected, rejecting ${resource.displayName}');
      return false;
    }

    // Check if this resource is required by the selected recipe
    if (!selectedRecipe!.requiresResource(resource)) {
      print('⚗️ Smelter: ${resource.displayName} not required for ${selectedRecipe!.output.displayName} recipe');
      return false;
    }

    // Get the required amount for this resource
    final required = selectedRecipe!.getRequiredAmount(resource);
    final current = inputStorage.getResourceQuantity(resource);

    // Check if we already have enough
    if (current >= required) {
      print('⚗️ Smelter: Already have enough ${resource.displayName} ($current/$required)');
      return false;
    }

    // Only accept what we need (don't overfill)
    final needed = required - current;
    final toAdd = amount.clamp(0, needed);

    if (toAdd < amount) {
      print('⚗️ Smelter: Only accepting $toAdd of $amount ${resource.displayName} (have $current, need $required)');
    }

    // Add to storage
    final success = inputStorage.addResource(resource, toAdd);
    
    if (success) {
      final newAmount = inputStorage.getResourceQuantity(resource);
      print('⚗️ Smelter: Added $toAdd ${resource.displayName} ($newAmount/$required)');
    }
    
    return success && toAdd == amount;  // Only return true if we accepted the full amount
  }

  @override
  void operate() {
    // If currently processing, continue
    if (isProcessing && currentRecipe != null) {

      // Check if we have enough energy to continue
      if (!canOperate()) {
        print('⚗️ Smelter: No energy, pausing (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
        return;
      }

      // Consume energy for this tick
      if (!consumeEnergy()) {
        print('⚗️ Smelter: Failed to consume energy, pausing');
        return;
      }
      
      processingProgress += 1;  // 1 second per tick

      if (processingProgress >= currentRecipe!.processingTime) {
        // Finish processing
        _completeRecipe();
      }
      return;
    }

    // Try to start a new recipe (only if recipe is selected)
    if (selectedRecipe != null) {
      _tryStartRecipe();
    }
  }

  void _tryStartRecipe() {
    // Only try to start the selected recipe
    if (selectedRecipe == null) return;

    // Check if we have ALL required inputs
    bool hasAllInputs = true;
    for (final input in selectedRecipe!.inputs) {
      if (!inputStorage.hasResource(input.resource, input.amount)) {
        hasAllInputs = false;
        break;
      }
    }

    if (!hasAllInputs) {
      return;  // Not ready yet
    }

    // Check if output has space
    final currentOutput = outputStorage.getResourceQuantity(selectedRecipe!.output);
    if (currentOutput + selectedRecipe!.outputAmount > stats.storageCapacity) {
      print('⚗️ Smelter: Output full, cannot start');
      return;
    }

    // Consume ALL inputs
    for (final input in selectedRecipe!.inputs) {
      inputStorage.removeResource(input.resource, input.amount);
    }

    // Start recipe
    currentRecipe = selectedRecipe;
    processingProgress = 0;
    isProcessing = true;
    
    print('⚗️ Smelter started: ${selectedRecipe!.inputSummary} → ${selectedRecipe!.output.displayName}');
  }

  void _completeRecipe() {
    if (currentRecipe == null) return;

    // Add output
    outputStorage.addResource(currentRecipe!.output, currentRecipe!.outputAmount);
    print('⚗️ Smelter completed: +${currentRecipe!.outputAmount} ${currentRecipe!.output.displayName}');

    // Reset
    isProcessing = false;
    processingProgress = 0;
    currentRecipe = null;
  }

  /// Get all items currently in input storage
  Map<ResourceType, int> getAllInputItems() {
    final items = <ResourceType, int>{};
    for (final stack in inputStorage.getAllStacks()) {
      if (stack.isResource) {
        items[stack.asResource!] = stack.quantity;
      }
    }
    return items;
  }

  /// Clear all inputs and return them
  Map<ResourceType, int> clearAllInputs() {
    final items = getAllInputItems();
    
    // Remove all from storage
    for (final entry in items.entries) {
      inputStorage.removeResource(entry.key, entry.value);
    }
    
    print('⚗️ Smelter cleared inputs: ${items.entries.map((e) => "${e.value} ${e.key.displayName}").join(", ")}');
    return items;
  }

  /// Get processing progress (0-1)
  double get progress {
    if (!isProcessing || currentRecipe == null) return 0;
    return processingProgress / currentRecipe!.processingTime;
  }

  // @override
  // double getCurrentEnergyConsumption() {
  //   // Only report consumption when actually processing
  //   if (!isProcessing || !isPowered || !canOperate()) return 0;
  //   return stats.energyConsumption;
  // }

  // @override
  // double getCurrentPollutionRate() {
  //   // ✓ Only pollute when actually processing
  //   if (!isProcessing || !isPowered || !canOperate()) return 0;
  //   return stats.pollutionRate;
  // }
}