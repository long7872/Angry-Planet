import 'base_machine.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import '../../../shared/machines/machine_type.dart';
import 'linker_visualizer.dart';

/// Energy Linker - Transfers energy between machines using pull-based logic
class EnergyLinkerMachine extends BaseMachine {
  BaseMachine? sourceMachine;
  List<BaseMachine?> targetMachines = [null, null, null, null];
  
  // Transfer rate: 50 NE per tick (adjustable)
  static const double energyPerTick = 50.0;
  
  // Track transferred energy for visualization
  bool _lastTransferSuccessful = false;

  late LinkerVisualizer visualizer;

  EnergyLinkerMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.energyLinker,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    visualizer = LinkerVisualizer(linker: this);
    add(visualizer);
  }

  @override
  void operate() {

    // Pull energy from source into buffer
    _pullEnergyFromSource();

    // Check if we have enough energy to operate the linker itself
    if (!canOperate()) {
      print('⚡ Energy Linker: No energy to operate (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
      _lastTransferSuccessful = false;
      return;
    }

    if (!_canTransfer()) {
      _lastTransferSuccessful = false;
      return;
    }
    
    // Distribute energy from buffer to targets
    _distributeEnergyToTargets();

    // Consume energy for linker operation (not the transferred energy!)
    if (_lastTransferSuccessful) {
      consumeEnergy();  // This sets isWorking = true
    }
  }

  /// Check if energy transfer is possible
  bool _canTransfer() {
    // Both machines must be set
    if (sourceMachine == null) return false;

    // Need at least one target
    if (!hasAnyTarget) return false;
    
    // // Source and target must be different
    // if (sourceMachine == targetMachine) {
    //   return false;
    // }
    
    // Source must have stored energy OR be producing energy
    if (!sourceMachine!.stats.isGenerator) {
      return false;
    }
    
    // Target must need energy
    // if (!targetMachine!.stats.needsEnergy) {
    //   return false;
    // }
    
    return true;
  }

  /// Pull energy from source into buffer
  void _pullEnergyFromSource() {
    // Check if source exists
    if (sourceMachine == null) return;

    // Check if buffer has space
    if (storedEnergy >= maxStoredEnergy) {
      return;  // Buffer full
    }
    
    final spaceInBuffer = maxStoredEnergy - storedEnergy;
    final toPull = energyPerTick.clamp(0, spaceInBuffer);
    
    // Try to pull from source's stored energy
    if (sourceMachine!.storedEnergy >= toPull) {
      sourceMachine!.storedEnergy -= toPull;
      storedEnergy += toPull;
      print('⚡ Energy Linker pulled: ${toPull.toStringAsFixed(1)} NE from ${sourceMachine!.machineType.displayName} (buffer: ${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy})');
    } else {
      // Pull whatever source has available
      final available = sourceMachine!.storedEnergy;
      if (available > 0) {
        sourceMachine!.storedEnergy = 0;
        storedEnergy += available;
        print('⚡ Energy Linker pulled: ${available.toStringAsFixed(1)} NE from ${sourceMachine!.machineType.displayName} (partial)');
      }
    }
  }

  /// Distribute energy from buffer to all targets
  void _distributeEnergyToTargets() {
    if (storedEnergy <= 0) {
      _lastTransferSuccessful = false;
      return;
    }  // Use inherited property
    
    // Get list of valid targets
    final validTargets = targetMachines.where((t) => t != null).toList();
    if (validTargets.isEmpty) {
      _lastTransferSuccessful = false;  // No targets
      return;
    }

    // Only transfer up to energyPerTick, not all stored energy!
    final energyToDistribute = storedEnergy.clamp(0, energyPerTick);
    
    // Distribute energy equally among targets
    final energyPerTarget = energyToDistribute / validTargets.length;

    // Track if any energy was actually transferred
    bool anyTransferred = false;
    double totalTransferred = 0;
    
    for (final target in validTargets) {
      if (target == null) continue;
      
      // Calculate how much this target can accept
      final spaceInTarget = target.maxStoredEnergy - target.storedEnergy;
      final toTransfer = energyPerTarget.clamp(0, spaceInTarget);
      
      if (toTransfer > 0) {
        target.storedEnergy += toTransfer;
        storedEnergy -= toTransfer;  // ✓ Use inherited property
        anyTransferred = true;
        print('⚡ Energy Linker transferred: ${toTransfer.toStringAsFixed(1)} NE to ${target.machineType.displayName}');
      }
    }
    storedEnergy -= totalTransferred;

    // Update last transfer amount
    _lastTransferSuccessful = anyTransferred;
  }

  /// Set source machine (machine to pull energy from)
  void setSource(BaseMachine? machine) {
    if (machine != null && machine == this) {
      print('⚠️ Cannot link to self');
      return;
    }
    
    // Source should have stored energy or be a generator
    if (machine != null && !machine.stats.isGenerator) {
      print('⚠️ Source machine cannot provide energy');
    }
    
    sourceMachine = machine;
    _lastTransferSuccessful = false;
    
    if (machine != null) {
      print('🔗 Energy Linker source set: ${machine.machineType.displayName} at ${machine.tilePosition}');
    } else {
      print('🔗 Energy Linker source cleared');
    }
  }

  /// Set target machine (machine to provide energy to)
  void setTarget(BaseMachine? machine, int slot) {
    if (slot < 0 || slot >= 4) {
      print('⚠️ Invalid slot: $slot (must be 0-3)');
      return;
    }

    if (machine != null && machine == this) {
      print('⚠️ Cannot link to self');
      return;
    }
    
    // Target should need energy
    if (machine != null && !machine.stats.isConsumer) {
      print('⚠️ Target machine does not need energy');
    }
    
    targetMachines[slot] = machine;
    _lastTransferSuccessful = false;
    
    if (machine != null) {
      print('⚡ Energy Linker target ${slot + 1} set: ${machine.machineType.displayName} at ${machine.tilePosition}');
    } else {
      print('⚡ Energy Linker target ${slot + 1} cleared');
    }
  }

  /// Clear all connections
  void clearConnections() {
    sourceMachine = null;
    targetMachines = [null, null, null, null];
    _lastTransferSuccessful = false;
    print('🔗 Energy Linker connections cleared');
  }

  /// Check if linker has any targets
  bool get hasAnyTarget => targetMachines.any((t) => t != null);
  
  /// Check if linker has source
  bool get hasSource => sourceMachine != null;
  
  /// Check if currently transferring energy
  bool get isTransferring => hasSource && hasAnyTarget && _lastTransferSuccessful;  // ✓ Use inherited property
  
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
    final energy = sourceMachine!.storedEnergy.toStringAsFixed(0);
    return '${sourceMachine!.machineType.displayName} ($energy NE stored)';
  }
  
  /// Get target machine info
  // String? get targetInfo {
  //   if (targetMachine == null) return null;
  //   final needed = targetMachine!.stats.energyConsumption.toStringAsFixed(1);
  //   return '${targetMachine!.machineType.displayName} (needs $needed NE/s)';
  // }
  
  // /// Get transfer efficiency (for UI/debugging)
  // double get transferEfficiency {
  //   if (!isConnected || !isTransferring) return 0;
  //   return (lastTransferAmount / energyPerTick) * 100;
  // }
  
  /// Get available source energy (for UI)
  double get sourceAvailableEnergy {
    if (sourceMachine == null) return 0;
    double available = sourceMachine!.storedEnergy;
    if (sourceMachine!.stats.isGenerator && sourceMachine!.canOperate()) {
      available += sourceMachine!.getCurrentEnergyProduction();
    }
    return available;
  }
  
  // /// Get target needed energy (for UI)
  // double get targetNeededEnergy {
  //   if (targetMachine == null) return 0;
  //   return targetMachine!.stats.energyConsumption;
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