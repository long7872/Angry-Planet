import 'dart:convert';
import 'dart:io';

class ClientSocket {
  late WebSocket socket;

  Future<void> connect() async {
    socket = await WebSocket.connect("ws://127.0.0.1:3333/ws");
  }

  void getChunk(int cx, int cy) {
    socket.add(jsonEncode({
      "type": "get_chunk",
      "cx": cx,
      "cy": cy,
    }));
  }

  Stream<dynamic> get messages => socket.asBroadcastStream();
}
