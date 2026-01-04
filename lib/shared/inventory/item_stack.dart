import '../resources/resource_type.dart';
import '../machines/machine_type.dart';

/// Represents a stack of items (resources or machines)
class ItemStack {
  final ItemStackType type;
  final dynamic item;  // ResourceType or MachineType
  int quantity;

  ItemStack({
    required this.type,
    required this.item,
    required this.quantity,
  });

  /// Create resource stack
  factory ItemStack.resource(ResourceType resource, int quantity) {
    return ItemStack(
      type: ItemStackType.resource,
      item: resource,
      quantity: quantity,
    );
  }

  /// Create machine stack
  factory ItemStack.machine(MachineType machine, int quantity) {
    return ItemStack(
      type: ItemStackType.machine,
      item: machine,
      quantity: quantity,
    );
  }

  bool get isResource => type == ItemStackType.resource;
  bool get isMachine => type == ItemStackType.machine;
  
  ResourceType? get asResource => isResource ? item as ResourceType : null;
  MachineType? get asMachine => isMachine ? item as MachineType : null;

  String get displayName {
    if (isResource) {
      return (item as ResourceType).displayName;
    } else {
      return (item as MachineType).displayName;
    }
  }

  /// Try to add items to this stack
  /// Returns amount that couldn't be added
  int add(int amount, {int maxStack = 999}) {
    final canAdd = maxStack - quantity;
    final toAdd = amount.clamp(0, canAdd);
    quantity += toAdd;
    return amount - toAdd;  // Return overflow
  }

  /// Try to remove items from this stack
  /// Returns amount actually removed
  int remove(int amount) {
    final toRemove = amount.clamp(0, quantity);
    quantity -= toRemove;
    return toRemove;
  }

  bool get isEmpty => quantity <= 0;
  bool get isFull => quantity >= 999;

  @override
  String toString() => '$displayName × $quantity';
}

enum ItemStackType {
  resource,
  machine,
}