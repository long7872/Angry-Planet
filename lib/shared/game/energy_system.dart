import '../../client/components/machines/base_machine.dart';

/// Energy system - tracks and manages Nuclear Energy (NE)
class EnergyNetwork {
  final Map<String, EnergyNode> _nodes = {};
  
  /// Register an energy node (machine)
  void registerNode(String nodeId, EnergyNode node) {
    _nodes[nodeId] = node;
  }

  /// Unregister node
  void unregisterNode(String nodeId) {
    _nodes.remove(nodeId);
  }

  /// Update all nodes (called every tick)
  void tick() {
    // Calculate network stats for UI/debugging
    final stats = getStats();
    
    print('⚡ Energy Network: ${stats.production.toStringAsFixed(1)} NE/s production, ${stats.consumption.toStringAsFixed(1)} NE/s consumption, Net: ${stats.net.toStringAsFixed(1)} NE/s');
    // Note: Machines now handle their own energy consumption from buffers
    // Network just provides statistics


    // // Calculate total production and consumption
    // double totalProduction = 0;
    // double totalConsumption = 0;

    // for (final node in _nodes.values) {
    //   if (node.isProducing) {
    //     totalProduction += node.energyProduction;
    //   }
    //   if (node.isConsuming) {
    //     totalConsumption += node.energyConsumption;
    //   }
    // }

    // final netEnergy = totalProduction - totalConsumption;
    
    // // Distribute energy to consumers
    // if (netEnergy >= 0) {
    //   // Sufficient energy - all machines work
    //   for (final node in _nodes.values) {
    //     node.isPowered = true;
    //   }
    // } else {
    //   // Insufficient energy - prioritize by type
    //   _distributeLimitedEnergy(totalProduction);
    // }
  }

  // void _distributeLimitedEnergy(double availableEnergy) {
  //   // Priority system: generators > processors > storage > linkers
  //   final priorityOrder = _nodes.values.toList()
  //     ..sort((a, b) => a.priority.compareTo(b.priority));

  //   double remaining = availableEnergy;
    
  //   for (final node in priorityOrder) {
  //     if (remaining >= node.energyConsumption) {
  //       node.isPowered = true;
  //       remaining -= node.energyConsumption;
  //     } else {
  //       node.isPowered = false;
  //     }
  //   }
  // }

  /// Get network statistics
  EnergyStats getStats() {
    double production = 0;
    double consumption = 0;
    int activeNodes = 0;

    for (final node in _nodes.values) {
      // if (node.isProducing) production += node.energyProduction;
      // if (node.isConsuming && node.isPowered) consumption += node.energyConsumption;
      // if (node.isPowered) activeNodes++;
      // Count as active if consuming or producing
      production += node.energyProduction;
      consumption += node.energyConsumption;
      // if (node.energyProduction > 0 || node.energyConsumption > 0) {
      //   activeNodes++;
      // }
      if (node.isPowered) activeNodes++;
    }

    return EnergyStats(
      production: production,
      consumption: consumption,
      net: production - consumption,
      activeNodes: activeNodes,
      totalNodes: _nodes.length,
    );
  }

  void clear() {
    _nodes.clear();
  }
}

/// Energy node (represents a machine in the network)
class EnergyNode {
  final String id;
  final BaseMachine machine;
  final int priority;              // Lower = higher priority

  // bool isPowered = true;  // Is this node currently receiving power?

  EnergyNode({
    required this.id,
    required this.machine,
    this.priority = 50,
  });

  /// ✓ NEW: Dynamic getter - reads machine's actual power state
  bool get isPowered => machine.isPowered;

  /// Dynamic getter - calls machine's current production
  double get energyProduction => machine.getCurrentEnergyProduction();

  /// Dynamic getter - calls machine's current consumption
  double get energyConsumption => machine.getCurrentEnergyConsumption();

  /// Dynamic getter - calls machine's current pollution
  double get pollutionRate => machine.getCurrentPollutionRate();

  bool get isProducing => energyProduction > 0;
  bool get isConsuming => energyConsumption > 0;
  bool get needsEnergy => isConsuming && !isProducing;
}

/// Energy statistics
class EnergyStats {
  final double production;
  final double consumption;
  final double net;
  final int activeNodes;
  final int totalNodes;

  EnergyStats({
    required this.production,
    required this.consumption,
    required this.net,
    required this.activeNodes,
    required this.totalNodes,
  });

  bool get isSufficient => net >= 0;
  double get efficiency => consumption > 0 ? (production / consumption) : 1.0;
}