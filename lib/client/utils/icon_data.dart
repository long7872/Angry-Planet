import 'package:flutter/material.dart';

import '../../shared/items/item_type.dart';

IconData getItemIcon(ItemType type) {
  switch (type) {
    case ItemType.drill:
      return Icons.construction;
    case ItemType.woodHarvester:  // ✓ NEW
      return Icons.forest;
    case ItemType.furnace:
      return Icons.fireplace;
    case ItemType.conveyor:
      return Icons.arrow_forward;
    case ItemType.storage:
      return Icons.inventory;
  }
}