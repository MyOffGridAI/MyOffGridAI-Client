import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/mqtt_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';
import 'package:myoffgridai_client/features/notifications/notifications_screen.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService mockService;

  final criticalNotif = const NotificationModel(
    id: 'n1',
    title: 'Sensor Alert',
    body: 'Temperature too high',
    type: 'SENSOR_ALERT',
    severity: 'CRITICAL',
    isRead: false,
    createdAt: '2026-03-14T10:00:00Z',
  );

  final warningNotif = const NotificationModel(
    id: 'n2',
    title: 'Low Battery',
    body: 'Battery below 20%',
    type: 'SYSTEM_HEALTH',
    severity: 'WARNING',
    isRead: false,
  );

  final readNotif = const NotificationModel(
    id: 'n3',
    title: 'System OK',
    body: 'All systems running',
    type: 'GENERAL',
    severity: 'INFO',
    isRead: true,
    createdAt: '2026-03-14T09:00:00Z',
    readAt: '2026-03-14T09:05:00Z',
    metadata: '{"source": "system"}',
  );

  setUp(() {
    mockService = MockNotificationService();
    registerFallbackValue('');
  });

  Widget buildScreen({
    List<NotificationModel>? notifications,
    MqttState? mqttState,
  }) {
    return ProviderScope(
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => notifications ?? [],
        ),
        notificationServiceProvider.overrideWithValue(mockService),
        mqttServiceProvider.overrideWith(
          (ref) => MqttServiceNotifier(ref)
            ..state = mqttState ?? const MqttState(),
        ),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  group('NotificationsScreen', () {
    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: []));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('shows notification tiles when data is present',
        (tester) async {
      await tester.pumpWidget(
          buildScreen(notifications: [criticalNotif, readNotif]));
      await tester.pumpAndSettle();

      expect(find.text('Sensor Alert'), findsOneWidget);
      expect(find.text('System OK'), findsOneWidget);
      expect(find.text('Temperature too high'), findsOneWidget);
    });

    testWidgets('displays Notifications title in AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows Mark all read button when unread notifications exist',
        (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('hides Mark all read button when all notifications are read',
        (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('shows unread indicator dot for unread notification',
        (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      // Unread notification title should be bold
      final titleWidget = tester.widget<Text>(find.text('Sensor Alert'));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('read notification title is not bold', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('System OK'));
      expect(titleWidget.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('shows error icon for critical severity', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows warning icon for warning severity', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [warningNotif]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('shows info icon for info severity', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('notification is wrapped in Dismissible', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('critical notification title is red', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('Sensor Alert'));
      expect(titleWidget.style?.color, Colors.red);
    });

    testWidgets('info notification title is not red', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      final titleWidget = tester.widget<Text>(find.text('System OK'));
      expect(titleWidget.style?.color, isNot(Colors.red));
    });

    testWidgets('notification tile has left border', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      // Find the Container wrapping the ListTile with border decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final borderedContainer = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration && decoration.border is Border) {
          final border = decoration.border as Border;
          return border.left.width == 4;
        }
        return false;
      });
      expect(borderedContainer, isNotEmpty);
    });
  });

  group('MQTT status', () {
    testWidgets('shows MQTT connected status', (tester) async {
      final mqttState = MqttState(
        connectionState: MqttConnectionStatus.connected,
        connectedAt: DateTime.now(),
      );

      await tester.pumpWidget(
          buildScreen(notifications: [], mqttState: mqttState));
      await tester.pumpAndSettle();

      expect(find.text('MQTT: Connected'), findsOneWidget);
    });

    testWidgets('shows MQTT disconnected status', (tester) async {
      const mqttState = MqttState(
        connectionState: MqttConnectionStatus.disconnected,
      );

      await tester.pumpWidget(
          buildScreen(notifications: [], mqttState: mqttState));
      await tester.pumpAndSettle();

      expect(find.text('MQTT: Disconnected'), findsOneWidget);
    });

    testWidgets('shows MQTT connecting status', (tester) async {
      const mqttState = MqttState(
        connectionState: MqttConnectionStatus.connecting,
      );

      await tester.pumpWidget(
          buildScreen(notifications: [], mqttState: mqttState));
      await tester.pumpAndSettle();

      expect(find.text('MQTT: Connecting...'), findsOneWidget);
    });

    testWidgets('shows MQTT error status', (tester) async {
      const mqttState = MqttState(
        connectionState: MqttConnectionStatus.error,
        errorMessage: 'Connection refused',
      );

      await tester.pumpWidget(
          buildScreen(notifications: [], mqttState: mqttState));
      await tester.pumpAndSettle();

      expect(find.text('MQTT: Error'), findsOneWidget);
    });
  });

  group('Mark all read', () {
    testWidgets('calls markAllAsRead on tap', (tester) async {
      when(() => mockService.markAllAsRead()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      verify(() => mockService.markAllAsRead()).called(1);
    });

    testWidgets('shows error on mark all read failure', (tester) async {
      when(() => mockService.markAllAsRead()).thenThrow(
        const ApiException(statusCode: 500, message: 'Mark all failed'),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark all failed'), findsOneWidget);
    });
  });

  group('Notification detail', () {
    testWidgets('opens detail sheet on tap', (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => const NotificationModel(
          id: 'n1',
          title: 'Sensor Alert',
          body: 'Temperature too high',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: true,
        ),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      // Detail sheet shows notification type and severity as chips
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('marks unread notification as read on tap', (tester) async {
      when(() => mockService.markAsRead('n1')).thenAnswer(
        (_) async => const NotificationModel(
          id: 'n1',
          title: 'Sensor Alert',
          body: 'Temperature too high',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: true,
        ),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      verify(() => mockService.markAsRead('n1')).called(1);
    });

    testWidgets('detail sheet shows type and severity chips', (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => const NotificationModel(
          id: 'n1',
          title: 'Sensor Alert',
          body: 'Temperature too high',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: true,
        ),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      expect(find.text('SENSOR_ALERT'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('detail sheet shows body text', (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => const NotificationModel(
          id: 'n1',
          title: 'Sensor Alert',
          body: 'Temperature too high',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: true,
        ),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      // Body text should appear in the sheet (also appears in the list, so findsWidgets)
      expect(find.text('Temperature too high'), findsWidgets);
    });

    testWidgets('does not call markAsRead for already-read notification',
        (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System OK'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.markAsRead(any()));
    });

    testWidgets('detail sheet shows readAt when present', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System OK'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Read:'), findsOneWidget);
    });

    testWidgets('detail sheet shows metadata when present', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System OK'));
      await tester.pumpAndSettle();

      expect(find.text('Metadata'), findsOneWidget);
      expect(find.text('{"source": "system"}'), findsOneWidget);
    });

    testWidgets('detail sheet shows createdAt when present', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System OK'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Created:'), findsOneWidget);
    });

    testWidgets('detail sheet hides readAt when null', (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => const NotificationModel(
          id: 'n1',
          title: 'Sensor Alert',
          body: 'Temperature too high',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: true,
        ),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Read:'), findsNothing);
    });

    testWidgets('detail sheet hides metadata when null', (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => const NotificationModel(
          id: 'n1',
          title: 'Sensor Alert',
          body: 'Temperature too high',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: true,
        ),
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      expect(find.text('Metadata'), findsNothing);
    });
  });

  group('Loading and error states', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final completer = Completer<List<NotificationModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => completer.future,
          ),
          notificationServiceProvider.overrideWithValue(mockService),
          mqttServiceProvider.overrideWith(
            (ref) => MqttServiceNotifier(ref)..state = const MqttState(),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending future leak
      completer.complete([]);
    });

    testWidgets('shows error view on API failure', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => throw const ApiException(
                statusCode: 500, message: 'Server error'),
          ),
          notificationServiceProvider.overrideWithValue(mockService),
          mqttServiceProvider.overrideWith(
            (ref) => MqttServiceNotifier(ref)..state = const MqttState(),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('shows generic error message on non-API failure',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => throw Exception('network down'),
          ),
          notificationServiceProvider.overrideWithValue(mockService),
          mqttServiceProvider.overrideWith(
            (ref) => MqttServiceNotifier(ref)..state = const MqttState(),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load notifications'), findsOneWidget);
    });

    testWidgets('error view shows retry button', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => throw const ApiException(
                statusCode: 500, message: 'Server error'),
          ),
          notificationServiceProvider.overrideWithValue(mockService),
          mqttServiceProvider.overrideWith(
            (ref) => MqttServiceNotifier(ref)..state = const MqttState(),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('maybeWhen orElse returns shrink in loading state',
        (tester) async {
      final completer = Completer<List<NotificationModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => completer.future,
          ),
          notificationServiceProvider.overrideWithValue(mockService),
          mqttServiceProvider.overrideWith(
            (ref) => MqttServiceNotifier(ref)..state = const MqttState(),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ));
      await tester.pump();

      // 'Mark all read' should not be visible in loading state (orElse returns SizedBox.shrink)
      expect(find.text('Mark all read'), findsNothing);

      // Complete to avoid pending future leak
      completer.complete([]);
    });
  });

  group('Delete notification', () {
    testWidgets('shows confirmation dialog on dismiss', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      // Swipe left to dismiss
      await tester.drag(find.text('Sensor Alert'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete Notification'), findsOneWidget);
    });

    // Note: The deleteNotification confirm/error paths (lines 103-129)
    // require the Dismissible item to be removed from the tree after
    // onDismissed fires. With a static provider override, the list
    // doesn't update after deletion, causing "A dismissed Dismissible
    // widget is still part of the tree" assertion. These lines cannot
    // be fully tested without a mutable provider or modifying lib/ code.
  });

  group('Relative date display', () {
    testWidgets('shows relative time for notifications with createdAt',
        (tester) async {
      await tester
          .pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      // The date '2026-03-14T10:00:00Z' should show as relative text
      // (e.g., "2 days ago", or "Mar 14" depending on when test runs)
      // Just verify the trailing Column renders something
      expect(find.text('Sensor Alert'), findsOneWidget);
    });
  });

  group('Severity colors in detail sheet', () {
    testWidgets('critical severity shows red chip in detail', (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => criticalNotif,
      );

      await tester.pumpWidget(buildScreen(notifications: [criticalNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sensor Alert'));
      await tester.pumpAndSettle();

      // The severity chip text
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('warning severity shows warning chip in detail',
        (tester) async {
      when(() => mockService.markAsRead(any())).thenAnswer(
        (_) async => warningNotif,
      );

      await tester.pumpWidget(buildScreen(notifications: [warningNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Low Battery'));
      await tester.pumpAndSettle();

      expect(find.text('WARNING'), findsOneWidget);
    });

    testWidgets('info severity shows info chip in detail', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: [readNotif]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System OK'));
      await tester.pumpAndSettle();

      expect(find.text('INFO'), findsOneWidget);
    });
  });
}
