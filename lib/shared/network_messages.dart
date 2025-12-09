class NetworkMessage {
  static const String playerJoined = 'player_joined';
  static const String playerUpdate = 'player_update';
  static const String positionSync = 'position_sync';
  static const String getChunk = 'get_chunk';
  static const String chunkData = 'chunk_data';
}

class PlayerUpdateMessage {
  final double x;
  final double y;
  final String direction;
  final String state;

  PlayerUpdateMessage({
    required this.x,
    required this.y,
    required this.direction,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
    'type': NetworkMessage.playerUpdate,
    'x': x,
    'y': y,
    'direction': direction,
    'state': state,
  };
}

class PlayerStateMessage {
  final String id;
  final String name;
  final double x;
  final double y;
  final String direction;
  final String state;

  PlayerStateMessage({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.direction,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': x,
    'y': y,
    'direction': direction,
    'state': state,
  };

  factory PlayerStateMessage.fromJson(Map<String, dynamic> json) => PlayerStateMessage(
    id: json['id'],
    name: json['name'] ?? 'Player',
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    direction: json['direction'] ?? 'down',
    state: json['state'] ?? 'idle',
  );
}