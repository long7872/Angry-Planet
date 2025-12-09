import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'managers/multiplayer_manager.dart';
import 'managers/position_sync.dart';
import 'network/ws_client.dart';
import 'world/client_world.dart';
import 'camera/camera_controller.dart';
import 'managers/chunk_loader.dart';
import 'render/sprite_manager.dart';
import 'player/player_component.dart';
import 'input/player_input_handler.dart';
import '../shared/player_data.dart';

class AngryPlanetGame extends FlameGame {
  late final ClientSocket socket;
  late final ClientWorld cworld;
  late final CameraController cameraController;
  late final ChunkLoader chunkLoader;
  late final JoystickComponent joystick;
  late final SpriteManager spriteManager;
  
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
  }
}