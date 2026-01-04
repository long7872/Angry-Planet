import '../../client/components/machines/base_machine.dart';

/// Pollution system - tracks global pollution
class PollutionSystem {
  static const double maxPollution = 10000;
  
  double _currentPollution = 0;
  final Map<String, BaseMachine> _sources = {};  // Machine ID → BaseMachine

  /// Register a pollution source
  void registerSource(String sourceId, BaseMachine machine) {
    _sources[sourceId] = machine;
  }

  /// Unregister source
  void unregisterSource(String sourceId) {
    _sources.remove(sourceId);
  }

  /// Update pollution rate for a source
  void updateSource(String sourceId, BaseMachine machine) {
    _sources[sourceId] = machine;
  }

  /// Tick update (called every second)
  void tick() {
    // Calculate net pollution change
    double totalPollution = 0;
    
    for (final machine in _sources.values) {
      final rate = machine.getCurrentPollutionRate();
      totalPollution += rate;
    }

    // Apply pollution change
    _currentPollution = (_currentPollution + totalPollution).clamp(0, maxPollution);
  }

  /// Get current pollution level
  double get currentPollution => _currentPollution;
  
  /// Get pollution percentage
  double get pollutionPercentage => (_currentPollution / maxPollution) * 100;

  /// Check if at max pollution
  bool get isMaxPollution => _currentPollution >= maxPollution;

  /// Get pollution level category
  PollutionLevel get level {
    if (_currentPollution < 1000) return PollutionLevel.clean;
    if (_currentPollution < 3000) return PollutionLevel.light;
    if (_currentPollution < 6000) return PollutionLevel.moderate;
    if (_currentPollution < 9000) return PollutionLevel.heavy;
    return PollutionLevel.critical;
  }

  /// Get statistics
  PollutionStats getStats() {
    double totalProduction = 0;
    double totalReduction = 0;

    for (final machine in _sources.values) {
      final rate = machine.getCurrentPollutionRate();
      
      if (rate > 0) {
        totalProduction += rate;
      } else {
        totalReduction += rate.abs();
      }
    }

    return PollutionStats(
      current: _currentPollution,
      max: maxPollution,
      production: totalProduction,
      reduction: totalReduction,
      net: totalProduction - totalReduction,
      level: level,
    );
  }

  /// Reset pollution (for testing)
  void reset() {
    _currentPollution = 0;
    _sources.clear();
  }
}

enum PollutionLevel {
  clean,      // 0-1000
  light,      // 1000-3000
  moderate,   // 3000-6000
  heavy,      // 6000-9000
  critical,   // 9000-10000
}

extension PollutionLevelExtension on PollutionLevel {
  String get displayName {
    switch (this) {
      case PollutionLevel.clean:
        return 'Clean';
      case PollutionLevel.light:
        return 'Light';
      case PollutionLevel.moderate:
        return 'Moderate';
      case PollutionLevel.heavy:
        return 'Heavy';
      case PollutionLevel.critical:
        return 'Critical';
    }
  }
}

class PollutionStats {
  final double current;
  final double max;
  final double production;
  final double reduction;
  final double net;
  final PollutionLevel level;

  PollutionStats({
    required this.current,
    required this.max,
    required this.production,
    required this.reduction,
    required this.net,
    required this.level,
  });

  double get percentage => (current / max) * 100;
}