import 'package:fast_noise/fast_noise.dart';

class NoiseGenerator {
  final PerlinNoise height;
  final PerlinNoise detail;

  NoiseGenerator(int seed)
      : height = PerlinNoise(seed: seed, frequency: 0.02),
        detail = PerlinNoise(seed: seed + 1000, frequency: 0.08);

  /// Get height value [-1..1]
  double getHeight(double x, double y) {
    return height.getNoise2(x, y);
  }

  /// Get detail value [-1..1]
  double getDetail(double x, double y) {
    return detail.getNoise2(x, y);
  }
}