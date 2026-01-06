import 'network/ws_server.dart';

Future<void> runIntegratedServer(int port, int seed) async {
  final server = AngryPlanetServer(port: port, seed: seed);
  await server.start();
}