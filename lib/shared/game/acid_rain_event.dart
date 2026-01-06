import 'dart:math';
import '../../client/components/machines/base_machine.dart';

/// Acid Rain Event - Damages machines when pollution is high
class AcidRainEvent {
  bool isActive = false;
  double duration = 0;  // Remaining duration in seconds
  double maxDuration = 0;
  
  // Cooldown system
  double cooldownRemaining = 0;  // Seconds until can trigger again
  static const double cooldownDuration = 60;  // 60 second cooldown after event

  final Random _random = Random();
  
  // Damage settings
  static const double damagePerTick = 5.0;
  static const double damageChance = 0.25;  // 25% chance per tick
  
  // Duration thresholds based on pollution
  static const double shortDuration = 15;   // 15 seconds
  static const double mediumDuration = 30;  // 30 seconds
  static const double longDuration = 60;    // 1 minute

  /// Start acid rain event based on pollution level
  void start(double pollutionPercentage) {
    if (isActive) return;  // Already active
    if (cooldownRemaining > 0) return;  // On cooldown
    
    // Determine duration based on pollution
    if (pollutionPercentage >= 80) {
      maxDuration = longDuration;
    } else if (pollutionPercentage >= 60) {
      maxDuration = mediumDuration;
    } else if (pollutionPercentage >= 1) {
      maxDuration = shortDuration;
    } else {
      return;  // Not high enough pollution
    }
    
    isActive = true;
    duration = maxDuration;
    print('☔ ACID RAIN EVENT STARTED! Duration: ${duration.toInt()}s');
  }

  /// Update event (called every tick)
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
    
    print('☔ Acid Rain: ${duration.toInt()}s remaining');
  }

  /// Apply damage to all machines with chance
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

  /// Stop the event
  void stop() {
    if (!isActive) return;
    
    isActive = false;
    duration = 0;
    cooldownRemaining = cooldownDuration;
    print('☔ Acid Rain event ended');
  }

  /// Get progress (0-1)
  double get progress => 1 - (duration / maxDuration);

  /// Check if on cooldown
  bool get isOnCooldown => cooldownRemaining > 0;
}