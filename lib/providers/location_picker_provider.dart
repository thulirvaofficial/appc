import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/address_model.dart';
import '../data/models/serviceable_area_model.dart';
import 'address_provider.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class LocationPickerState {
  final LatLng currentCenter;
  final String formattedAddress;
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final bool isChecking;
  final bool isServiceable;
  final String serviceabilityMessage;
  final ServiceableAreaModel? matchedArea;
  final List<Map<String, dynamic>> searchPredictions;
  final bool isSearching;
  final bool isGpsLoading;
  final String? errorMessage;

  const LocationPickerState({
    this.currentCenter = const LatLng(13.0827, 80.2707), // Chennai Central default
    this.formattedAddress = 'Fetching address...',
    this.street = '',
    this.area = 'Chennai',
    this.city = 'Chennai',
    this.state = 'Tamil Nadu',
    this.pincode = '600001',
    this.isChecking = false,
    this.isServiceable = true,
    this.serviceabilityMessage = 'Checking delivery availability...',
    this.matchedArea,
    this.searchPredictions = const [],
    this.isSearching = false,
    this.isGpsLoading = false,
    this.errorMessage,
  });

  LocationPickerState copyWith({
    LatLng? currentCenter,
    String? formattedAddress,
    String? street,
    String? area,
    String? city,
    String? state,
    String? pincode,
    bool? isChecking,
    bool? isServiceable,
    String? serviceabilityMessage,
    ServiceableAreaModel? matchedArea,
    List<Map<String, dynamic>>? searchPredictions,
    bool? isSearching,
    bool? isGpsLoading,
    String? errorMessage,
  }) {
    return LocationPickerState(
      currentCenter: currentCenter ?? this.currentCenter,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      street: street ?? this.street,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isChecking: isChecking ?? this.isChecking,
      isServiceable: isServiceable ?? this.isServiceable,
      serviceabilityMessage: serviceabilityMessage ?? this.serviceabilityMessage,
      matchedArea: matchedArea ?? this.matchedArea,
      searchPredictions: searchPredictions ?? this.searchPredictions,
      isSearching: isSearching ?? this.isSearching,
      isGpsLoading: isGpsLoading ?? this.isGpsLoading,
      errorMessage: errorMessage,
    );
  }
}

class LocationPickerNotifier extends StateNotifier<LocationPickerState> {
  final Ref ref;
  Timer? _debounceTimer;
  int _requestId = 0;

  LocationPickerNotifier(this.ref) : super(const LocationPickerState()) {
    _initFromSavedLocation();
  }

  Future<void> _initFromSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('thulirva_saved_lat');
      final lng = prefs.getDouble('thulirva_saved_lng');
      final pin = prefs.getString('thulirva_saved_pin');
      final addr = prefs.getString('thulirva_saved_addr');
      final area = prefs.getString('thulirva_saved_area');

      if (lat != null && lng != null) {
        state = state.copyWith(
          currentCenter: LatLng(lat, lng),
          pincode: pin ?? '600001',
          formattedAddress: addr ?? state.formattedAddress,
          area: area ?? state.area,
        );
        checkLocationAtCenter(LatLng(lat, lng));
      } else {
        // Fallback default: Anna Nagar, Chennai (Serviceable Area)
        const defaultCenter = LatLng(13.0850, 80.2100);
        state = state.copyWith(currentCenter: defaultCenter);
        checkLocationAtCenter(defaultCenter);
      }
    } catch (_) {}
  }

  void onCameraMoved(LatLng newCenter) {
    state = state.copyWith(currentCenter: newCenter);
  }

  void onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      checkLocationAtCenter(state.currentCenter);
    });
  }

  Future<void> checkLocationAtCenter(LatLng center) async {
    final int currentId = ++_requestId;
    state = state.copyWith(isChecking: true);
    final api = ref.read(apiClientProvider);

    // 1. Reverse Geocode Coordinates
    try {
      final geoRes = await api.get(
        ApiEndpoints.reverseGeocode,
        queryParameters: {
          'lat': center.latitude,
          'lng': center.longitude,
        },
      );

      // Latest-request-wins: Discard if newer request was started
      if (currentId != _requestId) return;

      if (geoRes.data != null && geoRes.data['success'] == true) {
        final d = geoRes.data;
        state = state.copyWith(
          formattedAddress: d['address'] ?? 'Selected Location (${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)})',
          street: d['street'] ?? '',
          area: d['area'] ?? '',
          city: d['city'] ?? '',
          state: d['state'] ?? '',
          pincode: d['pincode'] ?? '',
        );
      } else {
        state = state.copyWith(
          formattedAddress: 'Selected Location (${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)})',
          street: '',
          area: '',
          city: '',
          state: '',
          pincode: '',
        );
      }
    } catch (_) {
      if (currentId != _requestId) return;
      state = state.copyWith(
        formattedAddress: 'Selected Location (${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)})',
        street: '',
        area: '',
        city: '',
        state: '',
        pincode: '',
      );
    }

    // 2. Serviceability Check against Central Backend Database
    try {
      final checkRes = await api.post(
        ApiEndpoints.checkServiceability,
        data: {
          'latitude': center.latitude,
          'longitude': center.longitude,
          'pincode': state.pincode,
        },
      );

      // Latest-request-wins: Discard if newer request was started
      if (currentId != _requestId) return;

      final cData = checkRes.data;
      if (cData != null && cData['success'] == true) {
        final isServ = cData['serviceable'] == true;
        final areaJson = cData['area'];
        final matched = areaJson != null ? ServiceableAreaModel.fromJson(areaJson) : null;

        state = state.copyWith(
          isChecking: false,
          isServiceable: isServ,
          serviceabilityMessage: cData['message'] ?? (isServ ? 'Available for Delivery' : 'Coming Soon'),
          matchedArea: matched,
        );
      } else {
        state = state.copyWith(
          isChecking: false,
          isServiceable: false,
          serviceabilityMessage: "Sorry! Thulirva is not available in your area yet. We're working hard to bring fresh dairy products to your doorstep.",
          matchedArea: null,
        );
      }
    } catch (e) {
      if (currentId != _requestId) return;
      state = state.copyWith(
        isChecking: false,
        isServiceable: false,
        serviceabilityMessage: 'Unable to verify delivery area. Please check connection.',
      );
    }
  }

  Future<void> searchPlaces(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      state = state.copyWith(searchPredictions: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(
        ApiEndpoints.locationAutocomplete,
        queryParameters: {'input': clean},
      );

      if (res.data != null && res.data['success'] == true && res.data['predictions'] is List) {
        final list = (res.data['predictions'] as List)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
        state = state.copyWith(searchPredictions: list, isSearching: false);
      } else {
        state = state.copyWith(searchPredictions: [], isSearching: false);
      }
    } catch (_) {
      state = state.copyWith(searchPredictions: [], isSearching: false);
    }
  }

  void clearSearch() {
    state = state.copyWith(searchPredictions: [], isSearching: false);
  }

  Future<LatLng?> selectPrediction(Map<String, dynamic> pred) async {
    clearSearch();
    final api = ref.read(apiClientProvider);

    // 1. If prediction has direct lat/lng
    if (pred['latitude'] != null && pred['longitude'] != null) {
      final target = LatLng(
        double.parse(pred['latitude'].toString()),
        double.parse(pred['longitude'].toString()),
      );
      state = state.copyWith(currentCenter: target);
      await checkLocationAtCenter(target);
      return target;
    }

    // 2. If prediction has place_id, query place details
    if (pred['place_id'] != null) {
      try {
        final placeRes = await api.get(
          '/serviceability/place-details',
          queryParameters: {'place_id': pred['place_id']},
        );
        if (placeRes.data != null && placeRes.data['latitude'] != null) {
          final target = LatLng(
            double.parse(placeRes.data['latitude'].toString()),
            double.parse(placeRes.data['longitude'].toString()),
          );
          state = state.copyWith(currentCenter: target);
          await checkLocationAtCenter(target);
          return target;
        }
      } catch (_) {}
    }

    // 3. Otherwise forward geocode description or main text
    try {
      final desc = pred['description'] ?? pred['main_text'] ?? pred['name'] ?? '';
      final res = await api.get(
        ApiEndpoints.reverseGeocode,
        queryParameters: {'q': desc},
      );
      if (res.data != null && res.data['latitude'] != null) {
        final target = LatLng(
          double.parse(res.data['latitude'].toString()),
          double.parse(res.data['longitude'].toString()),
        );
        state = state.copyWith(currentCenter: target);
        await checkLocationAtCenter(target);
        return target;
      }
    } catch (_) {}
    return null;
  }

  Future<LatLng?> useCurrentGpsLocation() async {
    state = state.copyWith(isGpsLoading: true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isGpsLoading: false,
          errorMessage: 'Location services are disabled. Please enable GPS in device settings.',
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isGpsLoading: false,
            errorMessage: 'Location permissions are denied.',
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isGpsLoading: false,
          errorMessage: 'Location permissions are permanently denied. Please grant permission in settings.',
        );
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final gpsLatLng = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(currentCenter: gpsLatLng, isGpsLoading: false);
      await checkLocationAtCenter(gpsLatLng);
      return gpsLatLng;
    } catch (e) {
      state = state.copyWith(isGpsLoading: false, errorMessage: 'Could not fetch current GPS location.');
      return null;
    }
  }

  Future<AddressModel> saveCurrentLocation({
    String landmark = '',
    String deliveryInstructions = '',
  }) async {
    final user = ref.read(authProvider).user;
    final addressModel = AddressModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: user?.id,
      name: (user != null && user.name.isNotEmpty) ? user.name : 'My Delivery Address',
      phone: (user != null && user.phone != null && user.phone!.isNotEmpty) ? user.phone! : '9840122334',
      address: state.formattedAddress,
      street: state.street,
      area: state.area,
      city: state.city,
      state: state.state,
      pincode: state.pincode,
      landmark: landmark,
      deliveryInstructions: deliveryInstructions,
      latitude: state.currentCenter.latitude,
      longitude: state.currentCenter.longitude,
      serviceableAreaId: state.matchedArea?.id,
      isServiceable: state.isServiceable,
      isDefault: true,
    );

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('thulirva_saved_lat', state.currentCenter.latitude);
    await prefs.setDouble('thulirva_saved_lng', state.currentCenter.longitude);
    await prefs.setString('thulirva_saved_pin', state.pincode);
    await prefs.setString('thulirva_saved_addr', state.formattedAddress);
    await prefs.setString('thulirva_saved_area', state.area);
    await prefs.setBool('thulirva_saved_serviceable', state.isServiceable);

    // Update AddressNotifier selected address
    ref.read(addressProvider.notifier).selectAddress(addressModel);

    // If logged in, save to backend
    if (user != null) {
      ref.read(addressProvider.notifier).addAddress(addressModel).catchError((_) => false);
    }

    return addressModel;
  }
}

final locationPickerProvider = StateNotifierProvider<LocationPickerNotifier, LocationPickerState>((ref) {
  return LocationPickerNotifier(ref);
});
