import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../shared/network_messages.dart';

class RemotePlayerComponent extends PositionComponent {
  static const double playerSize = 32.0;
  final FlameGame game;
  final PlayerStateMessage initialState;
  
  late Map<String, Map<String, SpriteAnimation>> animations;
  late SpriteAnimationTicker currentAnimationTicker;
  
  String currentDirection = 'down';
  String currentState = 'idle';

  RemotePlayerComponent({
    required this.game,
    required this.initialState,
  }) : super(
          position: Vector2(initialState.x, initialState.y),
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
          priority: 99,
        );

  @override
  Future<void> onLoad() async {
    final image = await game.images.load('ui/player.png');
    
    animations = {
      'idle': {
        'down': _createAnimation(image, 0),
        'right': _createAnimation(image, 1),
        'left': _createAnimation(image, 1),
        'up': _createAnimation(image, 2),
      },
      'running': {
        'down': _createAnimation(image, 3),
        'right': _createAnimation(image, 4),
        'left': _createAnimation(image, 4),
        'up': _createAnimation(image, 5),
      },
    };
    
    currentAnimationTicker = animations['idle']!['down']!.createTicker();
  }

  SpriteAnimation _createAnimation(ui.Image image, int row) {
    final sprites = <Sprite>[];
    for (int col = 0; col < 6; col++) {
      sprites.add(Sprite(
        image,
        srcPosition: Vector2(col * 32.0, row * 32.0),
        srcSize: Vector2(32, 32),
      ));
    }
    return SpriteAnimation.spriteList(sprites, stepTime: 0.1, loop: true);
  }

  void updateFromServer(PlayerStateMessage state) {
    position.x = state.x;
    position.y = state.y;
    
    if (currentState != state.state || currentDirection != state.direction) {
      currentState = state.state;
      currentDirection = state.direction;
      currentAnimationTicker = animations[state.state]![state.direction]!.createTicker();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    currentAnimationTicker.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final sprite = currentAnimationTicker.getSprite();
    
    if (currentDirection == 'left') {
      canvas.save();
      canvas.translate(0, 0);
      canvas.scale(-1, 1);
      sprite.render(canvas, position: Vector2(-playerSize, 0), size: Vector2.all(playerSize));
      canvas.restore();
    } else {
      sprite.render(canvas, position: Vector2.zero(), size: Vector2.all(playerSize));
    }
    
    _renderName(canvas);
  }

  void _renderName(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: initialState.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        textPainter.width / 2 - 2,                    // Center horizontally
        - playerSize / 2,  // Just above sprite (2px gap)
      ),
    );
  }
}