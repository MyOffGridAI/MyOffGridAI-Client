import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('formatRelative returns "just now" for recent times', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), 'just now');
    });

    test('formatRelative returns minutes ago', () {
      final fiveAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatRelative(fiveAgo), '5 minutes ago');
    });

    test('formatRelative returns hours ago', () {
      final threeHoursAgo =
          DateTime.now().subtract(const Duration(hours: 3));
      expect(DateFormatter.formatRelative(threeHoursAgo), '3 hours ago');
    });

    test('formatRelative returns Yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.formatRelative(yesterday), 'Yesterday');
    });

    test('formatRelative returns days ago for 2-6 days', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.formatRelative(threeDaysAgo), '3 days ago');

      final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
      expect(DateFormatter.formatRelative(sixDaysAgo), '6 days ago');
    });

    test('formatRelative returns short date for 7+ days', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final result = DateFormatter.formatRelative(oldDate);
      // Should be a short date like "Mar 4"
      expect(result, isNotEmpty);
      expect(result, isNot('Yesterday'));
      expect(result, isNot(contains('ago')));
    });

    test('formatFull returns full date-time', () {
      final dt = DateTime(2026, 3, 14, 15, 45);
      final result = DateFormatter.formatFull(dt);
      expect(result, contains('March 14, 2026'));
      expect(result, contains('3:45 PM'));
    });

    test('formatDate returns short date', () {
      final dt = DateTime(2026, 3, 14);
      expect(DateFormatter.formatDate(dt), 'Mar 14, 2026');
    });
  });
}
