import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// High-Resolution 3D Delivery Scooty & Rider Marker Generator
class CustomerBikeMarkerGenerator {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> getRiderMarker({
    double heading = 0.0,
    bool isMoving = true,
  }) async {
    // Quantize heading to 15 degree buckets for memory efficiency
    final quantized = ((heading % 360) / 15).round() * 15;
    final key = 'rider_${quantized}_$isMoving';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final descriptor = await _drawRiderBitmap(heading: heading, isMoving: isMoving);
    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _drawRiderBitmap({
    required double heading,
    required bool isMoving,
  }) async {
    const double size = 150.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    const center = Offset(size / 2, size / 2);

    // 1. Radar pulse halo
    final glowPaint = Paint()
      ..color = (isMoving ? const Color(0xFF15803D) : const Color(0xFFD97706)).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 58, glowPaint);

    final outerRing = Paint()
      ..color = (isMoving ? const Color(0xFF16A34A) : const Color(0xFFD97706)).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 52, outerRing);

    // 2. White Disc
    final whiteDisc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final discShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 44, discShadow);
    canvas.drawCircle(center, 44, whiteDisc);

    // 3. Draw Scooter & Rider
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (heading != 0.0) {
      canvas.rotate(heading * math.pi / 180.0);
    }

    // Wheels (Front & Rear)
    final tirePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -34, 10, 16), const Radius.circular(4)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 18, 10, 16), const Radius.circular(4)), tirePaint);

    // Scooter Body / Frame
    final bodyPaint = Paint()
      ..color = const Color(0xFF1B4D3E)
      ..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(-8, -20)
      ..lineTo(8, -20)
      ..lineTo(10, 20)
      ..lineTo(-10, 20)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Gold Trim Lines
    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-8, -14), const Offset(-8, 16), goldPaint);
    canvas.drawLine(const Offset(8, -14), const Offset(8, 16), goldPaint);

    // Handlebars
    final barPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-18, -18), const Offset(18, -18), barPaint);

    // Headlight Beam (Yellow Glow)
    final lightPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(-6, -26, 12, 6), lightPaint);

    // Delivery Associate Torso (Green Windbreaker)
    final jacketPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(-12, -8, 24, 20), jacketPaint);

    // High-Vis Neon Sash
    final sashPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-8, -4), const Offset(8, 8), sashPaint);

    // Helmet & Visor
    final helmetPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 0), 10, helmetPaint);

    final visorPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(-6, -8, 12, 7), visorPaint);

    // Rear Insulated Delivery Box ("THULIRVA")
    final boxPaint = Paint()
      ..color = const Color(0xFF1B4D3E)
      ..style = PaintingStyle.fill;
    final boxBorder = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    const boxRect = Rect.fromLTWH(-14, 18, 28, 20);
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(5)), boxPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(5)), boxBorder);

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Farm Hub / Destination Custom Pin
  static Future<BitmapDescriptor> getHubPin() async {
    const double size = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final pinPaint = Paint()
      ..color = const Color(0xFF1B4D3E)
      ..style = PaintingStyle.fill;
    final goldRing = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const center = Offset(size / 2, 44);
    canvas.drawCircle(center, 34, pinPaint);
    canvas.drawCircle(center, 34, goldRing);

    final pointer = Path()
      ..moveTo(size / 2 - 14, 68)
      ..lineTo(size / 2 + 14, 68)
      ..lineTo(size / 2, 98)
      ..close();
    canvas.drawPath(pointer, pinPaint);

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, iconPaint);

    // Inner gold emblem
    final emblemPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, emblemPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}

