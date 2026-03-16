import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/services/event_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late EventService service;

  setUp(() {
    mockClient = MockApiClient();
    service = EventService(client: mockClient);
  });

  group('listEvents', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'ev1',
                'name': 'Daily Solar Check',
                'description': 'Check solar panel output',
                'eventType': 'RECURRING',
                'isEnabled': true,
                'cronExpression': '0 8 * * *',
                'actionType': 'AI_PROMPT',
                'actionPayload': 'Summarize solar output for yesterday',
                'nextFireAt': '2026-03-17T08:00:00Z',
                'createdAt': '2026-03-01T10:00:00Z',
              },
              {
                'id': 'ev2',
                'name': 'Temperature Alert',
                'eventType': 'SENSOR_THRESHOLD',
                'isEnabled': true,
                'sensorId': 'sensor-1',
                'thresholdOperator': 'ABOVE',
                'thresholdValue': 35.0,
                'actionType': 'PUSH_NOTIFICATION',
                'actionPayload': 'Temperature is too high!',
                'createdAt': '2026-03-05T14:00:00Z',
              },
            ],
          });

      final result = await service.listEvents();

      expect(result, hasLength(2));
      expect(result[0].id, 'ev1');
      expect(result[0].name, 'Daily Solar Check');
      expect(result[0].eventType, 'RECURRING');
      expect(result[0].isEnabled, isTrue);
      expect(result[0].cronExpression, '0 8 * * *');
      expect(result[0].actionType, 'AI_PROMPT');
      expect(result[1].eventType, 'SENSOR_THRESHOLD');
      expect(result[1].thresholdOperator, 'ABOVE');
      expect(result[1].thresholdValue, 35.0);
    });

    test('passes default pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listEvents();

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 0);
      expect(params['size'], 100);
    });

    test('passes custom pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listEvents(page: 1, size: 10);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 1);
      expect(params['size'], 10);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listEvents();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listEvents(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getEvent', () {
    test('returns parsed event', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/ev1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'ev1',
              'name': 'Daily Solar Check',
              'eventType': 'RECURRING',
              'isEnabled': true,
              'cronExpression': '0 8 * * *',
              'actionType': 'AI_PROMPT',
              'actionPayload': 'Summarize solar output',
            },
          });

      final result = await service.getEvent('ev1');

      expect(result.id, 'ev1');
      expect(result.name, 'Daily Solar Check');
      expect(result.eventType, 'RECURRING');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/bad-id',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Event not found',
      ));

      expect(
        () => service.getEvent('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('createEvent', () {
    test('sends POST with body and returns created event', () async {
      final body = <String, dynamic>{
        'name': 'New Event',
        'eventType': 'SCHEDULED',
        'actionType': 'PUSH_NOTIFICATION',
        'actionPayload': 'Reminder!',
      };

      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'ev-new',
              'name': 'New Event',
              'eventType': 'SCHEDULED',
              'isEnabled': true,
              'actionType': 'PUSH_NOTIFICATION',
              'actionPayload': 'Reminder!',
              'createdAt': '2026-03-16T12:00:00Z',
            },
          });

      final result = await service.createEvent(body);

      expect(result.id, 'ev-new');
      expect(result.name, 'New Event');
      expect(result.eventType, 'SCHEDULED');
      verify(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            data: any(named: 'data'),
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            AppConstants.eventsBasePath,
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Validation failed',
      ));

      expect(
        () => service.createEvent({'name': ''}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateEvent', () {
    test('sends PUT with body and returns updated event', () async {
      final body = <String, dynamic>{
        'name': 'Updated Event',
        'isEnabled': false,
      };

      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/ev1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'ev1',
              'name': 'Updated Event',
              'eventType': 'RECURRING',
              'isEnabled': false,
              'cronExpression': '0 8 * * *',
              'actionType': 'AI_PROMPT',
              'actionPayload': 'Summarize solar output',
              'updatedAt': '2026-03-16T13:00:00Z',
            },
          });

      final result = await service.updateEvent('ev1', body);

      expect(result.id, 'ev1');
      expect(result.name, 'Updated Event');
      expect(result.isEnabled, isFalse);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/ev1',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['name'], 'Updated Event');
      expect(sentData['isEnabled'], isFalse);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/ev1',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Event not found',
      ));

      expect(
        () => service.updateEvent('ev1', {'name': 'test'}),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deleteEvent', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.eventsBasePath}/ev1',
          )).thenAnswer((_) async {});

      await service.deleteEvent('ev1');

      verify(() => mockClient.delete(
            '${AppConstants.eventsBasePath}/ev1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.eventsBasePath}/ev1',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Event not found',
      ));

      expect(
        () => service.deleteEvent('ev1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('toggleEvent', () {
    test('sends PUT on toggle endpoint and returns toggled event', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/ev1/toggle',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'ev1',
              'name': 'Daily Solar Check',
              'eventType': 'RECURRING',
              'isEnabled': false,
              'cronExpression': '0 8 * * *',
              'actionType': 'AI_PROMPT',
              'actionPayload': 'Summarize solar output',
            },
          });

      final result = await service.toggleEvent('ev1');

      expect(result.id, 'ev1');
      expect(result.isEnabled, isFalse);
      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/ev1/toggle',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.eventsBasePath}/bad-id/toggle',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Event not found',
      ));

      expect(
        () => service.toggleEvent('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
