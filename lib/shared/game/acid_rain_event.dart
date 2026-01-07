// lib/shared/game/acid_rain_event.dart
import 'dart:math';
import '../../client/components/machines/base_machine.dart';

/// Acid Rain Event - Damages machines when pollution is high
class AcidRainEvent {
  bool isActive = false;
  double duration = 0; // Remaining duration in seconds
  double maxDuration = 0;

  // Cooldown system
  double cooldownRemaining = 0; // Seconds until can trigger again
  static const double cooldownDuration = 60; // 60 second cooldown after event

  final Random _random = Random();

  // Damage settings
  static const double damagePerTick = 5.0;
  static const double damageChance = 0.25; // 25% chance per tick

  // Duration thresholds based on pollution
  static const double shortDuration = 15; // 15 seconds
  static const double mediumDuration = 30; // 30 seconds
  static const double longDuration = 60; // 1 minute

  /// Start acid rain event.
  /// Either provide a pollutionPercentage (host usually) or an explicit duration.
  /// Returns true if started, false if couldn't (already active or on cooldown).
  bool start({double? pollutionPercentage, double? duration}) {
    if (isActive) return false; // Already active
    if (cooldownRemaining > 0) return false; // On cooldown

    if (duration != null) {
      maxDuration = duration;
    } else if (pollutionPercentage != null) {
      if (pollutionPercentage >= 80) {
        maxDuration = longDuration;
      } else if (pollutionPercentage >= 60) {
        maxDuration = mediumDuration;
      } else if (pollutionPercentage >= 1) {
        maxDuration = shortDuration;
      } else {
        return false; // Not high enough pollution
      }
    } else {
      return false; // Need a basis to start
    }

    isActive = true;
    this.duration = maxDuration;
    print('☔ ACID RAIN EVENT STARTED! Duration: ${maxDuration.toInt()}s');
    return true;
  }

  /// Update event (called every host tick with dt = 1s)
  /// `machines` is the authoritative list from host.
  void tick(List<BaseMachine> machines) {
    // Update cooldown
    if (cooldownRemaining > 0) {
      cooldownRemaining -= 1;
      if (cooldownRemaining <= 0) {
        cooldownRemaining = 0;
        print('☔ Acid rain event ready (cooldown ended)');
      }
    }

    if (!isActive) return;

    // Decrease duration
    duration -= 1;
    if (duration <= 0) {
      stop();
      return;
    }

    // Apply damage to machines
    _applyDamage(machines);

    // Debug log (host only should print this)
    print('☔ Acid Rain: ${duration.toInt()}s remaining');
  }

  /// Apply probabilistic damage to machines
  void _applyDamage(List<BaseMachine> machines) {
    int damagedCount = 0;

    for (final machine in machines) {
      // 25% chance to damage each machine
      if (_random.nextDouble() < damageChance) {
        machine.takeDamage(damagePerTick);
        damagedCount++;
      }
    }

    if (damagedCount > 0) {
      print('☔ Acid Rain damaged $damagedCount machine(s) for $damagePerTick HP');
    }
  }

  /// Stop the event (host calls)
  void stop() {
    if (!isActive) return;
    isActive = false;
    duration = 0;
    cooldownRemaining = cooldownDuration;
    print('☔ Acid Rain event ended, cooldown started ${cooldownRemaining.toInt()}s');
  }

  /// Get progress (0-1). Safe if maxDuration == 0.
  double get progress {
    if (maxDuration <= 0) return 0.0;
    return (maxDuration - duration) / maxDuration;
  }

  /// Check if on cooldown
  bool get isOnCooldown => cooldownRemaining > 0;

  /// Serialization to send to clients (host -> clients)
  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'duration': duration,
      'maxDuration': maxDuration,
      'cooldownRemaining': cooldownRemaining,
    };
  }

  /// Apply state on client from server snapshot. Client should NOT call tick().
  void fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'] as bool? ?? false;
    duration = (json['duration'] as num?)?.toDouble() ?? 0.0;
    maxDuration = (json['maxDuration'] as num?)?.toDouble() ?? 0.0;
    cooldownRemaining = (json['cooldownRemaining'] as num?)?.toDouble() ?? 0.0;
  }
}
