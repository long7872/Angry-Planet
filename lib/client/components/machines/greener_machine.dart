import 'base_machine.dart';
import 'package:flame/game.dart';
import '../../../shared/machines/machine_type.dart';

/// Greener - Reduces pollution
class GreenerMachine extends BaseMachine {
  GreenerMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.greener,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

  @override
  void operate() {
    // Check if we have enough energy to work
    if (!canOperate()) {
      print('🌿 Greener: No energy (${storedEnergy.toStringAsFixed(1)}/${maxStoredEnergy} NE)');
      return;
    }

    // Consume energy for this tick
    if (!consumeEnergy()) {
      print('🌿 Greener: Failed to consume energy');
      return;
    }

    // Greener actively reduces pollution when powered
    print('🌿 Greener active: -${stats.pollutionRate.abs()} pollution/s');
  }

  // @override
  // double getCurrentEnergyConsumption() {
  //   // Only report consumption when powered
  //   if (!isPowered || !canOperate()) return 0;
  //   return stats.energyConsumption;
  // }

  // @override
  // double getCurrentPollutionRate() {
  //   // ✓ Only reduce pollution when actually working
  //   if (!isPowered || !canOperate()) return 0;
  //   return stats.pollutionRate;  // Negative value = reduces pollution
  // }
}