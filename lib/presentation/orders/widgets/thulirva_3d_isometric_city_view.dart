import 'package:flutter/material.dart';

/// Interactive 3D Isometric City View
/// Renders an authentic isometric 3D city scene matching the reference specification:
/// - Isometric 3D buildings with multi-tier window bands, parapets, and rooftop HVAC units
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

  static const double _canvasWidth = 1400.0;
  static const double _canvasHeight = 1000.0;

  // Key focus coordinate (around center of delivery route)
  static const double _sceneCenterX = 700.0;
  static const double _sceneCenterY = 530.0;

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
      // In landscape, fit the ~1100px corridor comfortably into the screen
      targetScale = (viewportSize.width / 1150.0).clamp(0.65, 1.25);
      offsetY = 10.0;
    } else {
      // In portrait, fit the action corridor between floating cards
      targetScale = (viewportSize.width / 750.0).clamp(0.44, 0.85);
      offsetY = viewportSize.height * 0.04;
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

        // Auto-center camera whenever viewport layout changes significantly
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

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Clean Urban Base Foundation
    final groundPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // 2. Draw Realistic Isometric Avenues, Sidewalks, and Crosswalks
    _drawStreetsAndSidewalks(canvas, size);

    // 3. Define the Smooth Delivery Route Path
    final hubPoint = Offset(size.width * 0.16, size.height * 0.68);
    final customerPoint = Offset(size.width * 0.84, size.height * 0.40);

    final routePath = Path();
    routePath.moveTo(hubPoint.dx, hubPoint.dy);

    final cp1 = Offset(size.width * 0.28, size.height * 0.66);
    final p1 = Offset(size.width * 0.36, size.height * 0.58);
    final cp2 = Offset(size.width * 0.44, size.height * 0.52);
    final p2 = Offset(size.width * 0.52, size.height * 0.50);
    final cp3 = Offset(size.width * 0.62, size.height * 0.48);
    final p3 = Offset(size.width * 0.70, size.height * 0.45);
    final cp4 = Offset(size.width * 0.76, size.height * 0.43);

    routePath.quadraticBezierTo(cp1.dx, cp1.dy, p1.dx, p1.dy);
    routePath.quadraticBezierTo(cp2.dx, cp2.dy, p2.dx, p2.dy);
    routePath.quadraticBezierTo(cp3.dx, cp3.dy, p3.dx, p3.dy);
    routePath.quadraticBezierTo(cp4.dx, cp4.dy, customerPoint.dx, customerPoint.dy);

    // 4. Render 3D Extruded Buildings with Facade Windows & Rooftop Units
    _draw3DBuildings(canvas, size);

    // 5. Render 3D Low-Poly Trees along streets and courtyards
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
      ..color = Colors.white.withValues(alpha: 0.88)
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
      ..strokeWidth = 84
      ..style = PaintingStyle.stroke;

    // Diagonal Avenues (North-West to South-East)
    for (double i = -300; i < size.width + 500; i += 210) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + 850, size.height),
        sidewalkPaint,
      );
    }
    // Cross Streets (North-East to South-West)
    for (double i = -200; i < size.width + 600; i += 220) {
      canvas.drawLine(
        Offset(i + 450, 0),
        Offset(i - 450, size.height),
        sidewalkPaint,
      );
    }

    // 2. Asphalt Road Surfaces
    final roadPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.65)
      ..strokeWidth = 52
      ..style = PaintingStyle.stroke;

    for (double i = -300; i < size.width + 500; i += 210) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + 850, size.height),
        roadPaint,
      );
    }
    for (double i = -200; i < size.width + 600; i += 220) {
      canvas.drawLine(
        Offset(i + 450, 0),
        Offset(i - 450, size.height),
        roadPaint,
      );
    }

    // 3. Crisp Curb Edges
    final curbPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (double i = -300; i < size.width + 500; i += 210) {
      canvas.drawLine(Offset(i - 26, 0), Offset(i + 850 - 26, size.height), curbPaint);
      canvas.drawLine(Offset(i + 26, 0), Offset(i + 850 + 26, size.height), curbPaint);
    }
    for (double i = -200; i < size.width + 600; i += 220) {
      canvas.drawLine(Offset(i + 450 - 26, 0), Offset(i - 450 - 26, size.height), curbPaint);
      canvas.drawLine(Offset(i + 450 + 26, 0), Offset(i - 450 + 26, size.height), curbPaint);
    }

    // 4. White Pedestrian Crosswalks (Zebra Stripes at Intersections)
    final crosswalkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final intersectionNodes = [
      const Offset(420, 480),
      const Offset(630, 470),
      const Offset(850, 460),
      const Offset(520, 680),
      const Offset(740, 670),
      const Offset(310, 290),
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
      // Top Left block (near Hub)
      _BuildingData(Offset(size.width * 0.18, size.height * 0.35), 70, 50, 65, true, true),
      _BuildingData(Offset(size.width * 0.27, size.height * 0.28), 85, 55, 95, true, true),
      _BuildingData(Offset(size.width * 0.35, size.height * 0.23), 65, 45, 55, true, false),
      _BuildingData(Offset(size.width * 0.12, size.height * 0.48), 85, 55, 75, true, true),
      _BuildingData(Offset(size.width * 0.22, size.height * 0.50), 65, 48, 50, true, false),

      // Center Top block (Skyscrapers)
      _BuildingData(Offset(size.width * 0.43, size.height * 0.30), 80, 55, 110, true, true),
      _BuildingData(Offset(size.width * 0.51, size.height * 0.26), 90, 50, 85, true, true),
      _BuildingData(Offset(size.width * 0.59, size.height * 0.22), 75, 52, 70, true, false),
      _BuildingData(Offset(size.width * 0.47, size.height * 0.42), 65, 45, 60, true, false),
      _BuildingData(Offset(size.width * 0.55, size.height * 0.38), 82, 48, 88, true, true),
      _BuildingData(Offset(size.width * 0.63, size.height * 0.34), 68, 45, 68, true, false),

      // Center Bottom block (South of route)
      _BuildingData(Offset(size.width * 0.32, size.height * 0.74), 85, 55, 65, true, false),
      _BuildingData(Offset(size.width * 0.42, size.height * 0.68), 75, 50, 75, true, true),
      _BuildingData(Offset(size.width * 0.52, size.height * 0.62), 68, 45, 55, true, false),

      // Right Top block (Destination skyline)
      _BuildingData(Offset(size.width * 0.71, size.height * 0.26), 78, 52, 90, true, true),
      _BuildingData(Offset(size.width * 0.79, size.height * 0.22), 85, 58, 105, true, true),
      _BuildingData(Offset(size.width * 0.75, size.height * 0.46), 80, 50, 80, true, true),
      _BuildingData(Offset(size.width * 0.85, size.height * 0.42), 72, 54, 65, true, false),

      // Right Bottom block
      _BuildingData(Offset(size.width * 0.63, size.height * 0.64), 78, 48, 70, true, true),
      _BuildingData(Offset(size.width * 0.72, size.height * 0.60), 68, 44, 60, true, false),
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
    // 30-degree isometric projection constants
    const cos30 = 0.8660254;
    const sin30 = 0.5;

    final dx1 = w * cos30;
    final dy1 = w * sin30;
    final dx2 = -l * cos30;
    final dy2 = l * sin30;

    final pGroundFront = base;
    final pGroundRight = Offset(base.dx + dx1, base.dy - dy1);
    final pGroundLeft = Offset(base.dx + dx2, base.dy - dy2);
    final pGroundBack = Offset(base.dx + dx1 + dx2, base.dy - dy1 - dy2);

    final pTopFront = Offset(pGroundFront.dx, pGroundFront.dy - h);
    final pTopRight = Offset(pGroundRight.dx, pGroundRight.dy - h);
    final pTopLeft = Offset(pGroundLeft.dx, pGroundLeft.dy - h);
    final pTopBack = Offset(pGroundBack.dx, pGroundBack.dy - h);

    // 1. Soft Ambient Drop Shadow on Ground
    final shadowPath = Path()
      ..moveTo(pGroundFront.dx, pGroundFront.dy)
      ..lineTo(pGroundRight.dx + 24, pGroundRight.dy + 4)
      ..lineTo(pGroundBack.dx + 34, pGroundBack.dy + 12)
      ..lineTo(pGroundLeft.dx, pGroundLeft.dy)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()..color = Colors.black.withValues(alpha: 0.05),
    );

    // 2. Left Face (Cool Ambient Shadow Face)
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

    // 3. Right Face (Sun-facing Light Surface)
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

    // 4. Top Face (Sunlit Roof Surface)
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

    // Parapet Inner Roof Inset
    final roofInset = Path()
      ..moveTo(pTopFront.dx, pTopFront.dy - 1.2)
      ..lineTo(pTopRight.dx - 2.5, pTopRight.dy)
      ..lineTo(pTopBack.dx, pTopBack.dy + 1.2)
      ..lineTo(pTopLeft.dx + 2.5, pTopLeft.dy)
      ..close();
    canvas.drawPath(
      roofInset,
      Paint()..color = const Color(0xFFF8FAFC),
    );

    // 5. Rooftop Mechanical / Elevator Penthouse Unit
    if (hasRoofUnit && h >= 65) {
      final roofCenter = Offset(
        (pTopFront.dx + pTopRight.dx + pTopBack.dx + pTopLeft.dx) / 4,
        (pTopFront.dy + pTopRight.dy + pTopBack.dy + pTopLeft.dy) / 4,
      );
      _renderRoofTopUnit(canvas, roofCenter, w * 0.32, l * 0.32, 13);
    }
  }

  void _renderRoofTopUnit(Canvas canvas, Offset base, double w, double l, double h) {
    const cos30 = 0.8660254;
    const sin30 = 0.5;

    final dx1 = w * cos30;
    final dy1 = w * sin30;
    final dx2 = -l * cos30;
    final dy2 = l * sin30;

    final pf = base;
    final pr = Offset(base.dx + dx1, base.dy - dy1);
    final pl = Offset(base.dx + dx2, base.dy - dy2);
    final pb = Offset(base.dx + dx1 + dx2, base.dy - dy1 - dy2);

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
      Offset(size.width * 0.15, size.height * 0.40),
      Offset(size.width * 0.23, size.height * 0.46),
      Offset(size.width * 0.31, size.height * 0.44),
      Offset(size.width * 0.39, size.height * 0.37),
      Offset(size.width * 0.44, size.height * 0.56),
      Offset(size.width * 0.57, size.height * 0.52),
      Offset(size.width * 0.65, size.height * 0.54),
      Offset(size.width * 0.71, size.height * 0.37),
      Offset(size.width * 0.77, size.height * 0.53),
      Offset(size.width * 0.83, size.height * 0.34),
      // Additional courtyard trees
      Offset(size.width * 0.20, size.height * 0.62),
      Offset(size.width * 0.25, size.height * 0.64),
      Offset(size.width * 0.35, size.height * 0.65),
      Offset(size.width * 0.48, size.height * 0.47),
      Offset(size.width * 0.53, size.height * 0.44),
      Offset(size.width * 0.61, size.height * 0.42),
      Offset(size.width * 0.68, size.height * 0.47),
      Offset(size.width * 0.74, size.height * 0.42),
      Offset(size.width * 0.80, size.height * 0.48),
      Offset(size.width * 0.87, size.height * 0.38),
    ];

    for (final t in treeLocations) {
      // Tree Ground Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(t.dx + 4, t.dy + 3), width: 24, height: 12),
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );

      // Tree Trunk
      canvas.drawRect(
        Rect.fromLTWH(t.dx - 2, t.dy - 9, 4, 9),
        Paint()..color = const Color(0xFF78350F),
      );

      // 3D Tree Canopy (tiered spheres for foliage depth)
      canvas.drawCircle(
        Offset(t.dx, t.dy - 17),
        13,
        Paint()..color = const Color(0xFF15803D),
      );
      canvas.drawCircle(
        Offset(t.dx - 2, t.dy - 20),
        10,
        Paint()..color = const Color(0xFF22C55E),
      );
      canvas.drawCircle(
        Offset(t.dx - 3, t.dy - 22),
        6,
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
    final pulseRadius = 26.0 + (pulseValue * 20.0);
    final pulseAlpha = (1.0 - pulseValue).clamp(0.0, 0.75);

    // Outer halo
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: pulseRadius * 2.3, height: pulseRadius * 1.15),
      Paint()
        ..color = const Color(0xFF00A859).withValues(alpha: pulseAlpha * 0.45)
        ..style = PaintingStyle.fill,
    );
    // Inner pulse ring
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: pulseRadius * 1.6, height: pulseRadius * 0.8),
      Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: pulseAlpha * 0.65)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );

    // Soft drop shadow beneath wheels
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 72, height: 22),
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

    // Front Steering Column
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

    // Handlebars & Grips with Round Rear-View Mirrors
    canvas.drawLine(
      const Offset(10, -33),
      const Offset(20, -31),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(11, -36), 1.8, Paint()..color = const Color(0xFF64748B));

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
    const boxLeft = -39.0;
    const boxTop = -46.0;
    const boxW = 24.0;
    const boxH = 24.0;

    // Rear cargo rack support metal tubes
    canvas.drawLine(
      const Offset(-24, -20),
      const Offset(boxLeft + 4, boxTop + boxH),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 2.5,
    );
    canvas.drawLine(
      const Offset(-14, -20),
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
    const pillHeight = 36.0;
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
  final bool hasWindows;
  final bool hasRoofUnit;

  _BuildingData(this.pos, this.w, this.l, this.h, [this.hasWindows = true, this.hasRoofUnit = false]);
}
