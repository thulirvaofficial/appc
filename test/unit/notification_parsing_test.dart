import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/notification_model.dart';

void main() {
  group('Section 16: Notification Payload Parsing Tests', () {
    test('Parses subscription expiry notification correctly', () {
      final json = {
        'id': 'NOTIF-99',
        'type': 'subscription_expiry',
        'subscription_id': 'SUB-101',
        'customer_id': '1',
        'days_remaining': 5,
        'expiry_date': '06-11-2026',
        'title': 'Subscription Expiring Soon',
        'message': 'Your milk subscription will expire in 5 days. Tap to renew.',
        'data': {
          'type': 'subscription_expiry',
          'subscription_id': 'SUB-101',
          'customer_id': '1',
          'days_remaining': 5,
        },
        'is_read': false,
        'created_at': '2026-11-01T06:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'NOTIF-99');
      expect(notif.type, 'subscription_expiry');
      expect(notif.title, 'Subscription Expiring Soon');
      expect(notif.isRead, isFalse);
      expect(notif.data?['subscription_id'], 'SUB-101');
      expect(notif.data?['days_remaining'], 5);
    });
  });
}

