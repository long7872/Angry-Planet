import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../shared/items/item_type.dart';
import '../../shared/items/item_definition.dart';
import '../managers/machine_registry.dart';

class PlacedItemComponent extends SpriteComponent {
  final ItemType itemType;
  final Vector2 tilePosition;
  final FlameGame game;

  PlacedItemComponent({
    required this.itemType,
    required this.tilePosition,
    required this.game,
  }) : super(
          position: tilePosition * 16,
          size: Vector2.all(16),
          anchor: Anchor.topLeft,
          priority: 15,
        );

  @override
  Future<void> onLoad() async {
    final itemDef = getItemDefinition(itemType);
    sprite = await Sprite.load(itemDef.spritePath);
  }

  // ✓ NEW: Cleanup on removal
  @override
  void onRemove() {
    super.onRemove();
    
    // Find machine registry and unregister this machine
    final registry = game.children.query<MachineRegistry>().firstOrNull;
    if (registry != null) {
      registry.unregisterMachine(tilePosition);
    }
  }

  // Future: Add item functionality (mining, smelting, etc)
  void operate() {
    // Drill mines ore, furnace smelts, etc
  }
}