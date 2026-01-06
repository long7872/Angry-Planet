import 'base_machine.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/resources/resource_type.dart';
import 'holder_machine.dart';
import 'linker_visualizer.dart';
import 'smelter_machine.dart';

/// Item Linker - Transfers items between machines using pull-based logic
class ItemLinkerMachine extends BaseMachine {
  BaseMachine? sourceMachine;
  List<BaseMachine?> targetMachines = [null, null, null, null];
  
  // Transfer rate: 1 item per tick (distributed round-robin)
  static const int itemsPerTick = 1;
  
  // ✓ Track last transfer for visualization
  bool _lastTransferSuccessful = false;

  // Round-robin distribution
  int _currentTargetIndex = 0;

  late LinkerVisualizer visualizer;

  ItemLinkerMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.itemLinker,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add visualizer
    visualizer = LinkerVisualizer(linker: this);
    add(visualizer);
  }

  @override
  void operate() {
    if (!_canTransfer()) {
      _lastTransferSuccessful = false;
      return;
    }

    // Check if we have enough energy to operate
    if (!canOperate()) {
      print('📦 Item Linker: No energy to operate (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
      _lastTransferSuccessful = false;
      return;
    }
    
    // Pull-based: Try to move items from source output to target input
    _transferItems();

    // Consume energy for this tick
    if (_lastTransferSuccessful) {
      consumeEnergy();  // This sets isWorking = true
    }
  }

  /// Check if transfer is possible
  bool _canTransfer() {
    // Both machines must be set
    if (sourceMachine == null) return false;
    if (!hasAnyTarget) return false;
    
    // Source must have items in output
    final availableStacks = sourceMachine!.getAvailableOutputStacks();
    if (availableStacks.isEmpty) return false;

    for (final stack in availableStacks) {
      if (stack.isResource && !stack.isEmpty) {
        return true;  // Found at least one item to transfer
      }
    }
    
    return true;
  }

  void _transferItems() {
    final sourceOutput = sourceMachine!.getAvailableOutputStacks();
    
    // Try to transfer first available item
    for (final stack in sourceOutput) {
      if (!stack.isResource) continue;
      if (stack.isEmpty) continue;
      
      final resource = stack.asResource!;
      
      
      // Try to transfer items
      if (_transferResourceToNextTarget(resource, itemsPerTick)) {
        _lastTransferSuccessful = true;  // ✓ Mark as successfully transferring
        return;  // Successfully transferred, stop for this tick
      }
    }
    
    _lastTransferSuccessful = false;  // ✓ Failed to transfer anything
  }

  bool _transferResourceToNextTarget(ResourceType resource, int amount) {
    final validTargets = <int>[];
    for (int i = 0; i < 4; i++) {
      if (targetMachines[i] != null) {
        validTargets.add(i);
      }
    }
    
    if (validTargets.isEmpty) return false;
    
    for (int attempt = 0; attempt < validTargets.length; attempt++) {
      while (!validTargets.contains(_currentTargetIndex)) {
        _currentTargetIndex = (_currentTargetIndex + 1) % 4;
      }
      
      final targetIndex = _currentTargetIndex;
      final target = targetMachines[targetIndex]!;
      
      if (_transferResource(resource, amount, target)) {
        _currentTargetIndex = (_currentTargetIndex + 1) % 4;
        return true;
      }
      
      _currentTargetIndex = (_currentTargetIndex + 1) % 4;
    }
    
    return false;
  }

  /// Transfer a specific resource from source to target
  /// Returns true if successful
  bool _transferResource(ResourceType resource, int amount, BaseMachine target) {
    // Verify source has the item
    bool hasResource = false;
    for (final stack in sourceMachine!.getAvailableOutputStacks()) {
      if (stack.isResource && stack.asResource == resource && stack.quantity >= amount) {
        hasResource = true;
        break;
      }
    }

    if (!hasResource) {
      return false;
    }

    if (target is HolderMachine) {
      final holder = target;
      final spaceAvailable = holder.stats.storageCapacity - holder.totalItemsStored;
      
      if (spaceAvailable <= 0) {
        return false;
      }
      
      amount = amount.clamp(0, spaceAvailable);
    }
    
    // Try to remove from source
    if (!sourceMachine!.takeFromOutput(resource, amount)) {
      return false;
    }
    
    // Try to add to target, allows each machine to validate what it accepts
    if (target.addToInput(resource, amount)) {
      print('📦 Item Linker transferred: $amount ${resource.displayName} (${sourceMachine!.machineType.displayName} → ${target.machineType.displayName})');
      return true;
    } else {
      sourceMachine!.addToInput(resource, amount);
      
      if (target is! HolderMachine && target is! SmelterMachine) {
        print('📦 Item Linker blocked: target input full');
      }
      return false;
    }
  }

  /// Set source machine (machine to pull from)
  void setSource(BaseMachine? machine) {
    if (machine != null && machine == this) { 
      print('⚠️ Cannot link to self');
      return;
    }
    
    sourceMachine = machine;
    _lastTransferSuccessful = false;  // ✓ Reset transfer status
    
    if (machine != null) {
      print('📦 Item Linker source set: ${machine.machineType.displayName} at ${machine.tilePosition}');
    } else {
      print('📦 Item Linker source cleared');
    }
  }

  /// Set target machine (machine to push to)
  void setTarget(BaseMachine? machine, int slot) {
    if (slot < 0 || slot >= 4) {
      print('⚠️ Invalid slot: $slot (must be 0-3)');
      return;
    }
    
    if (machine != null && machine == this) {
      print('⚠️ Cannot link to self');
      return;
    }
    
    targetMachines[slot] = machine;
    _lastTransferSuccessful = false;
    
    if (machine != null) {
      print('📦 Item Linker target ${slot + 1} set: ${machine.machineType.displayName} at ${machine.tilePosition}');
    } else {
      print('📦 Item Linker target ${slot + 1} cleared');
    }
  }
  
  /// Clear all connections
  void clearConnections() {
    sourceMachine = null;
    targetMachines = [null, null, null, null];
    _lastTransferSuccessful = false;
    print('📦 Item Linker connections cleared');
  }

  bool get hasAnyTarget => targetMachines.any((t) => t != null);
  
  /// Check if linker has source
  bool get hasSource => sourceMachine != null;
  
  /// ✓ Check if currently transferring items
  bool get isTransferring => _lastTransferSuccessful && hasSource && hasAnyTarget;
  
  /// Get connection info for UI
  String get connectionStatus {
    final targetCount = targetMachines.where((t) => t != null).length;
    
    if (sourceMachine == null && targetCount == 0) {
      return 'Not connected';
    } else if (sourceMachine == null) {
      return 'Source missing → $targetCount target${targetCount != 1 ? 's' : ''}';
    } else if (targetCount == 0) {
      return '${sourceMachine!.machineType.displayName} → No targets';
    } else {
      final status = isTransferring ? '⚡' : '○';
      return '$status ${sourceMachine!.machineType.displayName} → $targetCount target${targetCount != 1 ? 's' : ''}';
    }
  }
  
  /// Get source machine info
  String? get sourceInfo {
    if (sourceMachine == null) return null;
    return '${sourceMachine!.machineType.displayName} (${sourceMachine!.tilePosition.x.toInt()}, ${sourceMachine!.tilePosition.y.toInt()})';
  }
  
  /// Get target machine info
  // String? get targetInfo {
  //   if (targetMachine == null) return null;
  //   return '${targetMachine!.machineType.displayName} (${targetMachine!.tilePosition.x.toInt()}, ${targetMachine!.tilePosition.y.toInt()})';
  // }

  // @override
  // double getCurrentEnergyConsumption() {
  //   // Only consume energy when actively transferring
  //   if (!isTransferring || !isPowered) return 0;
  //   return stats.energyConsumption;
  // }

  // @override
  // double getCurrentPollutionRate() {
  //   // ✓ Only pollute when actively transferring
  //   if (!isTransferring || !isPowered) return 0;
  //   return stats.pollutionRate;
  // }
}