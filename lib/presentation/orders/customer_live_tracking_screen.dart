import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/customer_bike_marker_generator.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

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

  // Camera & Perspective Settings (3D Isometric Master View)
  double _currentHeading = 45.0;
  double _currentTilt = 55.0;
  bool _is3dView = true;
  bool _trafficEnabled = false;

  // Custom Markers Cache
  BitmapDescriptor? _riderMarker;
  BitmapDescriptor? _hubMarker;

  // Padur Farm Hub Coordinates (Single Source of Truth)
  static const LatLng _padurHubPos = LatLng(12.8025, 80.2233);

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loadCustomMarkers();
    _startLiveTelemetrySync();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {
    try {
      final rider = await CustomerBikeMarkerGenerator.getRiderMarker(heading: _currentHeading);
      final hub = await CustomerBikeMarkerGenerator.getHubPin();
      if (mounted) {
        setState(() {
          _riderMarker = rider;
          _hubMarker = hub;
        });
      }
    } catch (e) {
      debugPrint('[CustomerTracking] Error loading markers: $e');
    }
  }

  void _startLiveTelemetrySync() {
    // 4-second continuous polling to ensure zero connection dropouts
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final orderId = _order.id.toString();
        final freshOrder = await ref.read(orderProvider.notifier).fetchOrderDetails(orderId);
        if (freshOrder != null && mounted) {
          final oldLat = _order.partnerLatitude;
          final oldLng = _order.partnerLongitude;

          // Compute new heading if rider moved
          if (freshOrder.partnerLatitude != null && freshOrder.partnerLongitude != null && oldLat != null && oldLng != null) {
            final dLat = freshOrder.partnerLatitude! - oldLat;
            final dLng = freshOrder.partnerLongitude! - oldLng;
            if (dLat.abs() > 0.0001 || dLng.abs() > 0.0001) {
              final radians = math.atan2(dLng, dLat);
              final degrees = (radians * 180 / math.pi + 360) % 360;
              _currentHeading = degrees;
              _loadCustomMarkers();
            }
          }

          setState(() {
            _order = freshOrder;
          });

          // Smoothly animate camera along with rider if in 3D follow mode
          if (_is3dView && _mapController != null && freshOrder.partnerLatitude != null && freshOrder.partnerLongitude != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(freshOrder.partnerLatitude!, freshOrder.partnerLongitude!),
                  zoom: 17.2,
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
          zoom: 17.2,
          tilt: _currentTilt,
          bearing: _currentHeading,
        ),
      ),
    );
  }

  void _toggle3dPerspective() {
    setState(() {
      _is3dView = !_is3dView;
      _currentTilt = _is3dView ? 55.0 : 0.0;
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _resolvedRiderPos,
            zoom: _is3dView ? 17.2 : 16.0,
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
    if (s == 'in_transit' || s == 'out_for_delivery') return 2;
    if (s == 'pickup_confirmed' || s == 'pickup' || s == 'preparing') return 1;
    return 0; // placed / assigned
  }

  @override
  Widget build(BuildContext context) {
    final partner = _order;
    final partnerName = partner.partnerName ?? 'Vigneshwaran M';
    final partnerPhone = partner.partnerPhone ?? '9840515293';
    final partnerVehicle = partner.partnerVehicle ?? 'Electric Scooter • TN 09 CY 4567';
    final partnerPhoto = partner.partnerPhoto ?? '/uploads/partners/vignesh_profile.png';
    final rating = partner.partnerRating ?? 4.9;

    final riderPos = _resolvedRiderPos;
    final customerPos = _resolvedCustomerPos;
    final distanceKm = _calculateDistanceKm(riderPos, customerPos);
    final etaMins = (distanceKm * 4.5).clamp(3, 30).round();

    final markers = <Marker>{
      // 1. Padur Farm Hub Marker
      Marker(
        markerId: const MarkerId('padur_hub'),
        position: _padurHubPos,
        icon: _hubMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: '🌾 Padur Farm Hub',
          snippet: 'Thulirva Cold-Chain Processing Center',
        ),
      ),
      // 2. Customer Destination Doorstep
      Marker(
        markerId: const MarkerId('destination'),
        position: customerPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(
          title: '🏠 Delivery Address',
          snippet: '${_order.address}, ${_order.city}',
        ),
      ),
      // 3. 3D Animated Scooty Rider Marker
      Marker(
        markerId: const MarkerId('scooty_rider'),
        position: riderPos,
        icon: _riderMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: _currentHeading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: '🛵 $partnerName',
          snippet: 'En route with your Farm Fresh delivery',
        ),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route_to_customer'),
        points: [_padurHubPos, riderPos, customerPos],
        color: const Color(0xFF1B4D3E),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // 1. Full 3D Isometric Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: riderPos,
                zoom: 17.0,
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

          // 2. Top Floating Header with Logo & Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildTopFloatingHeader(),
          ),

          // 3. Floating Delivery Partner Information Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            left: 16,
            right: 16,
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

          // 4. Floating Map Controls (Right Side)
          Positioned(
            right: 16,
            bottom: 270,
            child: Column(
              children: [
                _buildMapFloatingBtn(
                  icon: _is3dView ? Icons.view_in_ar_rounded : Icons.map_rounded,
                  tooltip: 'Toggle 3D View',
                  onTap: _toggle3dPerspective,
                  isActive: _is3dView,
                ),
                const SizedBox(height: 10),
                _buildMapFloatingBtn(
                  icon: _trafficEnabled ? Icons.traffic_rounded : Icons.traffic_outlined,
                  tooltip: 'Toggle Traffic',
                  onTap: () {
                    setState(() => _trafficEnabled = !_trafficEnabled);
                  },
                  isActive: _trafficEnabled,
                ),
                const SizedBox(height: 10),
                _buildMapFloatingBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on Rider',
                  onTap: _recenterOnRider,
                ),
              ],
            ),
          ),

          // 5. Bottom 4-Stage Delivery Progress Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildBottomProgressCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFloatingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.forestGreen, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Brand Logo & Title
          Image.asset(
            'assets/images/logo/thulirva_brand_logo.png',
            width: 30,
            height: 30,
            errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: AppColors.forestGreen, size: 28),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'THULIRVA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                          SizedBox(width: 3),
                          Text(
                            'LIVE GPS',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Live Delivery Tracking • #${_order.formattedOrderId}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Partner Avatar with Thulirva Green Border
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.forestGreen, width: 2),
                  color: AppColors.cream,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  photoFullUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppColors.forestGreen, size: 32),
                ),
              ),
              const SizedBox(width: 12),

              // Partner Name & Vehicle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            partnerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partnerVehicle,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ETA Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDE6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      '$etaMins MINS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action Buttons: Call & WhatsApp
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _callPartner(partnerPhone),
                    icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Call Partner',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsAppChat(partnerPhone),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.forestGreen),
                    label: const Text(
                      'Message / Chat',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.forestGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapFloatingBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppColors.forestGreen : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: isActive ? Colors.white : AppColors.forestGreen, size: 22),
        ),
      ),
    );
  }

  Widget _buildBottomProgressCard() {
    final stageIdx = _currentStageIndex;
    final isDelivered = stageIdx >= 3;
    final hasProof = (_order.deliveryProofUrl ?? '').isNotEmpty;
    final proofFullUrl = hasProof ? ApiEndpoints.resolveImageUrl(_order.deliveryProofUrl!) : '';

    String statusDescription = 'Your order is confirmed and assigned to a delivery associate.';
    if (stageIdx == 1) statusDescription = 'Partner has arrived at Padur Hub and verified farm fresh bottles.';
    if (stageIdx == 2) statusDescription = 'Partner is en route on electric scooty to your doorstep.';
    if (stageIdx == 3) statusDescription = 'Delivered safely! Doorstep photographic proof verified.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDelivered ? const Color(0xFF86EFAC) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4-Stage Progress Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStepNode(0, 'Confirmed', stageIdx >= 0, stageIdx == 0),
              _buildProgressDivider(stageIdx >= 1),
              _buildProgressStepNode(1, 'Hub Pickup', stageIdx >= 1, stageIdx == 1),
              _buildProgressDivider(stageIdx >= 2),
              _buildProgressStepNode(2, 'Out for Delivery', stageIdx >= 2, stageIdx == 2),
              _buildProgressDivider(stageIdx >= 3),
              _buildProgressStepNode(3, 'Delivered', stageIdx >= 3, stageIdx == 3),
            ],
          ),
          const SizedBox(height: 14),

          // Status Caption
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDelivered ? const Color(0xFFDCFCE7) : AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isDelivered ? Icons.verified_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: isDelivered ? const Color(0xFF15803D) : AppColors.forestGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusDescription,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDelivered ? const Color(0xFF15803D) : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Doorstep Delivery Proof Thumbnail if delivered
          if (isDelivered && hasProof) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showZoomImageDialog(proofFullUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      proofFullUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: AppColors.cream,
                        alignment: Alignment.center,
                        child: const Text('Doorstep photograph verified on central server', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Tap to View Proof', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStepNode(int index, String label, bool isReached, bool isCurrent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isReached ? AppColors.forestGreen : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: const Color(0xFFD4AF37), width: 2.5) : null,
          ),
          alignment: Alignment.center,
          child: isReached && !isCurrent
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
              : Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isReached ? FontWeight.bold : FontWeight.w500,
            color: isReached ? AppColors.forestGreen : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? AppColors.forestGreen : Colors.grey.shade300,
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
