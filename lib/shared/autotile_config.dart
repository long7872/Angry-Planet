/// Autotiling with 8-directional bitmask (hexadecimal)
class AutotileConfig {
  // Hexadecimal bit positions
  static const int BIT_SE = 0x01;  // 00000001 = 1
  static const int BIT_S  = 0x02;  // 00000010 = 2
  static const int BIT_SW = 0x04;  // 00000100 = 4
  static const int BIT_E  = 0x08;  // 00001000 = 8
  static const int BIT_W  = 0x10;  // 00010000 = 16
  static const int BIT_NE = 0x20;  // 00100000 = 32
  static const int BIT_N  = 0x40;  // 01000000 = 64
  static const int BIT_NW = 0x80;  // 10000000 = 128

  /// Calculate bitmask for a tile
  /// Returns 0x00 to 0xFF (0-255)
  static int calculateBitmask(
    bool Function(int dx, int dy) isDifferentBiome,
  ) {
    int mask = 0;

    // Check all 8 neighbors
    if (isDifferentBiome(1, 1))   mask |= BIT_SE;  // Southeast
    if (isDifferentBiome(0, 1))   mask |= BIT_S;   // South
    if (isDifferentBiome(-1, 1))  mask |= BIT_SW;  // Southwest
    if (isDifferentBiome(1, 0))   mask |= BIT_E;   // East
    if (isDifferentBiome(-1, 0))  mask |= BIT_W;   // West
    if (isDifferentBiome(1, -1))  mask |= BIT_NE;  // Northeast
    if (isDifferentBiome(0, -1))  mask |= BIT_N;   // North
    if (isDifferentBiome(-1, -1)) mask |= BIT_NW;  // Northwest

    return mask;
  }

  /// Debug: convert mask to readable string
  static String maskToString(int mask) {
    final bits = mask.toRadixString(2).padLeft(8, '0');
    return '0x${mask.toRadixString(16).toUpperCase().padLeft(2, '0')} ($bits)';
  }
}