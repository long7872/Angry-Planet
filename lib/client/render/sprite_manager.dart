import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../shared/tile_type.dart';

class SpriteManager {
  // Simple biome sprites
  final Map<BiomeType, Sprite> biomeSprites = {};
  
  // Multi-state resource sprites
  final Map<ResourceType, Map<ResourceState, Sprite>> resourceSprites = {};

  /// Load all sprites
  Future<void> loadAll(FlameGame game) async {
    print("📦 Loading sprites...");
    
    await _loadBiomeSprites(game);
    await _loadResourceSprites(game);
    
    print("✅ All sprites loaded!");
  }

  /// Load biome tile sprites
  Future<void> _loadBiomeSprites(FlameGame game) async {
    biomeSprites[BiomeType.water] = await game.loadSprite('tiles/water.png');
    biomeSprites[BiomeType.sand] = await game.loadSprite('tiles/sand.png');
    biomeSprites[BiomeType.grass] = await game.loadSprite('tiles/grass.png');
    biomeSprites[BiomeType.tree] = await game.loadSprite('tiles/tree.png');
    biomeSprites[BiomeType.stone] = await game.loadSprite('tiles/stone.png');
  }

  /// Load multi-state resource sprites
  Future<void> _loadResourceSprites(FlameGame game) async {
    // Load coal states
    resourceSprites[ResourceType.coal] = {
      ResourceState.intact: await game.loadSprite('resources/coal/intact.png'),
      // ResourceState.damaged1: await game.loadSprite('resources/coal/damaged1.png'),
      // ResourceState.damaged2: await game.loadSprite('resources/coal/damaged2.png'),
      // ResourceState.damaged3: await game.loadSprite('resources/coal/damaged3.png'),
      // ResourceState.breaking: await game.loadSprite('resources/coal/breaking.png'),
    };

    // Load iron states
    resourceSprites[ResourceType.iron] = {
      ResourceState.intact: await game.loadSprite('resources/iron/intact.png'),
      // ResourceState.damaged1: await game.loadSprite('resources/iron/damaged1.png'),
      // ResourceState.damaged2: await game.loadSprite('resources/iron/damaged2.png'),
      // ResourceState.damaged3: await game.loadSprite('resources/iron/damaged3.png'),
      // ResourceState.breaking: await game.loadSprite('resources/iron/breaking.png'),
    };

    // Load energy catalyst states
    resourceSprites[ResourceType.energyCatalyst] = {
      ResourceState.intact: await game.loadSprite('resources/energy_catalyst/intact.png'),
      // ResourceState.damaged1: await game.loadSprite('resources/energy_catalyst/damaged1.png'),
      // ResourceState.damaged2: await game.loadSprite('resources/energy_catalyst/damaged2.png'),
      // ResourceState.damaged3: await game.loadSprite('resources/energy_catalyst/damaged3.png'),
      // ResourceState.breaking: await game.loadSprite('resources/energy_catalyst/breaking.png'),
    };

    // Load forest states
    resourceSprites[ResourceType.forest] = {
      ResourceState.intact: await game.loadSprite('resources/forest/intact.png'),
      // ResourceState.damaged1: await game.loadSprite('resources/forest/damaged1.png'),
      // ResourceState.damaged2: await game.loadSprite('resources/forest/damaged2.png'),
      // ResourceState.damaged3: await game.loadSprite('resources/forest/damaged3.png'),
      // ResourceState.breaking: await game.loadSprite('resources/forest/breaking.png'),
    };
  }

  /// Get biome sprite
  Sprite? getBiomeSprite(BiomeType biome) {
    return biomeSprites[biome];
  }

  /// Get resource sprite for specific state
  Sprite? getResourceSprite(ResourceType resource, ResourceState state) {
    return resourceSprites[resource]?[state];
  }
}