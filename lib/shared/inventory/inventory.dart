import '../items/item_type.dart';
import '../items/item_definition.dart';

class InventoryItem {
  final ItemDefinition definition;
  int quantity;

  InventoryItem(this.definition, this.quantity);
}

class Inventory {
  final Map<ItemType, InventoryItem> items = {};

  void add(ItemType type, int amount) {
    if (items.containsKey(type)) {
      items[type]!.quantity += amount;
    } else {
      final def = getItemDefinition(type);
      items[type] = InventoryItem(def, amount);
    }
  }

  bool remove(ItemType type, int amount) {
    if (!has(type, amount)) return false;
    items[type]!.quantity -= amount;
    if (items[type]!.quantity == 0) {
      items.remove(type);
    }
    return true;
  }

  bool has(ItemType type, int amount) {
    return (items[type]?.quantity ?? 0) >= amount;
  }

  int getQuantity(ItemType type) {
    return items[type]?.quantity ?? 0;
  }

  List<InventoryItem> getAllItems() {
    return items.values.toList();
  }

  bool isEmpty() => items.isEmpty;
}