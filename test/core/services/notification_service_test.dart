import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/services/notification_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late NotificationService service;

  setUp(() {
    mockClient = MockApiClient();
    service = NotificationService(client: mockClient);
  });

  group('listNotifications', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'n1',
                'title': 'Sensor Alert',
                'body': 'Temperature exceeded threshold',
                'type': 'SENSOR_ALERT',
                'severity': 'WARNING',
                'isRead': false,
                'createdAt': '2026-03-15T10:00:00Z',
              },
              {
                'id': 'n2',
                'title': 'System Update',
                'body': 'Model updated successfully',
                'type': 'MODEL_UPDATE',
                'severity': 'INFO',
                'isRead': true,
                'createdAt': '2026-03-14T08:00:00Z',
                'readAt': '2026-03-14T09:00:00Z',
              },
            ],
          });

      final result = await service.listNotifications();

      expect(result, hasLength(2));
      expect(result[0].id, 'n1');
      expect(result[0].title, 'Sensor Alert');
      expect(result[0].type, 'SENSOR_ALERT');
      expect(result[0].severity, 'WARNING');
      expect(result[0].isRead, isFalse);
      expect(result[1].isRead, isTrue);
      expect(result[1].type, 'MODEL_UPDATE');
    });

    test('passes default query params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listNotifications();

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['unreadOnly'], isFalse);
      expect(params['page'], 0);
      expect(params['size'], 20);
    });

    test('passes unreadOnly filter and custom pagination', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listNotifications(unreadOnly: true, page: 1, size: 50);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['unreadOnly'], isTrue);
      expect(params['page'], 1);
      expect(params['size'], 50);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listNotifications();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listNotifications(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('markAsRead', () {
    test('sends PUT and returns updated notification', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/n1/read',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'n1',
              'title': 'Sensor Alert',
              'body': 'Temperature exceeded threshold',
              'type': 'SENSOR_ALERT',
              'severity': 'WARNING',
              'isRead': true,
              'createdAt': '2026-03-15T10:00:00Z',
              'readAt': '2026-03-16T08:00:00Z',
            },
          });

      final result = await service.markAsRead('n1');

      expect(result.id, 'n1');
      expect(result.isRead, isTrue);
      expect(result.readAt, '2026-03-16T08:00:00Z');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/n1/read',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/bad-id/read',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Notification not found',
      ));

      expect(
        () => service.markAsRead('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('markAllAsRead', () {
    test('calls PUT on read-all endpoint', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/read-all',
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.markAllAsRead();

      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/read-all',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/read-all',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      expect(
        () => service.markAllAsRead(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deleteNotification', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.notificationsBasePath}/n1',
          )).thenAnswer((_) async {});

      await service.deleteNotification('n1');

      verify(() => mockClient.delete(
            '${AppConstants.notificationsBasePath}/n1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.notificationsBasePath}/n1',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.deleteNotification('n1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getUnreadCount', () {
    test('returns count from map data', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': {'unreadCount': 5},
          });

      final result = await service.getUnreadCount();

      expect(result, 5);
    });

    test('returns 0 when unreadCount is null in map', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final result = await service.getUnreadCount();

      expect(result, 0);
    });

    test('returns data directly when it is an int', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': 3,
          });

      final result = await service.getUnreadCount();

      expect(result, 3);
    });

    test('returns 0 when data is not a map or int', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': 'unexpected',
          });

      final result = await service.getUnreadCount();

      expect(result, 0);
    });

    test('returns 0 when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {'data': null});

      final result = await service.getUnreadCount();

      expect(result, 0);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenThrow(const ApiException(
        statusCode: 401,
        message: 'Unauthorized',
      ));

      expect(
        () => service.getUnreadCount(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('notificationServiceProvider', () {
    test('creates NotificationService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(notificationServiceProvider);
      expect(service, isA<NotificationService>());
    });
  });

  group('notificationsProvider', () {
    test('returns notifications from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.notificationsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'n1',
                'title': 'Test',
                'body': 'Body',
                'type': 'GENERAL',
                'isRead': false,
              },
            ],
          });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);

      final notifications = await container.read(notificationsProvider.future);
      expect(notifications, hasLength(1));
      expect(notifications.first.id, 'n1');
    });
  });

  group('notificationsUnreadCountProvider', () {
    test('yields unread count from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': {'unreadCount': 7},
          });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);

      final count =
          await container.read(notificationsUnreadCountProvider.future);
      expect(count, 7);
    });

    test('yields 0 when getUnreadCount throws', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);

      final count =
          await container.read(notificationsUnreadCountProvider.future);
      expect(count, 0);
    });
  });
}
