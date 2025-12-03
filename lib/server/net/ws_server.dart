import 'dart:convert';
import 'dart:io';
import '../world/world_manager.dart';
import '../../shared/tile_type.dart';

class AngryPlanetServer {
  final world = WorldManager(12345);

  Future<void> start() async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 3333);
    print("Server running at ws://127.0.0.1:3333/ws");

    await for (var req in http) {
      if (req.uri.path == '/ws') {
        final socket = await WebSocketTransformer.upgrade(req);
        socket.listen((data) {
          final msg = jsonDecode(data);

          if (msg["type"] == "get_chunk") {
            final cx = msg["cx"];
            final cy = msg["cy"];
            final chunk = world.generateChunk(cx, cy);

            socket.add(jsonEncode({
              "type": "chunk_data",
              "chunk": chunk.toJson(),
            }));
          }
          // In ws_server.dart, add debug command
          if (msg["type"] == "debug_biomes") {
            final stats = <String, int>{};
            
            for (int cy = -2; cy < 2; cy++) {
              for (int cx = -2; cx < 2; cx++) {
                final chunk = world.generateChunk(cx, cy);
                for (var tile in chunk.tiles) {
                  stats[tile.biome.name] = (stats[tile.biome.name] ?? 0) + 1;
                  if (tile.resource != ResourceType.none) {
                    stats[tile.resource.name] = (stats[tile.resource.name] ?? 0) + 1;
                  }
                }
              }
            }
            
            socket.add(jsonEncode({"type": "debug", "stats": stats}));
          }
        });
      }
    }
  }
}
