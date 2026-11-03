import 'package:flutter_test/flutter_test.dart';

// Standalone implementation of Section 16 & 40 Subscription Expiry Logic for unit testing
class SubscriptionExpiryScheduler {
  final Set<String> _sentReminders = {};

  bool shouldSendReminder({
    required String subId,
    required String status,
    required DateTime expiryDate,
    required DateTime currentDate,
  }) {
    // Rule: Only active subscriptions receive reminders
    if (status.toLowerCase() != 'active') return false;

    final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final expiryOnly = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final daysRemaining = expiryOnly.difference(today).inDays;

    // Rule: 0 <= days_remaining <= 5
    // Stop reminders after expiry (days_remaining < 0)
    if (daysRemaining < 0 || daysRemaining > 5) return false;

    // Rule: Maximum one expiry reminder per subscription per day (Prevent duplicates)
    final dateStr = "${today.year}-${today.month}-${today.day}";
    final key = "${subId}_$dateStr";
    if (_sentReminders.contains(key)) return false;

    _sentReminders.add(key);
    return true;
  }
}

void main() {
  group('Section 40: Subscription Expiry Scheduler Tests', () {
    final now = DateTime(2026, 11, 1);

    test('5 days remaining -> triggers notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 6);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
    });

    test('4 days remaining -> triggers notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 5);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
    });

    test('3 days remaining -> triggers notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 4);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
    });

    test('2 days remaining -> triggers notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 3);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
    });

    test('1 day remaining -> triggers notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 2);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
    });

    test('0 days remaining (expires today) -> triggers notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 1);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
    });

    test('-1 day remaining (expired yesterday) -> NO notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 10, 31);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isFalse);
    });

    test('Cancelled subscription -> NO notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 3);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Cancelled', expiryDate: expiry, currentDate: now), isFalse);
    });

    test('Paused subscription -> NO notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 3);
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Paused', expiryDate: expiry, currentDate: now), isFalse);
    });

    test('Duplicate scheduler run on same day -> NO duplicate notification', () {
      final scheduler = SubscriptionExpiryScheduler();
      final expiry = DateTime(2026, 11, 3);
      // First run triggers
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isTrue);
      // Second run on same day is blocked
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: expiry, currentDate: now), isFalse);
    });

    test('Renewed subscription (extended expiry) -> recalculates schedule and avoids old reminder', () {
      final scheduler = SubscriptionExpiryScheduler();
      final renewedExpiry = DateTime(2026, 12, 1); // 30 days away
      expect(scheduler.shouldSendReminder(subId: 'SUB-1', status: 'Active', expiryDate: renewedExpiry, currentDate: now), isFalse);
    });
  });
}

