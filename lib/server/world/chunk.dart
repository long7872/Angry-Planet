import '../../shared/tile_type.dart';

class Chunk {
  static const int size = 32;

  final int cx, cy;
  final List<TileData> tiles;

  Chunk(this.cx, this.cy, this.tiles);

  /// Get tile at local position (returns null if out of bounds)
  TileData? getTileLocal(int tx, int ty) {
    if (tx < 0 || tx >= size || ty < 0 || ty >= size) return null;
    return tiles[ty * size + tx];
  }

  /// Get tile at index
  TileData getTileAt(int index) {
    return tiles[index];
  }

  Map<String, dynamic> toJson() => {
    "cx": cx,
    "cy": cy,
    "tiles": tiles.map((t) => t.toJson()).toList(),
  };

  factory Chunk.fromJson(Map<String, dynamic> json) {
    final tiles = (json["tiles"] as List)
        .map((t) => TileData.fromJson(t))
        .toList();
    
    return Chunk(json["cx"], json["cy"], tiles);
  }
}