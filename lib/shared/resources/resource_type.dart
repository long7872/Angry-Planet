/// Resource types in the game
enum ResourceType {
  none,           // Empty tile
  
  // Raw resources (extracted from world)
  wood,           // From chopper on forest tiles
  coal,           // From digger on coal nodes
  iron,       // From digger on iron nodes
  energyCatalyst, // From digger on energy catalyst nodes
  
  // Processed resources (made in machines)
  ironBar,       // Smelted from iron_ore
  energyCube,    // Smelted from energy_catalyst
}

extension ResourceTypeExtension on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.none:
        return 'Empty';
      case ResourceType.wood:
        return 'Wood';
      case ResourceType.coal:
        return 'Coal';
      case ResourceType.iron:
        return 'Iron Ore';
      case ResourceType.energyCatalyst:
        return 'Energy Catalyst';
      case ResourceType.ironBar:
        return 'Iron Bar';
      case ResourceType.energyCube:
        return 'Energy Cube';
    }
  }
  
  bool get isRawResource {
    return this == ResourceType.wood ||
           this == ResourceType.coal ||
           this == ResourceType.iron ||
           this == ResourceType.energyCatalyst;
  }
  
  bool get isProcessedResource {
    return this == ResourceType.ironBar ||
           this == ResourceType.energyCube;
  }
  
  bool get isBuildMaterial {
    return this == ResourceType.wood ||
           this == ResourceType.ironBar ||
           this == ResourceType.energyCube;
  }
}