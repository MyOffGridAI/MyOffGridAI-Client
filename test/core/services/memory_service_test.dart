import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/memory_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late MemoryService service;

  setUp(() {
    mockClient = MockApiClient();
    service = MemoryService(client: mockClient);
  });

  // ---------------------------------------------------------------------------
  // listMemories
  // ---------------------------------------------------------------------------
  group('listMemories', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'mem-1',
                'content': 'User prefers metric units',
                'importance': 'HIGH',
                'tags': 'preferences,units',
                'sourceConversationId': 'conv-1',
                'createdAt': '2026-03-10T08:00:00Z',
                'updatedAt': '2026-03-10T08:00:00Z',
                'lastAccessedAt': '2026-03-16T10:00:00Z',
                'accessCount': 5,
              },
              {
                'id': 'mem-2',
                'content': 'Garden is in zone 8b',
                'importance': 'MEDIUM',
                'tags': 'garden,climate',
                'sourceConversationId': null,
                'createdAt': '2026-03-12T14:00:00Z',
                'updatedAt': '2026-03-12T14:00:00Z',
                'lastAccessedAt': null,
                'accessCount': 0,
              },
            ],
          });

      final result = await service.listMemories();

      expect(result, hasLength(2));
      expect(result[0].id, 'mem-1');
      expect(result[0].content, 'User prefers metric units');
      expect(result[0].importance, 'HIGH');
      expect(result[0].tagList, ['preferences', 'units']);
      expect(result[0].accessCount, 5);
      expect(result[1].id, 'mem-2');
      expect(result[1].sourceConversationId, isNull);
    });

    test('passes default pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listMemories();

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 0);
      expect(params['size'], 20);
      expect(params.containsKey('importance'), isFalse);
      expect(params.containsKey('tag'), isFalse);
    });

    test('passes importance and tag filters', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listMemories(
        page: 1,
        size: 10,
        importance: 'HIGH',
        tag: 'garden',
      );

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 1);
      expect(params['size'], 10);
      expect(params['importance'], 'HIGH');
      expect(params['tag'], 'garden');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listMemories();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listMemories(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getMemory
  // ---------------------------------------------------------------------------
  group('getMemory', () {
    test('returns MemoryModel for given id', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'mem-1',
              'content': 'Solar panels produce 5kW daily',
              'importance': 'CRITICAL',
              'tags': 'solar,energy',
              'sourceConversationId': 'conv-5',
              'createdAt': '2026-03-10T08:00:00Z',
              'updatedAt': '2026-03-10T08:00:00Z',
              'lastAccessedAt': '2026-03-16T10:00:00Z',
              'accessCount': 12,
            },
          });

      final result = await service.getMemory('mem-1');

      expect(result.id, 'mem-1');
      expect(result.content, 'Solar panels produce 5kW daily');
      expect(result.importance, 'CRITICAL');
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1',
          )).called(1);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/missing',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Memory not found',
      ));

      expect(
        () => service.getMemory('missing'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteMemory
  // ---------------------------------------------------------------------------
  group('deleteMemory', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.memoryBasePath}/mem-1',
          )).thenAnswer((_) async {});

      await service.deleteMemory('mem-1');

      verify(() => mockClient.delete(
            '${AppConstants.memoryBasePath}/mem-1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.memoryBasePath}/mem-1',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.deleteMemory('mem-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateTags
  // ---------------------------------------------------------------------------
  group('updateTags', () {
    test('sends tags and returns updated MemoryModel', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1/tags',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'mem-1',
              'content': 'User prefers metric units',
              'importance': 'HIGH',
              'tags': 'preferences,units,updated',
              'sourceConversationId': 'conv-1',
              'createdAt': '2026-03-10T08:00:00Z',
              'updatedAt': '2026-03-16T15:00:00Z',
              'lastAccessedAt': '2026-03-16T10:00:00Z',
              'accessCount': 5,
            },
          });

      final result = await service.updateTags('mem-1', 'preferences,units,updated');

      expect(result.id, 'mem-1');
      expect(result.tagList, ['preferences', 'units', 'updated']);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1/tags',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['tags'], 'preferences,units,updated');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1/tags',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Invalid tags',
      ));

      expect(
        () => service.updateTags('mem-1', ''),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateImportance
  // ---------------------------------------------------------------------------
  group('updateImportance', () {
    test('sends importance and returns updated MemoryModel', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1/importance',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'mem-1',
              'content': 'User prefers metric units',
              'importance': 'CRITICAL',
              'tags': 'preferences,units',
              'sourceConversationId': 'conv-1',
              'createdAt': '2026-03-10T08:00:00Z',
              'updatedAt': '2026-03-16T15:30:00Z',
              'lastAccessedAt': '2026-03-16T10:00:00Z',
              'accessCount': 5,
            },
          });

      final result = await service.updateImportance('mem-1', 'CRITICAL');

      expect(result.id, 'mem-1');
      expect(result.importance, 'CRITICAL');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1/importance',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['importance'], 'CRITICAL');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/mem-1/importance',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Invalid importance level',
      ));

      expect(
        () => service.updateImportance('mem-1', 'INVALID'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // search
  // ---------------------------------------------------------------------------
  group('search', () {
    test('sends query and returns search results', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'memory': {
                  'id': 'mem-1',
                  'content': 'Solar panels produce 5kW daily',
                  'importance': 'CRITICAL',
                  'tags': 'solar,energy',
                  'sourceConversationId': null,
                  'createdAt': '2026-03-10T08:00:00Z',
                  'updatedAt': '2026-03-10T08:00:00Z',
                  'lastAccessedAt': null,
                  'accessCount': 0,
                },
                'similarityScore': 0.95,
              },
            ],
          });

      final result = await service.search('solar energy');

      expect(result, hasLength(1));
      expect(result[0].memory.id, 'mem-1');
      expect(result[0].memory.content, 'Solar panels produce 5kW daily');
      expect(result[0].similarityScore, 0.95);
    });

    test('passes query and topK in request body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.search('water', topK: 5);

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['query'], 'water');
      expect(sentData['topK'], 5);
    });

    test('uses default topK of 10', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.search('test');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['topK'], 10);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.search('nothing');

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/search',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Embedding service unavailable',
      ));

      expect(
        () => service.search('test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // exportMemories
  // ---------------------------------------------------------------------------
  group('exportMemories', () {
    test('returns full list of memories', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/export',
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'mem-1',
                'content': 'Memory one',
                'importance': 'LOW',
                'tags': null,
                'sourceConversationId': null,
                'createdAt': '2026-03-10T08:00:00Z',
                'updatedAt': '2026-03-10T08:00:00Z',
                'lastAccessedAt': null,
                'accessCount': 0,
              },
              {
                'id': 'mem-2',
                'content': 'Memory two',
                'importance': 'HIGH',
                'tags': 'important',
                'sourceConversationId': 'conv-1',
                'createdAt': '2026-03-11T08:00:00Z',
                'updatedAt': '2026-03-11T08:00:00Z',
                'lastAccessedAt': '2026-03-15T10:00:00Z',
                'accessCount': 3,
              },
            ],
          });

      final result = await service.exportMemories();

      expect(result, hasLength(2));
      expect(result[0].id, 'mem-1');
      expect(result[1].id, 'mem-2');
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/export',
          )).called(1);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/export',
          )).thenAnswer((_) async => {'data': null});

      final result = await service.exportMemories();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.memoryBasePath}/export',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Export failed',
      ));

      expect(
        () => service.exportMemories(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('memoryServiceProvider', () {
    test('creates MemoryService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(memoryServiceProvider), isA<MemoryService>());
    });
  });

  group('memoriesProvider', () {
    test('returns memories from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.memoryBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'mem-1', 'content': 'Test memory', 'importance': 'MEDIUM', 'createdAt': '2026-03-16T10:00:00Z'},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final memories = await container.read(memoriesProvider.future);
      expect(memories, hasLength(1));
    });
  });
}
