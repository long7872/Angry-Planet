// Biomes
enum BiomeType {
  water,
  sand,
  grass,
  tree,
  stone,
}

// Resources
enum ResourceType {
  none,
  coal,
  iron,
  energyCatalyst,
  forest, // trees on tree biome
}

// Resource health states
enum ResourceState {
  intact,      // 0 - Full health
  damaged1,    // 1 - 75% health
  damaged2,    // 2 - 50% health  
  damaged3,    // 3 - 25% health
  breaking,    // 4 - About to break
}

class TileData {
  final BiomeType biome;
  final ResourceType resource;
  final ResourceState resourceState;

  TileData({
    required this.biome,
    this.resource = ResourceType.none,
    this.resourceState = ResourceState.intact,
  });

  Map<String, dynamic> toJson() => {
    "biome": biome.index,
    "resource": resource.index,
    "state": resourceState.index,
  };

  factory TileData.fromJson(Map<String, dynamic> json) {
    return TileData(
      biome: BiomeType.values[json["biome"]],
      resource: ResourceType.values[json["resource"]],
      resourceState: ResourceState.values[json["state"] ?? 0],
    );
  }

  /// Create copy with different state
  TileData copyWith({
    BiomeType? biome,
    ResourceType? resource,
    ResourceState? resourceState,
  }) {
    return TileData(
      biome: biome ?? this.biome,
      resource: resource ?? this.resource,
      resourceState: resourceState ?? this.resourceState,
    );
  }
}