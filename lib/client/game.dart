import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shared/inventory/inventory.dart';
import '../shared/items/item_definition.dart';
import '../shared/items/item_type.dart';
import 'managers/machine_registry.dart';
import 'managers/multiplayer_manager.dart';
import 'managers/placement_state_manager.dart';
import 'managers/position_sync.dart';
import 'network/ws_client.dart';
import 'ui/overlays/hud_overlay.dart';
import 'ui/overlays/inventory_overlay.dart';
import 'ui/overlays/item_selection_row.dart';
import 'ui/overlays/selected_item_indicator.dart';
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

  // Add these properties to AngryPlanetGame class
  late PlacementStateManager placementManager;
  late Inventory inventory;
  late MachineRegistry machineRegistry;
  
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
    
    // Setup camera - IMPORTANT: use world property
    camera = CameraComponent.withFixedResolution(
      width: 800,
      height: 600,
      world: cworld,  // ← Connect world to camera
    );
    camera.viewfinder.anchor = Anchor.center;

    // Add world to game tree
    await camera.viewport.add(cworld);  // ← CRITICAL: Add world to game!

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
      id: 'local2',
      x: 0,
      y: 0,
      name: 'You',
    );
    localPlayer = PlayerComponent(
      data: playerData,
      game: this,
      speed: 2.0,
    );
    await cworld.add(localPlayer);  // Add player to world

    // Create input handler (connects joystick to player)
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

    // Camera controller (now follows player)
    cameraController = CameraController(
      camera: camera,
      joystick: joystick,
      moveSpeed: 8.0,
    );
    cameraController.setTarget(localPlayer);  // Set camera to follow player
    await add(cameraController);

    // Chunk loader (now uses player position)
    chunkLoader = ChunkLoader(
      wsClient: socket,  // Your socket variable
      clientWorld: cworld,  // Your cworld variable
      camera: camera,
      playerPosition: () => localPlayer.position,  // Add player position
    );
    await add(chunkLoader);

    print("✅ Game loaded! Joystick ready, chunks loading...");

    // Initialize inventory with test items
    inventory = Inventory();
    inventory.add(ItemType.drill, 5);
    inventory.add(ItemType.woodHarvester, 5);
    inventory.add(ItemType.furnace, 3);
    inventory.add(ItemType.conveyor, 10);
    inventory.add(ItemType.storage, 2);

    // ✓ Initialize machine registry
    machineRegistry = MachineRegistry();
    await add(machineRegistry);

    // Initialize placement system (with registry)
    placementManager = PlacementStateManager(
      world: cworld,
      inventory: inventory,
      game: this,
      machineRegistry: machineRegistry,  // ✓ Pass registry
    );
    await add(placementManager);

    // Add placement input handler
    // placementInputHandler = PlacementInputHandler(
    //   placementManager: placementManager,
    //   camera: camera,
    // );
    // await camera.viewport.add(placementInputHandler);

    // await add(placementInputHandler);

    // Register overlays
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

    overlays.addEntry('item_row', (context, game) {
      return ItemSelectionRow(
        placeableItems: getPlaceableItems(),
        inventory: inventory,
        onItemSelected: (type) => placementManager.selectItem(type),
        onClose: () => {placementManager.exitItemMode(), game.overlays.remove('tile_debug')}
      );
    });

    overlays.addEntry('selected_item_indicator', (context, game) {
      // Check if any valid tiles exist
      // final hasValidTiles = placementManager.getHighlighters()
      //     .where((h) => h.isValid)
      //     .isNotEmpty;
      
      return SelectedItemIndicator(
        selectedItem: placementManager.selectedItem!,
        hasValidTilesNotifier: placementManager.hasValidTilesNotifier,  // ✓ Pass notifier
        validTileCountNotifier: placementManager.validTileCountNotifier,  // ✓ Pass notifier
        onFindStone: () {
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

    // Show HUD by default
    overlays.add('hud');

    print("✅ Game loaded with placement system!");
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    
    print("👆 Game tap at: ${event.localPosition}");
    
    if (placementManager.currentState != PlacementState.itemSelected) {
      print("⚠️ State: ${placementManager.currentState}");
      return;
    }

    final worldPos = camera.globalToLocal(event.localPosition);

    print("🌍 World: $worldPos → Tile: (${(worldPos.x / 16).floor()}, ${(worldPos.y / 16).floor()})");
    
    placementManager.selectTile(worldPos);
  }
}