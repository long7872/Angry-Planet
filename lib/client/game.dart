import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'network/ws_client.dart';
import 'world/client_world.dart';
import 'camera/camera_controller.dart';
import 'managers/chunk_loader.dart';
import 'render/sprite_manager.dart';

class AngryPlanetGame extends FlameGame {
  late final ClientSocket socket;
  late final ClientWorld cworld;
  late final CameraController cameraController;
  late final ChunkLoader chunkLoader;
  late final JoystickComponent joystick;
  late final SpriteManager spriteManager;

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

    // Camera controller
    cameraController = CameraController(
      camera: camera,
      joystick: joystick,
      moveSpeed: 8.0,
    );
    add(cameraController);

    // Chunk loader
    chunkLoader = ChunkLoader(
      socket: socket,
      world: cworld,
      camera: camera,
    );
    add(chunkLoader);

    print("✅ Game loaded! Joystick ready, chunks loading...");
  }
}