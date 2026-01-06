import 'machine_type.dart';
import '../resources/resource_type.dart';

/// Configuration for which machines need input/output
class MachineConfig {
  /// Machines that don't need input storage
  static const Set<MachineType> noInputMachines = {
    MachineType.chopper,
    MachineType.digger,
    MachineType.energyLinker,
    MachineType.itemLinker,
    MachineType.greener,
  };

  /// Get accepted input resources for a machine
  static List<ResourceType>? getAcceptedInputs(MachineType type) {
    switch (type) {
      case MachineType.burner:
        return [ResourceType.coal, ResourceType.wood];
      
      case MachineType.smelter:
        return [
          ResourceType.iron,
          ResourceType.energyCatalyst,
          ResourceType.coal, 
        ];
      
      case MachineType.spaceship:
        return [ResourceType.energyCube];
      
      case MachineType.holder:
        return null;  // Accepts anything
      
      // Machines with no input
      case MachineType.chopper:
      case MachineType.digger:
      case MachineType.energyLinker:
      case MachineType.itemLinker:
      case MachineType.greener:
        return [];  // No input
    }
  }

  /// Check if machine needs input
  static bool needsInput(MachineType type) {
    return !noInputMachines.contains(type);
  }

  /// Check if machine can accept this resource as input
  static bool canAcceptInput(MachineType type, ResourceType resource) {
    final accepted = getAcceptedInputs(type);
    if (accepted == null) return true;  // Accepts anything
    if (accepted.isEmpty) return false;  // Accepts nothing
    return accepted.contains(resource);
  }
}