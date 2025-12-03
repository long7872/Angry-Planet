import '../../shared/tile_type.dart';

/// Configuration for ore spawning
class OreConfig {
  final ResourceType type;
  final double minDetail;    // Minimum detail noise required
  final double spawnChance;  // 0.0 to 1.0 probability

  const OreConfig({
    required this.type,
    required this.minDetail,
    required this.spawnChance,
  });
}