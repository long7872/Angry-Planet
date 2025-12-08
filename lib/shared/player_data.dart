class PlayerData {
  final String id;
  double x;
  double y;
  final String name;
  
  PlayerData({
    required this.id,
    required this.x,
    required this.y,
    this.name = 'Player',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'name': name,
  };

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      name: json['name'] ?? 'Player',
    );
  }
}