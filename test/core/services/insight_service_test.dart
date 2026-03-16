import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/insight_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late InsightService service;

  setUp(() {
    mockClient = MockApiClient();
    service = InsightService(client: mockClient);
  });

  group('listInsights', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'i1',
                'content': 'Solar panel efficiency dropped 15%',
                'category': 'EFFICIENCY',
                'isRead': false,
                'isDismissed': false,
                'generatedAt': '2026-03-15T10:00:00Z',
              },
              {
                'id': 'i2',
                'content': 'Battery maintenance due in 3 days',
                'category': 'MAINTENANCE',
                'isRead': true,
                'isDismissed': false,
                'generatedAt': '2026-03-14T08:00:00Z',
                'readAt': '2026-03-14T09:00:00Z',
              },
            ],
          });

      final result = await service.listInsights();

      expect(result, hasLength(2));
      expect(result[0].id, 'i1');
      expect(result[0].content, 'Solar panel efficiency dropped 15%');
      expect(result[0].category, 'EFFICIENCY');
      expect(result[0].isRead, isFalse);
      expect(result[1].isRead, isTrue);
      expect(result[1].category, 'MAINTENANCE');
    });

    test('passes default pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listInsights();

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 0);
      expect(params['size'], 20);
      expect(params.containsKey('category'), isFalse);
    });

    test('passes custom pagination and category filter', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listInsights(page: 2, size: 10, category: 'SECURITY');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 2);
      expect(params['size'], 10);
      expect(params['category'], 'SECURITY');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listInsights();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listInsights(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('generateInsights', () {
    test('returns parsed list of generated insights', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/generate',
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'gen1',
                'content': 'Consider adding more water storage',
                'category': 'PLANNING',
                'isRead': false,
                'isDismissed': false,
                'generatedAt': '2026-03-16T12:00:00Z',
              },
            ],
          });

      final result = await service.generateInsights();

      expect(result, hasLength(1));
      expect(result[0].id, 'gen1');
      expect(result[0].content, 'Consider adding more water storage');
      expect(result[0].category, 'PLANNING');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/generate',
          )).thenAnswer((_) async => {'data': null});

      final result = await service.generateInsights();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/generate',
          )).thenThrow(const ApiException(
        statusCode: 503,
        message: 'AI model unavailable',
      ));

      expect(
        () => service.generateInsights(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('markAsRead', () {
    test('sends PUT and returns updated insight', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/i1/read',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'i1',
              'content': 'Solar panel efficiency dropped 15%',
              'category': 'EFFICIENCY',
              'isRead': true,
              'isDismissed': false,
              'generatedAt': '2026-03-15T10:00:00Z',
              'readAt': '2026-03-16T08:00:00Z',
            },
          });

      final result = await service.markAsRead('i1');

      expect(result.id, 'i1');
      expect(result.isRead, isTrue);
      expect(result.readAt, '2026-03-16T08:00:00Z');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/i1/read',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/bad-id/read',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Insight not found',
      ));

      expect(
        () => service.markAsRead('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('dismiss', () {
    test('sends PUT and returns dismissed insight', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/i2/dismiss',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'i2',
              'content': 'Battery maintenance due',
              'category': 'MAINTENANCE',
              'isRead': true,
              'isDismissed': true,
              'generatedAt': '2026-03-14T08:00:00Z',
            },
          });

      final result = await service.dismiss('i2');

      expect(result.id, 'i2');
      expect(result.isDismissed, isTrue);
      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/i2/dismiss',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/bad-id/dismiss',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Insight not found',
      ));

      expect(
        () => service.dismiss('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getUnreadCount', () {
    test('returns count from map data', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': {'unreadCount': 7},
          });

      final result = await service.getUnreadCount();

      expect(result, 7);
    });

    test('returns 0 when unreadCount is null in map', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final result = await service.getUnreadCount();

      expect(result, 0);
    });

    test('returns 0 when data is not a map', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/unread-count',
          )).thenAnswer((_) async => {
            'data': 'unexpected',
          });

      final result = await service.getUnreadCount();

      expect(result, 0);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.insightsBasePath}/unread-count',
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
  group('insightServiceProvider', () {
    test('creates InsightService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(insightServiceProvider), isA<InsightService>());
    });
  });

  group('insightsProvider', () {
    test('returns insights from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.insightsBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'ins-1', 'content': 'Test', 'category': 'HEALTH', 'isRead': false, 'isDismissed': false},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final insights = await container.read(insightsProvider.future);
      expect(insights, hasLength(1));
    });
  });
}
