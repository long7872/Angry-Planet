import 'dart:async';

import 'package:angry_planet/shared/inventory/item_stack.dart';
import 'package:flutter/material.dart';
import '../../../shared/machines/machine_config.dart';
import '../../../shared/machines/machine_type.dart';
import '../../../shared/machines/machine_stats.dart';
import '../../../shared/machines/recipe.dart';
import '../../../shared/resources/resource_type.dart';
import '../../../shared/inventory/inventory.dart';
import '../../components/machines/base_machine.dart';
import '../../components/machines/burner_machine.dart';
import '../../components/machines/digger_machine.dart';
import '../../components/machines/chopper_machine.dart';
import '../../components/machines/energy_linker_machine.dart';
import '../../components/machines/item_linker_machine.dart';
import '../../components/machines/smelter_machine.dart';
import '../../components/machines/holder_machine.dart';
import '../../components/machines/spaceship_machine.dart';
import '../../managers/machine_registry.dart';
import '../../utils/icon_data.dart';
import 'linker_connection_ui.dart';

/// Helper class to track item quantities in machine vs player
class _InputItemData {
  final ResourceType resource;
  int inMachine;
  int inPlayer;

  _InputItemData({
    required this.resource,
    required this.inMachine,
    required this.inPlayer,
  });
}

class _StorageItemData {
  final ResourceType resource;
  int inStorage;
  int inPlayer;

  _StorageItemData({
    required this.resource,
    required this.inStorage,
    required this.inPlayer,
  });
}

class MachineUIOverlay extends StatefulWidget {
  final BaseMachine machine;
  final Inventory playerInventory;
  final MachineRegistry machineRegistry;
  final VoidCallback onClose;
  final Function(ResourceType, int) onTakeFromOutput;
  final Function(ResourceType, int) onAddToInput;

  const MachineUIOverlay({
    Key? key,
    required this.machine,
    required this.playerInventory,
    required this.machineRegistry,
    required this.onClose,
    required this.onTakeFromOutput,
    required this.onAddToInput,
  }) : super(key: key);

  @override
  State<MachineUIOverlay> createState() => _MachineUIOverlayState();
}

class _MachineUIOverlayState extends State<MachineUIOverlay> {
  static const Duration _uiCooldown = Duration(milliseconds: 350);

  bool _isCoolingDown = false;
  Timer? _cooldownTimer;

  bool _tryBeginAction() {
    if (_isCoolingDown) return false;

    _isCoolingDown = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_uiCooldown, () {
      if (mounted) {
        setState(() {
          _isCoolingDown = false;
        });
      } else {
        _isCoolingDown = false;
      }
    });

    return true;
  }
  
  @override
  void initState() {
    super.initState();
    // Rebuild UI every second to show live updates
    Future.delayed(Duration(seconds: 1), _updateUI);
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
      Future.delayed(Duration(seconds: 1), _updateUI);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.machine.stats;
    final isLinker = widget.machine is EnergyLinkerMachine || 
                    widget.machine is ItemLinkerMachine;
    final isHolder = widget.machine is HolderMachine;
    final isSmelter = widget.machine is SmelterMachine;
    final isSpaceship = widget.machine is SpaceshipMachine;

    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.85,  // ✓ Max 85% of screen
                minHeight: 300,                   // ✓ Min height
              ),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Special styling for spaceship
                gradient: isSpaceship 
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1a1a2e),
                          Color(0xFF16213e),
                          Color(0xFF0f3460),
                        ],
                      )
                    : null,
                color: isSpaceship ? null : Color(0xFF2C2416),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSpaceship 
                      ? ((widget.machine as SpaceshipMachine).isFullyCharged 
                          ? Colors.greenAccent 
                          : Colors.blueAccent)
                      : Color(0xFF8B7355),
                  width: 4,
                ),
                boxShadow: isSpaceship 
                    ? [
                        BoxShadow(
                          color: ((widget.machine as SpaceshipMachine).isFullyCharged 
                              ? Colors.greenAccent 
                              : Colors.blueAccent).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header - Fixed at top
                          _buildHeader(stats),
                          SizedBox(height: 10),
                          
                          // Machine Stats - Fixed
                          if (!isSpaceship) ...[
                            _buildStats(),
                            SizedBox(height: 10),
                          ],
                          // Machine-specific content
                          if (isLinker)
                            _buildMachineSpecificInfo()
                          else if (isHolder)
                            Container(
                              height: MediaQuery.of(context).size.height * 0.5,  // ✓ Set height for holder
                              child: _buildHolderStorage(),
                            )
                          else if (isSmelter)
                            Container(
                              height: MediaQuery.of(context).size.height * 0.55,  // ✓ Set height for smelter
                              child: _buildSmelterRecipeUI(),
                            )
                          else if (isSpaceship)
                            _buildSpaceshipUI()
                            // Container(
                            //   height: MediaQuery.of(context).size.height * 0.35,  // ✓ Set height for smelter
                            //   child: _buildSpaceshipUI(),
                            // )
                          else ...[
                            _buildMachineSpecificInfo(),
                            SizedBox(height: 15),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.35,  // ✓ Set height for storage
                              child: _buildStorage(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Close button - Fixed at bottom
                  SizedBox(height: 10),
                  _buildCloseButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MachineStats stats) {
    return Row(
      children: [
        Icon(
          getMachineIcon(widget.machine.machineType),
          size: 40,
          color: Colors.white,
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.type.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stats.type.description,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Power indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.machine.isPowered ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.machine.isPowered ? Icons.power : Icons.power_off,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 5),
              Text(
                widget.machine.isPowered ? 'Powered' : 'No Power',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B7355), width: 2),
      ),
      child: Column(
        children: [
          _buildStatRow(
            Icons.bolt,
            'Energy',
            widget.machine.stats.isGenerator
                ? '+${widget.machine.getCurrentEnergyProduction().toStringAsFixed(1)} NE/s'
                : '-${widget.machine.getCurrentEnergyConsumption().toStringAsFixed(1)} NE/s',
            widget.machine.stats.isGenerator ? Colors.green : Colors.orange,
          ),
          SizedBox(height: 8),
          _buildStatRow(
            Icons.cloud,
            'Pollution',
            '${widget.machine.getCurrentPollutionRate() >= 0 ? "+" : ""}${widget.machine.getCurrentPollutionRate().toStringAsFixed(1)} P/s',
            widget.machine.getCurrentPollutionRate() > 0 ? Colors.red : Colors.green,
          ),
          if (widget.machine.maxStoredEnergy > 0) ...[
            SizedBox(height: 8),
            _buildStatRow(
              Icons.battery_charging_full,
              'Stored Energy',
              '${widget.machine.storedEnergy.toStringAsFixed(0)} / ${widget.machine.maxStoredEnergy.toStringAsFixed(0)} NE',
              Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMachineSpecificInfo() {
    // Linkers show connection UI
    if (widget.machine is EnergyLinkerMachine || widget.machine is ItemLinkerMachine) {
      return _buildLinkerConnectionUI();
    }
    
    // Show machine-specific progress/info
    if (widget.machine is BurnerMachine) {
      return _buildBurnerInfo(widget.machine as BurnerMachine);
    } else if (widget.machine is DiggerMachine) {
      return _buildDiggerInfo(widget.machine as DiggerMachine);
    } else if (widget.machine is ChopperMachine) {
      return _buildChopperInfo(widget.machine as ChopperMachine);
    } else if (widget.machine is SmelterMachine) {
      return _buildSmelterInfo(widget.machine as SmelterMachine);
    } else if (widget.machine is HolderMachine) {
      return _buildHolderInfo(widget.machine as HolderMachine);
    }
    
    return SizedBox.shrink();
  }

  /// Build spaceship-specific UI
  Widget _buildSpaceshipUI() {
    final spaceship = widget.machine as SpaceshipMachine;
    final cubesLoaded = spaceship.energyCubesLoaded;
    final cubesNeeded = SpaceshipMachine.requiredCubes;
    final energyStored = spaceship.storedEnergy;
    final energyNeeded = SpaceshipMachine.requiredEnergy;
    final isFullyCharged = spaceship.isFullyCharged;
    final cubesReady = spaceship.cubesReady;
    final energyReady = spaceship.energyReady;
    final playerCubes = widget.playerInventory.getResourceQuantity(ResourceType.energyCube);

    return Column(
      children: [
        // Title
        Container(
          padding: EdgeInsets.all(8),
          child: Text(
            isFullyCharged 
                ? 'READY FOR LAUNCH!'
                : 'Charge the spaceship to escape',
            style: TextStyle(
              color: isFullyCharged ? Colors.greenAccent : Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        
        SizedBox(height: 10),
        
        // ✓ UPDATED: Two charging sections side by side
        Row(
          children: [
            // Energy Cubes Section
            Expanded(
              child: _buildCubeChargingSection(
                cubesLoaded, 
                cubesNeeded, 
                cubesReady,
                spaceship.cubeProgress,
              ),
            ),
            
            SizedBox(width: 10),
            
            // Energy Section
            Expanded(
              child: _buildEnergyChargingSection(
                energyStored,
                energyNeeded,
                energyReady,
                spaceship.energyProgress,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 15),
        
        // Loading Section for Energy Cubes (if not ready)
        if (!cubesReady)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      getResourceIcon(ResourceType.energyCube),
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Load Energy Cubes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'In inventory: $playerCubes',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Still needed: ${cubesNeeded - cubesLoaded}',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Load buttons
                Column(
                  children: [
                    SizedBox(
                      width: 70,
                      child: _buildSmallButton(
                        'Load',
                        Icons.add,
                        Colors.blue,
                        playerCubes > 0,
                        () => _loadCubeToSpaceship(1, spaceship),
                      ),
                    ),
                    SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: _buildSmallButton(
                        'All',
                        Icons.add_circle,
                        Colors.blue.shade700,
                        playerCubes > 0,
                        () => _loadCubeToSpaceship(playerCubes, spaceship),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        
        SizedBox(height: 10),
        
        // Energy charging info
        if (!energyReady)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orangeAccent, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy Charging',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Connect Energy Linker to charge',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Still needed: ${(energyNeeded - energyStored).toStringAsFixed(0)} NE',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        // Spacer to push launch button to bottom
        if (isFullyCharged)
          SizedBox(height: 20),
        
        // Launch Button (if fully charged)
        if (isFullyCharged) ...[
          SizedBox(height: 15),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _launchSpaceship(spaceship),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.greenAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'LAUNCH SPACESHIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build Energy Cube charging section
  Widget _buildCubeChargingSection(int loaded, int needed, bool isReady, double progress) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? Colors.greenAccent : Colors.blueAccent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.battery_charging_full,
            size: 36,
            color: isReady ? Colors.greenAccent : Colors.blueAccent,
          ),
          SizedBox(height: 8),
          Text(
            '$loaded / $needed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Energy Cubes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(
                isReady ? Colors.greenAccent : Colors.blueAccent,
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: isReady ? Colors.greenAccent : Colors.blueAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build energy charging section
  Widget _buildEnergyChargingSection(double stored, double needed, bool isReady, double progress) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? Colors.greenAccent : Colors.orangeAccent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flash_on,
            size: 36,
            color: isReady ? Colors.greenAccent : Colors.orangeAccent,
          ),
          SizedBox(height: 8),
          Text(
            '${stored.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '/ ${needed.toStringAsFixed(0)} NE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(
                isReady ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: isReady ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Load Energy Cubes to spaceship
  void _loadCubeToSpaceship(int amount, SpaceshipMachine spaceship) {
    final remaining = SpaceshipMachine.requiredCubes - spaceship.energyCubesLoaded;
    final toLoad = amount.clamp(0, remaining);
    
    if (widget.playerInventory.hasResource(ResourceType.energyCube, toLoad)) {
      if (spaceship.addToInput(ResourceType.energyCube, toLoad)) {
        widget.playerInventory.removeResource(ResourceType.energyCube, toLoad);
        setState(() {});
      }
    }
  }

  /// Launch spaceship
  void _launchSpaceship(SpaceshipMachine spaceship) {
    spaceship.launch();
    widget.onClose();
    
    // Show victory dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.greenAccent, width: 3),
          ),
          title: Column(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 60),
              SizedBox(height: 10),
              Text(
                'VICTORY!',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'You successfully escaped The Angry Planet!\n\nThanks for playing!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Return to main menu or restart
              },
              child: Text(
                'Continue',
                style: TextStyle(color: Colors.greenAccent, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinkerConnectionUI() {
    // Get all machines in world except this linker
    final allMachines = widget.machineRegistry
      .getAllMachines()
      .where((m) => m != widget.machine)
      .toList();

    print('🔍 Found ${allMachines.length} machines for linker connection');

    return LinkerConnectionUI(
      linker: widget.machine,
      availableMachines: allMachines,
      onSetSource: (machine) {
        setState(() {
          if (widget.machine is EnergyLinkerMachine) {
            (widget.machine as EnergyLinkerMachine).setSource(machine);
          } else if (widget.machine is ItemLinkerMachine) {
            (widget.machine as ItemLinkerMachine).setSource(machine);
          }
        });
      },
      onSetTarget: (machine, slot) {
        setState(() {
          if (widget.machine is EnergyLinkerMachine) {
            (widget.machine as EnergyLinkerMachine).setTarget(machine, slot);
          } else if (widget.machine is ItemLinkerMachine) {
            (widget.machine as ItemLinkerMachine).setTarget(machine, slot);
          }
        });
      },
    );
  }

  Widget _buildHolderStorage() {
    final holder = widget.machine as HolderMachine;
    
    // Combine machine storage + player items
    final Map<ResourceType, _StorageItemData> items = {};

    // Add items in holder
    for (final stack in holder.inputStorage.getAllStacks()) {
      if (stack.isResource) {
        items[stack.asResource!] = _StorageItemData(
          resource: stack.asResource!,
          inStorage: stack.quantity,
          inPlayer: 0,
        );
      }
    }

    // Add/update with player items
    for (final stack in widget.playerInventory.getAllStacks()) {
      if (stack.isResource) {
        final resource = stack.asResource!;
        if (items.containsKey(resource)) {
          items[resource]!.inPlayer = stack.quantity;
        } else {
          items[resource] = _StorageItemData(
            resource: resource,
            inStorage: 0,
            inPlayer: stack.quantity,
          );
        }
      }
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with capacity
          Row(
            children: [
              Icon(Icons.inventory, color: Colors.blue, size: 24),
              SizedBox(width: 10),
              Text(
                'Storage',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Text(
                  '${holder.totalItemsStored} / ${holder.stats.storageCapacity}',
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10),
          
          // Capacity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: holder.storageUsage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(
                holder.storageUsage > 80 ? Colors.red : Colors.blue,
              ),
            ),
          ),
          
          SizedBox(height: 15),
          
          // Item list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, color: Colors.white38, size: 48),
                        SizedBox(height: 10),
                        Text(
                          'Empty storage',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Add items from your inventory',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final data = items.values.elementAt(index);
                      return _buildHolderStorageItem(data, holder);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolderStorageItem(_StorageItemData data, HolderMachine holder) {
    final canAddMore = holder.totalItemsStored < holder.stats.storageCapacity;
    final spaceAvailable = holder.stats.storageCapacity - holder.totalItemsStored;
    final isPowered = holder.isPowered;
    
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF4D4030),
        borderRadius: BorderRadius.circular(10),
        border: data.inStorage > 0
            ? Border.all(color: Colors.blue.shade300, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Resource icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getResourceIcon(data.resource),
              color: Colors.white,
              size: 28,
            ),
          ),
          
          SizedBox(width: 12),
          
          // Resource info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.resource.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    // In storage badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory, size: 12, color: Colors.blue.shade200),
                          SizedBox(width: 4),
                          Text(
                            '${data.inStorage}',
                            style: TextStyle(
                              color: Colors.blue.shade200,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // In player badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.green.shade200),
                          SizedBox(width: 4),
                          Text(
                            '${data.inPlayer}',
                            style: TextStyle(
                              color: Colors.green.shade200,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ✓ Updated: Action buttons with "All" options
          Column(
            children: [
              // Add row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add 1 button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (data.inPlayer > 0 && canAddMore && isPowered)
                          ? () => _addToStorage(data.resource, 1, holder)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (data.inPlayer > 0 && canAddMore && isPowered)
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isPowered ? Icons.add : Icons.power_off, color: Colors.white, size: 16),
                            SizedBox(width: 3),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 4),
                  
                  // Add All button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (data.inPlayer > 0 && canAddMore && isPowered)
                          ? () {
                              final amountToAdd = data.inPlayer.clamp(0, spaceAvailable);
                              _addToStorage(data.resource, amountToAdd, holder);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: (data.inPlayer > 0 && canAddMore && isPowered)
                              ? Colors.green.shade600
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (data.inPlayer > 0 && canAddMore && isPowered)
                                ? Colors.green.shade300
                                : Colors.grey.shade600,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 5),
              
              // Take row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Take 1 button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (data.inStorage > 0 && isPowered)
                          ? () => _takeFromStorage(data.resource, 1, holder)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (data.inStorage > 0 && isPowered)
                              ? Colors.orange.shade700
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isPowered ? Icons.remove : Icons.power_off, color: Colors.white, size: 16),
                            SizedBox(width: 3),
                            Text(
                              'Take',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 4),
                  
                  // Take All button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (data.inStorage > 0 && isPowered)
                          ? () => _takeFromStorage(data.resource, data.inStorage, holder)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: (data.inStorage > 0 && isPowered)
                              ? Colors.orange.shade600
                              : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (data.inStorage > 0 && isPowered)
                                ? Colors.orange.shade300
                                : Colors.grey.shade600,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'All',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmelterRecipeUI() {
    final smelter = widget.machine as SmelterMachine;
    final availableRecipes = getRecipesForMachine(MachineType.smelter);

    return Column(
      children: [
        // Processing status banner
        _buildSmelterProcessingBanner(smelter),
        
        SizedBox(height: 15),
        
        // Recipe selection
        _buildRecipeSelector(smelter, availableRecipes),
        
        SizedBox(height: 15),
        
        // Selected recipe details with inputs/outputs
        Expanded(
          child: _buildRecipeDetails(smelter),
        ),
      ],
    );
  }

  /// Build processing status banner
  Widget _buildSmelterProcessingBanner(SmelterMachine smelter) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: smelter.isProcessing 
            ? Colors.deepOrange.shade900 
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                smelter.isProcessing ? Icons.factory : Icons.hourglass_empty,
                color: smelter.isProcessing ? Colors.orange : Colors.grey,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  smelter.isProcessing 
                      ? 'Processing: ${smelter.currentRecipe!.output.displayName}'
                      : 'Idle - Select a recipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (smelter.isProcessing) ...[
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: smelter.progress,
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
            ),
            SizedBox(height: 5),
            Text(
              '${(smelter.progress * 100).toStringAsFixed(0)}% - ${(smelter.currentRecipe!.processingTime - smelter.processingProgress).toStringAsFixed(0)}s remaining',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// Build recipe selector
  Widget _buildRecipeSelector(SmelterMachine smelter, List<Recipe> recipes) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Available Recipes',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // Undo/Clear button
              if (smelter.selectedRecipe != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _clearRecipe(smelter),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          // Recipe buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipes.map((recipe) {
              final isSelected = smelter.selectedRecipe?.id == recipe.id;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectRecipe(smelter, recipe),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.orange.shade700 
                          : Color(0xFF4D4030),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.orange.shade300 
                            : Colors.grey.shade600,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getResourceIcon(recipe.output),
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          recipe.output.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Select recipe with validation
  void _selectRecipe(SmelterMachine smelter, Recipe recipe) {
    // If same recipe, do nothing
    if (smelter.selectedRecipe?.id == recipe.id) return;

    // If changing recipes, need to return current inputs to player
    if (smelter.selectedRecipe != null) {
      final currentInputs = smelter.getAllInputItems();
      
      if (currentInputs.isNotEmpty) {
        // Check if player inventory has space
        if (!_canReturnItemsToPlayer(currentInputs)) {
          _showInventoryFullDialog();
          return;
        }
        
        // Return items to player
        final returned = smelter.clearAllInputs();
        for (final entry in returned.entries) {
          widget.playerInventory.addResource(entry.key, entry.value);
        }
        
        print('⚗️ Returned items to player: ${returned.entries.map((e) => "${e.value} ${e.key.displayName}").join(", ")}');
      }
    }

    // Select new recipe
    setState(() {
      smelter.selectedRecipe = recipe;
      print('🏭 Selected recipe: ${recipe.output.displayName}');
    });
  }

  /// ✓ NEW: Clear/undo recipe
  void _clearRecipe(SmelterMachine smelter) {
    final currentInputs = smelter.getAllInputItems();
    
    if (currentInputs.isNotEmpty) {
      // Check if player inventory has space
      if (!_canReturnItemsToPlayer(currentInputs)) {
        _showInventoryFullDialog();
        return;
      }
      
      // Return items to player
      final returned = smelter.clearAllInputs();
      for (final entry in returned.entries) {
        widget.playerInventory.addResource(entry.key, entry.value);
      }
      
      print('⚗️ Returned items to player: ${returned.entries.map((e) => "${e.value} ${e.key.displayName}").join(", ")}');
    }

    setState(() {
      smelter.selectedRecipe = null;
      print('🏭 Cleared recipe selection');
    });
  }

  /// ✓ NEW: Check if player can hold all items being returned
  bool _canReturnItemsToPlayer(Map<ResourceType, int> items) {
    for (final entry in items.entries) {
      if (!widget.playerInventory.canAddResource(entry.key, entry.value)) {
        return false;
      }
    }
    return true;
  }

  /// ✓ NEW: Show dialog when inventory is full
  void _showInventoryFullDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2C2416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.red, width: 3),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Inventory Full',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            'Your inventory doesn\'t have enough space to take back the items.\n\nFree up space before changing recipes.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.orange, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build recipe details with inputs and outputs
  Widget _buildRecipeDetails(SmelterMachine smelter) {
    if (smelter.selectedRecipe == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: Colors.white38, size: 48),
            SizedBox(height: 10),
            Text(
              'Select a recipe above',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final recipe = smelter.selectedRecipe!;

    return Row(
      children: [
        // Inputs section
        Expanded(
          child: _buildSmelterInputsSection(smelter, recipe),
        ),
        
        SizedBox(width: 10),
        
        // Arrow indicator
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward, color: Colors.orange, size: 32),
            SizedBox(height: 5),
            Text(
              '${recipe.processingTime.toStringAsFixed(0)}s',
              style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
            ),
          ],
        ),
        
        SizedBox(width: 10),
        
        // Output section
        Expanded(
          child: _buildSmelterOutputSection(smelter, recipe),
        ),
      ],
    );
  }

  /// Build inputs section for selected recipe
  Widget _buildSmelterInputsSection(SmelterMachine smelter, Recipe recipe) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.input, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Inputs Required',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          
          Expanded(
            child: SingleChildScrollView(  // ✓ ADD THIS
              child: Column(
                children: recipe.inputs.map((input) {
                  return _buildSmelterInputItem(smelter, input);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build single input item
  Widget _buildSmelterInputItem(SmelterMachine smelter, RecipeInput input) {
    final inMachine = smelter.inputStorage.getResourceQuantity(input.resource);
    final inPlayer = widget.playerInventory.getResourceQuantity(input.resource);
    final hasEnough = inMachine >= input.amount;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF4D4030),
        borderRadius: BorderRadius.circular(8),
        border: hasEnough 
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                getResourceIcon(input.resource),
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      input.resource.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        // In machine
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasEnough 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$inMachine / ${input.amount}',
                            style: TextStyle(
                              color: hasEnough ? Colors.green.shade200 : Colors.red.shade200,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        // In player
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '👤 $inPlayer',
                            style: TextStyle(
                              color: Colors.blue.shade200,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Add buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Take buttons
              Row(
                children: [
                  // Take 1
                  _buildSmallButton(
                    'Take',
                    Icons.remove,
                    Colors.orange,
                    inMachine > 0,
                    () => _takeFromInput(input.resource, 1, smelter),
                  ),
                  SizedBox(width: 6),
                  // Take All
                  _buildSmallButton(
                    'All',
                    Icons.download,
                    Colors.orange.shade600,
                    inMachine > 0,
                    () => _takeFromInput(input.resource, inMachine, smelter),
                  ),
                ],
              ),
              
              // Add buttons
              Row(
                children: [
                  // Add 1
                  _buildSmallButton(
                    'Add',
                    Icons.add,
                    Colors.green,
                    inPlayer > 0,
                    () => _addToInput(input.resource, 1),
                  ),
                  SizedBox(width: 6),
                  // Add All (smart - only adds what's needed)
                  _buildSmallButton(
                    'All',
                    Icons.add_circle,
                    Colors.green.shade600,
                    inPlayer > 0,
                    () {
                      final needed = input.amount - inMachine;
                      final toAdd = needed.clamp(0, inPlayer);
                      if (toAdd > 0) _addToInput(input.resource, toAdd);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Take items from input back to player
  void _takeFromInput(ResourceType resource, int amount, SmelterMachine smelter) {
    if (!_tryBeginAction()) return;

    // Check if player has space
    if (!widget.playerInventory.canAddResource(resource, amount)) {
      final available = widget.playerInventory.getAvailableSpace(resource);
      if (available > 0) {
        // Take partial amount
        amount = available;
      } else {
        print("❌ Player inventory full for ${resource.displayName}");
        _showInventoryFullDialog();
        return;
      }
    }

    // Remove from smelter
    if (smelter.inputStorage.removeResource(resource, amount)) {
      // Add to player
      widget.playerInventory.addResource(resource, amount);
      setState(() {});
      print("⬇️ Took $amount ${resource.displayName} from smelter input");
    }
  }

  /// Build outputs section
  Widget _buildSmelterOutputSection(SmelterMachine smelter, Recipe recipe) {
    final inOutput = smelter.outputStorage.getResourceQuantity(recipe.output);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.output, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Output',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (inOutput > 0) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4D4030),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              getResourceIcon(recipe.output),
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.output.displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '×$inOutput',
                                  style: TextStyle(
                                    color: Colors.green.shade300,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Take 1
                            _buildSmallButton(
                              'Take',
                              Icons.remove,
                              Colors.orange,
                              true,
                              () => _takeFromOutput(recipe.output, 1),
                            ),
                            SizedBox(width: 8),
                            // Take All
                            _buildSmallButton(
                              'All',
                              Icons.download,
                              Colors.orange.shade600,
                              true,
                              () => _takeFromOutput(recipe.output, inOutput),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(Icons.inbox, color: Colors.white38, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'Empty',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Add inputs to start',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Build small action button
  Widget _buildSmallButton(
    String label,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onPressed,
  ) {
    final canTap = enabled && !_isCoolingDown;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: canTap ? color : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToStorage(ResourceType resource, int amount, HolderMachine holder) {
    // Check storage capacity
    if (holder.totalItemsStored >= holder.stats.storageCapacity) {
      print("❌ Storage full");
      return;
    }

    if (!_tryBeginAction()) return;

    if (widget.playerInventory.hasResource(resource, amount)) {
      if (widget.onAddToInput(resource, amount)) {
        setState(() {});
        print("➕ Added $amount ${resource.displayName} to storage");
      } else {
        print("❌ Storage full");
      }
    } else {
      print("❌ Not enough ${resource.displayName} in player inventory");
    }
  }

  void _takeFromStorage(ResourceType resource, int amount, HolderMachine holder) {
    if (!_tryBeginAction()) return;

    if (widget.onTakeFromOutput(resource, amount)) {
      setState(() {});
      print("⬇️ Took $amount ${resource.displayName} from storage");
    } else {
      print("❌ Player inventory full");
    }
  }

  Widget _buildBurnerInfo(BurnerMachine burner) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: burner.isBurning ? Colors.orange.shade900 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                burner.isBurning ? Icons.local_fire_department : Icons.fireplace,
                color: burner.isBurning ? Colors.orange : Colors.grey,
              ),
              SizedBox(width: 10),
              Text(
              burner.isBurning 
                  ? 'Burning ${burner.currentFuel?.displayName ?? "Fuel"}'  // ✓ Show fuel type
                  : 'Idle',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            ],
          ),
          if (burner.isBurning) ...[
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: burner.burnProgress,
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(
                burner.currentFuel == ResourceType.wood  // ✓ Color based on fuel
                    ? Colors.brown.shade400
                    : Colors.orange,
              )
            ),
            SizedBox(height: 5),
            Text(
              '${burner.burnTimeRemaining.toStringAsFixed(0)}s remaining',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiggerInfo(DiggerMachine digger) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(getResourceIcon(digger.resourceNode), color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Extracting ${digger.resourceNode.displayName}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: digger.progress,
            backgroundColor: Colors.grey.shade700,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 5),
          Text(
            '${(digger.progress * 100).toStringAsFixed(0)}% complete',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChopperInfo(ChopperMachine chopper) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.park, color: Colors.green.shade300),
              SizedBox(width: 10),
              Text(
                'Harvesting Wood',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: chopper.progress,
            backgroundColor: Colors.grey.shade700,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 5),
          Text(
            '${(chopper.progress * 100).toStringAsFixed(0)}% complete',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSmelterInfo(SmelterMachine smelter) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: smelter.isProcessing ? Colors.deepOrange.shade900 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                smelter.isProcessing ? Icons.factory : Icons.hourglass_empty,
                color: smelter.isProcessing ? Colors.orange : Colors.grey,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      smelter.isProcessing 
                          ? 'Processing'
                          : 'Idle',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (smelter.isProcessing && smelter.currentRecipe != null) ...[
                      SizedBox(height: 4),
                      // ✓ Show all inputs
                      Text(
                        smelter.currentRecipe!.inputSummary,
                        style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
                      ),
                      Text(
                        '→ ${smelter.currentRecipe!.outputAmount} ${smelter.currentRecipe!.output.displayName}',
                        style: TextStyle(color: Colors.green.shade300, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (smelter.isProcessing) ...[
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: smelter.progress,
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            SizedBox(height: 5),
            Text(
              '${(smelter.progress * 100).toStringAsFixed(0)}% complete (${smelter.currentRecipe!.processingTime.toStringAsFixed(0)}s)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHolderInfo(HolderMachine holder) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory, color: Colors.blue.shade300),
          SizedBox(width: 10),
          Text(
            'Storage: ${holder.totalItemsStored} / ${holder.stats.storageCapacity}',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Spacer(),
          Text(
            '${holder.storageUsage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorage() {
    if (widget.machine is EnergyLinkerMachine || 
        widget.machine is ItemLinkerMachine) {
      return SizedBox.shrink();
    }
    
    return Row(
      children: [
        // Input storage
        Expanded(
          child: _buildStorageSection(
            'Input',
            widget.machine.inputStorage,
            true,
            Colors.blue,
          ),
        ),
        SizedBox(width: 10),
        // Output storage
        Expanded(
          child: _buildStorageSection(
            'Output',
            widget.machine.outputStorage,
            false,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSection(
    String title,
    Inventory storage,
    bool isInput,
    Color color,
  ) {
    final stacks = storage.getAllStacks();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D3020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: isInput
                ? _buildInputList()  // ✓ Special handling for input
                : _buildOutputList(stacks),  // Output shows machine storage only
          ),
        ],
      ),
    );
  }

  /// Build input list - shows what's in machine + what player can add
  Widget _buildInputList() {
    // Check if this machine needs input
    if (!MachineConfig.needsInput(widget.machine.machineType)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.not_interested, color: Colors.white38, size: 40),
            SizedBox(height: 10),
            Text(
              'No input needed',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // Get accepted inputs for this machine
    final acceptedInputs = MachineConfig.getAcceptedInputs(widget.machine.machineType);
    
    // Get what's currently in machine
    final machineStacks = widget.machine.inputStorage.getAllStacks();
    
    // Get what player has that this machine accepts
    final playerStacks = widget.playerInventory.getAllStacks()
        .where((stack) => stack.isResource)
        .where((stack) {
          // If machine accepts anything, show all
          if (acceptedInputs == null) return true;
          // Otherwise filter by accepted inputs
          return acceptedInputs.contains(stack.asResource);
        })
        .toList();

    // Combine and deduplicate
    final Map<ResourceType, _InputItemData> items = {};

    // Add machine items
    for (final stack in machineStacks) {
      if (stack.isResource) {
        items[stack.asResource!] = _InputItemData(
          resource: stack.asResource!,
          inMachine: stack.quantity,
          inPlayer: 0,
        );
      }
    }

    // Add/update with player items
    for (final stack in playerStacks) {
      if (stack.isResource) {
        final resource = stack.asResource!;
        if (items.containsKey(resource)) {
          items[resource]!.inPlayer = stack.quantity;
        } else {
          items[resource] = _InputItemData(
            resource: resource,
            inMachine: 0,
            inPlayer: stack.quantity,
          );
        }
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: Colors.white38, size: 40),
            SizedBox(height: 10),
            Text(
              'No items available',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items.values.elementAt(index);
        return _buildInputItem(data);
      },
    );
  }

  /// Build output list - shows what's in machine output
Widget _buildOutputList(List stacks) {
  if (stacks.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.white38, size: 40),
          SizedBox(height: 10),
          Text(
            'Empty',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    itemCount: stacks.length,
    itemBuilder: (context, index) {
      final stack = stacks[index];
      return _buildOutputItem(stack);
    },
  );
}

  /// Build input item showing machine + player quantities
  Widget _buildInputItem(_InputItemData data) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF4D4030),
        borderRadius: BorderRadius.circular(8),
        border: data.inMachine > 0
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            getResourceIcon(data.resource),
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.resource.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    // Machine quantity
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'In: ${data.inMachine}',
                        style: TextStyle(
                          color: Colors.blue.shade200,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    // Player quantity
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'You: ${data.inPlayer}',
                        style: TextStyle(
                          color: Colors.green.shade200,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Add button (only if player has items)
          if (data.inPlayer > 0)
            Column(
              children: [
                // Add 1
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.green, size: 28),
                  onPressed: () => _addToInput(data.resource, 1),
                  tooltip: 'Add 1',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(height: 4),
                // Add all
                if (data.inPlayer > 1)
                  InkWell(
                    onTap: () => _addToInput(data.resource, data.inPlayer),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Icon(Icons.block, color: Colors.grey, size: 24),
        ],
      ),
    );
  }

  /// Build output item
  Widget _buildOutputItem(ItemStack stack) {
    if (!stack.isResource) return SizedBox.shrink();
    
    final resource = stack.asResource!;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF4D4030),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            getResourceIcon(resource),
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '×${stack.quantity}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Take buttons
          Column(
            children: [
              // Take 1
              IconButton(
                icon: Icon(Icons.get_app, color: Colors.orange, size: 28),
                onPressed: () => _takeFromOutput(resource, 1),
                tooltip: 'Take 1',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              SizedBox(height: 4),
              // Take all
              if (stack.quantity > 1)
                InkWell(
                  onTap: () => _takeFromOutput(resource, stack.quantity),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _addToInput(ResourceType resource, int amount) {
    if (!_tryBeginAction()) return;

    // Add items from player inventory to machine input
    if (widget.playerInventory.hasResource(resource, amount)) {
      if (widget.onAddToInput(resource, amount)) {
        setState(() {});
        print("➕ Added $amount ${resource.displayName} to machine input");
      } else {
        print("❌ Machine input full");
      }
    } else {
      print("❌ Not enough ${resource.displayName} in player inventory");
    }
  }

  void _takeFromOutput(ResourceType resource, int amount) {
    if (!_tryBeginAction()) return;

    // Take items from machine output to player inventory
    if (widget.onTakeFromOutput(resource, amount)) {
      setState(() {});
      print("⬇️ Took $amount ${resource.displayName} from machine output");
    } else {
      print("❌ Player inventory full or not enough items");
    }
  }

  Widget _buildCloseButton() {
    return ElevatedButton(
      onPressed: widget.onClose,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Close',
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}