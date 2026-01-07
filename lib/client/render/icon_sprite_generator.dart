import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';

class IconSpriteGenerator {
  static final Map<String, Sprite> _cache = {};

  /// Convert IconData to Sprite
  static Future<Sprite> fromIcon(
    IconData iconData, {
    double size = 32.0,
    Color color = Colors.white,
  }) async {
    // Create cache key
    final cacheKey = '${iconData.codePoint}_${size}_${color.value}';
    
    // Return cached sprite if exists
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Create the sprite
    final sprite = await _generateSprite(iconData, size, color);
    _cache[cacheKey] = sprite;
    
    return sprite;
  }

  static Future<Sprite> _generateSprite(
    IconData iconData,
    double size,
    Color color,
  ) async {
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create text painter for the icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Draw the icon centered
    textPainter.paint(canvas, Offset(0, 0));

    // End recording
    final picture = recorder.endRecording();
    
    // Convert to image
    final image = await picture.toImage(
      size.toInt(),
      size.toInt(),
    );

    // Create sprite from image
    return Sprite(image);
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
  }
}