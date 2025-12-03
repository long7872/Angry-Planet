import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:isolate';
import '../server/server_main.dart';


Future<void> startLocalServer() async {
  if (kIsWeb) {
    print("Local server not supported on Web.");
    return;
  }

  final receivePort = ReceivePort();

  await Isolate.spawn(
    runServerIsolate,
    receivePort.sendPort,
  );

  // Optional: server sent logs/messages
  receivePort.listen((msg) {
    print("[Server] $msg");
  });
}

void runServerIsolate(SendPort sendPort) async {
  sendPort.send("Starting server...");
  await runIntegratedServer();
}
