import 'package:flame/components.dart';
import '../player/player_component.dart';

class PlayerInputHandler extends Component {
  final JoystickComponent joystick;
  final PlayerComponent player;

  PlayerInputHandler({
    required this.joystick,
    required this.player,
  });

  @override
  void update(double dt) {
    super.update(dt);
    
    // Get joystick input
    final delta = joystick.delta;
    
    if (!delta.isZero()) {
      // Set player velocity based on joystick
      player.setVelocity(delta);
    } else {
      // Stop player if joystick not touched
      player.setVelocity(Vector2.zero());
    }
  }
}