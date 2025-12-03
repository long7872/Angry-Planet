import '../../shared/tile_type.dart';
import '../utils/ore_config.dart';
import 'dart:math';

class BiomeClassifier {
  /// Ore spawn configurations (easy to adjust!)
  static const oreConfigs = [
    OreConfig(
      type: ResourceType.energyCatalyst,
      minDetail: 0.6,
      spawnChance: 0.03, // 3% chance
    ),
    OreConfig(
      type: ResourceType.iron,
      minDetail: 0.3,
      spawnChance: 0.05, // 5% chance
    ),
    OreConfig(
      type: ResourceType.coal,
      minDetail: 0.0,
      spawnChance: 0.08, // 8% chance
    ),
  ];

  /// Forest spawn configuration
  static const forestConfig = OreConfig(
    type: ResourceType.forest,
    minDetail: 0.0,
    spawnChance: 0.10, // 40% chance
  );

  /// Classify biome based on height
  static BiomeType classify(double height) {
    if (height < -0.6) return BiomeType.water;
    if (height < -0.3) return BiomeType.sand;
    if (height < -0.1) return BiomeType.grass;
    if (height < 0.2) return BiomeType.tree;
    return BiomeType.stone;
  }

  /// Determine resource based on biome + detail noise
  static ResourceType getResource(
    BiomeType biome,
    double detail,
    int wx,
    int wy,
  ) {
    switch (biome) {
      case BiomeType.stone:
        return _getStoneResource(detail, wx, wy);

      case BiomeType.tree:
        return _getTreeResource(detail, wx, wy);

      default:
        return ResourceType.none;
    }
  }

  /// Ore spawning for stone biome using OreConfig
  static ResourceType _getStoneResource(double detail, int wx, int wy) {
    final seed = _hashCoords(wx, wy);
    final random = _seededRandom(seed);

    // Check each ore type in order (rarest first)
    for (final config in oreConfigs) {
      if (detail > config.minDetail && random < config.spawnChance) {
        return config.type;
      }
    }

    return ResourceType.none;
  }

  /// Forest spawning for tree biome using config
  static ResourceType _getTreeResource(double detail, int wx, int wy) {
    final seed = _hashCoords(wx, wy);
    final random = _seededRandom(seed);

    if (detail > forestConfig.minDetail && random < forestConfig.spawnChance) {
      return forestConfig.type;
    }

    return ResourceType.none;
  }

  /// Create deterministic hash from coordinates
  static int _hashCoords(int x, int y) {
    return ((x * 374761393) + (y * 668265263)) & 0x7FFFFFFF;
  }

  /// Generate pseudo-random value from seed (0.0 to 1.0)
  static double _seededRandom(int seed) {
    final random = Random(seed);
    return random.nextDouble();
  }
}