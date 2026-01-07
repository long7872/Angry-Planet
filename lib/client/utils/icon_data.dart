import 'package:flutter/material.dart';
import '../../shared/machines/machine_type.dart';
import '../../shared/resources/resource_type.dart';

IconData getMachineIcon(MachineType type) {
  switch (type) {
    case MachineType.burner:
      return Icons.fireplace;
    case MachineType.digger:
      return Icons.construction;
    case MachineType.chopper:
      return Icons.forest;
    case MachineType.smelter:
      return Icons.factory;
    case MachineType.holder:
      return Icons.inventory;
    case MachineType.greener:
      return Icons.eco;
    case MachineType.energyLinker:
      return Icons.power;
    case MachineType.itemLinker:
      return Icons.move_down;
    case MachineType.spaceship:
      return Icons.rocket;
  }
}

  IconData getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.wood:
        return Icons.park;
      case ResourceType.coal:
        return Icons.circle;
      case ResourceType.iron:
        return Icons.square;
      case ResourceType.energyCatalyst:
        return Icons.bolt;
      case ResourceType.ironBar:
        return Icons.rectangle;
      case ResourceType.energyCube:
        return Icons.battery_full;
      default:
        return Icons.help;
    }
  }

// Get color for each machine type
  Color getMachineColor(MachineType type) {
    switch (type) {
      case MachineType.burner:
        return Colors.orange;
      case MachineType.digger:
        return Colors.brown;
      case MachineType.chopper:
        return Colors.green;
      case MachineType.smelter:
        return Colors.red;
      case MachineType.holder:
        return Colors.blue;
      case MachineType.greener:
        return Colors.lightGreen;
      case MachineType.energyLinker:
        return Colors.yellow;
      case MachineType.itemLinker:
        return Colors.cyan;
      case MachineType.spaceship:
        return Colors.purple;
    }
  }