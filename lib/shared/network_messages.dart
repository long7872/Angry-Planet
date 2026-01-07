class NetworkMessage {
  static const String setPlayerName = 'set_player_name';
  static const String playerJoined = 'player_joined';
  static const String playerUpdate = 'player_update';
  static const String positionSync = 'position_sync';
  static const String getChunk = 'get_chunk';
  static const String chunkData = 'chunk_data';

  static const String machinePlace = 'machine_place';
  static const String machineDestroy = 'machine_destroy';
  static const String machineSync = 'machine_sync';
  static const String machineUpdate = 'machine_update';

  static const String machineAction = 'machine_action';
  static const String machineActionResult = 'machine_action_result';
  static const String machineStateSync = 'machine_state_sync';
  static const String machineStateUpdate = 'machine_state_update';

  static const String hello = 'hello';
  static const String gameTick = 'game_tick';

  static const String chatMessage = 'chat_message';
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