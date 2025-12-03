import 'dart:ui';
import '../../shared/tile_type.dart';

class TileColors {
  // Biome colors
  static const Map<BiomeType, Color> biomes = {
    BiomeType.water: Color(0xFF2E5C8A),      // Deep blue
    BiomeType.sand: Color(0xFFE8D4A2),       // Sandy yellow
    BiomeType.grass: Color(0xFF5C8A3D),      // Green
    BiomeType.tree: Color(0xFF2D5016),       // Dark green
    BiomeType.stone: Color(0xFF6B6B6B),      // Gray
  };

  // Resource colors (for dots)
  static const Map<ResourceType, Color> resources = {
    ResourceType.coal: Color(0xFF1A1A1A),           // Black
    ResourceType.iron: Color(0xFFB87333),           // Copper/brown
    ResourceType.energyCatalyst: Color(0xFF00FFFF), // Cyan (glowing)
    ResourceType.forest: Color(0xFF1A3D0A),         // Very dark green
  };

  static Color getBiome(BiomeType type) {
    return biomes[type] ?? const Color(0xFFFF00FF); // Magenta = error
  }

  static Color? getResource(ResourceType type) {
    return resources[type];
  }
}