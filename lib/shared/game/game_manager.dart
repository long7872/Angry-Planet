// lib/shared/game/game_manager.dart
import 'dart:math';

import 'package:angry_planet/shared/machines/machine_type.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'acid_rain_event.dart';
import 'game_tick.dart';
import 'energy_system.dart';
import 'pollution_system.dart';
import '../../client/managers/machine_registry.dart';
import '../../client/components/machines/base_machine.dart';

/// Main game manager - coordinates all systems
class GameManager extends Component {
  final GameTick gameTick = GameTick();
  final EnergyNetwork energyNetwork = EnergyNetwork();
  final PollutionSystem pollutionSystem = PollutionSystem();
  final AcidRainEvent acidRainEvent = AcidRainEvent();

  final Random _random = Random();

  MachineRegistry? _machineRegistry;

  bool isHost = false;
  Function()? onTickBroadcast;

  /// New: event broadcast callback. Host should set this to send JSON to server / clients.
  /// Example: onEventBroadcast = (payload) => socket.send(jsonEncode(payload));
  void Function(Map<String, dynamic> payload)? onEventBroadcast;

  /// Register machine registry
  void registerMachineRegistry(MachineRegistry registry) {
    _machineRegistry = registry;
    print('🎮 Game Manager: Machine registry registered');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only host runs automatic ticks
    if (!isHost) return;

    // Check if we should execute a tick
    if (gameTick.update(dt)) {
      onTick();

      // Broadcast tick to other players (existing behavior)
      if (onTickBroadcast != null) {
        onTickBroadcast!();
      }
    }
  }

  /// Execute tick from host (for clients)
  void executeHostTick(int hostTickCount) {
    // Sync our tick count to host
    gameTick.setTickCount(hostTickCount);

    // Execute the tick (clients will NOT run host-only event/damage logic)
    onTick();
  }

  /// Execute one game tick (happens every second)
  void onTick() {
    if (_machineRegistry == null) return;

    print('\n⏱️ === TICK ${gameTick.tickCount} ===');

    // 1. Update energy distribution
    energyNetwork.tick();

    // 2. Update all machines
    _machineRegistry!.tickAllMachines();

    // 3. Update pollution
    pollutionSystem.tick();

    // 4. Host-only: check + run acid rain event / damage
    if (isHost) {
      _checkAcidRainEvent();

      // Keep track to broadcast stop when it ends
      final wasActiveBefore = acidRainEvent.isActive;

      acidRainEvent.tick(_machineRegistry!.getAllMachines());

      // If event ended during tick, broadcast stop
      if (wasActiveBefore && !acidRainEvent.isActive) {
        _broadcastEventStop();
      }
    }

    // 5. Log stats
    _logStats();
  }

  /// Check if acid rain should start (host only)
  void _checkAcidRainEvent() {
    // Only start if not already active and not on cooldown
    if (acidRainEvent.isActive) return;
    if (acidRainEvent.isOnCooldown) return;

    final pollutionStats = pollutionSystem.getStats();
    final pollutionPercentage = pollutionStats.percentage;

    // Example: scale trigger chance with pollution
    // base 1% + up to 9% when pollution very high
    final triggerChance = 0.01 + (pollutionPercentage / 100) * 0.09;

    if (_random.nextDouble() < triggerChance) {
      // Start event (decide duration from pollution)
      final started = acidRainEvent.start(pollutionPercentage: pollutionPercentage);
      if (started) {
        // Broadcast to clients the event start with chosen duration
        _broadcastEventStart(acidRainEvent.maxDuration);
      }
    }
  }

  /// Broadcast an event start to clients (host should implement onEventBroadcast)
  void _broadcastEventStart(double duration) {
    if (onEventBroadcast != null) {
      final payload = {
        'type': 'game_event',
        'event': 'acidRain',
        'duration': duration,
      };
      onEventBroadcast!(payload);
      print('📡 Broadcasted event start: acidRain ${duration}s');
    }
  }

  /// Broadcast event stop to clients
  void _broadcastEventStop() {
    if (onEventBroadcast != null) {
      final payload = {
        'type': 'game_event',
        'event': 'acidRainStop',
      };
      onEventBroadcast!(payload);
      print('📡 Broadcasted event stop: acidRainStop');
    }
  }

  void _logStats() {
    final energyStats = energyNetwork.getStats();
    final pollutionStats = pollutionSystem.getStats();

    print('⚡ Energy: ${energyStats.production.toStringAsFixed(1)}P / ${energyStats.consumption.toStringAsFixed(1)}C NE/s | ${energyStats.net >= 0 ? "✓" : "✗"} Net: ${energyStats.net.toStringAsFixed(1)} | Powered: ${energyStats.activeNodes}/${energyStats.totalNodes}');
    print('☣️  Pollution: ${pollutionStats.current.toStringAsFixed(0)} / ${pollutionStats.max.toStringAsFixed(0)} (${pollutionStats.percentage.toStringAsFixed(1)}%) | ${pollutionStats.level.displayName} | +${pollutionStats.production.toStringAsFixed(1)} -${pollutionStats.reduction.toStringAsFixed(1)}');

    if (acidRainEvent.isActive) {
      print('☔ ACID RAIN ACTIVE! ${acidRainEvent.duration.toInt()}s remaining');
    } else if (acidRainEvent.isOnCooldown) {
      if (gameTick.tickCount % 10 == 0) {
        print('☔ Acid rain cooldown: ${acidRainEvent.cooldownRemaining.toInt()}s remaining');
      }
    }
  }

  /// Register a machine with energy and pollution systems
  void registerMachine(BaseMachine machine) {
    // Register energy node
    if (machine.stats.isConsumer || machine.stats.isGenerator) {
      final priority = _getEnergyPriority(machine);
      final energyNode = EnergyNode(
        id: machine.machineId,
        machine: machine,
        priority: priority,
      );
      machine.energyNode = energyNode;
      energyNetwork.registerNode(machine.machineId, energyNode);
      print('⚡ Registered energy node: ${machine.machineType.displayName}');
    }

    // Register pollution source
    if (machine.stats.pollutionRate != 0) {
      pollutionSystem.registerSource(machine.machineId, machine);
      final rate = machine.stats.pollutionRate;
      if (rate > 0) {
        print('☣️  Registered pollution source: ${machine.machineType.displayName} (+${rate.toStringAsFixed(1)}/s)');
      } else {
        print('☣️  Registered pollution cleaner: ${machine.machineType.displayName} (${rate.toStringAsFixed(1)}/s)');
      }
    }
  }

  /// Unregister a machine from systems
  void unregisterMachine(BaseMachine machine) {
    energyNetwork.unregisterNode(machine.machineId);
    pollutionSystem.unregisterSource(machine.machineId);
    print('🗑️  Unregistered machine: ${machine.machineType.displayName}');
  }

  /// Get energy priority for machine type
  int _getEnergyPriority(BaseMachine machine) {
    // Lower number = higher priority
    if (machine.stats.isGenerator) return 0; // Generators first
    if (machine.machineType.name.contains('smelter')) return 10; // Processors
    if (machine.machineType.name.contains('digger')) return 10;
    if (machine.machineType.name.contains('chopper')) return 10;
    if (machine.machineType.name.contains('holder')) return 30; // Storage
    if (machine.machineType.name.contains('linker')) return 40; // Linkers last
    return 50;
  }

  /// Get current game stats for UI
  GameStats getGameStats() {
    final energyStats = energyNetwork.getStats();
    final pollutionStats = pollutionSystem.getStats();

    return GameStats(
      tickCount: gameTick.tickCount,
      energyStats: energyStats,
      pollutionStats: pollutionStats,
    );
  }
}

/// Combined game statistics
class GameStats {
  final int tickCount;
  final EnergyStats energyStats;
  final PollutionStats pollutionStats;

  GameStats({
    required this.tickCount,
    required this.energyStats,
    required this.pollutionStats,
  });
}
