/// Game tick manager - runs at fixed intervals
class GameTick {
  static const double tickRate = 1.0;  // 1 tick per second
  static const double tickInterval = 1.0 / tickRate;  // 1 second per tick

  double _accumulator = 0;
  int _tickCount = 0;

  /// Update with delta time, returns true if tick should execute
  bool update(double dt) {
    _accumulator += dt;
    
    if (_accumulator >= tickInterval) {
      _accumulator -= tickInterval;
      _tickCount++;
      return true;
    }
    
    return false;
  }

  int get tickCount => _tickCount;
  double get progress => _accumulator / tickInterval;
}