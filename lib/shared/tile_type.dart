// Biomes
enum BiomeType {
  water,   // Priority 0
  sand,    // Priority 1
  grass,   // Priority 2
  tree,    // Priority 3
  stone,   // Priority 4
}

// Extension to get biome priority
extension BiomePriority on BiomeType {
  int get priority => index; // Uses enum index as priority
  
  /// Check if this biome should draw transition to neighbor
  bool shouldDrawTransitionTo(BiomeType neighbor) {
    return priority < neighbor.priority;
  }
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

// 8 Directions for transitions
enum Direction {
  n,   // North
  ne,  // Northeast
  e,   // East
  se,  // Southeast
  s,   // South
  sw,  // Southwest
  w,   // West
  nw,  // Northwest
}

// Helper to get offset for direction
extension DirectionOffset on Direction {
  (int dx, int dy) get offset {
    switch (this) {
      case Direction.n:  return (0, -1);
      case Direction.ne: return (1, -1);
      case Direction.e:  return (1, 0);
      case Direction.se: return (1, 1);
      case Direction.s:  return (0, 1);
      case Direction.sw: return (-1, 1);
      case Direction.w:  return (-1, 0);
      case Direction.nw: return (-1, -1);
    }
  }
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