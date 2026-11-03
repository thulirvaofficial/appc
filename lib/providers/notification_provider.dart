import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/storage_service.dart';
import '../data/models/notification_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? errorMessage;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;

  NotificationNotifier(this.ref) : super(NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = ref.read(authProvider).user;
    final ident = user?.id?.toString() ?? '1';

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.userNotifications}/$ident');
      final data = res.data;

      if (data['success'] == true && data['notifications'] != null) {
        final list = (data['notifications'] as List)
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
        state = state.copyWith(notifications: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiEndpoints.readNotification}/$id/read');

      final updated = state.notifications.map((n) {
        if (n.id == id) {
          n.isRead = true;
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authProvider).user;
    final ident = user?.id?.toString() ?? '1';
    try {
      final api = ref.read(apiClientProvider);
      await api.put('${ApiEndpoints.readNotification}/user/$ident/read-all');

      final updated = state.notifications.map((n) {
        n.isRead = true;
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> registerPushToken(String token, String platform) async {
    final user = ref.read(authProvider).user;
    await StorageService.savePushToken(token);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.registerPushToken, data: {
        'token': token,
        'platform': platform,
        'user_id': user?.id,
      });
    } catch (_) {}
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

