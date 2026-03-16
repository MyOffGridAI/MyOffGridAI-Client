import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/mqtt_service.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';
import 'package:myoffgridai_client/features/notifications/notifications_screen.dart';

void main() {
  group('NotificationsScreen', () {
    Widget buildScreen({
      List<NotificationModel>? notifications,
      MqttState? mqttState,
    }) {
      return ProviderScope(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) => notifications ?? [],
          ),
          mqttServiceProvider.overrideWith(
            (ref) => MqttServiceNotifier(ref)
              ..state = mqttState ?? const MqttState(),
          ),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      );
    }

    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(buildScreen(notifications: []));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('shows notification tiles when data is present', (tester) async {
      final notifications = [
        const NotificationModel(
          id: 'n1',
          title: 'Alert One',
          body: 'Something happened',
          type: 'SENSOR_ALERT',
          severity: 'CRITICAL',
          isRead: false,
          createdAt: '2026-03-14T10:00:00Z',
        ),
        const NotificationModel(
          id: 'n2',
          title: 'Info Two',
          body: 'All good',
          type: 'GENERAL',
          severity: 'INFO',
          isRead: true,
          createdAt: '2026-03-14T09:00:00Z',
        ),
      ];

      await tester.pumpWidget(buildScreen(notifications: notifications));
      await tester.pumpAndSettle();

      expect(find.text('Alert One'), findsOneWidget);
      expect(find.text('Info Two'), findsOneWidget);
      expect(find.text('Something happened'), findsOneWidget);
    });

    testWidgets('shows Mark all read button when unread notifications exist',
        (tester) async {
      final notifications = [
        const NotificationModel(
          id: 'n1',
          title: 'Unread',
          body: 'Body',
          type: 'GENERAL',
          isRead: false,
        ),
      ];

      await tester.pumpWidget(buildScreen(notifications: notifications));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('hides Mark all read button when all notifications are read',
        (tester) async {
      final notifications = [
        const NotificationModel(
          id: 'n1',
          title: 'Read',
          body: 'Body',
          type: 'GENERAL',
          isRead: true,
        ),
      ];

      await tester.pumpWidget(buildScreen(notifications: notifications));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsNothing);
    });

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

    testWidgets('displays Notifications title in AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });
  });
}
