/// Machine types in the game
enum MachineType {
  burner,         // Energy generator (coal → NE)
  digger,         // Resource extractor (ore nodes)
  chopper,        // Wood harvester (forest tiles)
  smelter,        // Processor (ore → bars, catalyst → cubes)
  holder,         // Storage container
  greener,        // Pollution reducer
  energyLinker,  // Energy transfer network
  itemLinker,    // Item transfer network
  spaceship,  // End-game victory machine
}

extension MachineTypeExtension on MachineType {
  String get displayName {
    switch (this) {
      case MachineType.burner:
        return 'Burner';
      case MachineType.digger:
        return 'Digger';
      case MachineType.chopper:
        return 'Chopper';
      case MachineType.smelter:
        return 'Smelter';
      case MachineType.holder:
        return 'Holder';
      case MachineType.greener:
        return 'Greener';
      case MachineType.energyLinker:
        return 'Energy Linker';
      case MachineType.itemLinker:
        return 'Item Linker';
      case MachineType.spaceship:
        return 'Spaceship';
    }
  }
  
  String get description {
    switch (this) {
      case MachineType.burner:
        return 'Generates energy from coal or wood';
      case MachineType.digger:
        return 'Extracts ore from resource nodes';
      case MachineType.chopper:
        return 'Harvests wood from forests';
      case MachineType.smelter:
        return 'Processes ore into refined materials';
      case MachineType.holder:
        return 'Stores items';
      case MachineType.greener:
        return 'Reduces pollution';
      case MachineType.energyLinker:
        return 'Transfers energy between machines';
      case MachineType.itemLinker:
        return 'Transfers items between machines';
      case MachineType.spaceship:
        return 'Your ticket off this angry planet';
    }
  }
  
  bool get isExtractor {
    return this == MachineType.digger || this == MachineType.chopper;
  }
  
  bool get isLinker {
    return this == MachineType.energyLinker || this == MachineType.itemLinker;
  }
}