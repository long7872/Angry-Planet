import 'package:flutter/material.dart';

class TileDebugOverlay extends StatelessWidget {
  final int playerTileX;
  final int playerTileY;
  final List<String> validTiles;  // ["(-28, 35)", "(-27, 35)", ...]

  const TileDebugOverlay({
    Key? key,
    required this.playerTileX,
    required this.playerTileY,
    required this.validTiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 200,
      left: 20,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Player Tile: ($playerTileX, $playerTileY)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Valid Tiles (Stone):',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
            ...validTiles.take(5).map((tile) => Text(
              '  ✓ $tile',
              style: TextStyle(color: Colors.yellow, fontSize: 11),
            )),
            if (validTiles.length > 5)
              Text(
                '  + ${validTiles.length - 5} more...',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}