import 'package:flutter/material.dart';

/// Interactive 3D Isometric City View
/// Renders an authentic isometric city scene matching the reference image:
/// - Isometric 3D buildings with multi-faceted shading
/// - Realistic low-poly trees and sidewalks
/// - Vibrant green Thulirva delivery route
/// - Origin "Thulirva Dairy Hub" pin and destination "Customer" pin
/// - Realistic 3D electric scooty with delivery rider wearing green uniform/helmet
/// - Signature green Thulirva delivery cargo box with brand emblem
/// - Glowing ground pulse disc
/// - Interactive gestures: Pan, Zoom, Pinch
class Thulirva3DIsometricCityView extends StatefulWidget {
  final double progress; // 0.0 to 1.0 along the route
  final String hubName;
  final String customerArea;
  final VoidCallback? onRecenter;

  const Thulirva3DIsometricCityView({
    super.key,
    this.progress = 0.52,
    this.hubName = 'Thulirva Dairy Hub',
    this.customerArea = 'Thiruverkadu',
    this.onRecenter,
  });

  @override
  State<Thulirva3DIsometricCityView> createState() => _Thulirva3DIsometricCityViewState();
}

class _Thulirva3DIsometricCityViewState extends State<Thulirva3DIsometricCityView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Center the camera on the rider by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCamera();
    });
  }

  void _centerCamera() {
    _transformController.value = Matrix4.diagonal3Values(1.05, 1.05, 1.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.5,
            maxScale: 2.5,
            child: SizedBox(
              width: 1400,
              height: 1000,
              child: CustomPaint(
                painter: _IsometricCityPainter(
                  pulseValue: _animController.value,
                  progress: widget.progress.clamp(0.05, 0.95),
                  hubName: widget.hubName,
                  customerArea: widget.customerArea,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IsometricCityPainter extends CustomPainter {
  final double pulseValue;
  final double progress;
  final String hubName;
  final String customerArea;

  _IsometricCityPainter({
    required this.pulseValue,
    required this.progress,
    required this.hubName,
    required this.customerArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Clean Isometric Ground Base
    final groundPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // Draw Subtle Grid Lanes / Streets
    final streetPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 44
      ..style = PaintingStyle.stroke;

    // Isometric street lines
    for (double i = -400; i < size.width + 600; i += 180) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + 800, size.height),
        streetPaint,
      );
    }
    for (double i = -400; i < size.width + 600; i += 180) {
      canvas.drawLine(
        Offset(i + 400, 0),
        Offset(i - 400, size.height),
        streetPaint,
      );
    }

    // 2. Define the Vibrant Green Delivery Route
    // Curved smooth path from Bottom-Left (Hub) to Right (Customer)
    final hubPoint = Offset(size.width * 0.18, size.height * 0.68);
    final customerPoint = Offset(size.width * 0.82, size.height * 0.42);

    final routePath = Path();
    routePath.moveTo(hubPoint.dx, hubPoint.dy);

    // Smooth spline waypoints matching reference image
    final cp1 = Offset(size.width * 0.30, size.height * 0.65);
    final p1 = Offset(size.width * 0.36, size.height * 0.58);
    final cp2 = Offset(size.width * 0.42, size.height * 0.52);
    final p2 = Offset(size.width * 0.50, size.height * 0.50);
    final cp3 = Offset(size.width * 0.60, size.height * 0.48);
    final p3 = Offset(size.width * 0.68, size.height * 0.46);
    final cp4 = Offset(size.width * 0.74, size.height * 0.45);

    routePath.quadraticBezierTo(cp1.dx, cp1.dy, p1.dx, p1.dy);
    routePath.quadraticBezierTo(cp2.dx, cp2.dy, p2.dx, p2.dy);
    routePath.quadraticBezierTo(cp3.dx, cp3.dy, p3.dx, p3.dy);
    routePath.quadraticBezierTo(cp4.dx, cp4.dy, customerPoint.dx, customerPoint.dy);

    // 3. Render 3D Extruded Buildings (Background Layer)
    _draw3DBuildings(canvas, size);

    // 4. Render 3D Low-Poly Trees along streets
    _draw3DTrees(canvas, size);

    // 5. Draw Glowing Green Route Line
    // Outer Mint Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.35)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, glowPaint);

    // Core Emerald Green Line
    final coreRoutePaint = Paint()
      ..color = const Color(0xFF00A859)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, coreRoutePaint);

    // Subtle White Center Dashed Line
    final whiteDashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final metrics = routePath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final totalLen = metric.length;

      // Draw route dashes
      for (double d = 0; d < totalLen; d += 16) {
        final extract = metric.extractPath(d, d + 8);
        canvas.drawPath(extract, whiteDashPaint);
      }

      // Compute Rider Position & Direction at current progress
      final currentDist = totalLen * progress;
      final tangent = metric.getTangentForOffset(currentDist);

      if (tangent != null) {
        final riderPos = tangent.position;
        final riderAngle = tangent.angle;

        // 6. Draw 3D Rider & Scooty
        _draw3DRiderAndScooty(canvas, riderPos, riderAngle);
      }
    }

    // 7. Render Origin Pin: "Thulirva Dairy Hub"
    _drawOriginHubPin(canvas, hubPoint, hubName);

    // 8. Render Destination Pin: "Customer <Area>"
    _drawDestinationCustomerPin(canvas, customerPoint, customerArea);
  }

  /// Renders 3D Extruded Isometric Buildings with Realistic Depth & Shading
  void _draw3DBuildings(Canvas canvas, Size size) {
    // Array of isometric buildings with footprint and height
    final buildings = [
      // Top Left block
      _BuildingData(Offset(size.width * 0.20, size.height * 0.35), 70, 50, 60),
      _BuildingData(Offset(size.width * 0.28, size.height * 0.30), 80, 55, 85),
      _BuildingData(Offset(size.width * 0.36, size.height * 0.25), 65, 45, 50),
      // Mid Left block
      _BuildingData(Offset(size.width * 0.12, size.height * 0.50), 90, 60, 75),
      _BuildingData(Offset(size.width * 0.22, size.height * 0.52), 60, 50, 45),
      // Center Top block
      _BuildingData(Offset(size.width * 0.44, size.height * 0.32), 75, 60, 95),
      _BuildingData(Offset(size.width * 0.52, size.height * 0.28), 85, 50, 70),
      _BuildingData(Offset(size.width * 0.60, size.height * 0.24), 70, 55, 60),
      // Center Mid block (above route)
      _BuildingData(Offset(size.width * 0.48, size.height * 0.44), 65, 45, 55),
      _BuildingData(Offset(size.width * 0.56, size.height * 0.40), 80, 50, 80),
      _BuildingData(Offset(size.width * 0.64, size.height * 0.36), 65, 45, 65),
      // Center Bottom block (below route)
      _BuildingData(Offset(size.width * 0.34, size.height * 0.72), 85, 55, 60),
      _BuildingData(Offset(size.width * 0.44, size.height * 0.66), 70, 50, 70),
      _BuildingData(Offset(size.width * 0.52, size.height * 0.60), 65, 45, 50),
      // Right Top block
      _BuildingData(Offset(size.width * 0.72, size.height * 0.28), 75, 55, 80),
      _BuildingData(Offset(size.width * 0.80, size.height * 0.24), 85, 60, 90),
      // Right Mid block
      _BuildingData(Offset(size.width * 0.76, size.height * 0.48), 80, 50, 75),
      _BuildingData(Offset(size.width * 0.86, size.height * 0.44), 70, 55, 60),
      // Right Bottom block
      _BuildingData(Offset(size.width * 0.62, size.height * 0.62), 75, 50, 65),
      _BuildingData(Offset(size.width * 0.70, size.height * 0.58), 65, 45, 55),
    ];

    for (final b in buildings) {
      _renderSingleIsometricBuilding(canvas, b.pos, b.w, b.l, b.h);
    }
  }

  void _renderSingleIsometricBuilding(Canvas canvas, Offset base, double w, double l, double h) {
    // 3D Isometric projection offsets: 30-degree projection angles
    final dx1 = w * 0.866;
    final dy1 = w * 0.5;
    final dx2 = -l * 0.866;
    final dy2 = l * 0.5;

    final pGroundFront = base;
    final pGroundRight = Offset(base.dx + dx1, base.dy - dy1);
    final pGroundLeft = Offset(base.dx + dx2, base.dy - dy2);
    final pGroundBack = Offset(base.dx + dx1 + dx2, base.dy - dy1 - dy2);

    final pTopFront = Offset(pGroundFront.dx, pGroundFront.dy - h);
    final pTopRight = Offset(pGroundRight.dx, pGroundRight.dy - h);
    final pTopLeft = Offset(pGroundLeft.dx, pGroundLeft.dy - h);
    final pTopBack = Offset(pGroundBack.dx, pGroundBack.dy - h);

    // 1. Drop Shadow
    final shadowPath = Path()
      ..moveTo(pGroundFront.dx, pGroundFront.dy)
      ..lineTo(pGroundRight.dx + 15, pGroundRight.dy)
      ..lineTo(pGroundBack.dx + 25, pGroundBack.dy + 10)
      ..lineTo(pGroundLeft.dx, pGroundLeft.dy)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()..color = Colors.black.withValues(alpha: 0.04),
    );

    // 2. Left Face (Ambient / Mid Shadow)
    final leftFace = Path()
      ..moveTo(pGroundFront.dx, pGroundFront.dy)
      ..lineTo(pGroundLeft.dx, pGroundLeft.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pTopFront.dx, pTopFront.dy)
      ..close();
    canvas.drawPath(
      leftFace,
      Paint()..color = const Color(0xFFCBD5E1),
    );

    // Left face border
    canvas.drawPath(
      leftFace,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // 3. Right Face (Sun-facing Light Shadow)
    final rightFace = Path()
      ..moveTo(pGroundFront.dx, pGroundFront.dy)
      ..lineTo(pGroundRight.dx, pGroundRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopFront.dx, pTopFront.dy)
      ..close();
    canvas.drawPath(
      rightFace,
      Paint()..color = const Color(0xFFE2E8F0),
    );

    canvas.drawPath(
      rightFace,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // 4. Top Face (Sunlit Bright Surface)
    final topFace = Path()
      ..moveTo(pTopFront.dx, pTopFront.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopBack.dx, pTopBack.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    canvas.drawPath(
      topFace,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Roof Parapet / Inner Edge
    final roofInset = Path()
      ..moveTo(pTopFront.dx, pTopFront.dy - 1)
      ..lineTo(pTopRight.dx - 2, pTopRight.dy)
      ..lineTo(pTopBack.dx, pTopBack.dy + 1)
      ..lineTo(pTopLeft.dx + 2, pTopLeft.dy)
      ..close();
    canvas.drawPath(
      roofInset,
      Paint()..color = const Color(0xFFF8FAFC),
    );
  }

  /// Renders 3D Trees with Foliage and Trunk
  void _draw3DTrees(Canvas canvas, Size size) {
    final treeLocations = [
      Offset(size.width * 0.16, size.height * 0.42),
      Offset(size.width * 0.24, size.height * 0.48),
      Offset(size.width * 0.32, size.height * 0.45),
      Offset(size.width * 0.40, size.height * 0.38),
      Offset(size.width * 0.45, size.height * 0.58),
      Offset(size.width * 0.58, size.height * 0.52),
      Offset(size.width * 0.65, size.height * 0.55),
      Offset(size.width * 0.72, size.height * 0.38),
      Offset(size.width * 0.78, size.height * 0.55),
      Offset(size.width * 0.84, size.height * 0.35),
    ];

    for (final t in treeLocations) {
      // Tree Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(t.dx + 4, t.dy + 2), width: 22, height: 12),
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );

      // Tree Trunk
      canvas.drawRect(
        Rect.fromLTWH(t.dx - 2, t.dy - 8, 4, 8),
        Paint()..color = const Color(0xFF78350F),
      );

      // 3D Tree Canopy (tiered spheres for foliage depth)
      canvas.drawCircle(
        Offset(t.dx, t.dy - 16),
        12,
        Paint()..color = const Color(0xFF15803D),
      );
      canvas.drawCircle(
        Offset(t.dx - 2, t.dy - 18),
        9,
        Paint()..color = const Color(0xFF22C55E),
      );
      canvas.drawCircle(
        Offset(t.dx - 3, t.dy - 20),
        5,
        Paint()..color = const Color(0xFF86EFAC),
      );
    }
  }

  /// Renders 3D Delivery Associate on White Electric Scooter with Green Thulirva Box
  /// Matches the isometric 3/4 side-view in the master reference screenshot
  void _draw3DRiderAndScooty(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // 1. Isometric Ground Pulse Disc (Pulsing glowing mint green ring on asphalt)
    final pulseRadius = 26.0 + (pulseValue * 18.0);
    final pulseAlpha = (1.0 - pulseValue).clamp(0.0, 0.7);

    // Glowing outer halo
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: pulseRadius * 2.2, height: pulseRadius * 1.1),
      Paint()
        ..color = const Color(0xFF00A859).withValues(alpha: pulseAlpha * 0.45)
        ..style = PaintingStyle.fill,
    );
    // Glowing inner ring
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: pulseRadius * 1.6, height: pulseRadius * 0.8),
      Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: pulseAlpha * 0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Soft drop shadow beneath wheels
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 70, height: 22),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // 2. Wheels (Rear & Front)
    final tirePaint = Paint()..color = const Color(0xFF1E293B);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);
    final hubPaint = Paint()..color = const Color(0xFFE2E8F0);

    // Rear Wheel (Center at x = -22, y = -8)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-22, -8), width: 18, height: 18),
      tirePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-22, -8), width: 10, height: 10),
      rimPaint,
    );
    canvas.drawCircle(const Offset(-22, -8), 2.5, hubPaint);

    // Front Wheel (Center at x = +22, y = -8)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(22, -8), width: 18, height: 18),
      tirePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(22, -8), width: 10, height: 10),
      rimPaint,
    );
    canvas.drawCircle(const Offset(22, -8), 2.5, hubPaint);

    // 3. Electric Scooter Chassis & Body Panels (Modern White Gloss)
    final bodyPaint = Paint()..color = const Color(0xFFF8FAFC);
    final shadowBodyPaint = Paint()..color = const Color(0xFFE2E8F0);

    // Lower Floorboard / Battery Tray
    final floorboard = Path()
      ..moveTo(-14, -8)
      ..lineTo(14, -8)
      ..lineTo(16, -14)
      ..lineTo(-12, -14)
      ..close();
    canvas.drawPath(floorboard, shadowBodyPaint);
    canvas.drawRect(
      const Rect.fromLTWH(-12, -15, 26, 3),
      Paint()..color = const Color(0xFF334155),
    );

    // Front Steering Fork & Column
    canvas.drawLine(
      const Offset(22, -8),
      const Offset(16, -26),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Front Aerodynamic Apron / Fairing
    final frontApron = Path()
      ..moveTo(12, -14)
      ..lineTo(22, -18)
      ..lineTo(18, -32)
      ..lineTo(12, -32)
      ..close();
    canvas.drawPath(frontApron, bodyPaint);

    // Headlight (Warm LED glow facing forward)
    canvas.drawCircle(
      const Offset(20, -24),
      3.0,
      Paint()..color = const Color(0xFFFEF08A),
    );

    // Handlebars & Grips
    canvas.drawLine(
      const Offset(10, -33),
      const Offset(20, -31),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // Rear Body Fairing (Covering rear wheel)
    final rearFairing = Path()
      ..moveTo(-12, -14)
      ..lineTo(-4, -14)
      ..lineTo(-6, -22)
      ..lineTo(-28, -20)
      ..lineTo(-28, -12)
      ..close();
    canvas.drawPath(rearFairing, bodyPaint);

    // Contoured Scooter Seat (Padded Black Leather)
    final seatPath = Path()
      ..moveTo(-26, -22)
      ..lineTo(-2, -22)
      ..lineTo(2, -20)
      ..lineTo(-26, -20)
      ..close();
    canvas.drawPath(
      seatPath,
      Paint()..color = const Color(0xFF0F172A),
    );

    // 4. Delivery Associate (Rider)
    // Dark Charcoal Pants / Legs
    final legPath = Path()
      ..moveTo(-10, -22)
      ..lineTo(2, -20)
      ..lineTo(6, -13)
      ..lineTo(10, -13)
      ..lineTo(8, -10)
      ..lineTo(4, -10)
      ..lineTo(-2, -16)
      ..close();
    canvas.drawPath(
      legPath,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Torso: Signature Thulirva Green Windbreaker
    final jacketPaint = Paint()..color = const Color(0xFF15803D);
    final jacketHighlight = Paint()..color = const Color(0xFF22C55E);

    final torsoPath = Path()
      ..moveTo(-10, -23)
      ..lineTo(2, -21)
      ..lineTo(6, -38)
      ..lineTo(-4, -39)
      ..close();
    canvas.drawPath(torsoPath, jacketPaint);

    // Arm extending forward to grip handlebar
    canvas.drawLine(
      const Offset(2, -36),
      const Offset(14, -32),
      Paint()
        ..color = const Color(0xFF166534)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );
    // Glove on throttle
    canvas.drawCircle(const Offset(14, -32), 2.5, Paint()..color = const Color(0xFF0F172A));

    // Green Helmet with Sunlit Visor
    canvas.drawCircle(
      const Offset(1, -47),
      9.0,
      jacketPaint,
    );
    canvas.drawCircle(
      const Offset(-1, -49),
      6.0,
      jacketHighlight,
    );
    // Aerodynamic Dark Visor (Facing forward)
    final visorPath = Path()
      ..moveTo(2, -50)
      ..lineTo(9, -47)
      ..lineTo(6, -42)
      ..lineTo(1, -44)
      ..close();
    canvas.drawPath(
      visorPath,
      Paint()..color = const Color(0xFF0F172A),
    );

    // 5. Signature Thulirva Emerald Green Cargo Delivery Box
    // Isometric 3D Cube mounted on rear carrier rack
    final boxLeft = -39.0;
    final boxTop = -46.0;
    final boxW = 24.0;
    final boxH = 24.0;

    // Rear cargo rack support metal tubes
    canvas.drawLine(
      const Offset(-24, -20),
      Offset(boxLeft + 4, boxTop + boxH),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 2.5,
    );
    canvas.drawLine(
      const Offset(-14, -20),
      Offset(boxLeft + boxW - 4, boxTop + boxH),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 2.5,
    );

    // Side Face of Box (Facing viewer) - Rich Thulirva Green
    final boxRect = Rect.fromLTWH(boxLeft, boxTop, boxW, boxH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF00A859),
    );

    // Top Face of Box (Sunlit top lid)
    final topFace = Path()
      ..moveTo(boxLeft, boxTop)
      ..lineTo(boxLeft + 8, boxTop - 6)
      ..lineTo(boxLeft + boxW + 8, boxTop - 6)
      ..lineTo(boxLeft + boxW, boxTop)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = const Color(0xFF22C55E),
    );

    // Front/Right Edge Face of Box (Isometric Depth)
    final edgeFace = Path()
      ..moveTo(boxLeft + boxW, boxTop)
      ..lineTo(boxLeft + boxW + 8, boxTop - 6)
      ..lineTo(boxLeft + boxW + 8, boxTop + boxH - 6)
      ..lineTo(boxLeft + boxW, boxTop + boxH)
      ..close();
    canvas.drawPath(
      edgeFace,
      Paint()..color = const Color(0xFF15803D),
    );

    // White "Thulirva" Brand Logo Emblem on the Side Face of Cargo Box
    final logoTextPainter = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(text: '🌿 ', style: TextStyle(fontSize: 6)),
          TextSpan(
            text: 'Thulirva',
            style: TextStyle(
              color: Colors.white,
              fontSize: 5.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    logoTextPainter.layout();
    logoTextPainter.paint(
      canvas,
      Offset(boxLeft + (boxW - logoTextPainter.width) / 2, boxTop + (boxH - logoTextPainter.height) / 2),
    );

    canvas.restore();
  }

  /// Renders Origin Hub Pin: "Thulirva Dairy Hub"
  void _drawOriginHubPin(Canvas canvas, Offset pos, String label) {
    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 14), width: 34, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Green Circular Badge
    final badgePaint = Paint()..color = const Color(0xFF00A859);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 6), 18, badgePaint);

    // Outer border
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 6),
      18,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Storefront / Hub Icon
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '🏪',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(pos.dx - iconPainter.width / 2, pos.dy - 6 - iconPainter.height / 2),
    );

    // White Card Pill below: "Thulirva Dairy Hub"
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Color(0xFF173F2D),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final pillWidth = textPainter.width + 20;
    final pillHeight = 28.0;
    final pillRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + 26),
      width: pillWidth,
      height: pillHeight,
    );

    // Pill background
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(14)),
      Paint()..color = Colors.white,
    );
    // Pill shadow border
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(14)),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy + 26 - textPainter.height / 2),
    );
  }

  /// Renders Destination Pin: "Customer <Area>"
  void _drawDestinationCustomerPin(Canvas canvas, Offset pos, String area) {
    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 14), width: 34, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Red Circular Badge
    final badgePaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 6), 18, badgePaint);

    // Outer border
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 6),
      18,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // House / Customer Icon
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '🏠',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(pos.dx - iconPainter.width / 2, pos.dy - 6 - iconPainter.height / 2),
    );

    // White Card Pill below: "Customer \n <Area>"
    final textSpan = TextSpan(
      children: [
        const TextSpan(
          text: 'Customer\n',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: area,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final pillWidth = textPainter.width + 24;
    final pillHeight = 36.0;
    final pillRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + 30),
      width: pillWidth,
      height: pillHeight,
    );

    // Pill background
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(12)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy + 30 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _IsometricCityPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.progress != progress ||
        oldDelegate.hubName != hubName ||
        oldDelegate.customerArea != customerArea;
  }
}

class _BuildingData {
  final Offset pos;
  final double w;
  final double l;
  final double h;

  _BuildingData(this.pos, this.w, this.l, this.h);
}
