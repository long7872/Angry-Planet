import '../resources/resource_type.dart';

/// Represents the cost to build a machine
class BuildCost {
  final int wood;
  final int ironBar;
  final int energyCube;
  final int coal;

  const BuildCost({
    this.wood = 0,
    this.ironBar = 0,
    this.energyCube = 0,
    this.coal = 0
  });

  /// Total number of items required
  int get totalItems => wood + ironBar + energyCube + coal;

  /// Check if cost is zero (free to build)
  bool get isFree => totalItems == 0;

  /// Get list of required resources with quantities
  Map<ResourceType, int> toMap() {
    final map = <ResourceType, int>{};
    if (wood > 0) map[ResourceType.wood] = wood;
    if (ironBar > 0) map[ResourceType.ironBar] = ironBar;
    if (energyCube > 0) map[ResourceType.energyCube] = energyCube;
    if (coal > 0) map[ResourceType.coal] = coal;
    return map;
  }

  @override
  String toString() {
    final parts = <String>[];
    if (wood > 0) parts.add('$wood Wood');
    if (ironBar > 0) parts.add('$ironBar Iron Bar');
    if (energyCube > 0) parts.add('$energyCube Energy Cube');
    if (coal > 0) parts.add('$coal Coal');
    return parts.isEmpty ? 'Free' : parts.join(', ');
  }
}