import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../shared/inventory/item_stack.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/machines/machine_stats.dart';
import '../../../shared/inventory/inventory.dart';
import '../../../shared/resources/resource_type.dart';
import '../../../shared/game/energy_system.dart';
import '../../render/icon_sprite_generator.dart';
import '../../utils/icon_data.dart';
import 'machine_health_bar.dart';

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

  // Health system
  double health = 150;
  double maxHealth = 150;
  bool isBroken = false;

  bool _inventoryLocked = false;

  bool get inventoryLocked => _inventoryLocked;

  void lockInventory() => _inventoryLocked = true;
  void unlockInventory() => _inventoryLocked = false;

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
  void render(Canvas canvas) {
    // Apply red tint if damaged
    if (isDamaged && !isBroken) {
      final damagePercentage = 1 - healthPercentage;
      final redTint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.red.withOpacity(damagePercentage * 0.6),  // More damage = more red
          BlendMode.srcATop,
        );
      
      canvas.saveLayer(null, redTint);
      super.render(canvas);
      canvas.restore();
    } else if (isBroken) {
      // Broken machines are dark red
      final brokenTint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.red.withOpacity(0.8),
          BlendMode.srcATop,
        );
      
      canvas.saveLayer(null, brokenTint);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load sprite based on machine type
    sprite = await _loadMachineSprite();

    // Add health bar component
    add(MachineHealthBar(
      machine: this,
      game: game,
    ));
  }

  Future<Sprite> _loadMachineSprite() async {
    // TODO: Load actual machine sprites
    // For now, use placeholder
    try {
      // return await Sprite.load('items/${machineType.name}.png');
      print('Using icon for ${machineType.name}');
      return await IconSpriteGenerator.fromIcon(
        getMachineIcon(machineType),
        size: 16.0,  // Match your tile size
        color: getMachineColor(machineType),
      );
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

    if (_inventoryLocked) return;

      _inventoryLocked = true;
      isWorking = false;

      if (!isBroken) {
        _updatePowerStatus();
        operate();
      }

      _inventoryLocked = false;

    // isWorking = false;

    // Check if machine is broken
    // if (isBroken) {
    //   return;  // Broken machines don't operate
    // }

    // Update power status BEFORE operating
    // _updatePowerStatus();
    
    // operate();
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
    if (_inventoryLocked) return false;
    return inputStorage.addResource(resource, amount);
  }

  /// Take item from output storage
  bool takeFromOutput(ResourceType resource, int amount) {
    if (_inventoryLocked) return false;
    return outputStorage.removeResource(resource, amount);
  }

  /// Take damage
  void takeDamage(double amount) {
    health -= amount;
    health = health.clamp(0, maxHealth);
    
    if (health <= 0 && !isBroken) {
      isBroken = true;
      print('💥 ${machineType.displayName} at ${tilePosition} is BROKEN!');
    }
  }

  /// Repair machine
  void repair(double amount) {
    if (health >= maxHealth) return;
    
    health += amount;
    health = health.clamp(0, maxHealth);
    
    if (isBroken && health > 0) {
      isBroken = false;
      print('🔧 ${machineType.displayName} at ${tilePosition} REPAIRED!');
    }
  }

  List<ItemStack> getAvailableOutputStacks() {
    return outputStorage.getAllStacks();
  }

  /// Get health percentage
  double get healthPercentage => health / maxHealth;

  /// Check if damaged
  bool get isDamaged => health < maxHealth;

  /// Get current energy production (for display)
  double getCurrentEnergyProduction() {
    // if (!stats.isGenerator) return 0;
    // return stats.energyProduction;
    if (isBroken) return 0;
    return isWorking ? stats.energyProduction : 0;
  }

  /// Get current energy consumption (for display)
  double getCurrentEnergyConsumption() {
    // if (!isPowered) return 0;
    // if (!canOperate()) return 0;
    if (isBroken) return 0;
    return isWorking ? stats.energyConsumption : 0;
  }

  /// Get current pollution rate (for display)
  double getCurrentPollutionRate() {
    // if (!canOperate()) return 0;
    // return stats.pollutionRate;
    if (isBroken) return 0;
    return isWorking ? stats.pollutionRate : 0;
  }
}