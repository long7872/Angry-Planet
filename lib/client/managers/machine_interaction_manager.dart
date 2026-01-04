import 'package:angry_planet/shared/machines/machine_type.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../components/machines/base_machine.dart';
import '../world/client_world.dart';

/// Manages machine interactions (clicking machines to open UI)
class MachineInteractionManager extends Component with TapCallbacks {
  final FlameGame game;
  final ClientWorld world;
  
  BaseMachine? selectedMachine;

  MachineInteractionManager({
    required this.game,
    required this.world,
  });

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Convert screen to world coordinates
    final worldPos = game.camera.globalToLocal(event.localPosition);
    
    // Convert to tile position
    final tilePos = Vector2(
      (worldPos.x / 16).floor().toDouble(),
      (worldPos.y / 16).floor().toDouble(),
    );

    print("🖱️ Machine interaction tap at tile: $tilePos");

    // Try to find machine at this position
    final machine = _findMachineAtTile(tilePos);
    
    if (machine != null) {
      openMachineUI(machine);
    } else if (selectedMachine != null) {
      // Clicked outside - close UI
      closeMachineUI();
    }
  }

  BaseMachine? _findMachineAtTile(Vector2 tilePos) {
    // Search all machines in world
    final machines = world.children.query<BaseMachine>();
    
    for (final machine in machines) {
      // Check if this machine's tile position matches
      if (machine.tilePosition.x.toInt() == tilePos.x.toInt() &&
          machine.tilePosition.y.toInt() == tilePos.y.toInt()) {
        return machine;
      }
    }
    
    return null;
  }

  void openMachineUI(BaseMachine machine) {
    selectedMachine = machine;
    game.overlays.add('machine_ui');
    print("🔧 Opened UI for ${machine.machineType.displayName} at ${machine.tilePosition}");
  }

  void closeMachineUI() {
    if (selectedMachine != null) {
      print("🔧 Closed UI for ${selectedMachine!.machineType.displayName}");
      selectedMachine = null;
      game.overlays.remove('machine_ui');
    }
  }

  /// Add item to selected machine's input
  bool addItemToInput(resourceType, int amount) {
    if (selectedMachine == null) return false;
    return selectedMachine!.addToInput(resourceType, amount);
  }

  /// Take item from selected machine's output
  bool takeItemFromOutput(resourceType, int amount) {
    if (selectedMachine == null) return false;
    return selectedMachine!.takeFromOutput(resourceType, amount);
  }
}