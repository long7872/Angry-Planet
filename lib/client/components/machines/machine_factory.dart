import 'package:flame/game.dart';
import 'base_machine.dart';
import 'burner_machine.dart';
import 'digger_machine.dart';
import 'chopper_machine.dart';
import 'smelter_machine.dart';
import 'holder_machine.dart';
import 'greener_machine.dart';
import 'energy_linker_machine.dart';
import 'item_linker_machine.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/resources/resource_type.dart';
import 'package:flame/components.dart';

import 'spaceship_machine.dart';

/// Factory for creating machines
class MachineFactory {
  static int _nextMachineId = 0;

  /// Create a machine of the specified type
  static BaseMachine createMachine({
    required MachineType type,
    required Vector2 tilePosition,
    required FlameGame game,
    ResourceType? resourceNode,  // For digger
    String? rMachineId,
  }) {
    final machineId = rMachineId ?? 'machine_${_nextMachineId++}';
    // final machineId = 'machine_${_nextMachineId++}';

    switch (type) {
      case MachineType.burner:
        return BurnerMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.digger:
        if (resourceNode == null) {
          throw ArgumentError('Digger requires resourceNode parameter');
        }
        return DiggerMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
          resourceNode: resourceNode,
        );

      case MachineType.chopper:
        return ChopperMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.smelter:
        return SmelterMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.holder:
        return HolderMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.greener:
        return GreenerMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.energyLinker:
        return EnergyLinkerMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.itemLinker:
        return ItemLinkerMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );

      case MachineType.spaceship:
        return SpaceshipMachine(
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        );
    }
  }

  static void syncNextMachineId(String machineId) {
    final match = RegExp(r'machine_(\d+)').firstMatch(machineId);
    if (match == null) return;

    final id = int.parse(match.group(1)!);
    if (id >= _nextMachineId) {
      _nextMachineId = id + 1;
      print('🔧 Sync machine id → $_nextMachineId');
    }
  }
}