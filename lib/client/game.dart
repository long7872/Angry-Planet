import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shared/inventory/inventory.dart';
import '../shared/machines/machine_type.dart';
import '../shared/resources/resource_type.dart';
import '../shared/game/game_manager.dart';
import 'managers/machine_interaction_manager.dart';
import 'managers/placement_state_manager.dart';
import 'managers/machine_registry.dart';
import 'managers/multiplayer_manager.dart';
import 'managers/position_sync.dart';
import 'network/ws_client.dart';
import 'ui/overlays/hud_overlay.dart';
import 'ui/overlays/inventory_overlay.dart';
import 'ui/overlays/machine_selection_row.dart';
import 'ui/overlays/machine_ui_overlay.dart';
import 'ui/overlays/selected_machine_indicator.dart';
import 'ui/overlays/tile_debug_overlay.dart';
import 'world/client_world.dart';
import 'camera/camera_controller.dart';
import 'managers/chunk_loader.dart';
import 'render/sprite_manager.dart';
import 'player/player_component.dart';
import 'input/player_input_handler.dart';
import '../shared/player_data.dart';

class AngryPlanetGame extends FlameGame with TapCallbacks {
  late final ClientSocket socket;
  late final ClientWorld cworld;
  late final CameraController cameraController;
  late final ChunkLoader chunkLoader;
  late final JoystickComponent joystick;
  late final SpriteManager spriteManager;

  // Game systems
  late final GameManager gameManager;
  late final PlacementStateManager placementManager;
  late final Inventory inventory;
  late final MachineRegistry machineRegistry;
  late final MachineInteractionManager machineInteractionManager;
  
  // Player components
  late final PlayerComponent localPlayer;
  late final PlayerInputHandler inputHandler;

  AngryPlanetGame(this.socket);

  @override
  Future<void> onLoad() async {
    // Load sprites
    spriteManager = SpriteManager();
    await spriteManager.loadAll(this);

    // Create world with sprite manager
    cworld = ClientWorld(spriteManager: spriteManager);
    
    // Setup camera
    camera = CameraComponent.withFixedResolution(
      width: 800,
      height: 600,
      world: cworld,
    );
    camera.viewfinder.anchor = Anchor.center;

    // Add world to game tree
    await camera.viewport.add(cworld);

    // Create joystick
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 30,
        paint: Paint()..color = Colors.cyan.withOpacity(0.9),
      ),
      background: CircleComponent(
        radius: 70,
        paint: Paint()
          ..color = Colors.cyan.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      ),
      margin: const EdgeInsets.only(left: 60, bottom: 60),
    );
    await camera.viewport.add(joystick);

    // Create local player at origin
    final playerData = PlayerData(
      id: 'local',
      x: 0,
      y: 0,
      name: 'You',
    );
    localPlayer = PlayerComponent(
      data: playerData,
      game: this,
      speed: 2.0,
    );
    await cworld.add(localPlayer);

    // Create input handler
    inputHandler = PlayerInputHandler(
      joystick: joystick,
      player: localPlayer,
    );
    await add(inputHandler);

    // Position sync
    final positionSync = PositionSync(
      player: localPlayer,
      socket: socket,
    );
    await add(positionSync);

    // Multiplayer manager
    final multiplayerManager = MultiplayerManager(
      socket: socket,
      world: cworld,
      game: this,
    );
    await add(multiplayerManager);

    // Camera controller
    cameraController = CameraController(
      camera: camera,
      joystick: joystick,
      moveSpeed: 8.0,
    );
    cameraController.setTarget(localPlayer);
    await add(cameraController);

    // Chunk loader
    chunkLoader = ChunkLoader(
      wsClient: socket,
      clientWorld: cworld,
      camera: camera,
      playerPosition: () => localPlayer.position,
    );
    await add(chunkLoader);

    // ✓ Initialize game manager
    gameManager = GameManager();
    await add(gameManager);

    // ✓ Initialize inventory with starting resources
    inventory = Inventory(
      maxSlots: 50,        // 50 different item types
      maxStackSize: 200,   // 999 per stack (each resource type)
    );
    _giveStartingResources();

    // ✓ Initialize machine registry (with game manager)
    machineRegistry = MachineRegistry(gameManager: gameManager);
    await add(machineRegistry);

    // ✓ Initialize placement system
    placementManager = PlacementStateManager(
      world: cworld,
      inventory: inventory,
      game: this,
      machineRegistry: machineRegistry,
    );
    await add(placementManager);

    // ✓ Initialize machine interaction manager
    machineInteractionManager = MachineInteractionManager(
      game: this,
      world: cworld,
    );
    await add(machineInteractionManager);

    // Register overlays
    _registerOverlays();

    // Show HUD by default
    overlays.add('hud');

    print("✅ Game loaded with all systems!");
  }

  void _giveStartingResources() {
    // Give player starting resources for building
    inventory.addResource(ResourceType.wood, 200);
    inventory.addResource(ResourceType.iron, 20);
    inventory.addResource(ResourceType.ironBar, 100);
    inventory.addResource(ResourceType.energyCatalyst, 40);
    inventory.addResource(ResourceType.energyCube, 40);
    inventory.addResource(ResourceType.coal, 100);  // For burner
    
    print("🎁 Starting resources added to inventory");
  }

  void _registerOverlays() {
    overlays.addEntry('hud', (context, game) {
      return HudOverlay(
        onBaloPressed: () => placementManager.openInventory(),
        onItemPressed: () {
          if (placementManager.currentState == PlacementState.itemSelectionMode) {
            placementManager.exitItemMode();
            // game.overlays.remove('tile_debug');
          } else if (placementManager.currentState == PlacementState.itemSelected) {
            // Item is selected → Go back to selection mode
            placementManager.deselectItem();  // ✓ New method
          } else {
            placementManager.enterItemMode();
            // game.overlays.add('tile_debug');
          }
        },
      );
    });

    overlays.addEntry('inventory', (context, game) {
      return InventoryOverlay(
        inventory: inventory,
        onClose: () => placementManager.closeInventory(),
      );
    });

    overlays.addEntry('machine_row', (context, game) {
      return MachineSelectionRow(
        placeableMachines: MachineType.values,
        inventory: inventory,
        onMachineSelected: (type) => placementManager.selectMachine(type),
        onClose: () {
          placementManager.exitItemMode();
          game.overlays.remove('tile_debug');
        },
      );
    });

    overlays.addEntry('selected_machine_indicator', (context, game) {
      return SelectedMachineIndicator(
        selectedMachine: placementManager.selectedMachine!,
        hasValidTilesNotifier: placementManager.hasValidTilesNotifier,
        validTileCountNotifier: placementManager.validTileCountNotifier,
        onFindResource: () {
          placementManager.teleportToNearestValidBiome();
        },
        onCancel: () {
          placementManager.deselectItem();
        },
      );
    });

    overlays.addEntry('tile_debug', (context, game) {
      final player = cworld.children.query<PlayerComponent>().firstOrNull;
      if (player == null) return SizedBox.shrink();
      
      final playerTileX = (player.position.x / 16).floor();
      final playerTileY = (player.position.y / 16).floor();
      
      return TileDebugOverlay(
        playerTileX: playerTileX,
        playerTileY: playerTileY,
        validTiles: placementManager.getValidTileCoords(),
      );
    });

    // ✓ NEW: Machine UI overlay
    overlays.addEntry('machine_ui', (context, game) {
      final machine = machineInteractionManager.selectedMachine;
      if (machine == null) return SizedBox.shrink();

      return MachineUIOverlay(
        machine: machine,
        playerInventory: inventory,
        machineRegistry: machineRegistry,
        onClose: () => machineInteractionManager.closeMachineUI(),
        onTakeFromOutput: (resource, amount) {
          // Take from machine output to player inventory
          // if (machine.outputStorage.removeResource(resource, amount)) {
          //   inventory.addResource(resource, amount);
          //   return true;
          // }
          // return false;
          if (machine.takeFromOutput(resource, amount)) {
            inventory.addResource(resource, amount);
            return true;
          }
          return false;
        },
        onAddToInput: (resource, amount) {
          // Add from player inventory to machine input
          if (inventory.removeResource(resource, amount)) {
            if (machine.addToInput(resource, amount)) {
              return true;
            } else {
              // Rollback if machine input full
              inventory.addResource(resource, amount);
              return false;
            }
          }
          return false;
        },
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // ✓ Update game manager (ticks machines, energy, pollution)
    gameManager.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    
    // Priority 1: Placement mode
    if (placementManager.currentState == PlacementState.itemSelected) {
      final worldPos = camera.globalToLocal(event.localPosition);
      placementManager.selectTile(worldPos);
      return;
    }

    // Priority 2: Machine interaction (when not in placement mode)
    // Let machine interaction manager handle it
    machineInteractionManager.onTapDown(event);
  }
}