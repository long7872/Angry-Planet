import 'package:flame/components.dart';
import '../player/player_component.dart';

class CameraController extends Component {
  final CameraComponent camera;
  final JoystickComponent? joystick;
  PlayerComponent? targetPlayer;
  
  // Camera settings
  final double moveSpeed;
  static const double smoothing = 10.0;
  
  bool followPlayer = false; // Start with manual control

  CameraController({
    required this.camera,
    this.joystick,
    this.moveSpeed = 300.0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    
    if (followPlayer && targetPlayer != null) {
      // Mode 1: Follow player automatically
      _followPlayer(dt);
    } else if (joystick != null) {
      // Mode 2: Manual camera control with joystick
      _manualControl(dt);
    }
  }

  /// Manual camera control with joystick
  void _manualControl(double dt) {
    final direction = joystick!.delta;

    if (direction != Vector2.zero()) {
      camera.viewfinder.position += direction * moveSpeed * dt;
    }
  }

  /// Smooth camera following player
  void _followPlayer(double dt) {
    final playerPos = targetPlayer!.position;
    final currentPos = camera.viewfinder.position;
    
    final targetPos = playerPos;
    final newPos = currentPos + (targetPos - currentPos) * smoothing * dt;
    
    camera.viewfinder.position = newPos;
  }

  /// Enable player following mode
  void setTarget(PlayerComponent player) {
    targetPlayer = player;
    followPlayer = true;
    
    // Snap camera to player immediately
    camera.viewfinder.position = player.position.clone();
  }

  /// Disable player following (return to manual control)
  void disableFollow() {
    followPlayer = false;
  }

  /// Enable player following
  void enableFollow() {
    if (targetPlayer != null) {
      followPlayer = true;
    }
  }

  /// Check if currently following player
  bool get isFollowing => followPlayer;
}