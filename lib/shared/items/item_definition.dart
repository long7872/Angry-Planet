import '../resources/resource_type.dart';
import 'item_type.dart';

class ItemDefinition {
  final ItemType type;
  final String name;
  final String iconPath;
  final String spritePath;
  final bool isPlaceable;
  final List<ResourceType> validResources;  // ✓ Changed from validBiomes
  final String description;

  const ItemDefinition({
    required this.type,
    required this.name,
    required this.iconPath,
    required this.spritePath,
    required this.isPlaceable,
    required this.validResources,  // ✓ Changed from validBiomes
    required this.description,
  });
}

// ✓ UPDATED: Resource-based item definitions
const Map<ItemType, ItemDefinition> itemDefinitions = {
  ItemType.drill: ItemDefinition(
    type: ItemType.drill,
    name: 'Mining Drill',
    iconPath: 'ui/items/drill_icon.png',
    spritePath: 'items/drill.png',
    isPlaceable: true,
    validResources: [
      ResourceType.coal,
      ResourceType.iron,
      ResourceType.energyCatalyst,
    ],
    description: 'Extracts ore from resource nodes',
  ),
  
  ItemType.woodHarvester: ItemDefinition(
    type: ItemType.woodHarvester,
    name: 'Wood Harvester',
    iconPath: 'ui/items/wood_harvester_icon.png',
    spritePath: 'items/wood_harvester.png',
    isPlaceable: true,
    validResources: [
      ResourceType.wood,
    ],
    description: 'Harvests wood from forests',
  ),
  
  ItemType.furnace: ItemDefinition(
    type: ItemType.furnace,
    name: 'Furnace',
    iconPath: 'ui/items/furnace_icon.png',
    spritePath: 'items/furnace.png',
    isPlaceable: true,
    validResources: [
      ResourceType.none,
    ],
    description: 'Smelts ore into metal',
  ),
  
  ItemType.conveyor: ItemDefinition(
    type: ItemType.conveyor,
    name: 'Conveyor Belt',
    iconPath: 'ui/items/conveyor_icon.png',
    spritePath: 'items/conveyor.png',
    isPlaceable: true,
    validResources: [
      ResourceType.none,
    ],
    description: 'Transports items',
  ),
  
  ItemType.storage: ItemDefinition(
    type: ItemType.storage,
    name: 'Storage Box',
    iconPath: 'ui/items/storage_icon.png',
    spritePath: 'items/storage.png',
    isPlaceable: true,
    validResources: [
      ResourceType.none,
    ],
    description: 'Stores items',
  ),
};

ItemDefinition getItemDefinition(ItemType type) {
  return itemDefinitions[type]!;
}

List<ItemDefinition> getPlaceableItems() {
  return itemDefinitions.values.where((def) => def.isPlaceable).toList();
}