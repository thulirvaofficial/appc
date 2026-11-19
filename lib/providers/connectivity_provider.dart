import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/connectivity_service.dart';
import 'business_config_provider.dart';
import 'category_provider.dart';
import 'coupon_provider.dart';
import 'notification_provider.dart';
import 'order_provider.dart';
import 'product_provider.dart';
import 'settings_provider.dart';
import 'subscription_provider.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

class ConnectivityNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final ConnectivityService _service;

  ConnectivityNotifier(this._ref, this._service) : super(_service.isOnline) {
    _service.isOnlineNotifier.addListener(_onServiceStatusChanged);
  }

  void _onServiceStatusChanged() {
    final newStatus = _service.isOnline;
    if (state != newStatus) {
      state = newStatus;
      if (newStatus) {
        // Automatically refresh active data when connection is restored
        refreshAppData();
      }
    }
  }

  Future<bool> retryConnection() async {
    final success = await _service.checkConnection(forceProbe: true);
    if (success) {
      state = true;
      refreshAppData();
    }
    return success;
  }

  void refreshAppData() {
    try {
      _ref.read(productProvider.notifier).fetchProducts();
      _ref.read(categoryProvider.notifier).fetchCategories();
      _ref.read(notificationProvider.notifier).fetchNotifications();
      _ref.read(settingsProvider.notifier).fetchSettings();
      _ref.read(subscriptionProvider.notifier).fetchSubscriptions();
      _ref.read(orderProvider.notifier).fetchOrders();
      _ref.read(couponProvider.notifier).fetchCoupons();
      _ref.read(businessConfigProvider.notifier).refreshAll();
    } catch (_) {}
  }

  @override
  void dispose() {
    _service.isOnlineNotifier.removeListener(_onServiceStatusChanged);
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(ref, service);
});

