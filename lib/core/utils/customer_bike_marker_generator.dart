import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// High-Resolution 3D Delivery Scooty & Custom Pin Marker Generator
/// Renders authentic isometric 3D scooter markers, Thulirva Dairy Hub pins,
/// and Customer Destination pins matching the design reference specification.
class CustomerBikeMarkerGenerator {
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Generates a high-res 3D Isometric Scooter marker oriented by [heading]
  static Future<BitmapDescriptor> getRiderMarker({
    double heading = 0.0,
    bool isMoving = true,
  }) async {
    // Quantize heading to 15 degree increments for smooth rotation & caching
    final quantized = (((heading % 360) / 15).round() * 15) % 360;
    final key = 'rider_3d_${quantized}_$isMoving';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final descriptor = await _draw3DRiderBitmap(heading: quantized.toDouble(), isMoving: isMoving);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Renders a true 3D Isometric delivery scooter with rider, cargo box, and ground aura
  static Future<BitmapDescriptor> _draw3DRiderBitmap({
    required double heading,
    required bool isMoving,
  }) async {
    const double size = 180.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    const center = Offset(size / 2, size / 2);

    // 1. Ground Pulse Aura Disc (Glowing Mint / Cyan on asphalt)
    final pulseColor = isMoving ? const Color(0xFF00A859) : const Color(0xFFD97706);
    final outerAura = Paint()
      ..color = pulseColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: 120, height: 60),
      outerAura,
    );

    final innerRing = Paint()
      ..color = pulseColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: 90, height: 45),
      innerRing,
    );

    // 2. Realistic Ground Contact Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 4, center.dy + 12), width: 85, height: 26),
      shadowPaint,
    );

    // Rotate scooter according to direction of travel
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (heading != 0.0) {
      canvas.rotate(heading * math.pi / 180.0);
    }

    // 3. Scooter Wheels
    final tirePaint = Paint()..color = const Color(0xFF1E293B);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);
    final hubPaint = Paint()..color = const Color(0xFFF1F5F9);

    // Front Wheel
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -32), width: 14, height: 24), tirePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -32), width: 8, height: 16), rimPaint);
    canvas.drawCircle(const Offset(0, -32), 3, hubPaint);

    // Rear Wheel
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 28), width: 16, height: 26), tirePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 28), width: 9, height: 18), rimPaint);
    canvas.drawCircle(const Offset(0, 28), 3, hubPaint);

    // 4. White Electric Scooter Chassis & Body
    final bodyPaint = Paint()..color = const Color(0xFFF8FAFC);
    final shadowBodyPaint = Paint()..color = const Color(0xFFCBD5E1);

    // Scooter Foot Deck
    final footDeck = Path()
      ..moveTo(-11, -16)
      ..lineTo(11, -16)
      ..lineTo(13, 16)
      ..lineTo(-13, 16)
      ..close();
    canvas.drawPath(footDeck, shadowBodyPaint);
    canvas.drawRect(
      const Rect.fromLTWH(-9, -12, 18, 24),
      Paint()..color = const Color(0xFF334155),
    );

    // Front Apron & Steering Column
    final frontApron = Path()
      ..moveTo(-12, -26)
      ..lineTo(12, -26)
      ..lineTo(10, -14)
      ..lineTo(-10, -14)
      ..close();
    canvas.drawPath(frontApron, bodyPaint);

    // Front LED Headlight Beam (Bright Yellow Glow)
    final headlightPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawOval(const Rect.fromLTWH(-6, -35, 12, 8), headlightPaint);

    // Handlebars with Grips & Round Chrome Mirrors
    final handlebarPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-22, -22), const Offset(22, -22), handlebarPaint);
    // Left & Right Mirrors
    canvas.drawCircle(const Offset(-23, -25), 3.0, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(const Offset(23, -25), 3.0, Paint()..color = const Color(0xFF94A3B8));

    // Contoured Scooter Seat (Padded Black Leather)
    final seatRect = Rect.fromCenter(center: const Offset(0, 6), width: 20, height: 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0F172A),
    );

    // 5. Seated Delivery Partner
    // Dark Charcoal Pants / Legs
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-8, -4), width: 8, height: 16),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8, -4), width: 8, height: 16),
      Paint()..color = const Color(0xFF1E293B),
    );

    // Torso: Signature Thulirva Green Windbreaker
    final jacketPaint = Paint()..color = const Color(0xFF15803D);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 24, height: 22),
      jacketPaint,
    );

    // High-Vis Reflector Sash
    canvas.drawLine(
      const Offset(-8, -6),
      const Offset(8, 6),
      Paint()
        ..color = const Color(0xFFFACC15)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // Arms gripping handlebars
    final armPaint = Paint()
      ..color = const Color(0xFF166534)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-7, -4), const Offset(-16, -20), armPaint);
    canvas.drawLine(const Offset(7, -4), const Offset(16, -20), armPaint);

    // Green Safety Helmet with Dark Aerodynamic Visor
    canvas.drawCircle(
      const Offset(0, -9),
      11.0,
      Paint()..color = const Color(0xFF15803D),
    );
    canvas.drawCircle(
      const Offset(-2, -11),
      8.0,
      Paint()..color = const Color(0xFF22C55E),
    );
    // Dark Front Visor
    canvas.drawOval(
      const Rect.fromLTWH(-7, -19, 14, 8),
      Paint()..color = const Color(0xFF0F172A),
    );

    // 6. Signature Emerald Green Thulirva Cargo Delivery Box (Mounted on Rear Rack)
    const boxW = 32.0;
    const boxH = 30.0;
    const boxRect = Rect.fromLTWH(-boxW / 2, 18, boxW, boxH);

    // Cargo box base shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect.shift(const Offset(0, 2)), const Radius.circular(5)),
      Paint()..color = const Color(0xFF064E3B),
    );

    // Main Box Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF00A859),
    );

    // Top Lid Highlight
    final lidRect = Rect.fromLTWH(-boxW / 2, 18, boxW, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF22C55E),
    );

    // White "🌿 Thulirva" Brand Logo on the Cargo Box
    final textPainter = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(text: '🌿 ', style: TextStyle(fontSize: 8)),
          TextSpan(
            text: 'Thulirva',
            style: TextStyle(
              color: Colors.white,
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((boxRect.width - textPainter.width) / 2 - boxW / 2, boxRect.top + 13),
    );

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Farm Hub Pin: "Thulirva \n Dairy Hub" matching reference image
  static Future<BitmapDescriptor> getHubPin({String name = 'Thulirva Dairy Hub'}) async {
    final key = 'hub_pin_${name.hashCode}';
    if (_cache.containsKey(key)) return _cache[key]!;

    const double width = 160.0;
    const double height = 110.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // 1. Top Green Circular Badge
    const badgeCenter = Offset(width / 2, 28);
    final badgePaint = Paint()..color = const Color(0xFF00A859);
    canvas.drawCircle(badgeCenter, 22, badgePaint);
    canvas.drawCircle(
      badgeCenter,
      22,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke,
    );

    // Storefront Icon (🏪)
    final iconPainter = TextPainter(
      text: const TextSpan(text: '🏪', style: TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(badgeCenter.dx - iconPainter.width / 2, badgeCenter.dy - iconPainter.height / 2));

    // 2. White Card Pill below: "Thulirva \n Dairy Hub"
    final textSpan = const TextSpan(
      children: [
        TextSpan(
          text: 'Thulirva\n',
          style: TextStyle(color: Color(0xFF173F2D), fontSize: 10, fontWeight: FontWeight.w700),
        ),
        TextSpan(
          text: 'Dairy Hub',
          style: TextStyle(color: Color(0xFF173F2D), fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    );
    final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout();

    final pillWidth = textPainter.width + 22;
    const pillHeight = 36.0;
    final pillRect = Rect.fromCenter(
      center: const Offset(width / 2, 70),
      width: pillWidth,
      height: pillHeight,
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect.shift(const Offset(0, 3)), const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    textPainter.paint(
      canvas,
      Offset(pillRect.center.dx - textPainter.width / 2, pillRect.center.dy - textPainter.height / 2),
    );

    // 3. Pointer Anchor pointing down
    final pointer = Path()
      ..moveTo(width / 2 - 8, pillRect.bottom)
      ..lineTo(width / 2 + 8, pillRect.bottom)
      ..lineTo(width / 2, height - 2)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.white);
    canvas.drawPath(
      pointer,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    final descriptor = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Customer Destination Pin: "Customer \n <Area>" matching reference image
  static Future<BitmapDescriptor> getCustomerPin({String area = 'Thiruverkadu'}) async {
    final cleanArea = area.trim().isNotEmpty ? area.trim() : 'Thiruverkadu';
    final key = 'customer_pin_${cleanArea.hashCode}';
    if (_cache.containsKey(key)) return _cache[key]!;

    const double width = 160.0;
    const double height = 110.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // 1. Top Red Circular Badge
    const badgeCenter = Offset(width / 2, 28);
    final badgePaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(badgeCenter, 22, badgePaint);
    canvas.drawCircle(
      badgeCenter,
      22,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke,
    );

    // Home Icon (🏠)
    final iconPainter = TextPainter(
      text: const TextSpan(text: '🏠', style: TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(badgeCenter.dx - iconPainter.width / 2, badgeCenter.dy - iconPainter.height / 2));

    // 2. White Card Pill below: "Customer \n <Area>"
    final textSpan = TextSpan(
      children: [
        const TextSpan(
          text: 'Customer\n',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w700),
        ),
        TextSpan(
          text: cleanArea,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    );
    final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.layout();

    final pillWidth = textPainter.width + 22;
    const pillHeight = 36.0;
    final pillRect = Rect.fromCenter(
      center: const Offset(width / 2, 70),
      width: pillWidth,
      height: pillHeight,
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect.shift(const Offset(0, 3)), const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    textPainter.paint(
      canvas,
      Offset(pillRect.center.dx - textPainter.width / 2, pillRect.center.dy - textPainter.height / 2),
    );

    // 3. Pointer Anchor pointing down
    final pointer = Path()
      ..moveTo(width / 2 - 8, pillRect.bottom)
      ..lineTo(width / 2 + 8, pillRect.bottom)
      ..lineTo(width / 2, height - 2)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.white);
    canvas.drawPath(
      pointer,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }

    final descriptor = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _cache[key] = descriptor;
    return descriptor;
  }
}
