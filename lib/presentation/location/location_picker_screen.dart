import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/location_picker_provider.dart';
import 'widgets/coming_soon_view.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _isMoving = false;
  bool _showExtraFields = false;

  @override
  void dispose() {
    _searchController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _animateTo(LatLng target) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationPickerProvider);
    final notifier = ref.read(locationPickerProvider.notifier);

    // Skip native GoogleMap rendering during automated widget testing to avoid missing platform view crash
    final isTesting = Platform.environment.containsKey('FLUTTER_TEST');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 1. Google Map View
            if (!isTesting)
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialPosition ?? state.currentCenter,
                    zoom: 15.5,
                  ),
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  onCameraMoveStarted: () {
                    setState(() => _isMoving = true);
                  },
                  onCameraMove: (pos) {
                    notifier.onCameraMoved(pos.target);
                  },
                  onCameraIdle: () {
                    setState(() => _isMoving = false);
                    notifier.onCameraIdle();
                  },
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFE2F1E8),
                  child: const Center(
                    child: Text(
                      'Thulirva Google Map',
                      style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

            // 2. Fixed Center Location Pin with Floating Shadow
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      transform: Matrix4.translationValues(0, _isMoving ? -12 : 0, 0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFE5C97A),
                          size: 26,
                        ),
                      ),
                    ),
                    // Ground Pin Shadow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isMoving ? 8 : 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: _isMoving ? 0.15 : 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top Header: Back Button & Places Autocomplete Search Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Search Input Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                            decoration: InputDecoration(
                              hintText: 'Search street, building, PIN code...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.forestGreen, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        notifier.clearSearch();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (val) {
                              notifier.searchPlaces(val);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Predictions Dropdown
                  if (state.searchPredictions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: state.searchPredictions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = state.searchPredictions[idx];
                          final main = item['main_text'] ?? item['description'] ?? '';
                          final sec = item['secondary_text'] ?? '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.forestGreen, size: 20),
                            title: Text(main, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: sec.isNotEmpty ? Text(sec, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                            onTap: () async {
                              _searchController.text = main;
                              final target = await notifier.selectPrediction(item);
                              if (target != null) {
                                _animateTo(target);
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 4. Floating GPS "Use My Current Location" FAB
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 270,
              child: FloatingActionButton.extended(
                heroTag: 'gps_fab',
                backgroundColor: Colors.white,
                elevation: 3,
                icon: state.isGpsLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                      )
                    : const Icon(Icons.my_location_rounded, color: AppColors.forestGreen, size: 20),
                label: const Text(
                  'Current Location',
                  style: TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                onPressed: () async {
                  final target = await notifier.useCurrentGpsLocation();
                  if (target != null) {
                    _animateTo(target);
                  }
                },
              ),
            ),

            // 5. Bottom Location Detail & Confirmation Card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Serviceability Indicator Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildServiceabilityBadge(state),
                        if (state.matchedArea != null)
                          Text(
                            'ETA: ${state.matchedArea!.estimatedDeliveryTime}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Area & Street Heading
                    Text(
                      state.street.isNotEmpty ? state.street : state.area,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Full Formatted Address
                    Text(
                      state.formattedAddress,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Optional Landmark & Instructions Accordion
                    InkWell(
                      onTap: () => setState(() => _showExtraFields = !_showExtraFields),
                      child: Row(
                        children: [
                          Icon(
                            _showExtraFields ? Icons.remove_circle_outline : Icons.add_circle_outline,
                            size: 15,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showExtraFields ? 'Hide delivery notes' : 'Add landmark & instructions (Optional)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showExtraFields) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _landmarkController,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Landmark (e.g. Near Roundtana / Flat 4B)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _instructionsController,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Delivery instructions for rider (e.g. Ring bell, leave at door)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Primary Action Button: "SAVE LOCATION"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.isServiceable ? AppColors.forestGreen : const Color(0xFFD97706),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: state.isChecking
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                final areaName = state.area;

                                if (state.isServiceable) {
                                  // Save serviceable location
                                  await notifier.saveCurrentLocation(
                                    landmark: _landmarkController.text.trim(),
                                    deliveryInstructions: _instructionsController.text.trim(),
                                  );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Delivery location updated to $areaName!'),
                                      backgroundColor: AppColors.forestGreen,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  navigator.pop(true);
                                } else {
                                  // Show Coming Soon Experience
                                  if (!mounted) return;
                                  ComingSoonModal.show(
                                    context,
                                    areaName: areaName,
                                    onSavePreferred: () async {
                                      await notifier.saveCurrentLocation(
                                        landmark: _landmarkController.text.trim(),
                                        deliveryInstructions: _instructionsController.text.trim(),
                                      );
                                      if (mounted) {
                                        navigator.pop(true);
                                      }
                                    },
                                    onChangeLocation: () {
                                      // Focus search bar
                                    },
                                  );
                                }
                              },
                        child: Text(
                          state.isChecking
                              ? 'Checking serviceability...'
                              : state.isServiceable
                                  ? 'CONFIRM & SAVE LOCATION'
                                  : 'AREA NOT SERVICEABLE • COMING SOON',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceabilityBadge(LocationPickerState state) {
    if (state.isChecking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.forestGreen),
            ),
            SizedBox(width: 6),
            Text('Checking area...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    if (state.isServiceable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 14),
            SizedBox(width: 5),
            Text(
              'Available for Delivery',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 14),
          SizedBox(width: 5),
          Text(
            'Coming Soon to this Area',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}
