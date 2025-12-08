import 'dart:async';
import 'dart:io';
import 'dart:convert';

/// WebSocket client for server communication
class ClientSocket {
  final String url;
  WebSocket? _socket;
  final List<Function(String)> _messageHandlers = [];
  bool _isConnected = false;

  ClientSocket([this.url = "ws://127.0.0.1:3333/ws"]);

  /// Connect to WebSocket server
  Future<void> connect() async {
    try {
      print("🔌 Connecting to server...");
      _socket = await WebSocket.connect(url);
      _isConnected = true;
      print("✅ Connected!");

      // Listen to incoming messages
      _socket!.listen(
        (data) {
          final message = data.toString();
          print("📨 Raw message received (${message.length} bytes)");
          
          // Notify all registered handlers
          for (final handler in _messageHandlers) {
            handler(message);
          }
        },
        onDone: () {
          print("🔌 Disconnected from server");
          _isConnected = false;
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
          _isConnected = false;
        },
      );
    } catch (e) {
      print("❌ Failed to connect: $e");
      _isConnected = false;
    }
  }

  /// Register a message handler
  void onMessage(Function(String) handler) {
    print("📝 Message handler registered (total: ${_messageHandlers.length + 1})");
    _messageHandlers.add(handler);
  }

  /// Send message to server (generic)
  void send(String message) {
    if (_isConnected && _socket != null) {
      print("📤 Sending: ${message.substring(0, message.length > 100 ? 100 : message.length)}");
      _socket!.add(message);
    } else {
      print("⚠️ Cannot send message: not connected");
    }
  }

  /// Legacy method: Get chunk (kept for backward compatibility)
  void getChunk(int cx, int cy) {
    send(jsonEncode({
      "type": "get_chunk",
      "cx": cx,
      "cy": cy,
    }));
  }

  /// Disconnect from server
  void disconnect() {
    if (_socket != null) {
      _socket!.close();
      _socket = null;
      _isConnected = false;
      print("🔌 Disconnected");
    }
  }

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Stream of messages (legacy, kept for backward compatibility)
  Stream<dynamic> get messages => _socket?.asBroadcastStream() ?? Stream.empty();
}