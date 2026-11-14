import 'package:flutter/material.dart';

/// Interactive 3D Isometric City View
/// Renders an authentic isometric 3D city scene matching the reference specification:
/// - Mathematically exact 30-degree isometric projection grid
/// - Broad diagonal avenue running from bottom-left towards top-right
/// - Realistic isometric 3D buildings with multi-tier window bands, parapets, and rooftop HVAC units
/// - Clean isometric avenues with sidewalks, curbs, and pedestrian crosswalks
/// - Realistic low-poly 3D trees with multi-toned canopies and circular drop shadows
/// - Vibrant green Thulirva delivery route with glowing mint halo and white dashed centerline
/// - Origin "Thulirva Dairy Hub" pin and destination "Customer <Area>" pin
/// - Realistic 3D electric scooty with delivery rider wearing green uniform/helmet
/// - Signature green Thulirva delivery cargo box with brand emblem and leaf
/// - Glowing ground pulse disc beneath the scooter
/// - Interactive gestures: Pan, Zoom, Pinch with intelligent auto-framing
class Thulirva3DIsometricCityView extends StatefulWidget {
  final double progress; // 0.0 to 1.0 along the route
  final String hubName;
  final String customerArea;
  final VoidCallback? onRecenter;

  const Thulirva3DIsometricCityView({
    super.key,
    this.progress = 0.55,
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
  Size? _lastViewportSize;

  static const double _canvasWidth = 1500.0;
  static const double _canvasHeight = 950.0;

  // Key focus coordinate (around center of delivery boulevard where rider travels)
  static const double _sceneCenterX = 750.0;
  static const double _sceneCenterY = 475.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _centerCamera(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final isLandscape = viewportSize.width > viewportSize.height;
    final double targetScale;
    final double offsetY;

    if (isLandscape) {
      // In landscape, fit the action corridor comfortably into the screen
      targetScale = (viewportSize.width / 1350.0).clamp(0.60, 1.20);
      offsetY = 10.0;
    } else {
      // In portrait, fit between top & bottom cards
      targetScale = (viewportSize.width / 820.0).clamp(0.42, 0.85);
      offsetY = viewportSize.height * 0.05;
    }

    final tx = (viewportSize.width / 2.0) - (_sceneCenterX * targetScale);
    final ty = (viewportSize.height / 2.0) - (_sceneCenterY * targetScale) + offsetY;

    final matrix = Matrix4.identity();
    matrix.storage[0] = targetScale;
    matrix.storage[5] = targetScale;
    matrix.storage[12] = tx;
    matrix.storage[13] = ty;
    _transformController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastViewportSize == null ||
            (_lastViewportSize!.width - currentSize.width).abs() > 30 ||
            (_lastViewportSize!.height - currentSize.height).abs() > 30) {
          _lastViewportSize = currentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _centerCamera(currentSize);
          });
        }

        return Container(
          color: const Color(0xFFE2E8F0),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(900),
                minScale: 0.35,
                maxScale: 3.0,
                child: SizedBox(
                  width: _canvasWidth,
                  height: _canvasHeight,
                  child: CustomPaint(
                    painter: _IsometricCityPainter(
                      pulseValue: _animController.value,
                      progress: widget.progress.clamp(0.04, 0.96),
                      hubName: widget.hubName,
                      customerArea: widget.customerArea,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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

  // Mathematically exact 30-degree Isometric unit vectors
  // vAvenue (axis 1): Points North-East / Up-Right along the main boulevard
  // cos(30°) = 0.866025, -sin(30°) = -0.5
  static const double cos30 = 0.86602540378;
  static const double sin30 = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Clean Urban Base Foundation (Light Concrete / Slate)
    final groundPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // 2. Draw Realistic Isometric Avenues, Sidewalks, and Crosswalks
    _drawStreetsAndSidewalks(canvas, size);

    // 3. Define the Smooth Delivery Route Path
    // Origin Hub: Lower-Left (220, 680)
    // Merge into Main Boulevard at (380, 600)
    // Run straight up-right along main boulevard to (1040, 260)
    // Turn slightly right into customer street to (1150, 310)
    final hubPoint = const Offset(210, 675);
    final boulevardEntry = const Offset(360, 600);
    final customerTurn = const Offset(1040, 260);
    final customerPoint = const Offset(1150, 315);

    final routePath = Path();
    routePath.moveTo(hubPoint.dx, hubPoint.dy);
    // Smooth turn out of hub onto boulevard
    routePath.quadraticBezierTo(270, 655, boulevardEntry.dx, boulevardEntry.dy);
    // Straight boulevard run (exact isometric avenue)
    routePath.lineTo(customerTurn.dx, customerTurn.dy);
    // Smooth curve into customer doorstep street
    routePath.quadraticBezierTo(1090, 280, customerPoint.dx, customerPoint.dy);

    // 4. Render 3D Extruded Buildings with Facade Windows & Rooftop Units
    _draw3DBuildings(canvas, size);

    // 5. Render 3D Low-Poly Trees along sidewalks and courtyards
    _draw3DTrees(canvas, size);

    // 6. Draw Glowing Green Route Line
    // Outer Mint Glow Halo
    final glowPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.38)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, glowPaint);

    // Core Emerald Green Ribbon
    final coreRoutePaint = Paint()
      ..color = const Color(0xFF00A859)
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, coreRoutePaint);

    // Subtle White Center Dashed Line
    final whiteDashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final metrics = routePath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final totalLen = metric.length;

      // Draw route dashes
      for (double d = 0; d < totalLen; d += 18) {
        final extract = metric.extractPath(d, d + 9);
        canvas.drawPath(extract, whiteDashPaint);
      }

      // Compute Rider Position & Tangent
      final currentDist = totalLen * progress;
      final tangent = metric.getTangentForOffset(currentDist);

      if (tangent != null) {
        final riderPos = tangent.position;
        final riderAngle = tangent.angle;

        // 7. Draw 3D Rider & Scooty
        _draw3DRiderAndScooty(canvas, riderPos, riderAngle);
      }
    }

    // 8. Render Origin Pin: "Thulirva Dairy Hub"
    _drawOriginHubPin(canvas, hubPoint, hubName);

    // 9. Render Destination Pin: "Customer <Area>"
    _drawDestinationCustomerPin(canvas, customerPoint, customerArea);
  }

  /// Renders Isometric Avenues, Sidewalks, and Pedestrian Crosswalks
  void _drawStreetsAndSidewalks(Canvas canvas, Size size) {
    // 1. Broad Sidewalk Base Bands
    final sidewalkPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 78
      ..style = PaintingStyle.stroke;

    final asphaltPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.75)
      ..strokeWidth = 52
      ..style = PaintingStyle.stroke;

    final curbPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.50)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Avenues running along Axis 1 (North-East / Up-Right): slope = -tan(30°) = -0.57735
    // Equation: y - y0 = -0.57735 * (x - x0)
    // Main Delivery Boulevard: passes through (0, 780) -> (1500, 780 - 1500 * 0.57735 = -86)
    // Intercepts: y-intercepts at regular intervals
    final avenueIntercepts = [1150.0, 850.0, 550.0, 250.0];

    for (final y0 in avenueIntercepts) {
      final pStart = Offset(0, y0);
      final pEnd = Offset(size.width, y0 - size.width * (sin30 / cos30));

      // Draw Sidewalk base
      canvas.drawLine(pStart, pEnd, sidewalkPaint);
      // Draw Asphalt roadway
      canvas.drawLine(pStart, pEnd, asphaltPaint);

      // Draw Curbs
      final perpX = 39 * sin30;
      final perpY = 39 * cos30;
      canvas.drawLine(Offset(pStart.dx - perpX, pStart.dy - perpY), Offset(pEnd.dx - perpX, pEnd.dy - perpY), curbPaint);
      canvas.drawLine(Offset(pStart.dx + perpX, pStart.dy + perpY), Offset(pEnd.dx + perpX, pEnd.dy + perpY), curbPaint);
    }

    // Cross Streets running along Axis 2 (South-East / Down-Right): slope = +tan(30°) = +0.57735
    // Equation: y - y0 = +0.57735 * (x - x0)
    final crossStreetIntercepts = [-450.0, -150.0, 150.0, 450.0, 750.0];

    for (final y0 in crossStreetIntercepts) {
      final pStart = Offset(0, y0);
      final pEnd = Offset(size.width, y0 + size.width * (sin30 / cos30));

      // Draw Sidewalk base
      canvas.drawLine(pStart, pEnd, sidewalkPaint);
      // Draw Asphalt roadway
      canvas.drawLine(pStart, pEnd, asphaltPaint);

      // Draw Curbs
      final perpX = 39 * sin30;
      final perpY = -39 * cos30;
      canvas.drawLine(Offset(pStart.dx - perpX, pStart.dy - perpY), Offset(pEnd.dx - perpX, pEnd.dy - perpY), curbPaint);
      canvas.drawLine(Offset(pStart.dx + perpX, pStart.dy + perpY), Offset(pEnd.dx + perpX, pEnd.dy + perpY), curbPaint);
    }

    // White Pedestrian Crosswalks (Zebra Stripes at Intersections along Main Boulevard)
    final crosswalkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final intersectionNodes = [
      const Offset(450, 560),
      const Offset(710, 410),
      const Offset(970, 260),
      const Offset(320, 780),
      const Offset(580, 630),
      const Offset(840, 480),
    ];

    for (final node in intersectionNodes) {
      for (int s = -3; s <= 3; s++) {
        canvas.drawLine(
          Offset(node.dx + (s * 4.5) - 8, node.dy - 10),
          Offset(node.dx + (s * 4.5) + 8, node.dy + 10),
          crosswalkPaint,
        );
      }
    }
  }

  /// Renders 3D Extruded Isometric Buildings with Realistic Facades & Rooftops
  void _draw3DBuildings(Canvas canvas, Size size) {
    final buildings = [
      // 1. North-West Blocks (Above Main Boulevard - Commercial & Residential Skyline)
      // Block A (Near Hub, West)
      _BuildingData(const Offset(220, 490), 75, 55, 70, true, true),
      _BuildingData(const Offset(310, 440), 80, 50, 95, true, true),
      _BuildingData(const Offset(390, 390), 65, 45, 60, true, false),
      _BuildingData(const Offset(160, 420), 70, 48, 80, true, true),

      // Block B (Center North-West - Tall Modern Office Towers)
      _BuildingData(const Offset(480, 340), 90, 60, 120, true, true),
      _BuildingData(const Offset(570, 290), 95, 55, 105, true, true),
      _BuildingData(const Offset(660, 240), 80, 50, 85, true, false),
      _BuildingData(const Offset(540, 210), 85, 52, 95, true, true),
      _BuildingData(const Offset(630, 160), 75, 45, 75, true, false),

      // Block C (East North-West - Destination Area)
      _BuildingData(const Offset(750, 190), 85, 55, 90, true, true),
      _BuildingData(const Offset(840, 140), 90, 60, 110, true, true),
      _BuildingData(const Offset(930, 90), 75, 50, 70, true, false),
      _BuildingData(const Offset(1020, 140), 70, 45, 65, true, false),
      _BuildingData(const Offset(1110, 190), 80, 50, 85, true, true),

      // 2. South-East Blocks (Below Main Boulevard - Mid-rise & Commercial Warehouses)
      // Block D (South-West)
      _BuildingData(const Offset(380, 770), 85, 55, 65, true, false),
      _BuildingData(const Offset(470, 720), 80, 50, 75, true, true),
      _BuildingData(const Offset(560, 670), 70, 45, 55, true, false),

      // Block E (Center South-East)
      _BuildingData(const Offset(650, 620), 85, 55, 75, true, true),
      _BuildingData(const Offset(740, 570), 90, 50, 85, true, true),
      _BuildingData(const Offset(830, 520), 75, 48, 65, true, false),

      // Block F (East South-East)
      _BuildingData(const Offset(920, 470), 80, 50, 70, true, true),
      _BuildingData(const Offset(1010, 420), 85, 52, 80, true, true),
      _BuildingData(const Offset(1100, 370), 75, 46, 60, true, false),
      _BuildingData(const Offset(1190, 420), 70, 44, 55, true, false),
    ];

    for (final b in buildings) {
      _renderSingleIsometricBuilding(canvas, b.pos, b.w, b.l, b.h, b.hasWindows, b.hasRoofUnit);
    }
  }

  void _renderSingleIsometricBuilding(
    Canvas canvas,
    Offset base,
    double w,
    double l,
    double h,
    bool hasWindows,
    bool hasRoofUnit,
  ) {
    // 30-degree isometric projection vectors:
    // dx1, dy1 along axis 1 (boulevard axis)
    final dx1 = w * cos30;
    final dy1 = -w * sin30;
    // dx2, dy2 along axis 2 (cross-street axis)
    final dx2 = l * cos30;
    final dy2 = l * sin30;

    final pGroundFront = base;
    final pGroundRight = Offset(base.dx + dx2, base.dy + dy2);
    final pGroundLeft = Offset(base.dx - dx1, base.dy - dy1);
    final pGroundBack = Offset(base.dx - dx1 + dx2, base.dy - dy1 + dy2);

    final pTopFront = Offset(pGroundFront.dx, pGroundFront.dy - h);
    final pTopRight = Offset(pGroundRight.dx, pGroundRight.dy - h);
    final pTopLeft = Offset(pGroundLeft.dx, pGroundLeft.dy - h);
    final pTopBack = Offset(pGroundBack.dx, pGroundBack.dy - h);

    // 1. Soft Ambient Drop Shadow on Ground
    final shadowPath = Path()
      ..moveTo(pGroundFront.dx, pGroundFront.dy)
      ..lineTo(pGroundRight.dx + 26, pGroundRight.dy + 6)
      ..lineTo(pGroundBack.dx + 34, pGroundBack.dy + 14)
      ..lineTo(pGroundLeft.dx, pGroundLeft.dy)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );

    // 2. Left Face (Cool Shaded Side - Slate Medium)
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
    canvas.drawPath(
      leftFace,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Left Facade Window Strips
    if (hasWindows && h > 35) {
      final windowPaint = Paint()..color = const Color(0xFF64748B);
      for (double floor = 12.0; floor < h - 10; floor += 13.0) {
        final wPath = Path()
          ..moveTo(pGroundFront.dx, pGroundFront.dy - floor)
          ..lineTo(pGroundLeft.dx, pGroundLeft.dy - floor)
          ..lineTo(pGroundLeft.dx, pGroundLeft.dy - floor - 5.5)
          ..lineTo(pGroundFront.dx, pGroundFront.dy - floor - 5.5)
          ..close();
        canvas.drawPath(wPath, windowPaint);
      }
    }

    // 3. Right Face (Sun-facing Light Surface - Off-White)
    final rightFace = Path()
      ..moveTo(pGroundFront.dx, pGroundFront.dy)
      ..lineTo(pGroundRight.dx, pGroundRight.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopFront.dx, pTopFront.dy)
      ..close();
    canvas.drawPath(
      rightFace,
      Paint()..color = const Color(0xFFF1F5F9),
    );
    canvas.drawPath(
      rightFace,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Right Facade Window Strips
    if (hasWindows && h > 35) {
      final windowPaintRight = Paint()..color = const Color(0xFF94A3B8);
      for (double floor = 12.0; floor < h - 10; floor += 13.0) {
        final wPath = Path()
          ..moveTo(pGroundFront.dx, pGroundFront.dy - floor)
          ..lineTo(pGroundRight.dx, pGroundRight.dy - floor)
          ..lineTo(pGroundRight.dx, pGroundRight.dy - floor - 5.5)
          ..lineTo(pGroundFront.dx, pGroundFront.dy - floor - 5.5)
          ..close();
        canvas.drawPath(wPath, windowPaintRight);
      }
    }

    // 4. Top Face (Sunlit Roof Surface - Crisp White)
    final topFace = Path()
      ..moveTo(pTopFront.dx, pTopFront.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pTopBack.dx, pTopBack.dy)
      ..lineTo(pTopLeft.dx, pTopLeft.dy)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      topFace,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // 5. Rooftop Mechanical / Elevator Penthouse Unit
    if (hasRoofUnit && h >= 65) {
      final roofCenter = Offset(
        (pTopFront.dx + pTopRight.dx + pTopBack.dx + pTopLeft.dx) / 4,
        (pTopFront.dy + pTopRight.dy + pTopBack.dy + pTopLeft.dy) / 4,
      );
      _renderRoofTopUnit(canvas, roofCenter, w * 0.32, l * 0.32, 14);
    }
  }

  void _renderRoofTopUnit(Canvas canvas, Offset base, double w, double l, double h) {
    final dx1 = w * cos30;
    final dy1 = -w * sin30;
    final dx2 = l * cos30;
    final dy2 = l * sin30;

    final pf = base;
    final pr = Offset(base.dx + dx2, base.dy + dy2);
    final pl = Offset(base.dx - dx1, base.dy - dy1);
    final pb = Offset(base.dx - dx1 + dx2, base.dy - dy1 + dy2);

    final tpf = Offset(pf.dx, pf.dy - h);
    final tpr = Offset(pr.dx, pr.dy - h);
    final tpl = Offset(pl.dx, pl.dy - h);
    final tpb = Offset(pb.dx, pb.dy - h);

    // Unit Left Face
    final lf = Path()
      ..moveTo(pf.dx, pf.dy)
      ..lineTo(pl.dx, pl.dy)
      ..lineTo(tpl.dx, tpl.dy)
      ..lineTo(tpf.dx, tpf.dy)
      ..close();
    canvas.drawPath(lf, Paint()..color = const Color(0xFF94A3B8));

    // Unit Right Face
    final rf = Path()
      ..moveTo(pf.dx, pf.dy)
      ..lineTo(pr.dx, pr.dy)
      ..lineTo(tpr.dx, tpr.dy)
      ..lineTo(tpf.dx, tpf.dy)
      ..close();
    canvas.drawPath(rf, Paint()..color = const Color(0xFFCBD5E1));

    // Unit Top Face
    final tf = Path()
      ..moveTo(tpf.dx, tpf.dy)
      ..lineTo(tpr.dx, tpr.dy)
      ..lineTo(tpb.dx, tpb.dy)
      ..lineTo(tpl.dx, tpl.dy)
      ..close();
    canvas.drawPath(tf, Paint()..color = const Color(0xFFE2E8F0));

    // Rooftop Antenna Mast
    canvas.drawLine(
      Offset(tpb.dx, tpb.dy),
      Offset(tpb.dx, tpb.dy - 12),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.5,
    );
  }

  /// Renders 3D Low-Poly Trees with Multi-Tier Foliage & Shadows
  void _draw3DTrees(Canvas canvas, Size size) {
    final treeLocations = [
      // Sidewalk trees along Main Boulevard (North-West side)
      const Offset(350, 520),
      const Offset(420, 480),
      const Offset(490, 440),
      const Offset(560, 400),
      const Offset(630, 360),
      const Offset(700, 320),
      const Offset(770, 280),
      const Offset(840, 240),
      const Offset(910, 200),
      const Offset(980, 160),

      // Sidewalk trees along Main Boulevard (South-East side)
      const Offset(400, 640),
      const Offset(470, 600),
      const Offset(540, 560),
      const Offset(610, 520),
      const Offset(680, 480),
      const Offset(750, 440),
      const Offset(820, 400),
      const Offset(890, 360),
      const Offset(960, 320),
      const Offset(1030, 280),

      // Courtyard and park trees
      const Offset(270, 420),
      const Offset(450, 270),
      const Offset(720, 140),
      const Offset(520, 740),
      const Offset(780, 640),
      const Offset(1050, 460),
    ];

    for (final t in treeLocations) {
      // Tree Ground Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(t.dx + 4, t.dy + 3), width: 22, height: 11),
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
        Offset(t.dx - 2, t.dy - 19),
        9,
        Paint()..color = const Color(0xFF22C55E),
      );
      canvas.drawCircle(
        Offset(t.dx - 3, t.dy - 21),
        5,
        Paint()..color = const Color(0xFF86EFAC),
      );
    }
  }

  /// Renders 3D Delivery Associate on White Electric Scooter with Green Thulirva Box
  /// Matches the isometric 3/4 perspective in the master reference screenshot
  void _draw3DRiderAndScooty(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // 1. Isometric Ground Pulse Disc (Pulsing glowing mint green ring on asphalt)
    final pulseRadius = 26.0 + (pulseValue * 22.0);
    final pulseAlpha = (1.0 - pulseValue).clamp(0.0, 0.75);

    // Outer halo
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: pulseRadius * 2.4, height: pulseRadius * 1.2),
      Paint()
        ..color = const Color(0xFF00A859).withValues(alpha: pulseAlpha * 0.45)
        ..style = PaintingStyle.fill,
    );
    // Inner pulse ring
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: pulseRadius * 1.7, height: pulseRadius * 0.85),
      Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: pulseAlpha * 0.70)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );

    // Soft drop shadow beneath wheels along isometric angle
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 68, height: 20),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );

    // Rotate slightly to align with the tangent of the street avenue
    // In our coordinate system, the boulevard runs at ~ -30 degrees
    canvas.rotate(angle);

    // 2. Wheels (Rear & Front)
    final tirePaint = Paint()..color = const Color(0xFF1E293B);
    final rimPaint = Paint()..color = const Color(0xFF94A3B8);
    final hubPaint = Paint()..color = const Color(0xFFE2E8F0);

    // Rear Wheel (Center at x = -20, y = -6)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, -6), width: 17, height: 17),
      tirePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, -6), width: 10, height: 10),
      rimPaint,
    );
    canvas.drawCircle(const Offset(-20, -6), 2.5, hubPaint);

    // Front Wheel (Center at x = +22, y = -6)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(22, -6), width: 17, height: 17),
      tirePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(22, -6), width: 10, height: 10),
      rimPaint,
    );
    canvas.drawCircle(const Offset(22, -6), 2.5, hubPaint);

    // 3. Electric Scooter Chassis & Body Panels (Modern White Gloss)
    final bodyPaint = Paint()..color = const Color(0xFFF8FAFC);
    final shadowBodyPaint = Paint()..color = const Color(0xFFE2E8F0);

    // Lower Floorboard / Battery Tray
    final floorboard = Path()
      ..moveTo(-12, -6)
      ..lineTo(14, -6)
      ..lineTo(16, -12)
      ..lineTo(-10, -12)
      ..close();
    canvas.drawPath(floorboard, shadowBodyPaint);
    canvas.drawRect(
      const Rect.fromLTWH(-10, -13, 24, 3),
      Paint()..color = const Color(0xFF334155),
    );

    // Front Steering Column
    canvas.drawLine(
      const Offset(22, -6),
      const Offset(16, -26),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Front Aerodynamic Apron / Fairing
    final frontApron = Path()
      ..moveTo(12, -12)
      ..lineTo(22, -16)
      ..lineTo(18, -30)
      ..lineTo(12, -30)
      ..close();
    canvas.drawPath(frontApron, bodyPaint);

    // Headlight (Warm LED glow facing forward)
    canvas.drawCircle(
      const Offset(20, -22),
      3.0,
      Paint()..color = const Color(0xFFFEF08A),
    );

    // Handlebars & Grips with Round Rear-View Mirrors
    canvas.drawLine(
      const Offset(10, -31),
      const Offset(20, -29),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(11, -34), 1.8, Paint()..color = const Color(0xFF64748B));

    // Rear Body Fairing (Covering rear wheel)
    final rearFairing = Path()
      ..moveTo(-10, -12)
      ..lineTo(-2, -12)
      ..lineTo(-4, -20)
      ..lineTo(-26, -18)
      ..lineTo(-26, -10)
      ..close();
    canvas.drawPath(rearFairing, bodyPaint);

    // Contoured Scooter Seat (Padded Black Leather)
    final seatPath = Path()
      ..moveTo(-24, -20)
      ..lineTo(-2, -20)
      ..lineTo(2, -18)
      ..lineTo(-24, -18)
      ..close();
    canvas.drawPath(
      seatPath,
      Paint()..color = const Color(0xFF0F172A),
    );

    // 4. Delivery Associate (Rider)
    // Dark Charcoal Pants / Legs
    final legPath = Path()
      ..moveTo(-8, -20)
      ..lineTo(2, -18)
      ..lineTo(6, -12)
      ..lineTo(10, -12)
      ..lineTo(8, -9)
      ..lineTo(4, -9)
      ..lineTo(-2, -15)
      ..close();
    canvas.drawPath(
      legPath,
      Paint()..color = const Color(0xFF0F172A),
    );

    // Torso: Signature Thulirva Green Windbreaker
    final jacketPaint = Paint()..color = const Color(0xFF15803D);
    final jacketHighlight = Paint()..color = const Color(0xFF22C55E);

    final torsoPath = Path()
      ..moveTo(-8, -21)
      ..lineTo(2, -19)
      ..lineTo(6, -36)
      ..lineTo(-4, -37)
      ..close();
    canvas.drawPath(torsoPath, jacketPaint);

    // Arm extending forward to grip handlebar
    canvas.drawLine(
      const Offset(2, -34),
      const Offset(14, -30),
      Paint()
        ..color = const Color(0xFF166534)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );
    // Glove on throttle
    canvas.drawCircle(const Offset(14, -30), 2.5, Paint()..color = const Color(0xFF0F172A));

    // Green Helmet with Sunlit Visor
    canvas.drawCircle(
      const Offset(1, -45),
      9.0,
      jacketPaint,
    );
    canvas.drawCircle(
      const Offset(-1, -47),
      6.0,
      jacketHighlight,
    );
    // Aerodynamic Dark Visor (Facing forward)
    final visorPath = Path()
      ..moveTo(2, -48)
      ..lineTo(9, -45)
      ..lineTo(6, -40)
      ..lineTo(1, -42)
      ..close();
    canvas.drawPath(
      visorPath,
      Paint()..color = const Color(0xFF0F172A),
    );

    // 5. Signature Thulirva Emerald Green Cargo Delivery Box
    // Isometric 3D Cube mounted on rear carrier rack
    const boxLeft = -37.0;
    const boxTop = -44.0;
    const boxW = 24.0;
    const boxH = 24.0;

    // Rear cargo rack support metal tubes
    canvas.drawLine(
      const Offset(-22, -18),
      const Offset(boxLeft + 4, boxTop + boxH),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 2.5,
    );
    canvas.drawLine(
      const Offset(-12, -18),
      const Offset(boxLeft + boxW - 4, boxTop + boxH),
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

    // Outer white border
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

    final pillWidth = textPainter.width + 22;
    const pillHeight = 28.0;
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

  /// Renders Destination Pin: "Customer <Area>" matching reference image (pin with card on right)
  void _drawDestinationCustomerPin(Canvas canvas, Offset pos, String area) {
    // Drop shadow under pin
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 14), width: 34, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Red Circular Badge
    final badgePaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(Offset(pos.dx, pos.dy - 6), 18, badgePaint);

    // Outer white border
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

    // White Card Pill to the RIGHT of the red badge (matching reference image)
    final textSpan = TextSpan(
      children: [
        const TextSpan(
          text: 'Customer\n',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: area,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final pillWidth = textPainter.width + 24;
    const pillHeight = 36.0;
    // Position card directly to the right of the badge
    final cardCenter = Offset(pos.dx + 22 + pillWidth / 2, pos.dy - 6);
    final pillRect = Rect.fromCenter(
      center: cardCenter,
      width: pillWidth,
      height: pillHeight,
    );

    // Card drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect.shift(const Offset(0, 3)), const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Card background
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    textPainter.paint(
      canvas,
      Offset(cardCenter.dx - textPainter.width / 2, cardCenter.dy - textPainter.height / 2),
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
  final bool hasWindows;
  final bool hasRoofUnit;

  _BuildingData(this.pos, this.w, this.l, this.h, [this.hasWindows = true, this.hasRoofUnit = false]);
}
