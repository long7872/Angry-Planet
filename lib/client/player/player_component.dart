import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../shared/player_data.dart';
import '../managers/collision_manager.dart';

enum PlayerDirection { down, right, left, up }
enum PlayerState { idle, running }

class PlayerComponent extends PositionComponent {
  static const double playerSize = 32.0;
  final double speed;
  final FlameGame game;
  
  final PlayerData data;
  
  // Animation system
  late Map<PlayerState, Map<PlayerDirection, SpriteAnimation>> animations;
  late SpriteAnimationTicker currentAnimationTicker;
  
  PlayerDirection currentDirection = PlayerDirection.down;
  PlayerState currentState = PlayerState.idle;
  
  Vector2 velocity = Vector2.zero();

  // Collision system
  CollisionManager? collisionManager;
  
  PlayerComponent({
    required this.data,
    required this.game,
    this.speed = 100
  }) : super(
          position: Vector2(data.x, data.y),
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
          priority: 100,
        );

  /// Set collision manager
  void setCollisionManager(CollisionManager manager) {
    collisionManager = manager;
  }

  @override
  Future<void> onLoad() async {
    final image = await game.images.load('ui/player.png');
    
    // Create all animations
    animations = {
      PlayerState.idle: {
        PlayerDirection.down: _createAnimation(image, 0),
        PlayerDirection.right: _createAnimation(image, 1),
        PlayerDirection.left: _createAnimation(image, 1),
        PlayerDirection.up: _createAnimation(image, 2),
      },
      PlayerState.running: {
        PlayerDirection.down: _createAnimation(image, 3),
        PlayerDirection.right: _createAnimation(image, 4),
        PlayerDirection.left: _createAnimation(image, 4),
        PlayerDirection.up: _createAnimation(image, 5),
      },
    };
    
    // Initialize ticker with idle down animation
    currentAnimationTicker = animations[PlayerState.idle]![PlayerDirection.down]!.createTicker();
  }

  SpriteAnimation _createAnimation(ui.Image image, int row) {
    final sprites = <Sprite>[];
    
    for (int col = 0; col < 6; col++) {
      sprites.add(
        Sprite(
          image,
          srcPosition: Vector2(col * 32.0, row * 32.0),
          srcSize: Vector2(32, 32),
        ),
      );
    }
    
    return SpriteAnimation.spriteList(
      sprites,
      stepTime: 0.1,
      loop: true,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Store previous state/direction
    final prevState = currentState;
    final prevDirection = currentDirection;
    
    // Update position and state
    if (!velocity.isZero()) {
      // Calculate intended movement
      final movement = velocity * dt;
      final newPosition = position + movement;

      // ✓ Check collision
      if (collisionManager != null) {
        if (collisionManager!.canMoveTo(newPosition, size)) {
          // Free to move
          position.setFrom(newPosition);
          data.x = position.x;
          data.y = position.y;
        } else {
          // Try sliding along obstacles
          _trySlideMovement(movement);
        }
      } else {
        // No collision manager - move freely
        position.setFrom(newPosition);
        data.x = position.x;
        data.y = position.y;
      }
      
      _updateDirection();
      currentState = PlayerState.running;
    } else {
      currentState = PlayerState.idle;
    }
    
    // If state or direction changed, switch animation
    if (prevState != currentState || prevDirection != currentDirection) {
      currentAnimationTicker = animations[currentState]![currentDirection]!.createTicker();
    }
    
    // Update current animation
    currentAnimationTicker.update(dt);
  }

  /// Try to slide along obstacles
  void _trySlideMovement(Vector2 movement) {
    // Try moving only horizontally
    if (movement.x != 0) {
      final horizontalMove = Vector2(movement.x, 0);
      final newPos = position + horizontalMove;
      if (collisionManager!.canMoveTo(newPos, size)) {
        position.add(horizontalMove);
        data.x = position.x;
        data.y = position.y;
        return;
      }
    }
    
    // Try moving only vertically
    if (movement.y != 0) {
      final verticalMove = Vector2(0, movement.y);
      final newPos = position + verticalMove;
      if (collisionManager!.canMoveTo(newPos, size)) {
        position.add(verticalMove);
        data.x = position.x;
        data.y = position.y;
        return;
      }
    }
    
    // If both fail, don't move (blocked)
  }

  void _updateDirection() {
    if (velocity.x.abs() > velocity.y.abs()) {
      currentDirection = velocity.x > 0 ? PlayerDirection.right : PlayerDirection.left;
    } else {
      currentDirection = velocity.y > 0 ? PlayerDirection.down : PlayerDirection.up;
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = currentAnimationTicker.getSprite();
    
    // Flip horizontally for left direction
    if (currentDirection == PlayerDirection.left) {
      canvas.save();
      canvas.translate(0, 0);  // Keep at center
      canvas.scale(-1, 1);      // Flip horizontally
      sprite.render(
        canvas,
        position: Vector2(-playerSize, 0),  // ✓ Compensate for flip
        size: Vector2.all(playerSize),
      );
      canvas.restore();
    } else {
      sprite.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2.all(playerSize),
      );
    }
    
    _renderName(canvas);
  }

  void setVelocity(Vector2 direction) {
    velocity = direction * speed;
  }

  void _renderName(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: data.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // 👉 Center X, place just above head
    final x = (size.x - textPainter.width) / 2;
    final y = -textPainter.height - 2; // 2px gap above sprite

    textPainter.paint(canvas, Offset(x, y));
  }
}