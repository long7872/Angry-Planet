import 'package:angry_planet/client/components/machines/base_machine.dart';
import 'package:angry_planet/client/components/machines/burner_machine.dart';
import 'package:angry_planet/client/components/machines/energy_linker_machine.dart';
import 'package:angry_planet/client/components/machines/item_linker_machine.dart';
import 'package:angry_planet/client/components/machines/spaceship_machine.dart';

import '../../../shared/machines/machine_type.dart';
import '../../../shared/inventory/inventory.dart';
import '../../../shared/resources/resource_type.dart';

class MachineState {
  /// Serialize machine state to JSON
  static Map<String, dynamic> toJson(BaseMachine machine) {
    return {
      'id': machine.machineId,
      'storedEnergy': machine.storedEnergy,
      'health': machine.health,
      'isBroken': machine.isBroken,
      'isWorking': machine.isWorking,
      'isPowered': machine.isPowered,
      
      // Storage
      'inputStorage': _serializeInventory(machine.inputStorage),
      'outputStorage': _serializeInventory(machine.outputStorage),
      
      // Machine-specific state
      'customState': _getCustomState(machine),
    };
  }
  
  /// Deserialize and apply state to machine
  static void fromJson(BaseMachine machine, Map<String, dynamic> json) {
    machine.storedEnergy = (json['storedEnergy'] as num?)?.toDouble() ?? 0;
    machine.health = (json['health'] as num?)?.toDouble() ?? 150;
    machine.isBroken = json['isBroken'] as bool? ?? false;
    // machine.isWorking = json['isWorking'] as bool? ?? false;
    // machine.isPowered = json['isPowered'] as bool? ?? false;
    
    // Apply storage
    if (json['inputStorage'] != null) {
      _applyInventory(machine.inputStorage, json['inputStorage']);
    }
    if (json['outputStorage'] != null) {
      _applyInventory(machine.outputStorage, json['outputStorage']);
    }
    
    // Apply custom state
    if (json['customState'] != null) {
      _applyCustomState(machine, json['customState']);
    }
  }
  
  /// Serialize inventory
  static Map<String, dynamic> _serializeInventory(Inventory inventory) {
    final stacks = inventory.getAllStacks();
    return {
      'stacks': stacks.map((stack) => {
        'resource': stack.asResource?.name,
        'amount': stack.quantity,
      }).toList(),
    };
  }
  
  /// Apply inventory from JSON
  static void _applyInventory(
    Inventory inventory,
    Map<String, dynamic> json,
  ) {
    final stacks = json['stacks'] as List?;
    if (stacks == null) return;

    final Map<ResourceType, int> serverData = {};

    for (final stackData in stacks) {
      final resourceName = stackData['resource'] as String;
      final amount = stackData['amount'] as int;

      final resource = ResourceType.values.firstWhere(
        (r) => r.name == resourceName,
        orElse: () => ResourceType.none,
      );

      if (resource != ResourceType.none) {
        serverData[resource] = amount;
      }
    }

    // ⭐ SAFE SYNC (KHÔNG GIẬT – KHÔNG MẤT)
    inventory.syncFromServer(serverData);
  }
  
  /// Get machine-specific custom state
  static Map<String, dynamic>? _getCustomState(BaseMachine machine) {
    switch (machine.machineType) {

      case MachineType.burner:
        if (machine is BurnerMachine) {
          return {
            'isBurning': machine.isBurning,
            'burnTimeRemaining': machine.burnTimeRemaining,
          };
        }
        break;

      case MachineType.itemLinker:
        if (machine is ItemLinkerMachine) {
          return {
            'sourceId': machine.sourceMachineId,
            'targetIds': machine.targetMachineIds,
          };
        }
        break;

      case MachineType.energyLinker:
        if (machine is EnergyLinkerMachine) {
          return {
            'sourceId': machine.sourceMachineId,
            'targetIds': machine.targetMachineIds,
          };
        }
        break;

      case MachineType.spaceship:
        if (machine is SpaceshipMachine) {
          return {
            'energyCubesLoaded': machine.energyCubesLoaded,
            'isLaunched': machine.isLaunched,
          };
        }
        break;

      default:
        break;
    }

    return null;
  }
  
  /// Apply machine-specific custom state
  static void _applyCustomState(BaseMachine machine, Map<String, dynamic> customState) {
    final type = machine.machineType;
    
    switch (type) {
      case MachineType.burner:
        if (machine is BurnerMachine) {
        machine.isBurning = customState['isBurning'] as bool? ?? false;
        machine.burnTimeRemaining = (customState['burnTimeRemaining'] as num?)?.toDouble() ?? 0.0;
      }
      break;
        

      case MachineType.itemLinker:
        if (machine is ItemLinkerMachine) {
          machine.sourceMachineId =
              customState['sourceId'] as String?;
          machine.targetMachineIds =
              (customState['targetIds'] as List?)
                  ?.cast<String?>() ??
              [null, null, null, null];
        }
        break;

      case MachineType.energyLinker:
        if (machine is EnergyLinkerMachine) {
          machine.sourceMachineId =
              customState['sourceId'] as String?;
          machine.targetMachineIds =
              (customState['targetIds'] as List?)
                  ?.cast<String?>() ??
              [null, null, null, null];
        }
        break;

      case MachineType.spaceship:
        if (machine is SpaceshipMachine) {
          machine.energyCubesLoaded =
              customState['energyCubesLoaded'] as int? ?? 0;
          machine.isLaunched =
              customState['isLaunched'] as bool? ?? false;
        }
        break;
      
      default:
        break;
    }
    
    // // Burner-specific
    // if (type == 'burner') {
    //   machine.isBurning = customState['isBurning'] as bool? ?? false;
    //   machine.burnTimeRemaining = (customState['burnTimeRemaining'] as num?)?.toDouble() ?? 0.0;
    // }
    
    // // Linker-specific
    // if (type == 'itemLinker' || type == 'energyLinker') {
    //   // machine.sourceMachineId = customState['sourceId'] as String?;
    //   // machine.targetMachineIds = (customState['targetIds'] as List?)?.cast<String>() ?? [];
    //   machine.sourceMachineId = customState['sourceId'] as String?;
    //   machine.targetMachineIds = (customState['targetIds'] as List?)?.cast<String?>() ?? [null, null, null, null];
      
    // }
    
    // // Spaceship-specific
    // if (type == 'spaceship') {
    //   machine.energyCubesLoaded = customState['energyCubesLoaded'] as int? ?? 0;
    //   machine.isLaunched = customState['isLaunched'] as bool? ?? false;
    // }
  }
}