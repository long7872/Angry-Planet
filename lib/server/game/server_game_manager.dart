class ServerGameManager {
  int tickCount = 0;
  double pollution = 0;
  List<String> activeEvents = [];

  void tick() {
    tickCount++;
    
    // Update pollution (example - adjust based on your logic)
    // In real implementation, this would be calculated from machines
    
    // Check for events (example)
    if (pollution > 4000 && !activeEvents.contains('acid_rain')) {
      // Trigger acid rain
      activeEvents.add('acid_rain');
    }
    
    if (tickCount % 10 == 0) {
      print('⏱️ Server TICK $tickCount | Pollution: ${pollution.toInt()}');
    }
  }
}