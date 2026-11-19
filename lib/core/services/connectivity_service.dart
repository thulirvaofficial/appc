import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';

enum NetworkStatus {
  online,
  offline,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final Dio _probeDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      sendTimeout: const Duration(seconds: 4),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _statusController.stream;

  bool get isOnline => isOnlineNotifier.value;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicOfflineTimer;
  bool _isChecking = false;
  DateTime? _lastFailureReportTime;

  /// Initialize listeners
  void initialize() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(_handleInterfaceChange);

    // Initial check
    checkConnection();
  }

  void dispose() {
    _subscription?.cancel();
    _periodicOfflineTimer?.cancel();
    _statusController.close();
  }

  void _handleInterfaceChange(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) && results.length == 1) {
      _setOnlineStatus(false);
      _startPeriodicOfflineCheck();
    } else {
      // Interface changed to mobile or wifi -> verify real reachability immediately
      checkConnection();
    }
  }

  /// Called by ApiClient when any network request fails with connection error or timeout
  void reportNetworkFailure() {
    final now = DateTime.now();
    // Debounce rapid API errors
    if (_lastFailureReportTime != null &&
        now.difference(_lastFailureReportTime!).inMilliseconds < 1500) {
      return;
    }
    _lastFailureReportTime = now;
    debugPrint('🚨 [ConnectivityService] Network failure reported from API Client.');

    // Fast check to confirm offline state
    checkConnection(forceProbe: true);
  }

  /// Probes both generic internet (DNS) and backend /api/health
  Future<bool> checkConnection({bool forceProbe = false}) async {
    if (_isChecking) return isOnlineNotifier.value;
    _isChecking = true;

    try {
      // 1. Check local interface first
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        _setOnlineStatus(false);
        _startPeriodicOfflineCheck();
        return false;
      }

      // 2. Check Backend Health endpoint
      final backendOk = await _probeBackend();
      if (backendOk) {
        _setOnlineStatus(true);
        _stopPeriodicOfflineCheck();
        return true;
      }

      // 3. Fallback: check general DNS lookup
      final internetOk = await _probeInternetDns();
      if (!internetOk) {
        _setOnlineStatus(false);
        _startPeriodicOfflineCheck();
        return false;
      }

      // If internet works but backend is unreachable: still considered offline for app functionality
      _setOnlineStatus(false);
      _startPeriodicOfflineCheck();
      return false;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      _setOnlineStatus(false);
      _startPeriodicOfflineCheck();
      return false;
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _probeBackend() async {
    try {
      final healthUrl = '${ApiEndpoints.baseUrl}/health';
      final response = await _probeDio.get(healthUrl);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return true;
      }
    } catch (_) {
      // Fallback: try root server or products
      try {
        final productsUrl = '${ApiEndpoints.baseUrl}/products';
        final res = await _probeDio.get(productsUrl);
        if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 400) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<bool> _probeInternetDns() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('8.8.8.8')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  void _setOnlineStatus(bool online) {
    if (isOnlineNotifier.value != online) {
      debugPrint('🌐 [ConnectivityService] Online status changed to: $online');
      isOnlineNotifier.value = online;
      _statusController.add(online);
    }
  }

  void _startPeriodicOfflineCheck() {
    _periodicOfflineTimer?.cancel();
    _periodicOfflineTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      checkConnection();
    });
  }

  void _stopPeriodicOfflineCheck() {
    _periodicOfflineTimer?.cancel();
    _periodicOfflineTimer = null;
  }
}
