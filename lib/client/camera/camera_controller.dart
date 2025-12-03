import 'package:flame/components.dart';

class CameraController extends Component {
  final CameraComponent camera;
  final JoystickComponent joystick;
  final double moveSpeed;

  CameraController({
    required this.camera,
    required this.joystick,
    this.moveSpeed = 300.0,
  });

  @override
  void update(double dt) {
    super.update(dt);

    // Use direction (normalized -1 to 1)
    final direction = joystick.delta;

    if (direction != Vector2.zero()) {
      // Multiply by speed and delta time for smooth movement
      camera.viewfinder.position += direction * moveSpeed * dt;
    }
  }
}