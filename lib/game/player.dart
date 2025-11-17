import 'dart:async' as timer;
import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Player extends RectangleComponent {
  Player()
      : super(
          size: Vector2.all(50),
          paint: Paint()..color = const Color(0xFF00FF00),
        );

  static const int myPlayerId = 1;  // Bigint auto=1
  static const String myRoomId = 'f6b1a81e-aa98-4243-9d46-9c96b1c77ccf';

  late SupabaseClient supabase;
  timer.Timer? _sendThrottleTimer;  // Throttle gửi (tránh spam mỗi frame)
  bool _isSending = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    print('Player onLoad() called! Position init: x=${position.x}, y=${position.y}');
    supabase = Supabase.instance.client;

    // Throttle timer: Chỉ gửi nếu không gửi trong 100ms
    _sendThrottleTimer = timer.Timer.periodic(const Duration(milliseconds: 100), (t) {
      _isSending = false;  // Reset flag mỗi 100ms
    });
  }

  // Method gọi từ my_game để gửi
  void sendPositionUpdate() {
    if (_isSending) return;  // Throttle: Bỏ qua nếu đang gửi
    _isSending = true;
    print("Sending position update from my_game...");
    _sendToSupabase();
  }

  Future<void> _sendToSupabase() async {
    try {
      final response = await supabase
          .from('players')
          .update({
            'position': {
              'x': position.x.toDouble(),
              'y': position.y.toDouble(),
            }
          })
          .eq('id', myPlayerId)
          .eq('room_id', myRoomId);

      if (response.error != null) {
        print('Lỗi cập nhật: ${response.error!.message}');
      } else {
        print('Gửi OK: x=${position.x.toStringAsFixed(1)}, y=${position.y.toStringAsFixed(1)}');
      }
    } catch (e) {
      print('Exception gửi data: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Bỏ distance check, giờ detect ở my_game
  }

  @override
  void onRemove() {
    _sendThrottleTimer?.cancel();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final eyePaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(const Offset(15, 15), 5, eyePaint);
    canvas.drawCircle(const Offset(35, 15), 5, eyePaint);
  }
}