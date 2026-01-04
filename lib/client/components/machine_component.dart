import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../shared/machines/machine_type.dart';
import '../../shared/machines/machine_stats.dart';
import '../../shared/game/energy_system.dart';
import '../managers/machine_registry.dart';

class MachineComponent extends SpriteComponent {
  final MachineType machineType;
  final Vector2 tilePosition;
  final FlameGame game;
  final MachineStats stats;

  // Machine state
  bool isPowered = false;
  EnergyNode? energyNode;
  
  MachineComponent({
    required this.machineType,
    required this.tilePosition,
    required this.game,
  }) : stats = getMachineStats(machineType),
       super(
          position: tilePosition * 16,
          size: Vector2.all(16),
          anchor: Anchor.topLeft,
          priority: 75,
        );

  @override
  Future<void> onLoad() async {
    // Load sprite (placeholder for now - use icon)
    // TODO: Load actual machine sprites
    sprite = await Sprite.load('items/placeholder.png');
  }

  @override
  void onRemove() {
    super.onRemove();
    
    // Unregister from machine registry
    final registry = game.children.query<MachineRegistry>().firstOrNull;
    registry?.unregisterMachine(tilePosition);
  }

  /// Called every tick to update machine behavior
  void tick() {
    if (!isPowered && stats.isConsumer) {
      // Machine is unpowered - do nothing
      return;
    }

    // Machine-specific behavior will be implemented later
    operate();
  }

  /// Machine operation logic (override in subclasses)
  void operate() {
    // Base implementation - will be specialized per machine type
  }
}