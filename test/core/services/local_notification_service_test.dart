import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:myoffgridai_client/core/services/local_notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late LocalNotificationService service;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = LocalNotificationService(plugin: mockPlugin);
  });

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });

  group('LocalNotificationService', () {
    test('isInitialized is false before initialize()', () {
      expect(service.isInitialized, isFalse);
    });

    test('initialize() sets isInitialized to true', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(null);

      await service.initialize();

      expect(service.isInitialized, isTrue);
      verify(() => mockPlugin.initialize(any())).called(1);
    });

    test('initialize() is idempotent — second call is no-op', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(null);

      await service.initialize();
      await service.initialize();

      verify(() => mockPlugin.initialize(any())).called(1);
    });

    test('showNotification() is no-op when not initialized', () async {
      await service.showNotification(
        id: 1,
        title: 'Test',
        body: 'Body',
      );

      verifyNever(() => mockPlugin.show(any(), any(), any(), any()));
    });

    test('showNotification() calls plugin.show when initialized', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(null);
      when(() => mockPlugin.show(any(), any(), any(), any(), payload: any(named: 'payload')))
          .thenAnswer((_) async {});

      await service.initialize();
      await service.showNotification(
        id: 42,
        title: 'Test Title',
        body: 'Test Body',
        payload: 'test-payload',
      );

      verify(() => mockPlugin.show(
            42,
            'Test Title',
            'Test Body',
            any(),
            payload: 'test-payload',
          )).called(1);
    });

    test('showAlertNotification() is no-op when not initialized', () async {
      const notification = NotificationModel(
        id: 'notif-1',
        title: 'Alert',
        body: 'Something happened',
        type: 'SENSOR_ALERT',
        severity: 'CRITICAL',
        isRead: false,
      );

      await service.showAlertNotification(notification);

      verifyNever(() => mockPlugin.show(any(), any(), any(), any()));
    });

    test('showAlertNotification() calls plugin.show with correct args', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(null);
      when(() => mockPlugin.show(any(), any(), any(), any(), payload: any(named: 'payload')))
          .thenAnswer((_) async {});

      await service.initialize();

      const notification = NotificationModel(
        id: 'notif-1',
        title: 'Sensor Alert',
        body: 'Temperature exceeds threshold',
        type: 'SENSOR_ALERT',
        severity: 'CRITICAL',
        isRead: false,
      );

      await service.showAlertNotification(notification);

      verify(() => mockPlugin.show(
            'notif-1'.hashCode,
            'Sensor Alert',
            'Temperature exceeds threshold',
            any(),
            payload: 'notif-1',
          )).called(1);
    });
  });
}
