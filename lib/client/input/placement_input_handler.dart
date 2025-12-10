import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../managers/placement_state_manager.dart';

class PlacementInputHandler extends Component with TapCallbacks {
  final PlacementStateManager placementManager;
  final CameraComponent camera;

  PlacementInputHandler({
    required this.placementManager,
    required this.camera,
  });

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    print("👆 Screen tap at: ${event.localPosition}");

    // Only handle taps in item-selected state
    if (placementManager.currentState != PlacementState.itemSelected) {
      print("⚠️ Not in item-selected state (current: ${placementManager.currentState})");
      return;
    }

    // Convert screen position to world position using camera
    final screenPos = event.localPosition;
    final worldPos = camera.viewfinder.transform.globalToLocal(screenPos);
    
    print("🌍 World position: $worldPos");
    
    placementManager.selectTile(worldPos);
  }
}