import 'package:flame/components.dart';  // ✓ ADD THIS
import '../machines/machine_type.dart';
import 'game_tick.dart';
import 'energy_system.dart';
import 'pollution_system.dart';
import '../../client/managers/machine_registry.dart';
import '../../client/components/machines/base_machine.dart';

/// Main game manager - coordinates all systems
class GameManager extends Component {  // ✓ EXTEND Component
  final GameTick gameTick = GameTick();
  final EnergyNetwork energyNetwork = EnergyNetwork();
  final PollutionSystem pollutionSystem = PollutionSystem();
  
  MachineRegistry? _machineRegistry;

  /// Register machine registry
  void registerMachineRegistry(MachineRegistry registry) {
    _machineRegistry = registry;
    print('🎮 Game Manager: Machine registry registered');
  }

  @override
  void update(double dt) {
    super.update(dt);  // ✓ Call super
    
    // Check if we should execute a tick
    if (gameTick.update(dt)) {
      onTick();
    }
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

    // 4. Log stats
    _logStats();
  }

  void _logStats() {
    final energyStats = energyNetwork.getStats();
    final pollutionStats = pollutionSystem.getStats();

    print('⚡ Energy: ${energyStats.production.toStringAsFixed(1)}P / ${energyStats.consumption.toStringAsFixed(1)}C NE/s | ${energyStats.net >= 0 ? "✓" : "✗"} Net: ${energyStats.net.toStringAsFixed(1)} | Powered: ${energyStats.activeNodes}/${energyStats.totalNodes}');
    print('☣️  Pollution: ${pollutionStats.current.toStringAsFixed(0)} / ${pollutionStats.max.toStringAsFixed(0)} (${pollutionStats.percentage.toStringAsFixed(1)}%) | ${pollutionStats.level.displayName} | +${pollutionStats.production.toStringAsFixed(1)} -${pollutionStats.reduction.toStringAsFixed(1)}');
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
    if (machine.stats.isGenerator) return 0;  // Generators first
    if (machine.machineType.name.contains('smelter')) return 10;  // Processors
    if (machine.machineType.name.contains('digger')) return 10;
    if (machine.machineType.name.contains('chopper')) return 10;
    if (machine.machineType.name.contains('holder')) return 30;  // Storage
    if (machine.machineType.name.contains('linker')) return 40;  // Linkers last
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