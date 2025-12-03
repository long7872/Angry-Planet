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

class TileData {
  final BiomeType biome;
  final ResourceType resource;

  TileData({
    required this.biome,
    this.resource = ResourceType.none,
  });

  Map<String, dynamic> toJson() => {
    "biome": biome.index,
    "resource": resource.index,
  };

  factory TileData.fromJson(Map<String, dynamic> json) {
    return TileData(
      biome: BiomeType.values[json["biome"]],
      resource: ResourceType.values[json["resource"]],
    );
  }
}