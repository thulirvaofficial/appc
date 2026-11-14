import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/routing_service.dart';
import '../../core/utils/customer_bike_marker_generator.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import 'widgets/thulirva_3d_isometric_city_view.dart';

class CustomerLiveTrackingScreen extends ConsumerStatefulWidget {
  final OrderModel initialOrder;

  const CustomerLiveTrackingScreen({
    super.key,
    required this.initialOrder,
  });

  @override
  ConsumerState<CustomerLiveTrackingScreen> createState() => _CustomerLiveTrackingScreenState();
}

class _CustomerLiveTrackingScreenState extends ConsumerState<CustomerLiveTrackingScreen> {
  GoogleMapController? _mapController;
  late OrderModel _order;
  Timer? _telemetryTimer;
  socket_io.Socket? _socket;

  // Camera & Perspective Settings (3D Isometric Master View)
  double _currentHeading = 45.0;
  double _currentTilt = 52.0;
  bool _is3dView = true;
  final bool _trafficEnabled = false;

  // View Mode: Real Google Maps 3D Live Delivery Tracking (Worldwide) vs 3D Isometric Stylized City
  bool _showIsometricCity = false;
  MapType _currentMapType = MapType.normal;

  // Custom Markers Cache
  BitmapDescriptor? _riderMarker;
  BitmapDescriptor? _hubMarker;
  BitmapDescriptor? _customerMarker;

  // Real Road Network Polyline Coordinates
  List<LatLng> _roadPolylinePoints = [];

  // Padur Farm Hub Coordinates (Single Source of Truth)
  static const LatLng _padurHubPos = LatLng(12.8025, 80.2233);

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loadCustomMarkers();
    _loadRealRoadRoute();
    _initSocket();
    _startLiveTelemetrySync();

    // Allow both portrait and landscape viewing for 3D live delivery tracking
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _mapController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _initSocket() {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    try {
      final origin = ApiEndpoints.serverRoot;
      debugPrint('[CustomerTracking] Connecting to socket server: $origin');

      _socket = socket_io.io(
        origin,
        socket_io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('[CustomerTracking] Connected to socket server');
        _joinTrackingRooms();
      });

      _socket!.onReconnect((_) {
        debugPrint('[CustomerTracking] Reconnected to socket server');
        _joinTrackingRooms();
      });

      void handleLocationEvent(dynamic data) {
        if (!mounted || data is! Map) return;
        final lat = double.tryParse(data['latitude']?.toString() ?? '');
        final lng = double.tryParse(data['longitude']?.toString() ?? '');
        final heading = double.tryParse(data['heading']?.toString() ?? '') ?? _currentHeading;

        if (lat != null && lng != null) {
          final oldLat = _order.partnerLatitude;
          final oldLng = _order.partnerLongitude;

          if (oldLat != null && oldLng != null) {
            final dLat = lat - oldLat;
            final dLng = lng - oldLng;
            if (dLat.abs() > 0.00005 || dLng.abs() > 0.00005) {
              final radians = math.atan2(dLng, dLat);
              _currentHeading = (radians * 180 / math.pi + 360) % 360;
            } else if (heading != 0) {
              _currentHeading = heading;
            }
          } else if (heading != 0) {
            _currentHeading = heading;
          }

          setState(() {
            _order = _order.copyWith(
              partnerLatitude: lat,
              partnerLongitude: lng,
            );
          });

          _loadCustomMarkers();

          if (_is3dView && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 17.5,
                  tilt: _currentTilt,
                  bearing: _currentHeading,
                ),
              ),
            );
          }
        }
      }

      _socket!.on('delivery:location_updated', handleLocationEvent);
      _socket!.on('delivery:location:update', handleLocationEvent);
      _socket!.on('partner:location:updated', handleLocationEvent);

      void handleStatusEvent(dynamic data) {
        if (!mounted || data is! Map) return;
        final newStatus = data['status']?.toString() ?? data['order_status']?.toString();
        if (newStatus != null && newStatus.isNotEmpty) {
          setState(() {
            _order = _order.copyWith(orderStatus: newStatus);
          });
          if (newStatus.toLowerCase() == 'delivered') {
            _telemetryTimer?.cancel();
          }
        }
      }

      _socket!.on('order:status_updated', handleStatusEvent);
      _socket!.on('order:status', handleStatusEvent);
      _socket!.on('delivery:in_transit', (_) => handleStatusEvent({'status': 'out_for_delivery'}));
      _socket!.on('delivery:delivered', (_) => handleStatusEvent({'status': 'delivered'}));
    } catch (e) {
      debugPrint('[CustomerTracking] Socket init error: $e');
    }
  }

  void _joinTrackingRooms() {
    if (_socket != null && _socket!.connected) {
      final orderId = _order.id.toString();
      _socket!.emit('join:order', {'orderId': orderId});
      if (_order.userId != null) {
        _socket!.emit('join:customer', {'userId': _order.userId.toString()});
      }
      debugPrint('[CustomerTracking] Joined room order_$orderId');
    }
  }

  void _toggleOrientation() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final customerArea = (_order.city.isNotEmpty
              ? _order.city
              : (_order.address.isNotEmpty ? _order.address.split(',').first : 'Thiruverkadu'))
          .trim();

      final rider = await CustomerBikeMarkerGenerator.getRiderMarker(
        heading: _currentHeading,
        isMoving: _order.orderStatus.toLowerCase() == 'out_for_delivery' ||
            _order.orderStatus.toLowerCase() == 'in_transit' ||
            _order.orderStatus.toLowerCase() == 'picked_up',
      );
      final hub = await CustomerBikeMarkerGenerator.getHubPin(name: 'Thulirva Dairy Hub');
      final customer = await CustomerBikeMarkerGenerator.getCustomerPin(area: customerArea);

      if (mounted) {
        setState(() {
          _riderMarker = rider;
          _hubMarker = hub;
          _customerMarker = customer;
        });
      }
    } catch (e) {
      debugPrint('[CustomerTracking] Error loading markers: $e');
    }
  }

  Future<void> _loadRealRoadRoute() async {
    try {
      final points = await RoutingService.getRealRoadPath(
        origin: _padurHubPos,
        destination: _resolvedCustomerPos,
        rider: _resolvedRiderPos,
      );
      if (mounted && points.isNotEmpty) {
        setState(() {
          _roadPolylinePoints = points;
        });
      }
    } catch (e) {
      debugPrint('[CustomerTracking] Error loading real road route: $e');
    }
  }

  void _startLiveTelemetrySync() {
    // 3.5-second polling for real-time GPS telemetry from centralized backend
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
      try {
        final orderId = _order.id.toString();
        final freshOrder = await ref.read(orderProvider.notifier).fetchOrderDetails(orderId);
        if (freshOrder != null && mounted) {
          final oldLat = _order.partnerLatitude;
          final oldLng = _order.partnerLongitude;

          // Compute directional heading if rider moved
          if (freshOrder.partnerLatitude != null &&
              freshOrder.partnerLongitude != null &&
              oldLat != null &&
              oldLng != null) {
            final dLat = freshOrder.partnerLatitude! - oldLat;
            final dLng = freshOrder.partnerLongitude! - oldLng;
            if (dLat.abs() > 0.00005 || dLng.abs() > 0.00005) {
              final radians = math.atan2(dLng, dLat);
              final degrees = (radians * 180 / math.pi + 360) % 360;
              _currentHeading = degrees;
              _loadCustomMarkers();
            }
          }

          setState(() {
            _order = freshOrder;
          });

          // Smoothly animate camera along with rider in 3D follow mode
          if (_is3dView &&
              _mapController != null &&
              freshOrder.partnerLatitude != null &&
              freshOrder.partnerLongitude != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(freshOrder.partnerLatitude!, freshOrder.partnerLongitude!),
                  zoom: 17.5,
                  tilt: _currentTilt,
                  bearing: _currentHeading,
                ),
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  LatLng get _resolvedCustomerPos {
    final lat = _order.latitude ?? 12.8090;
    final lng = _order.longitude ?? 80.2280;
    return LatLng(lat, lng);
  }

  LatLng get _resolvedRiderPos {
    final lat = _order.partnerLatitude ?? (_resolvedCustomerPos.latitude - 0.0045);
    final lng = _order.partnerLongitude ?? (_resolvedCustomerPos.longitude - 0.0035);
    return LatLng(lat, lng);
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((p2.latitude - p1.latitude) * p) / 2 +
        math.cos(p1.latitude * p) * math.cos(p2.latitude * p) *
            (1 - math.cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _callPartner(String? phone) async {
    final raw = phone ?? '9840515293';
    final clean = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsAppChat(String? phone) async {
    final raw = phone ?? '9840515293';
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanNumber = clean.length == 10 ? '91$clean' : clean;
    final uri = Uri.parse('https://wa.me/$cleanNumber?text=Hello%20Thulirva%20Partner,%20regarding%20my%20order%20#${_order.formattedOrderId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _recenterOnRider() {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _resolvedRiderPos,
          zoom: 17.5,
          tilt: _currentTilt,
          bearing: _currentHeading,
        ),
      ),
    );
  }

  void _toggle3dPerspective() {
    setState(() {
      _is3dView = !_is3dView;
      _currentTilt = _is3dView ? 52.0 : 0.0;
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _resolvedRiderPos,
            zoom: _is3dView ? 17.5 : 16.0,
            tilt: _currentTilt,
            bearing: _is3dView ? _currentHeading : 0.0,
          ),
        ),
      );
    }
  }

  int get _currentStageIndex {
    final s = _order.orderStatus.toLowerCase().replaceAll(' ', '_');
    if (s == 'delivered' || s == 'collected') return 3;
    if (s == 'out_for_delivery' || s == 'in_transit' || s == 'picked_up' || s == 'pickup_confirmed') return 2;
    if (s == 'preparing' || s == 'processing' || s == 'assigned') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final partner = _order;
    final partnerName = (partner.partnerName != null && partner.partnerName!.trim().isNotEmpty)
        ? partner.partnerName!
        : 'Kumar R';
    final partnerPhone = partner.partnerPhone ?? '9840515293';
    final partnerVehicle = partner.partnerVehicle ?? 'Electric Scooter • TN 09 CY 4567';
    final partnerPhoto = partner.partnerPhoto ?? '/uploads/partners/kumar_profile.png';
    final rating = partner.partnerRating ?? 4.8;

    final riderPos = _resolvedRiderPos;
    final customerPos = _resolvedCustomerPos;
    final distanceKm = _calculateDistanceKm(riderPos, customerPos);
    final etaMins = (distanceKm * 4.5).clamp(3, 30).round();

    final customerArea = (_order.city.isNotEmpty
            ? _order.city
            : (_order.address.isNotEmpty ? _order.address.split(',').first : 'Thiruverkadu'))
        .trim();

    // 1. Google Map Custom Markers
    final markers = <Marker>{
      // Origin Hub
      Marker(
        markerId: const MarkerId('padur_hub'),
        position: _padurHubPos,
        icon: _hubMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),
        infoWindow: const InfoWindow(
          title: '🌾 Thulirva Dairy Hub',
          snippet: 'Padur Cold-Chain Processing Hub',
        ),
      ),
      // Destination Customer Doorstep
      Marker(
        markerId: const MarkerId('destination'),
        position: customerPos,
        icon: _customerMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: '🏠 Delivery Address',
          snippet: '${_order.address}, ${_order.city}',
        ),
      ),
      // 3D Animated Scooty Rider
      Marker(
        markerId: const MarkerId('scooty_rider'),
        position: riderPos,
        icon: _riderMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: _currentHeading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: '🛵 $partnerName (En Route)',
          snippet: 'ETA: $etaMins min (${distanceKm.toStringAsFixed(1)} km)',
        ),
      ),
    };

    // 2. Glowing Green Real Road Network Polyline
    final activeRoute = _roadPolylinePoints.isNotEmpty
        ? _roadPolylinePoints
        : [_padurHubPos, riderPos, customerPos];

    final polylines = <Polyline>{
      // Outer Glowing Mint Green Ribbon
      Polyline(
        polylineId: const PolylineId('route_glow'),
        points: activeRoute,
        color: const Color(0x6622C55E),
        width: 11,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      // Core Emerald Green Road Path
      Polyline(
        polylineId: const PolylineId('route_core'),
        points: activeRoute,
        color: const Color(0xFF00A859),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    double routeProgress = 0.55;
    if (_currentStageIndex == 0) {
      routeProgress = 0.08;
    } else if (_currentStageIndex == 1) {
      routeProgress = 0.25;
    } else if (_currentStageIndex == 2) {
      routeProgress = 0.62;
    } else if (_currentStageIndex >= 3) {
      routeProgress = 0.95;
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Primary Live Map Engine (Real Google Maps 3D vs 3D Isometric Stylized City)
          if (_showIsometricCity)
            Positioned.fill(
              child: Thulirva3DIsometricCityView(
                progress: routeProgress,
                hubName: 'Thulirva Dairy Hub',
                customerArea: customerArea,
                onRecenter: _recenterOnRider,
              ),
            )
          else
            Positioned.fill(
              child: GoogleMap(
                mapType: _currentMapType,
                initialCameraPosition: CameraPosition(
                  target: riderPos,
                  zoom: 17.5,
                  tilt: _currentTilt,
                  bearing: _currentHeading,
                ),
                markers: markers,
                polylines: polylines,
                trafficEnabled: _trafficEnabled,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                buildingsEnabled: true,
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                  _recenterOnRider();
                },
              ),
            ),

          // 2. Floating Top Header & Action Buttons (Unified responsive single Row)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 6 : 10),
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildTopFloatingHeader()),
                const SizedBox(width: 8),
                _buildTopRightActions(),
              ],
            ),
          ),

          // 3. Floating View Mode Toggle Pill (Instant Switch between Real Google 3D & 3D Isometric View)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 62),
            left: isLandscape ? 280 : 16,
            right: isLandscape ? null : 16,
            child: Align(
              alignment: isLandscape ? Alignment.centerLeft : Alignment.center,
              child: _buildModeTogglePill(),
            ),
          ),

          // 4. Floating Delivery Partner Card (Pinned to Left Side per Reference Image)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 52 : 108),
            left: 16,
            width: isLandscape ? 250 : 240,
            child: _buildPartnerInfoCard(
              partnerName: partnerName,
              partnerPhone: partnerPhone,
              partnerVehicle: partnerVehicle,
              partnerPhoto: partnerPhoto,
              rating: rating,
              etaMins: etaMins,
              distanceKm: distanceKm,
            ),
          ),

          // 5. Floating Bottom Delivery Progress Timeline (Matching Reference Pill Card)
          Positioned(
            bottom: isLandscape ? 16 : 24,
            left: isLandscape ? 278 : 16,
            right: isLandscape ? 24 : 16,
            child: _buildBottomProgressCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFloatingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 19),
          ),
          const SizedBox(width: 6),
          Image.asset(
            'assets/images/logo/thulirva_brand_logo.png',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: Color(0xFF00A859), size: 20),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Thulirva',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00A859),
                  ),
                ),
                Text(
                  'Live Delivery Tracking',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildModeTogglePill() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillTab(
            label: '🗺️ Google 3D',
            isSelected: !_showIsometricCity,
            onTap: () {
              if (_showIsometricCity) {
                setState(() => _showIsometricCity = false);
                _recenterOnRider();
              }
            },
          ),
          const SizedBox(width: 4),
          _buildPillTab(
            label: '🏙️ 3D City',
            isSelected: _showIsometricCity,
            onTap: () {
              if (!_showIsometricCity) {
                setState(() => _showIsometricCity = true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A859) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightActions() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLandscape) ...[
          _buildCircularTopBtn(
            icon: Icons.search_rounded,
            tooltip: 'Search',
            onTap: () {},
          ),
          const SizedBox(width: 6),
        ],
        _buildCircularTopBtn(
          icon: isLandscape ? Icons.stay_current_portrait_rounded : Icons.screen_rotation_rounded,
          tooltip: isLandscape ? 'Switch to Portrait' : 'Rotate to Fullscreen Landscape (Reference View)',
          onTap: _toggleOrientation,
        ),
        const SizedBox(width: 6),
        _buildCircularTopBtn(
          icon: Icons.view_in_ar_rounded,
          tooltip: 'Toggle 3D Perspective Tilt',
          onTap: _toggle3dPerspective,
          isActive: _is3dView,
        ),
        const SizedBox(width: 6),
        _buildCircularTopBtn(
          icon: Icons.my_location_rounded,
          tooltip: 'Recenter on 3D Rider',
          onTap: _recenterOnRider,
        ),
        const SizedBox(width: 6),
        _buildCircularTopBtn(
          icon: Icons.layers_outlined,
          tooltip: 'Cycle Map Style (Google 3D / Satellite / Isometric)',
          onTap: () {
            setState(() {
              if (_showIsometricCity) {
                _showIsometricCity = false;
                _currentMapType = MapType.normal;
              } else if (_currentMapType == MapType.normal) {
                _currentMapType = MapType.hybrid;
              } else {
                _showIsometricCity = true;
              }
            });
          },
          isActive: !_showIsometricCity,
        ),
      ],
    );
  }

  Widget _buildCircularTopBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: const Color(0xFF00A859), width: 1.8) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 17,
            color: isActive ? const Color(0xFF00A859) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerInfoCard({
    required String partnerName,
    required String partnerPhone,
    required String partnerVehicle,
    required String partnerPhoto,
    required double rating,
    required int etaMins,
    required double distanceKm,
  }) {
    final photoFullUrl = ApiEndpoints.resolveImageUrl(partnerPhoto);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name & Rating + Subtitle
          Row(
            children: [
              GestureDetector(
                onTap: () => _showZoomImageDialog(photoFullUrl),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE2E8F0),
                    border: Border.all(color: const Color(0xFF00A859), width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    photoFullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/partner_kumar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF00A859),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            partnerName.isNotEmpty ? partnerName : 'Kumar R',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Delivery Partner',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // 1. Status: On the way
          Row(
            children: const [
              Icon(Icons.two_wheeler_rounded, size: 15, color: Color(0xFF00A859)),
              SizedBox(width: 8),
              Text(
                'On the way',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 2. ETA & Distance
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF00A859)),
              SizedBox(width: 8),
              Text(
                'ETA: $etaMins min (${distanceKm.toStringAsFixed(1)} km)',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Call Partner Button
          InkWell(
            onTap: () => _callPartner(partnerPhone),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: const [
                  Icon(Icons.phone_rounded, size: 15, color: Color(0xFF00A859)),
                  SizedBox(width: 8),
                  Text(
                    'Call Partner',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF00A859)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 4. Chat Button
          InkWell(
            onTap: () => _openWhatsAppChat(partnerPhone),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF00A859)),
                  SizedBox(width: 8),
                  Text(
                    'Chat',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF00A859)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomProgressCard() {
    final stageIdx = _currentStageIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildProgressStepNode(0, 'Order Confirmed', stageIdx >= 0, stageIdx == 0),
          _buildProgressDivider(stageIdx >= 1),
          _buildProgressStepNode(1, 'Preparing', stageIdx >= 1, stageIdx == 1),
          _buildProgressDivider(stageIdx >= 2),
          _buildProgressStepNode(2, 'Out for Delivery', stageIdx >= 2, stageIdx == 2),
          _buildProgressDivider(stageIdx >= 3),
          _buildProgressStepNode(3, 'Delivered', stageIdx >= 3, stageIdx == 3),
        ],
      ),
    );
  }

  Widget _buildProgressStepNode(int index, String label, bool isReached, bool isCurrent) {
    IconData icon;
    if (index == 0 || index == 1) {
      icon = Icons.check_rounded;
    } else if (index == 2) {
      icon = Icons.delivery_dining_rounded;
    } else {
      icon = Icons.inventory_2_outlined;
    }

    final isCompletedOrActive = isReached;
    final bgColor = isCompletedOrActive ? const Color(0xFF00A859) : const Color(0xFFE2E8F0);
    final iconColor = isCompletedOrActive ? Colors.white : const Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: const Color(0xFF00A859).withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: index == 2 ? 18 : 16),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isCompletedOrActive ? FontWeight.w800 : FontWeight.w600,
              color: isCompletedOrActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isActive ? const Color(0xFF00A859) : const Color(0xFFCBD5E1),
      ),
    );
  }

  void _showZoomImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/partner_kumar.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
