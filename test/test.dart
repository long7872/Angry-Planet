import 'package:angry_planet/client/render/autotile_mapper.dart';

void main() {
  testAutotileMapper();
}

extension Binary on int {
  int get b {
    return int.parse(toRadixString(10), radix: 2);
  }
}

void testAutotileMapper() {
  print("\n=== Autotile Mapper Test ===\n");
  
  final tests = {
    // Basic cases
    0x00: (4, 'center', 'No neighbors'),
    0x40: (1, 'edge_n', 'N only'),
    0x02: (7, 'edge_s', 'S only'),
    0x08: (5, 'edge_e', 'E only'),
    0x10: (3, 'edge_w', 'W only'),
    
    // Outer corners (diagonal ONLY, no cardinals)
    0x80: (0, 'outer_nw', 'NW diagonal only'),
    0x20: (2, 'outer_ne', 'NE diagonal only'),
    0x01: (8, 'outer_se', 'SE diagonal only'),
    0x04: (6, 'outer_sw', 'SW diagonal only'),
    
    // Inner corners (two perpendicular cardinals, NO diagonal)
    0x50: (9, 'inner_nw', 'N+W, no NW diagonal'),
    0x48: (10, 'inner_ne', 'N+E, no NE diagonal'),
    0x0A: (11, 'inner_se', 'S+E, no SE diagonal'),
    0x12: (12, 'inner_sw', 'S+W, no SW diagonal'),
    
    // Edge with diagonal (should still use edge)
    0x60: (1, 'edge_n', 'N + NW diagonal'),
    0xC0: (1, 'edge_n', 'N + NW + NE diagonals'),
    
    // Two perpendicular with diagonal (should use edge, not inner corner)
    0xD0: (1, 'edge_n', 'N+W with NW diagonal'),
  };

  var passed = 0;
  var failed = 0;

  for (final entry in tests.entries) {
    final mask = entry.key;
    final (expectedIndex, expectedName, description) = entry.value;
    final actualIndex = AutotileMapper.mapBitmaskToTileIndex(mask);
    
    final status = actualIndex == expectedIndex ? '✓' : '✗';
    final hex = '0x${mask.toRadixString(16).toUpperCase().padLeft(2, '0')}';
    
    print('$status $hex: $description');
    print('   Expected: $expectedIndex ($expectedName)');
    print('   Got: $actualIndex (${AutotileMapper.getTileName(actualIndex)})');
    
    if (actualIndex == expectedIndex) {
      passed++;
    } else {
      failed++;
    }
    print('');
  }

  print('Results: $passed passed, $failed failed\n');
}