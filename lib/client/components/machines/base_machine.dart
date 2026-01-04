import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/machines/machine_stats.dart';
import '../../../shared/inventory/inventory.dart';
import '../../../shared/resources/resource_type.dart';
import '../../../shared/game/energy_system.dart';

/// Base class for all machines
abstract class BaseMachine extends SpriteComponent {
  final MachineType machineType;
  final Vector2 tilePosition;
  final FlameGame game;
  final MachineStats stats;
  final String machineId;

  // Machine state
  bool isPowered = false;
  EnergyNode? energyNode;
  
  // Internal storage
  late final Inventory inputStorage;
  late final Inventory outputStorage;
  
  // Energy buffer (for generators)
  double storedEnergy = 0;
  double maxStoredEnergy = 0;

  // Track if machine is actively working this tick
  bool isWorking = false;

  BaseMachine({
    required this.machineType,
    required this.tilePosition,
    required this.game,
    required this.machineId,
  }) : stats = getMachineStats(machineType),
       super(
          position: tilePosition * 16,
          size: Vector2.all(16),
          anchor: Anchor.topLeft,
          priority: 75,
        ) {
    // Initialize storage based on machine type
    final storageCapacity = stats.storageCapacity;
    inputStorage = Inventory(maxSlots: storageCapacity > 0 ? 10 : 0);
    outputStorage = Inventory(maxSlots: storageCapacity > 0 ? 10 : 0);

    maxStoredEnergy = stats.energyBuffer;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load sprite based on machine type
    sprite = await _loadMachineSprite();
  }

  Future<Sprite> _loadMachineSprite() async {
    // TODO: Load actual machine sprites
    // For now, use placeholder
    try {
      return await Sprite.load('items/${machineType.name}.png');
    } catch (e) {
      // Fallback to colored rectangle
      return await Sprite.load('items/placeholder.png');
    }
  }

  /// Called every game tick (1 per second)
  void tick() {
    // if (!canOperate()) {
    //   return;
    // }

    isWorking = false;

    // Update power status BEFORE operating
    _updatePowerStatus();
    
    operate();
  }

  /// Check if machine can operate this tick
  bool canOperate() {
    // // Generators don't need power
    // if (stats.isGenerator) {
    //   return true;
    // }
    
    // // Other machines need power
    // return isPowered;

    // Operate the machine
    return hasEnoughEnergy();
  }

  /// Update power status based on energy availability
  void _updatePowerStatus() {
    if (stats.isGenerator) {
      // Generators set their own powered state based on active operation
      // (handled in each generator's operate() method)
    } else {
      // Consumers are powered if they have any energy
      isPowered = storedEnergy > 0;
    }
  }

  /// Machine-specific operation (override in subclasses)
  void operate();

  /// Check if machine has enough energy to operate
  bool hasEnoughEnergy() {
    // Generators don't need energy to work
    if (stats.isGenerator) return true;
    
    // Check if we have enough energy for 1 second of operation
    final energyNeeded = stats.energyConsumption;
    return storedEnergy >= energyNeeded;
  }

  /// Consume energy from buffer for operation
  /// Returns true if successful
  bool consumeEnergy() {
    // Generators don't consume energy
    if (stats.isGenerator) {
      isWorking = true;
      return true;
    }
    
    final energyNeeded = stats.energyConsumption;
    
    if (storedEnergy >= energyNeeded) {
      storedEnergy -= energyNeeded;
      isWorking = true;
      return true;
    }
    
    return false;
  }

  /// Add item to input storage
  bool addToInput(ResourceType resource, int amount) {
    return inputStorage.addResource(resource, amount);
  }

  /// Take item from output storage
  bool takeFromOutput(ResourceType resource, int amount) {
    return outputStorage.removeResource(resource, amount);
  }

  /// Get current energy production (for display)
  double getCurrentEnergyProduction() {
    // if (!stats.isGenerator) return 0;
    // return stats.energyProduction;
    return isWorking ? stats.energyProduction : 0;
  }

  /// Get current energy consumption (for display)
  double getCurrentEnergyConsumption() {
    // if (!isPowered) return 0;
    // if (!canOperate()) return 0;
    return isWorking ? stats.energyConsumption : 0;
  }

  /// Get current pollution rate (for display)
  double getCurrentPollutionRate() {
    // if (!canOperate()) return 0;
    // return stats.pollutionRate;
    return isWorking ? stats.pollutionRate : 0;
  }
}