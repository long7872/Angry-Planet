import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'bootstrap/local_server_runner.dart';
import 'client/network/ws_client.dart';
import 'client/game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 Starting server...");
  await startLocalServer();
  await Future.delayed(Duration(seconds: 1));

  print("🔌 Connecting to server...");
  final socket = ClientSocket();
  await socket.connect();
  print("✅ Connected!");

  runApp(MyApp(socket));
}

class MyApp extends StatelessWidget {
  final ClientSocket socket;

  const MyApp(this.socket, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Angry Planet',
      home: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget(
          game: AngryPlanetGame(socket),
        ),
      ),
    );
  }
}