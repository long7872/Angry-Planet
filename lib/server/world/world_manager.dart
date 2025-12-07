import 'chunk.dart';
import 'noise_generator.dart';
import 'biome_classifier.dart';
import '../../shared/tile_type.dart';

class WorldManager {
  final NoiseGenerator noise;
  final Map<String, Chunk> _cache = {};

  WorldManager(int seed) : noise = NoiseGenerator(seed);

  Chunk generateChunk(int cx, int cy) {
    final key = "$cx,$cy";
    if (_cache.containsKey(key)) return _cache[key]!;

    final tiles = <TileData>[];

    for (int ty = 0; ty < Chunk.size; ty++) {
      for (int tx = 0; tx < Chunk.size; tx++) {
        final wx = cx * Chunk.size + tx;  // World X (int)
        final wy = cy * Chunk.size + ty;  // World Y (int)

        // Sample noise (needs double for Perlin)
        final h = noise.getHeight(wx.toDouble(), wy.toDouble());
        final d = noise.getDetail(wx.toDouble(), wy.toDouble());

        // Determine biome
        final biome = BiomeClassifier.classify(h);

        bool isEdge = false;
        // Sample 4 neighbors
        final radius = 2;
        final hN = noise.getHeight(wx.toDouble(), (wy - radius).toDouble());
        final hS = noise.getHeight(wx.toDouble(), (wy + radius).toDouble());
        final hW = noise.getHeight((wx - radius).toDouble(), wy.toDouble());
        final hE = noise.getHeight((wx + radius).toDouble(), wy.toDouble());

        // Compare biomes
        if (BiomeClassifier.classify(hN) != biome) isEdge = true;
        if (BiomeClassifier.classify(hS) != biome) isEdge = true;
        if (BiomeClassifier.classify(hW) != biome) isEdge = true;
        if (BiomeClassifier.classify(hE) != biome) isEdge = true;

        ResourceType resource = ResourceType.none;
        // Determine resource (pass int coords for seeding)
        if (!isEdge) {
          resource = BiomeClassifier.getResource(biome, d, wx, wy);
        }

        tiles.add(TileData(biome: biome, resource: resource));
      }
    }

    final chunk = Chunk(cx, cy, tiles);
    _cache[key] = chunk;
    return chunk;
  }
}