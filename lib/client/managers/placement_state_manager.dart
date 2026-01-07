import 'package:angry_planet/client/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../shared/machines/machine_stats.dart';
import '../../shared/machines/machine_type.dart';
import '../../shared/resources/resource_type.dart';
import '../../shared/tile_type.dart';
import '../components/machines/machine_factory.dart';
import '../player/player_component.dart';
import '../world/client_world.dart';
import '../ui/placement/tile_highlighter.dart';
import '../ui/placement/ghost_preview.dart';
import '../ui/placement/confirm_buttons.dart';
import '../../shared/inventory/inventory.dart';
import 'machine_registry.dart';

enum PlacementState {
  idle,
  inventoryOpen,
  itemSelectionMode,
  itemSelected,
  ghostPreview,
}

class PlacementStateManager extends Component {
  final ClientWorld world;
  final Inventory inventory;
  final AngryPlanetGame game;
  final MachineRegistry machineRegistry;

  PlacementState currentState = PlacementState.idle;
  MachineType? selectedMachine;
  Vector2? selectedTile;

  final List<TileHighlighter> _highlighters = [];
  GhostPreview? _ghostPreview;
  ConfirmButtons? _confirmButtons;

  // Track player position to update highlights
  Vector2 _lastPlayerTilePos = Vector2.zero();
  static const double highlightUpdateInterval = 0.1;
  double _timeSinceHighlightUpdate = 0;
  static const int highlightRadius = 3;

  final ValueNotifier<bool> hasValidTilesNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> validTileCountNotifier = ValueNotifier<int>(0);

  PlacementStateManager({
    required this.world,
    required this.inventory,
    required this.game,
    required this.machineRegistry,
  });

  @override
  void update(double dt) {
    super.update(dt);

    // Update highlights if in placement mode and player moved
    if (currentState == PlacementState.itemSelectionMode ||
        currentState == PlacementState.itemSelected) {
      _timeSinceHighlightUpdate += dt;

      if (_timeSinceHighlightUpdate >= highlightUpdateInterval) {
        final currentPlayerTile = _getPlayerTilePosition();

        if (currentPlayerTile != _lastPlayerTilePos) {
          _updateHighlights();
          _lastPlayerTilePos = currentPlayerTile;
        }

        _timeSinceHighlightUpdate = 0;
      }
    }
  }

  // ==================== STATE TRANSITIONS ====================

  void openInventory() {
    if (currentState == PlacementState.itemSelectionMode) {
      exitItemMode();
    }
    currentState = PlacementState.inventoryOpen;
    game.overlays.add('inventory');
    print("📦 Inventory opened");
  }

  void closeInventory() {
    currentState = PlacementState.idle;
    game.overlays.remove('inventory');
    print("📦 Inventory closed");
  }

  void enterItemMode() {
    if (currentState == PlacementState.inventoryOpen) {
      closeInventory();
    }

    currentState = PlacementState.itemSelectionMode;
    _lastPlayerTilePos = _getPlayerTilePosition();
    _highlightValidTiles();
    game.overlays.add('machine_row');
    print("🔧 Item mode activated");
  }

  void exitItemMode() {
    _clearHighlights();
    _clearSelection();
    game.overlays.remove('machine_row');
    game.overlays.remove('selected_machine_indicator');
    currentState = PlacementState.idle;

    // Reset notifiers
    hasValidTilesNotifier.value = false;
    validTileCountNotifier.value = 0;
    print("🔧 Item mode deactivated");
  }

  void selectMachine(MachineType machineType) {
    // Check if can afford
    final stats = getMachineStats(machineType);
    if (!inventory.canAfford(stats.buildCost.toMap())) {
      print("❌ Cannot afford ${stats.type.displayName}");
      print("   Cost: ${stats.buildCost}");
      return;
    }

    selectedMachine = machineType;
    currentState = PlacementState.itemSelected;
    
    // Update highlights based on selected machine
    _updateHighlights();
    
    // Show selected item indicator
    game.overlays.remove('machine_row');
    game.overlays.add('selected_machine_indicator');
    
    print("✅ Selected: ${machineType.displayName}");
  }

  void deselectItem() {
    if (currentState != PlacementState.itemSelected) return;
    
    print("🔙 Deselecting item, returning to item selection");
    
    // Remove selected item indicator
    game.overlays.remove('selected_machine_indicator');
    
    // Clear selection
    selectedMachine = null;
    selectedTile = null;
    
    // Go back to item selection mode
    currentState = PlacementState.itemSelectionMode;
    
    // Show item row again
    game.overlays.add('machine_row');
    
    // Update highlights to show all tiles (not just valid ones)
    _updateHighlights();
  }

  void selectTile(Vector2 worldPos) {
    if (currentState != PlacementState.itemSelected) {
      print("⚠️ Not in item selected state");
      return;
    }
    if (selectedMachine == null) {
      print("⚠️ No item selected");
      return;
    }

    final tilePos = Vector2(
      (worldPos.x / 16).floor().toDouble(),
      (worldPos.y / 16).floor().toDouble(),
    );

    print("🎯 Tapped tile at: $tilePos (world: $worldPos)");

    // ✓ CHECK 1: Is tile within highlighted area?
    if (!_isTileInHighlightedArea(tilePos)) {
      print("❌ Tile is outside highlighted area");
      _showOutOfRangeEffect(tilePos);  // ✓ Visual feedback
      return;
    }

    // CHECK 2: Is tile valid for this item?
    if (!_isValidTile(tilePos)) {
      final tile = _getTileAt(tilePos);
      final stats = getMachineStats(selectedMachine!);
      
      // ✓ UPDATED: Better error messages
      if (machineRegistry.hasMachineAt(tilePos)) {
        final existing = machineRegistry.getMachineAt(tilePos);
        print("❌ Cannot place - ${existing?.machineType.name} already here");
      } else if (tile != null) {
        print("❌ Cannot place ${stats.type.displayName} on ${tile.resource.name}");
        print("   Required: ${stats.validPlacements.map((r) => r.name).join(' OR ')}");
      }

      return;
    }

    selectedTile = tilePos;
    currentState = PlacementState.ghostPreview;
    _showGhostPreview(tilePos);

    print("👻 Ghost preview at tile $tilePos");
  }

  bool _isTileInHighlightedArea(Vector2 tilePos) {
    final playerTile = _getPlayerTilePosition();
    
    // Calculate distance from player (currently 3 tiles in each direction = 7×7 grid)
    // const int highlightRadius = 3;
    
    final dx = (tilePos.x - playerTile.x).abs();
    final dy = (tilePos.y - playerTile.y).abs();
    
    final isInArea = dx <= highlightRadius && dy <= highlightRadius;
    
    if (!isInArea) {
      print("⚠️ Tile ($tilePos) is ${dx.toInt()}×${dy.toInt()} away from player ($playerTile)");
      print("   Max allowed: $highlightRadius tiles");
    }
    
    return isInArea;
  }

  void _showOutOfRangeEffect(Vector2 tilePos) {
    final flash = RectangleComponent(
      position: tilePos * 16,
      size: Vector2.all(16),
      paint: Paint()..color = Colors.red.withOpacity(0.7),
      priority: 200,
    );
    
    world.add(flash);
    
    // Remove after 0.3 seconds
    flash.add(
      RemoveEffect(
        delay: 0.3,
      ),
    );
  }

  void confirmPlacement() {
    if (selectedMachine == null || selectedTile == null) {
      print("⚠️ Cannot confirm: missing machine or tile");
      return;
    }

    print("🏗️ Confirming placement...");

    final stats = getMachineStats(selectedMachine!);

    // Check can afford
    if (!inventory.canAfford(stats.buildCost.toMap())) {
      print("❌ Cannot afford ${stats.type.displayName}");
      return;
    }

    // Deduct build cost
    if (!inventory.deductCost(stats.buildCost.toMap())) {
      print("❌ Failed to deduct cost");
      return;
    }

    // Get resource type at this tile (for digger)
    final tile = _getTileAt(selectedTile!);
    final resourceNode = tile?.resource;

    // Place machine
    _placeMachine(selectedMachine!, selectedTile!, resourceNode);

    // Cleanup
    _hideGhostPreview();
    _clearHighlights();
    _clearSelection();

    currentState = PlacementState.idle;
    game.overlays.remove('selected_machine_indicator');

    print("✅ Machine placed successfully");
  }

  void cancelPlacement() {
    _hideGhostPreview();
    // _clearHighlights();
    // _clearSelection();
    selectedTile = null;
    currentState = PlacementState.itemSelected;

    // Show item row again
    game.overlays.add('machine_row');

    print("❌ Placement cancelled");
  }

  // ==================== HIGHLIGHT MANAGEMENT ====================

  void _updateHighlights() {
    _clearHighlights();
    _highlightValidTiles();
    _updateValidTileNotifiers();
  }

  void _highlightValidTiles() {
    final playerTile = _getPlayerTilePosition();

    // Highlight 3x3 area around player
    for (int dx = -highlightRadius; dx <= highlightRadius; dx++) {
      for (int dy = -highlightRadius; dy <= highlightRadius; dy++) {
        final tile = Vector2(playerTile.x + dx, playerTile.y + dy);

        bool shouldHighlight = false;
        bool isValid = false;

        // In item selection mode, highlight all nearby tiles
        if (currentState == PlacementState.itemSelectionMode) {
          shouldHighlight = true;
          isValid = true;
        }
        // In item selected mode, only highlight valid tiles
        else if (currentState == PlacementState.itemSelected) {
          shouldHighlight = true;
          isValid = _isValidTile(tile);
        }

        if (shouldHighlight) {
          final highlighter = TileHighlighter(
            tilePosition: tile,
            isValid: isValid, // ✓ Pass validity to highlighter
          );
          world.add(highlighter);
          _highlighters.add(highlighter);
        }
      }
    }

    final validCount = _highlighters.where((h) => h.isValid).length;
    print(
      "💡 Highlighted ${_highlighters.length} tiles around $playerTile ($validCount valid)",
    );
  }

  // ✓ NEW: Update notifiers when highlights change
  void _updateValidTileNotifiers() {
    final validTiles = _highlighters.where((h) => h.isValid).toList();
    final validCount = validTiles.length;
    final hasValid = validCount > 0;
    
    // Update notifiers (triggers UI rebuild)
    if (hasValidTilesNotifier.value != hasValid) {
      hasValidTilesNotifier.value = hasValid;
      print("🔔 Valid tiles changed: $hasValid");
    }
    
    if (validTileCountNotifier.value != validCount) {
      validTileCountNotifier.value = validCount;
      print("🔔 Valid tile count: $validCount");
    }
  }

  void _clearHighlights() {
    for (final highlighter in _highlighters) {
      world.remove(highlighter);
    }
    _highlighters.clear();
  }

  void _clearSelection() {
    selectedMachine = null;
    selectedTile = null;
  }

  // ==================== VALIDATION ====================

  bool _isValidTile(Vector2 tilePos) {
    if (selectedMachine == null) return false;

    final stats = getMachineStats(selectedMachine!);
    
    // CHECK 1: Get tile data
    final tile = _getTileAt(tilePos);
    if (tile == null) {
      print("⚠️ Tile data not found at $tilePos");
      return false;
    }

    // CHECK 2: Machine already exists?
    if (machineRegistry.hasMachineAt(tilePos)) {
      print("⚠️ Machine already exists at $tilePos");
      return false;
    }

    // CHECK 3: Resource type matches?
    final isValid = stats.validPlacements.contains(tile.resource);
    
    if (!isValid) {
      print("⚠️ Invalid placement: ${tile.resource.name} for ${stats.type.displayName}");
      print("   Required: ${stats.validPlacements.map((r) => r.name).join(' OR ')}");
    }
    
    return isValid;
  }

  TileData? _getTileAt(Vector2 tilePos) {
    final chunkX = (tilePos.x / 32).floor();
    final chunkY = (tilePos.y / 32).floor();
    final localX = tilePos.x.toInt() % 32;
    final localY = tilePos.y.toInt() % 32;

    // Get chunk from world
    final chunk = world.getChunk(chunkX, chunkY);
    if (chunk == null) {
      print("⚠️ Chunk not loaded at ($chunkX, $chunkY)");
      return null;
    }

    return chunk.getTileLocal(localX, localY);
  }

  Vector2 _getPlayerTilePosition() {
    // Get from game's local player component
    final player = world.children.query<PlayerComponent>().firstOrNull;
    if (player == null) {
      print("⚠️ Player component not found");
      return Vector2.zero();
    }

    return Vector2(
      (player.position.x / 16).floor().toDouble(),
      (player.position.y / 16).floor().toDouble(),
    );
  }

  void _showGhostPreview(Vector2 tilePos) {
    if (selectedMachine == null) return;

    _ghostPreview = GhostPreview(
      machineType: selectedMachine!,
      tilePosition: tilePos,
      game: game, 
    );
    world.add(_ghostPreview!);

    _confirmButtons = ConfirmButtons(
      tilePosition: tilePos,
      onAccept: () => confirmPlacement(),
      onCancel: () => cancelPlacement(),
      game: game,
    );
    world.add(_confirmButtons!);

    print("👻 Ghost preview created at $tilePos");
  }

  void _hideGhostPreview() {
    if (_ghostPreview != null) {
      world.remove(_ghostPreview!);
      _ghostPreview = null;
    }
    if (_confirmButtons != null) {
      world.remove(_confirmButtons!);
      _confirmButtons = null;
    }
  }

  // ==================== PLACEMENT (UPDATED) ====================

  void _placeMachine(MachineType machineType, Vector2 tilePos, ResourceType? resourceNode) {
    final machine = MachineFactory.createMachine(
      type: machineType,
      tilePosition: tilePos,
      game: game,
      resourceNode: resourceNode,
    );
    
    world.add(machine);
    
    // Register in machine registry
    machineRegistry.registerMachine(tilePos, machine);

    // Send to server
    game.sendMachinePlacement(machine);
    
    print("Placed ${getMachineStats(machineType).type.displayName} at $tilePos");
  }

  // Add this method at the end of the class

  void teleportToNearestValidBiome() {
    if (selectedMachine == null) return;
    
    final stats = getMachineStats(selectedMachine!);
    final player = world.children.query<PlayerComponent>().firstOrNull;
    if (player == null) return;
    
    print("🔍 Searching for valid biome...");
    
    // Search in expanding circles
    for (int radius = 2; radius <= 20; radius++) {
      for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
          final tilePos = Vector2(
            (player.position.x / 16).floor() + dx.toDouble(),
            (player.position.y / 16).floor() + dy.toDouble(),
          );
          
          final tile = _getTileAt(tilePos);
          if (tile != null && stats.validPlacements.contains(tile.biome)) {
            // Found valid tile! Teleport player
            final worldPos = tilePos * 16 + Vector2(8, 8); // Center of tile
            player.position = worldPos;
            player.data.x = worldPos.x;
            player.data.y = worldPos.y;
            
            print("✈️ Teleported to ${tile.biome.name} at $tilePos");
            
            // Update highlights
            _updateHighlights();
            return;
          }
        }
      }
    }
    
    print("❌ No valid biome found within search radius");
  }

  // ==================== PUBLIC GETTERS ====================

  List<TileHighlighter> getHighlighters() => _highlighters;

  // Add this getter at the end of the class
  List<String> getValidTileCoords() {
    return _highlighters
        .where((h) => h.isValid)
        .map((h) => "(${h.tilePosition.x.toInt()}, ${h.tilePosition.y.toInt()})")
        .toList();
  }

  bool get isInPlacementMode {
    return currentState == PlacementState.itemSelectionMode ||
           currentState == PlacementState.itemSelected ||
           currentState == PlacementState.ghostPreview;
  }

  // ==================== CLEANUP ====================

  @override
  void onRemove() {
    hasValidTilesNotifier.dispose();
    validTileCountNotifier.dispose();
    super.onRemove();
  }
}
