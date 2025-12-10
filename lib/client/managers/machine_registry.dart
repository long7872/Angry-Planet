import 'package:flame/components.dart';
import '../components/placed_item.dart';

/// Tracks all placed machines on the map to prevent overlapping placement
class MachineRegistry extends Component {
  // Map of "tileX,tileY" → PlacedItemComponent
  final Map<String, PlacedItemComponent> _placedMachines = {};

  /// Register a new machine at a tile position
  void registerMachine(Vector2 tilePos, PlacedItemComponent machine) {
    final key = _tileKey(tilePos);
    _placedMachines[key] = machine;
    print("🏭 Registered ${machine.itemType.name} at $tilePos");
  }

  /// Remove a machine from a tile position
  void unregisterMachine(Vector2 tilePos) {
    final key = _tileKey(tilePos);
    final machine = _placedMachines.remove(key);
    if (machine != null) {
      print("🗑️ Unregistered ${machine.itemType.name} from $tilePos");
    }
  }

  /// Check if a machine already exists at this tile
  bool hasMachineAt(Vector2 tilePos) {
    return _placedMachines.containsKey(_tileKey(tilePos));
  }

  /// Get the machine at a specific tile (if any)
  PlacedItemComponent? getMachineAt(Vector2 tilePos) {
    return _placedMachines[_tileKey(tilePos)];
  }

  /// Get all placed machines
  List<PlacedItemComponent> getAllMachines() {
    return _placedMachines.values.toList();
  }

  /// Clear all machines
  void clear() {
    _placedMachines.clear();
  }

  String _tileKey(Vector2 tilePos) {
    return "${tilePos.x.toInt()},${tilePos.y.toInt()}";
  }
}