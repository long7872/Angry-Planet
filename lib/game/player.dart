import 'dart:async' as timer;
import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Player extends RectangleComponent {
  Player()
      : super(
          size: Vector2.all(50),
          paint: Paint()..color = const Color(0xFF00FF00),
        );

  static const String myPlayerId = 'b866ad1d-ea50-4dc3-a801-c8c319a24b78';  // ← Chỉnh ID thật của bạn!
  static const String myRoomId = '6c191125-6f34-496f-b592-b5a6aa1ddbaa';      // ← Chỉnh ID phòng thật!

  late final SupabaseClient _supabase;
  timer.Timer? _throttleTimer;  // ← Thay debounce → throttle periodic
  Vector2 _lastSentPosition = Vector2.zero();  // Theo dõi vị trí cuối gửi để tránh spam giống nhau

  final Logger logger = Logger();

  @override
  Future<void> onLoad() async {
    logger.d('Player onLoad started');
    super.onLoad();
    _supabase = Supabase.instance.client;
    logger.d('Supabase client initialized');

    // Gửi init position ngay
    await _sendToSupabase();

    // Start throttle timer: Gửi mỗi 100ms nếu di chuyển
    _throttleTimer = timer.Timer.periodic(const Duration(milliseconds: 100), (_) {
      if ((position - _lastSentPosition).length > 5.0) {  // Chỉ gửi nếu vị trí thay đổi >5px
        _sendToSupabase();
      }
    });
    logger.d('Throttle timer started (100ms)');

    logger.d('Player onLoad completed');
  }

  // Bỏ schedulePositionUpdate() - giờ tự động qua throttle

  Future<void> _sendToSupabase() async {
    logger.d('_sendToSupabase started - position: ${position.x.toStringAsFixed(1)}, ${position.y.toStringAsFixed(1)}');
    try {
      await _supabase.from('players').update({
        'position': {'x': position.x, 'y': position.y},
      }).eq('id', myPlayerId).eq('room_id', myRoomId);
      _lastSentPosition = position.clone();  // Update last sent
      logger.i('Position sent successfully to Supabase');
    } catch (e) {
      logger.e('Send error: $e');
    }
    logger.d('_sendToSupabase ended');
  }

  @override
  void render(Canvas canvas) {
    // Comment log ở đây để chống lag - chỉ uncomment nếu cần debug render
    // logger.d('Render frame started');
    super.render(canvas);
    final eyePaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(const Offset(15, 15), 5, eyePaint);
    canvas.drawCircle(const Offset(35, 15), 5, eyePaint);
    // logger.d('Render frame ended');
  }

  @override
  void onRemove() {
    logger.d('Player onRemove called');
    _throttleTimer?.cancel();
    logger.d('Throttle timer cancelled on remove');
    super.onRemove();
  }
}