import 'base_machine.dart';
import 'package:flame/game.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/resources/resource_type.dart';

/// Burner - Generates energy from coal
class BurnerMachine extends BaseMachine {
  // Burner state
  bool isBurning = false;
  double burnTimeRemaining = 0;
  ResourceType? currentFuel;

  static const double coalBurnDuration = 10;  // 10 seconds
  static const double woodBurnDuration = 2;   // 2 seconds
  static const double energyPerSecond = 20;   // 20 NE/s

  BurnerMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.burner,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  void operate() {
    // If currently burning, continue
    if (isBurning) {
      burnTimeRemaining -= 1;  // Tick = 1 second
      
      // Generate energy to buffer
      final energyToGenerate = energyPerSecond;
      final spaceAvailable = maxStoredEnergy - storedEnergy;
      final actualGenerated = energyToGenerate.clamp(0, spaceAvailable);

      // Generate energy
      // storedEnergy = (storedEnergy + energyPerSecond).clamp(0, maxStoredEnergy);
      storedEnergy += actualGenerated;

      // Set powered status (generator is powered when actively burning)
      isWorking = true;
      isPowered = true;
      
      print('🔥 Burner generating: +$energyPerSecond NE/s (${storedEnergy.toStringAsFixed(0)}/${maxStoredEnergy.toStringAsFixed(0)} NE stored)');
      
      if (burnTimeRemaining <= 0) {
        isBurning = false;
        currentFuel = null;
        isWorking = false;
        isPowered = false;  // No longer powered when not burning
        print('🔥 Burner fuel depleted');
      }
      return;
    }

    // Not burning - not powered
    isPowered = false;

    // Try to start burning - check coal first, then wood
    if (inputStorage.hasResource(ResourceType.coal, 1)) {
      _startBurning(ResourceType.coal, coalBurnDuration);
    } else if (inputStorage.hasResource(ResourceType.wood, 1)) {
      _startBurning(ResourceType.wood, woodBurnDuration);
    }
  }

  void _startBurning(ResourceType fuel, double duration) {
    inputStorage.removeResource(fuel, 1);
    currentFuel = fuel;
    isBurning = true;
    burnTimeRemaining = duration;
    isPowered = true;
    print('🔥 Burner started: consuming 1 ${fuel.displayName} (${duration}s)');
  }

  @override
  double getCurrentEnergyProduction() {
    if (isBroken) return 0;
    return isBurning ? energyPerSecond : 0;
  }

  @override
  double getCurrentPollutionRate() {
    if (isBroken) return 0;
    return isBurning ? stats.pollutionRate : 0;
  }

  /// Get burn progress (0-1)
  double get burnProgress {
    if (!isBurning || currentFuel == null) return 0;
    final totalDuration = currentFuel == ResourceType.coal 
        ? coalBurnDuration 
        : woodBurnDuration;
    return 1 - (burnTimeRemaining / totalDuration);
  }

  /// Get total burn duration for current fuel
  double get totalBurnDuration {
    if (currentFuel == ResourceType.coal) return coalBurnDuration;
    if (currentFuel == ResourceType.wood) return woodBurnDuration;
    return 0;
  }
}