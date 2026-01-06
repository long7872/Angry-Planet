import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:isolate';
import '../server/server_main.dart';

Future<void> startLocalServer(int port, int seed) async {
  if (kIsWeb) {
    print("Local server not supported on Web.");
    return;
  }

  final receivePort = ReceivePort();

  await Isolate.spawn(
    runServerIsolate,
    {
      'sendPort': receivePort.sendPort,
      'port': port,
      'seed': seed,
    },
  );

  // Optional: server sent logs/messages
  receivePort.listen((msg) {
    print("[Server] $msg");
  });
}

void runServerIsolate(Map<String, dynamic> args) async {
  final sendPort = args['sendPort'] as SendPort;
  final port = args['port'] as int;
  final seed = args['seed'] as int;
  
  sendPort.send("Starting server on port $port with seed $seed...");
  await runIntegratedServer(port, seed);
}