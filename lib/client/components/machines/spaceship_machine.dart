import 'base_machine.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/resources/resource_type.dart';

/// Spaceship - End-game victory machine
class SpaceshipMachine extends BaseMachine {
  // Energy Cube charging
  // int energyCubesLoaded = 0;
  static const int requiredCubes = 20;

  // Energy charging (uses storedEnergy from BaseMachine)
  static const double requiredEnergy = 10000;

  bool isLaunched = false;

  SpaceshipMachine({
    required Vector2 tilePosition,
    required FlameGame game,
    required String machineId,
  }) : super(
          machineType: MachineType.spaceship,
          tilePosition: tilePosition,
          game: game,
          machineId: machineId,
        ) {
    storedEnergy = 9000;
  }

  @override
  void operate() {
    // Spaceship is passive - doesn't operate
  }

  int get energyCubesLoaded =>
    inputStorage.getResourceQuantity(ResourceType.energyCube);

  /// Check if spaceship is fully charged (both conditions)
  bool get isFullyCharged => energyCubesLoaded >= requiredCubes && storedEnergy >= requiredEnergy;
  
  /// Check if Energy Cubes are loaded
  bool get cubesReady => energyCubesLoaded >= requiredCubes;
  
  /// Check if energy buffer is charged
  bool get energyReady => storedEnergy >= requiredEnergy;

  /// Get Energy Cube charging progress (0-1)
  double get cubeProgress => energyCubesLoaded / requiredCubes;
  
  /// ✓ NEW: Get energy charging progress (0-1)
  double get energyProgress => storedEnergy / requiredEnergy;

  @override
  bool addToInput(ResourceType resource, int amount) {
    if (resource != ResourceType.energyCube) {
      print('🚀 Spaceship: Only Energy Cubes accepted');
      return false;
    }

    if (energyCubesLoaded >= requiredCubes) {
      print('🚀 Spaceship: Already fully charged!');
      return false;
    }

    final spaceAvailable = requiredCubes - energyCubesLoaded;
    final toAdd = amount.clamp(0, spaceAvailable);

    if (toAdd > 0) {
      inputStorage.addResource(resource, toAdd);
      print('🚀 Spaceship charged: $energyCubesLoaded / $requiredCubes Energy Cubes');
      
      if (isFullyCharged) {
        print('🚀 SPACESHIP FULLY CHARGED! Ready to launch!');
      }
      
      return toAdd == amount;
    }

    return false;
  }

  void launch() {
    if (!isFullyCharged) {
      print('🚀 Cannot launch: Need ${requiredCubes - energyCubesLoaded} more Energy Cubes');
      return;
    }

    if (isLaunched) {
      print('🚀 Spaceship already launched!');
      return;
    }

    isLaunched = true;
    print('🚀🚀🚀 LAUNCHING SPACESHIP! 🚀🚀🚀');
    print('🎉 YOU WIN! You escaped The Angry Planet!');
  }

}