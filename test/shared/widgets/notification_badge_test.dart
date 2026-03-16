import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/widgets/notification_badge.dart';

void main() {
  group('NotificationBadge', () {
    testWidgets('hidden when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 0,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      // Should just show the icon without the badge container
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      // No red badge text
      expect(find.text('0'), findsNothing);
    });

    testWidgets('visible with correct count when count > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 5,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ for counts over 99', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 150,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('shows exact count at boundary of 99', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 99,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.text('99'), findsOneWidget);
      expect(find.text('99+'), findsNothing);
    });

    testWidgets('shows 99+ at boundary of 100', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 100,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('shows count of 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: 1,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('hidden when count is negative', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              count: -1,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.text('-1'), findsNothing);
    });
  });
}
