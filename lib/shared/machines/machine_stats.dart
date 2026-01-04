import '../resources/resource_type.dart';
import 'machine_type.dart';
import 'build_cost.dart';

/// Stats for a specific machine type
class MachineStats {
  final MachineType type;
  final String description;
  final double energyConsumption;  // NE per second (0 = generator)
  final double energyProduction;    // NE per second (0 = consumer)
  final double pollutionRate;       // Pollution per second (+/-)
  final int storageCapacity;        // Max items in storage
  final double energyBuffer;       // Energy buffer capacity in NE
  final List<ResourceType> validPlacements; // Where can be placed
  final BuildCost buildCost;
  
  const MachineStats({
    required this.type,
    this.description = "",
    this.energyConsumption = 0,
    this.energyProduction = 0,
    this.pollutionRate = 0,
    this.storageCapacity = 0,
    this.energyBuffer = 0,
    this.validPlacements = const [ResourceType.none],
    required this.buildCost,
  });

  bool get isGenerator => energyProduction > 0;
  bool get isConsumer => energyConsumption > 0;
  bool get isPolluter => pollutionRate > 0;
  bool get isCleaner => pollutionRate < 0;
}

/// Complete machine definitions
const Map<MachineType, MachineStats> machineDefinitions = {
  MachineType.burner: MachineStats(
    type: MachineType.burner,
    description: 'Generates energy from coal or wood',
    energyConsumption: 0,
    energyProduction: 20,  // 20 NE/s when burning
    pollutionRate: 5,      // +5 P/s when burning
    storageCapacity: 20,
    energyBuffer: 500,     // ✓ 500 NE buffer
    validPlacements: [
      ResourceType.none
    ],
    buildCost: BuildCost(wood: 10, ironBar: 15, energyCube: 3),
  ),

  MachineType.digger: MachineStats(
    type: MachineType.digger,
    description: 'Extracts ore from resource nodes',
    energyConsumption: 10,
    energyProduction: 0,
    pollutionRate: 3,
    storageCapacity: 10,
    energyBuffer: 100,
    validPlacements: [
      ResourceType.coal,
      ResourceType.iron,
      ResourceType.energyCatalyst,
    ],
    buildCost: BuildCost(ironBar: 20, energyCube: 5),
  ),

  MachineType.chopper: MachineStats(
    type: MachineType.chopper,
    description: 'Harvests wood from forests',
    energyConsumption: 10,
    energyProduction: 0,
    pollutionRate: 3,
    storageCapacity: 10,
    energyBuffer: 100,
    validPlacements: [ResourceType.wood], // Forest tiles
    buildCost: BuildCost(wood: 10, ironBar: 8),
  ),

  MachineType.smelter: MachineStats(
    type: MachineType.smelter,
    description: 'Processes ore into refined materials',
    energyConsumption: 5,
    energyProduction: 0,
    pollutionRate: 5,
    storageCapacity: 20,
    energyBuffer: 100,
    validPlacements: [ResourceType.none],
    buildCost: BuildCost(wood: 10, ironBar: 20),
  ),

  MachineType.holder: MachineStats(
    type: MachineType.holder,
    description: 'Stores items',
    energyConsumption: 1,
    energyProduction: 0,
    pollutionRate: 0,
    storageCapacity: 100,
    energyBuffer: 1000,
    validPlacements: [ResourceType.none],
    buildCost: BuildCost(wood: 20, ironBar: 5),
  ),

  MachineType.greener: MachineStats(
    type: MachineType.greener,
    description: 'Reduces pollution',
    energyConsumption: 30,
    energyProduction: 0,
    pollutionRate: -10,
    storageCapacity: 0,
    energyBuffer: 100,
    validPlacements: [ResourceType.none],
    buildCost: BuildCost(wood: 30, ironBar: 20, energyCube: 10),
  ),

  MachineType.energyLinker: MachineStats(
    type: MachineType.energyLinker,
    description: 'Transfers energy between machines',
    energyConsumption: 5,
    energyProduction: 0,
    pollutionRate: 2,
    storageCapacity: 0,
    energyBuffer: 50,
    validPlacements: [ResourceType.none],
    buildCost: BuildCost(ironBar: 5, energyCube: 2),
  ),

  MachineType.itemLinker: MachineStats(
    type: MachineType.itemLinker,
    description: 'Transfers items between machines',
    energyConsumption: 5,
    energyProduction: 0,
    pollutionRate: 2,
    storageCapacity: 0,
    energyBuffer: 50,
    validPlacements: [ResourceType.none],
    buildCost: BuildCost(wood: 5, ironBar: 5),
  ),
};

MachineStats getMachineStats(MachineType type) {
  return machineDefinitions[type]!;
}