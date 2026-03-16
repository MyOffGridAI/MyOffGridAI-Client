import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/insight_model.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/insight_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';
import 'package:myoffgridai_client/features/insights/insights_screen.dart';

class MockInsightService extends Mock implements InsightService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockInsightService mockInsightService;
  late MockNotificationService mockNotifService;

  final unreadInsight = InsightModel.fromJson({
    'id': '1',
    'content': 'Solar efficiency dropping',
    'category': 'MAINTENANCE',
    'isRead': false,
    'isDismissed': false,
  });

  final readInsight = InsightModel.fromJson({
    'id': '2',
    'content': 'Battery health looks good',
    'category': 'HEALTH',
    'isRead': true,
    'isDismissed': false,
  });

  final securityInsight = InsightModel.fromJson({
    'id': '3',
    'content': 'Fortress has been active for 30 days',
    'category': 'SECURITY',
    'isRead': false,
    'isDismissed': false,
  });

  final unreadNotif = const NotificationModel(
    id: 'n1',
    title: 'Sensor Alert',
    body: 'Temperature too high',
    type: 'ALERT',
    severity: 'WARNING',
    isRead: false,
  );

  final readNotif = const NotificationModel(
    id: 'n2',
    title: 'System OK',
    body: 'All systems running',
    type: 'SUCCESS',
    severity: 'INFO',
    isRead: true,
  );

  setUp(() {
    mockInsightService = MockInsightService();
    mockNotifService = MockNotificationService();
    registerFallbackValue('');
  });

  Widget buildScreen({
    List<InsightModel> insights = const [],
    List<NotificationModel> notifications = const [],
  }) {
    return ProviderScope(
      overrides: [
        insightsProvider.overrideWith((ref) => insights),
        notificationsProvider.overrideWith((ref) => notifications),
        insightServiceProvider.overrideWithValue(mockInsightService),
        notificationServiceProvider.overrideWithValue(mockNotifService),
      ],
      child: const MaterialApp(home: InsightsScreen()),
    );
  }

  group('InsightsScreen tabs', () {
    testWidgets('shows tab bar with Insights and Notifications',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsWidgets);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsWidgets);
    });

    testWidgets('shows generate insights button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });

  group('Insights tab', () {
    testWidgets('shows empty state for insights tab', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No insights yet'), findsOneWidget);
    });

    testWidgets('displays insights list', (tester) async {
      await tester.pumpWidget(
          buildScreen(insights: [unreadInsight, readInsight]));
      await tester.pumpAndSettle();

      expect(find.text('Solar efficiency dropping'), findsOneWidget);
      expect(find.text('Battery health looks good'), findsOneWidget);
    });

    testWidgets('shows category text', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [unreadInsight]));
      await tester.pumpAndSettle();

      expect(find.text('MAINTENANCE'), findsOneWidget);
    });

    testWidgets('shows check button for unread insight', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [unreadInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides check button for read insight', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [readInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('mark as read calls service', (tester) async {
      when(() => mockInsightService.markAsRead('1')).thenAnswer(
        (_) async => InsightModel.fromJson({
          'id': '1',
          'content': 'Solar efficiency dropping',
          'category': 'MAINTENANCE',
          'isRead': true,
          'isDismissed': false,
        }),
      );

      await tester.pumpWidget(buildScreen(insights: [unreadInsight]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(() => mockInsightService.markAsRead('1')).called(1);
    });

    testWidgets('shows security icon for SECURITY category', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [securityInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('shows build icon for MAINTENANCE category', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [unreadInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('shows favorite icon for HEALTH category', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [readInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('insight is wrapped in Dismissible', (tester) async {
      await tester.pumpWidget(buildScreen(insights: [unreadInsight]));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });
  });

  group('Insights error state', () {
    testWidgets('shows API error for insights', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) =>
              throw const ApiException(
                  statusCode: 500, message: 'Insights error')),
          notificationsProvider.overrideWith((ref) => <NotificationModel>[]),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load insights'), findsOneWidget);
      expect(find.text('Insights error'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception in insights',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider
              .overrideWith((ref) => throw Exception('unknown')),
          notificationsProvider.overrideWith((ref) => <NotificationModel>[]),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on insights error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          notificationsProvider.overrideWith((ref) => <NotificationModel>[]),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Notifications error state', () {
    testWidgets('shows API error for notifications', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) => <InsightModel>[]),
          notificationsProvider.overrideWith((ref) =>
              throw const ApiException(
                  statusCode: 500, message: 'Notif error')),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      // Switch to Notifications tab
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
      expect(find.text('Notif error'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception in notifications',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) => <InsightModel>[]),
          notificationsProvider
              .overrideWith((ref) => throw Exception('unknown')),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });
  });

  group('Category icons', () {
    testWidgets('shows eco icon for SUSTAINABILITY', (tester) async {
      final sustainInsight = InsightModel.fromJson({
        'id': '4',
        'content': 'Sustainability tip',
        'category': 'SUSTAINABILITY',
        'isRead': false,
        'isDismissed': false,
      });

      await tester.pumpWidget(buildScreen(insights: [sustainInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.eco), findsOneWidget);
    });

    testWidgets('shows calendar icon for PLANNING', (tester) async {
      final planningInsight = InsightModel.fromJson({
        'id': '5',
        'content': 'Planning suggestion',
        'category': 'PLANNING',
        'isRead': false,
        'isDismissed': false,
      });

      await tester.pumpWidget(buildScreen(insights: [planningInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows speed icon for EFFICIENCY', (tester) async {
      final effInsight = InsightModel.fromJson({
        'id': '6',
        'content': 'Efficiency note',
        'category': 'EFFICIENCY',
        'isRead': false,
        'isDismissed': false,
      });

      await tester.pumpWidget(buildScreen(insights: [effInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('shows lightbulb icon for unknown category', (tester) async {
      final unknownInsight = InsightModel.fromJson({
        'id': '7',
        'content': 'Unknown category insight',
        'category': 'UNKNOWN',
        'isRead': false,
        'isDismissed': false,
      });

      await tester.pumpWidget(buildScreen(insights: [unknownInsight]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    });
  });

  group('Notification type colors', () {
    testWidgets('shows info icon for unknown type', (tester) async {
      final infoNotif = const NotificationModel(
        id: 'n3',
        title: 'Info',
        body: 'Information notice',
        type: 'INFO',
        severity: 'INFO',
        isRead: false,
      );

      await tester.pumpWidget(buildScreen(notifications: [infoNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });

  group('Notification mark read', () {
    testWidgets('mark read calls service', (tester) async {
      when(() => mockNotifService.markAsRead('n1'))
          .thenAnswer((_) async => unreadNotif);

      await tester
          .pumpWidget(buildScreen(notifications: [unreadNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      verify(() => mockNotifService.markAsRead('n1')).called(1);
    });
  });

  group('Generate insights', () {
    testWidgets('calls generateInsights on button tap', (tester) async {
      when(() => mockInsightService.generateInsights())
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      verify(() => mockInsightService.generateInsights()).called(1);
      expect(find.text('Insights generated'), findsOneWidget);
    });

    testWidgets('shows error on generate failure', (tester) async {
      when(() => mockInsightService.generateInsights()).thenThrow(
        const ApiException(statusCode: 500, message: 'Generation failed'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(find.text('Generation failed'), findsOneWidget);
    });
  });

  group('Notifications tab', () {
    testWidgets('shows empty state for notifications', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Switch to Notifications tab
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('displays notification list', (tester) async {
      await tester.pumpWidget(
          buildScreen(notifications: [unreadNotif, readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Sensor Alert'), findsOneWidget);
      expect(find.text('System OK'), findsOneWidget);
    });

    testWidgets('shows Mark All as Read button', (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [unreadNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Mark All as Read'), findsOneWidget);
    });

    testWidgets('mark all as read calls service', (tester) async {
      when(() => mockNotifService.markAllAsRead())
          .thenAnswer((_) async {});

      await tester
          .pumpWidget(buildScreen(notifications: [unreadNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark All as Read'));
      await tester.pumpAndSettle();

      verify(() => mockNotifService.markAllAsRead()).called(1);
    });

    testWidgets('shows check button for unread notification', (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [unreadNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides check button for read notification', (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('notification tile is wrapped in Dismissible', (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [unreadNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });
  });

  group('Notification type icons', () {
    testWidgets('shows warning icon for ALERT type', (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [unreadNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('shows warning_amber icon for WARNING type', (tester) async {
      const warningNotif = NotificationModel(
        id: 'n4',
        title: 'Warning',
        body: 'Low battery warning',
        type: 'WARNING',
        severity: 'WARNING',
        isRead: false,
      );

      await tester
          .pumpWidget(buildScreen(notifications: [warningNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('shows error icon for ERROR type', (tester) async {
      const errorNotif = NotificationModel(
        id: 'n5',
        title: 'Error',
        body: 'System error occurred',
        type: 'ERROR',
        severity: 'CRITICAL',
        isRead: false,
      );

      await tester
          .pumpWidget(buildScreen(notifications: [errorNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows check_circle icon for SUCCESS type', (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('Insights loading state', () {
    testWidgets('shows loading indicator while insights load', (tester) async {
      final completer = Completer<List<InsightModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) => completer.future),
          notificationsProvider.overrideWith((ref) => <NotificationModel>[]),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(<InsightModel>[]);
    });

    testWidgets('insights retry button triggers reload', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          notificationsProvider.overrideWith((ref) => <NotificationModel>[]),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should still show error (provider re-throws)
      expect(find.text('Failed to load insights'), findsOneWidget);
    });
  });

  group('Notifications loading state', () {
    testWidgets('notifications retry button triggers reload', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          insightsProvider.overrideWith((ref) => <InsightModel>[]),
          notificationsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          insightServiceProvider.overrideWithValue(mockInsightService),
          notificationServiceProvider.overrideWithValue(mockNotifService),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
    });
  });
}
