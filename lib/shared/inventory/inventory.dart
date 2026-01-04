import 'item_stack.dart';
import '../resources/resource_type.dart';
import '../machines/machine_type.dart';

/// Player or machine inventory with stack-based storage
class Inventory {
  final Map<String, ItemStack> _stacks = {};
  final int maxSlots;
  final int maxStackSize;

  Inventory({
    this.maxSlots = 100,
    this.maxStackSize = 999,
  });

  /// Add resource to inventory
  /// Returns true if fully added, false if some/all couldn't be added
  bool addResource(ResourceType resource, int amount) {
    final key = 'resource_${resource.name}';
    
    if (_stacks.containsKey(key)) {
      // Check if we can add to existing stack
      final currentAmount = _stacks[key]!.quantity;
      final canAdd = (maxStackSize - currentAmount).clamp(0, amount);
      
      if (canAdd <= 0) return false;  // Stack full
      
      final overflow = _stacks[key]!.add(canAdd, maxStack: maxStackSize);
      return overflow == 0 && canAdd == amount;
    } else if (_stacks.length < maxSlots) {
      // Create new stack (limited by maxStackSize)
      final toAdd = amount.clamp(0, maxStackSize);
      _stacks[key] = ItemStack.resource(resource, toAdd);
      return toAdd == amount;
    }
    
    return false;  // Inventory full
  }

  /// Check if can add resource without exceeding capacity
  bool canAddResource(ResourceType resource, int amount) {
    final key = 'resource_${resource.name}';
    
    if (_stacks.containsKey(key)) {
      final currentAmount = _stacks[key]!.quantity;
      return (currentAmount + amount) <= maxStackSize;
    } else if (_stacks.length < maxSlots) {
      return amount <= maxStackSize;
    }
    
    return false;
  }

  int getAvailableSpace(ResourceType resource) {
    final key = 'resource_${resource.name}';
    
    if (_stacks.containsKey(key)) {
      final currentAmount = _stacks[key]!.quantity;
      return maxStackSize - currentAmount;
    } else if (_stacks.length < maxSlots) {
      return maxStackSize;
    }
    
    return 0;
  }
  
  /// Add machine to inventory
  bool addMachine(MachineType machine, int amount) {
    final key = 'machine_${machine.name}';
    
    if (_stacks.containsKey(key)) {
      final overflow = _stacks[key]!.add(amount);
      return overflow == 0;
    } else if (_stacks.length < maxSlots) {
      _stacks[key] = ItemStack.machine(machine, amount);
      return true;
    }
    
    return false;
  }

  /// Remove resource from inventory
  /// Returns true if fully removed, false if not enough
  bool removeResource(ResourceType resource, int amount) {
    final key = 'resource_${resource.name}';
    if (!_stacks.containsKey(key)) return false;
    
    final removed = _stacks[key]!.remove(amount);
    if (_stacks[key]!.isEmpty) {
      _stacks.remove(key);
    }
    
    return removed == amount;
  }

  /// Remove machine from inventory
  bool removeMachine(MachineType machine, int amount) {
    final key = 'machine_${machine.name}';
    if (!_stacks.containsKey(key)) return false;
    
    final removed = _stacks[key]!.remove(amount);
    if (_stacks[key]!.isEmpty) {
      _stacks.remove(key);
    }
    
    return removed == amount;
  }

  /// Check if has enough resources
  bool hasResource(ResourceType resource, int amount) {
    final key = 'resource_${resource.name}';
    return (_stacks[key]?.quantity ?? 0) >= amount;
  }

  /// Check if has enough machines
  bool hasMachine(MachineType machine, int amount) {
    final key = 'machine_${machine.name}';
    return (_stacks[key]?.quantity ?? 0) >= amount;
  }

  /// Get resource quantity
  int getResourceQuantity(ResourceType resource) {
    final key = 'resource_${resource.name}';
    return _stacks[key]?.quantity ?? 0;
  }

  /// Get machine quantity
  int getMachineQuantity(MachineType machine) {
    final key = 'machine_${machine.name}';
    return _stacks[key]?.quantity ?? 0;
  }

  /// Get all stacks
  List<ItemStack> getAllStacks() {
    return _stacks.values.where((stack) => !stack.isEmpty).toList();
  }

  /// Check if can afford build cost
  bool canAfford(Map<ResourceType, int> cost) {
    for (final entry in cost.entries) {
      if (!hasResource(entry.key, entry.value)) {
        return false;
      }
    }
    return true;
  }

  /// Deduct build cost from inventory
  bool deductCost(Map<ResourceType, int> cost) {
    if (!canAfford(cost)) return false;
    
    for (final entry in cost.entries) {
      removeResource(entry.key, entry.value);
    }
    return true;
  }

  bool get isEmpty => _stacks.isEmpty;
  int get usedSlots => _stacks.length;
  int get freeSlots => maxSlots - usedSlots;
}