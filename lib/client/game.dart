import 'dart:convert';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shared/inventory/inventory.dart';
import '../shared/machines/machine_type.dart';
import '../shared/network_messages.dart';
import '../shared/resources/resource_type.dart';
import '../shared/game/game_manager.dart';
import 'components/machines/base_machine.dart';
import 'components/machines/energy_linker_machine.dart';
import 'components/machines/item_linker_machine.dart';
import 'components/machines/machine_factory.dart';
import 'components/machines/machine_state.dart';
import 'managers/collision_manager.dart';
import 'managers/machine_interaction_manager.dart';
import 'managers/machine_repair_manager.dart';
import 'managers/placement_state_manager.dart';
import 'managers/machine_registry.dart';
import 'managers/multiplayer_manager.dart';
import 'managers/position_sync.dart';
import 'network/ws_client.dart';
import 'ui/overlays/chat_overlay.dart';
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
import 'dart:async' as time;

class AngryPlanetGame extends FlameGame with TapCallbacks {
  late final ClientSocket socket;
  final String playerName;
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
  late final MachineRepairManager machineRepairManager;
  late final CollisionManager collisionManager;

  final List<ChatMessage> chatMessages = [];  // ✓ ADD
  bool isChatOpen = false;

  // bool _useServerTick = true;
  bool isHost = false;  
  String? myPlayerId; 

  time.Timer? _stateUpdateTimer;
  
  // Player components
  late final PlayerComponent localPlayer;
  late final PlayerInputHandler inputHandler;

  AngryPlanetGame(
    this.socket, {
    this.playerName = "Player",
  });

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
      name: playerName,
    );

    // _sendPlayerName();
    
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

    _setupMachineNetworkListeners();

    socket.send(jsonEncode({
      'type': NetworkMessage.hello,
    }));

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

    // Initialize game manager
    gameManager = GameManager();
    await add(gameManager);

    // Set up tick broadcast (host only)
    gameManager.onTickBroadcast = () {
      if (isHost) {
        socket.send(jsonEncode({
          'type': NetworkMessage.gameTick,
          'tick': gameManager.gameTick.tickCount,
        }));
      }
    };

    // Initialize inventory with starting resources
    inventory = Inventory(
      maxSlots: 50,        // 50 different item types
      maxStackSize: 200,   // 999 per stack (each resource type)
    );
    _giveStartingResources();

    // Initialize machine registry (with game manager)
    machineRegistry = MachineRegistry(gameManager: gameManager);
    await add(machineRegistry);

    // Set host status after we know our player ID
    // This will be set when we receive player_joined message
    Future.delayed(Duration(milliseconds: 1000), () {
      print("Setttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt");
      gameManager.isHost = isHost;
    });

    // Initialize placement system
    placementManager = PlacementStateManager(
      world: cworld,
      inventory: inventory,
      game: this,
      machineRegistry: machineRegistry,
    );
    await add(placementManager);

    // Start periodic state updates (every 0.5 seconds)
    _startStateUpdateTimer();

    // Initialize machine interaction manager
    machineInteractionManager = MachineInteractionManager(
      game: this,
      world: cworld,
    );
    await add(machineInteractionManager);

    machineRepairManager = MachineRepairManager(
      game: this,
      playerInventory: inventory,
      world: cworld,
    );
    await add(machineRepairManager);

    // Initialize collision manager
    collisionManager = CollisionManager(
      world: cworld,
      getMachines: () => machineRegistry.getAllMachines(),
    );
    localPlayer.setCollisionManager(collisionManager);

    // Register overlays
    _registerOverlays();

    // Show HUD by default
    overlays.add('hud');

    print("✅ Game loaded with all systems!");
  }

  // Send player name to server
  void _sendPlayerName() {
    socket.send(jsonEncode({
      'type': NetworkMessage.setPlayerName,
      'name': playerName,
    }));
  }

  // Setup machine network listeners
  void _setupMachineNetworkListeners() {
    socket.onMessage((message) {
      try {
        final data = jsonDecode(message);
        
        if (data['type'] == NetworkMessage.machinePlace) {
          _handleRemoteMachinePlace(data['machine']);
        }
        else if (data['type'] == NetworkMessage.machineDestroy) {
          _handleRemoteMachineDestroy(data['id']);
        }
        else if (data['type'] == NetworkMessage.machineSync) {
          // Initial sync of existing machines
          final machines = data['machines'] as List;
          for (final machineData in machines) {
            _handleRemoteMachinePlace(machineData);
          }
        }
        // Handle state sync from server
        else if (data['type'] == NetworkMessage.machineStateSync) {
          final states = data['states'] as List;
          for (final stateData in states) {
            _applyMachineState(stateData);
          }
        }
        
        // Handle single state update
        else if (data['type'] == NetworkMessage.machineStateUpdate) {
          _applyMachineState(data['state']);
        }

        // Detect if we're host (first player)
        else if (data['type'] == NetworkMessage.playerJoined) {
          myPlayerId = data['id'];
          // First player (player_0) is host
          isHost = myPlayerId == 'player_0';
          print(isHost ? '👑 I am HOST' : '👥 I am CLIENT');

          _sendPlayerName();
        }
        
        // Receive tick from host
        else if (data['type'] == NetworkMessage.gameTick && !isHost) {
          final hostTick = data['tick'] as int;
          gameManager.executeHostTick(hostTick);
        }

        else if (data['type'] == NetworkMessage.chatMessage) {
          _handleChatMessage(data);
        }
      } catch (e) {
        print('❌ Error handling machine message: $e');
      }
    });
  }

  // Handle incoming chat message
  void _handleChatMessage(Map<String, dynamic> data) {
    final playerName = data['playerName'] as String;
    final message = data['message'] as String;
    final isMe = data['playerId'] == myPlayerId;
    
    chatMessages.add(ChatMessage(
      playerName: playerName,
      message: message,
      timestamp: DateTime.now(),
      isMe: isMe,
    ));
    
    // Limit to 100 messages
    if (chatMessages.length > 100) {
      chatMessages.removeAt(0);
    }
    
    // Refresh chat overlay if open
    if (isChatOpen) {
      overlays.remove('chat');
      overlays.add('chat');
    }
    
    print('💬 Chat: [$playerName] $message');
  }

  // Send chat message
  void sendChatMessage(String message) {
    socket.send(jsonEncode({
      'type': NetworkMessage.chatMessage,
      'message': message,
    }));
  }

  // Handle remote machine placement
  void _handleRemoteMachinePlace(Map<String, dynamic> machineData) {
    final machineType = MachineType.values.firstWhere(
      (t) => t.name == machineData['type'],
      orElse: () => MachineType.burner,
    );
    
    final tilePos = Vector2(
      (machineData['x'] as num).toDouble(),
      (machineData['y'] as num).toDouble(),
    );
    
    final machineId = machineData['id'] as String;

    MachineFactory.syncNextMachineId(machineId);

    // Avoid duplicate
    if (machineRegistry.getMachineById(machineId) != null) {
      print('⚠️ Machine already exists: $machineId');
      return;
    }
    
    print('📡 Received remote machine: $machineType at $tilePos');

    
    // Create machine on client
    final machine = MachineFactory.createMachine(
      type: machineType,
      tilePosition: tilePos,
      game: this,
      rMachineId: machineId,
    );

    cworld.add(machine);
    machineRegistry.registerMachine(tilePos, machine);

    print('📡 Remote machine placed: $machineType at $tilePos');
  }

  // Handle remote machine destruction
  void _handleRemoteMachineDestroy(String machineId) {
    print('📡 Received remote machine destroy: $machineId');
    
    final machine = machineRegistry.getMachineById(machineId);
    if (machine != null) {
      machineRegistry.removeMachine(machine);
    }
  }

  // Send machine placement to server
  void sendMachinePlacement(BaseMachine machine) {
    socket.send(jsonEncode({
      'type': NetworkMessage.machinePlace,
      'id': machine.machineId,
      'machineType': machine.machineType.name,
      'x': machine.tilePosition.x,
      'y': machine.tilePosition.y,
      'state': MachineState.toJson(machine),
    }));
  }

  // Send machine destruction to server
  void sendMachineDestruction(String machineId) {
    socket.send(jsonEncode({
      'type': NetworkMessage.machineDestroy,
      'id': machineId,
    }));
  }


  // Periodic state updates
  void _startStateUpdateTimer() {
    _stateUpdateTimer = time.Timer.periodic(Duration(milliseconds: 500), (timer) {
      _sendMachineStates();
    });
  }
  
  // Send all machine states to server
  void _sendMachineStates() {
    final machines = machineRegistry.getAllMachines();
    
    for (final machine in machines) {
      final state = MachineState.toJson(machine);
      
      socket.send(jsonEncode({
        'type': NetworkMessage.machineStateUpdate,
        'id': machine.machineId,
        'state': state,
      }));
    }
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
          // Disable repair mode when entering item mode
          if (machineRepairManager.isRepairMode) {
            machineRepairManager.disableRepairMode();
            overlays.remove('hud');
            overlays.add('hud');
          }
          if (placementManager.currentState == PlacementState.itemSelectionMode) {
            placementManager.exitItemMode();
            // game.overlays.remove('tile_debug');
          } else if (placementManager.currentState == PlacementState.itemSelected) {
            // Item is selected → Go back to selection mode
            placementManager.deselectItem();  // New method
          } else {
            placementManager.enterItemMode();
            // game.overlays.add('tile_debug');
          }
        },
        onRepairPressed: () { 
          machineRepairManager.toggleRepairMode();
          // Refresh HUD to show updated state
          overlays.remove('hud');
          overlays.add('hud');
        },

        onChatPressed: () {
          if (isChatOpen) {
            overlays.remove('chat');
            isChatOpen = false;
          } else {
            overlays.add('chat');
            isChatOpen = true;
          }
        },
        isRepairMode: machineRepairManager.isRepairMode,
      );
    });

    // ✓ ADD: Chat overlay
    overlays.addEntry('chat', (context, game) {
      return ChatOverlay(
        messages: chatMessages,
        onSendMessage: (message) => sendChatMessage(message),
        onClose: () {
          overlays.remove('chat');
          isChatOpen = false;
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

    // Machine UI overlay
    overlays.addEntry('machine_ui', (context, game) {
      final machine = machineInteractionManager.selectedMachine;
      if (machine == null) return SizedBox.shrink();

      return MachineUIOverlay(
        machine: machine,
        playerInventory: inventory,
        machineRegistry: machineRegistry,
        onClose: () => machineInteractionManager.closeMachineUI(),
        onTakeFromOutput: (resource, amount) {
          if (!inventory.canAddResource(resource, amount)) return false;

          final taken = machine.takeFromOutput(resource, amount);
          if (!taken) return false;
          
          inventory.addResource(resource, amount);

          return true;
        },
        onAddToInput: (resource, amount) {
          if (!inventory.hasResource(resource, amount)) return false;

          final added = machine.addToInput(resource, amount);
          if (!added) return false;
          inventory.removeResource(resource, amount);
          // Add from player inventory to machine input
          // if (inventory.removeResource(resource, amount)) {
          //   if (machine.addToInput(resource, amount)) {
          //     return true;
          //   } else {
          //     // Rollback if machine input full
          //     inventory.addResource(resource, amount);
          //     return false;
          //   }
          // }
          return true;
        },
      );
    });
  }

  // Apply received state to local machine
  void _applyMachineState(Map<String, dynamic> stateData) {
    final machineId = stateData['id'] as String;
    final machine = machineRegistry.getMachineById(machineId);
    
    if (machine != null) {
      MachineState.fromJson(machine, stateData);

      // Resolve linker references after applying state
      if (machine is ItemLinkerMachine) {
        machine.resolveReferences(machineRegistry);
      } else if (machine is EnergyLinkerMachine) {
        machine.resolveReferences(machineRegistry);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // ✓ Update game manager (ticks machines, energy, pollution)
    gameManager.update(dt);
  }

  @override
  void onRemove() {
    _stateUpdateTimer?.cancel();  // Cleanup
    super.onRemove();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    
    // Priority 1: Check for damaged machines (repair interaction)
    if (machineRepairManager.isRepairMode) {
      machineRepairManager.onTapDown(event);
      return;
    }

    // Priority 2: Placement mode
    if (placementManager.currentState == PlacementState.itemSelected) {
      final worldPos = camera.globalToLocal(event.localPosition);
      placementManager.selectTile(worldPos);
      return;
    }

    // Priority 3: Machine interaction (when not in placement mode)
    // Let machine interaction manager handle it
    machineInteractionManager.onTapDown(event);
  }
}