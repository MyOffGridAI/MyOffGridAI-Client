import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/insight_model.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/insight_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';
import 'package:myoffgridai_client/features/insights/insights_screen.dart';

void main() {
  group('InsightsScreen', () {
    Widget buildScreen({
      List<InsightModel> insights = const [],
      List<NotificationModel> notifications = const [],
    }) {
      return ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) => insights),
          notificationsProvider.overrideWith((ref) => notifications),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      );
    }

    testWidgets('shows tab bar with Insights and Notifications', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsWidgets);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows empty state for insights tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No insights yet'), findsOneWidget);
    });

    testWidgets('displays insights list', (tester) async {
      final insights = [
        InsightModel.fromJson({
          'id': '1',
          'content': 'Solar efficiency dropping',
          'category': 'MAINTENANCE',
          'isRead': false,
          'isDismissed': false,
        }),
      ];

      await tester.pumpWidget(buildScreen(insights: insights));
      await tester.pumpAndSettle();

      expect(find.text('Solar efficiency dropping'), findsOneWidget);
    });

    testWidgets('shows generate insights button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Title appears in app bar
      expect(find.text('Insights'), findsWidgets);
    });
  });
}
