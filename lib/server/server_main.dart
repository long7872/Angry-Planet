import 'network/ws_server.dart';

Future<void> runIntegratedServer() async {
  final server = AngryPlanetServer();
  await server.start();
}
