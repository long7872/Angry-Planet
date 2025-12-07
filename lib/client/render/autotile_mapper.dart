import '../../shared/autotile_config.dart';

/// Fixed autotile mapper - inner corners for ALL perpendicular edges
class AutotileMapper {
  static const N  = AutotileConfig.BIT_N;   // 0x40
  static const S  = AutotileConfig.BIT_S;   // 0x02
  static const E  = AutotileConfig.BIT_E;   // 0x08
  static const W  = AutotileConfig.BIT_W;   // 0x10
  static const NE = AutotileConfig.BIT_NE;  // 0x20
  static const NW = AutotileConfig.BIT_NW;  // 0x80
  static const SE = AutotileConfig.BIT_SE;  // 0x01
  static const SW = AutotileConfig.BIT_SW;  // 0x04

  static int mapBitmaskToTileIndex(int mask) {
    if (mask == 0x00) return 4;  // Center

    final hasN = (mask & N) != 0;
    final hasS = (mask & S) != 0;
    final hasE = (mask & E) != 0;
    final hasW = (mask & W) != 0;
    final hasNE = (mask & NE) != 0;
    final hasNW = (mask & NW) != 0;
    final hasSE = (mask & SE) != 0;
    final hasSW = (mask & SW) != 0;

    // === PRIORITY 1: Inner Corners (HIGHEST PRIORITY) ===
    // Use inner corner for ANY two perpendicular cardinals
    // Ignore diagonal - doesn't matter for inner corners!
    
    if (hasN && hasW) return 9;   // Inner NW corner
    if (hasN && hasE) return 10;  // Inner NE corner
    if (hasS && hasE) return 11;  // Inner SE corner
    if (hasS && hasW) return 12;  // Inner SW corner

    // === PRIORITY 2: Outer Corners ===
    // Diagonal ONLY (no adjacent cardinals)
    
    if (hasNW && !hasN && !hasW) return 0;  // Outer NW
    if (hasNE && !hasN && !hasE) return 2;  // Outer NE
    if (hasSE && !hasS && !hasE) return 8;  // Outer SE
    if (hasSW && !hasS && !hasW) return 6;  // Outer SW

    // === PRIORITY 3: Cardinal Edges ===
    // Single direction
    
    if (hasN && !hasS && !hasE && !hasW) return 1;  // Edge N
    if (hasS && !hasN && !hasE && !hasW) return 7;  // Edge S
    if (hasE && !hasN && !hasS && !hasW) return 5;  // Edge E
    if (hasW && !hasN && !hasS && !hasE) return 3;  // Edge W

    // === PRIORITY 4: Opposite Edges ===
    
    if (hasN && hasS) return 1;  // Both N+S → use N edge
    if (hasE && hasW) return 5;  // Both E+W → use E edge

    // === PRIORITY 5: Single Edge + Diagonals ===
    
    if (hasN) return 1;  // North edge (with any diagonals)
    if (hasS) return 7;  // South edge (with any diagonals)
    if (hasE) return 5;  // East edge (with any diagonals)
    if (hasW) return 3;  // West edge (with any diagonals)

    // === FALLBACK ===
    return 4;  // Center
  }

  static String getTileName(int index) {
    const names = [
      'outer_nw', 'edge_n', 'outer_ne',
      'edge_w', 'center', 'edge_e',
      'outer_sw', 'edge_s', 'outer_se',
      'inner_nw', 'inner_ne', 'inner_se', 'inner_sw',
    ];
    return index >= 0 && index < names.length ? names[index] : 'unknown';
  }

  static String explainBitmask(int mask) {
    final hasN = (mask & N) != 0;
    final hasS = (mask & S) != 0;
    final hasE = (mask & E) != 0;
    final hasW = (mask & W) != 0;
    final hasNE = (mask & NE) != 0;
    final hasNW = (mask & NW) != 0;
    final hasSE = (mask & SE) != 0;
    final hasSW = (mask & SW) != 0;

    final bits = <String>[];
    if (hasN) bits.add('N');
    if (hasS) bits.add('S');
    if (hasE) bits.add('E');
    if (hasW) bits.add('W');
    if (hasNE) bits.add('NE');
    if (hasNW) bits.add('NW');
    if (hasSE) bits.add('SE');
    if (hasSW) bits.add('SW');

    final tileIndex = mapBitmaskToTileIndex(mask);
    final hexMask = '0x${mask.toRadixString(16).toUpperCase().padLeft(2, '0')}';
    
    return '$hexMask [${bits.join(",")}] → Tile $tileIndex (${getTileName(tileIndex)})';
  }
}