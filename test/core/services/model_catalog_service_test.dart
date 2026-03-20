import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/services/model_catalog_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late ModelCatalogService service;

  setUp(() {
    mockClient = MockApiClient();
    service = ModelCatalogService(client: mockClient);
  });

  group('searchCatalog', () {
    test('returns list of HfModelModel on success', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/catalog/search',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {
              'models': [
                {
                  'id': 'TheBloke/Llama-2-7B-GGUF',
                  'downloads': 100000,
                  'likes': 50,
                  'tags': ['gguf'],
                  'siblings': [
                    {'rfilename': 'model.Q4_K_M.gguf', 'size': 4000000000},
                  ],
                },
              ],
              'totalCount': 1,
            },
          });

      final results = await service.searchCatalog(query: 'llama');

      expect(results.length, 1);
      expect(results[0].id, 'TheBloke/Llama-2-7B-GGUF');
      expect(results[0].files.length, 1);
    });

    test('passes query params correctly', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {'models': <dynamic>[], 'totalCount': 0},
          });

      await service.searchCatalog(query: 'test', format: 'mlx', limit: 10);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['q'], 'test');
      expect(params['format'], 'mlx');
      expect(params['limit'], 10);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final results = await service.searchCatalog(query: 'test');

      expect(results, isEmpty);
    });

    test('supports empty query for browse mode', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {
              'models': [
                {
                  'id': 'trending/model',
                  'downloads': 999999,
                  'likes': 500,
                  'tags': ['gguf'],
                  'siblings': [
                    {'rfilename': 'model.Q4_K_M.gguf', 'size': 4000000000},
                  ],
                },
              ],
              'totalCount': 1,
            },
          });

      final results = await service.searchCatalog();

      expect(results.length, 1);
      expect(results[0].id, 'trending/model');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['q'], '');
      expect(params['format'], 'gguf');
      expect(params['limit'], 20);
    });

    test('throws ApiException on error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      expect(
        () => service.searchCatalog(query: 'test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getModelDetails', () {
    test('returns HfModelModel on success', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/catalog/TheBloke/Llama-2-7B-GGUF',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'TheBloke/Llama-2-7B-GGUF',
              'author': 'TheBloke',
              'modelId': 'Llama-2-7B-GGUF',
              'downloads': 100000,
              'likes': 50,
              'tags': ['gguf'],
              'siblings': <dynamic>[],
            },
          });

      final model =
          await service.getModelDetails('TheBloke', 'Llama-2-7B-GGUF');

      expect(model.id, 'TheBloke/Llama-2-7B-GGUF');
      expect(model.author, 'TheBloke');
    });

    test('throws ApiException on error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(any()))
          .thenThrow(const ApiException(
        statusCode: 404,
        message: 'Model not found',
      ));

      expect(
        () => service.getModelDetails('unknown', 'model'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getModelFiles', () {
    test('returns list of HfModelFileModel on success', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/catalog/TheBloke/Model/files',
          )).thenAnswer((_) async => {
            'data': [
              {'rfilename': 'model.Q4_K_M.gguf', 'size': 4000000000},
              {'rfilename': 'model.Q8_0.gguf', 'size': 7000000000},
            ],
          });

      final files = await service.getModelFiles('TheBloke', 'Model');

      expect(files.length, 2);
      expect(files[0].filename, 'model.Q4_K_M.gguf');
      expect(files[1].sizeBytes, 7000000000);
    });

    test('returns empty list when data is empty', () async {
      when(() => mockClient.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => {'data': <dynamic>[]});

      final files = await service.getModelFiles('test', 'model');

      expect(files, isEmpty);
    });
  });

  group('startDownload', () {
    test('posts download request and returns response map', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/download',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'downloadId': 'dl-abc-123',
              'targetPath': '/models/TheBloke/Model/model.gguf',
              'estimatedSizeBytes': 4000000000,
            },
          });

      final result = await service.startDownload(
        repoId: 'TheBloke/Model',
        filename: 'model.gguf',
      );

      expect(result['downloadId'], 'dl-abc-123');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            any(),
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['repoId'], 'TheBloke/Model');
      expect(sentData['filename'], 'model.gguf');
    });

    test('throws ApiException on error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.startDownload(repoId: 'r', filename: 'f'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getAllDownloads', () {
    test('returns list of DownloadProgressModel', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/download',
          )).thenAnswer((_) async => {
            'data': [
              {
                'downloadId': 'dl-1',
                'repoId': 'test/model',
                'filename': 'model.gguf',
                'status': 'DOWNLOADING',
                'bytesDownloaded': 1000,
                'totalBytes': 5000,
                'percentComplete': 20.0,
                'speedBytesPerSecond': 500.0,
                'estimatedSecondsRemaining': 8,
              },
            ],
          });

      final downloads = await service.getAllDownloads();

      expect(downloads.length, 1);
      expect(downloads[0].downloadId, 'dl-1');
      expect(downloads[0].status, 'DOWNLOADING');
      expect(downloads[0].percentComplete, 20.0);
    });

    test('returns empty list when no downloads', () async {
      when(() => mockClient.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => {'data': <dynamic>[]});

      final downloads = await service.getAllDownloads();

      expect(downloads, isEmpty);
    });
  });

  group('cancelDownload', () {
    test('calls delete endpoint', () async {
      when(() => mockClient.delete(
            '${AppConstants.modelsBasePath}/download/dl-123',
          )).thenAnswer((_) async {});

      await service.cancelDownload('dl-123');

      verify(() => mockClient.delete(
            '${AppConstants.modelsBasePath}/download/dl-123',
          )).called(1);
    });
  });

  group('listLocalModels', () {
    test('returns list of LocalModelFileModel', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/local',
          )).thenAnswer((_) async => {
            'data': [
              {
                'filename': 'llama.Q4_K_M.gguf',
                'repoId': 'TheBloke/Llama-2-7B-GGUF',
                'format': 'gguf',
                'sizeBytes': 4370000000,
                'lastModified': '2025-12-01T10:00:00Z',
                'isCurrentlyLoaded': false,
              },
              {
                'filename': 'phi-3.Q8_0.gguf',
                'repoId': 'microsoft/Phi-3-GGUF',
                'format': 'gguf',
                'sizeBytes': 8000000000,
                'isCurrentlyLoaded': true,
              },
            ],
          });

      final models = await service.listLocalModels();

      expect(models.length, 2);
      expect(models[0].filename, 'llama.Q4_K_M.gguf');
      expect(models[1].isCurrentlyLoaded, isTrue);
    });

    test('returns empty list when no local models', () async {
      when(() => mockClient.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => {'data': <dynamic>[]});

      final models = await service.listLocalModels();

      expect(models, isEmpty);
    });

    test('throws ApiException on error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(any()))
          .thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal error',
      ));

      expect(
        () => service.listLocalModels(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deleteLocalModel', () {
    test('calls delete endpoint with filename', () async {
      when(() => mockClient.delete(
            '${AppConstants.modelsBasePath}/local/model.gguf',
          )).thenAnswer((_) async {});

      await service.deleteLocalModel('model.gguf');

      verify(() => mockClient.delete(
            '${AppConstants.modelsBasePath}/local/model.gguf',
          )).called(1);
    });

    test('throws ApiException on error', () async {
      when(() => mockClient.delete(any()))
          .thenThrow(const ApiException(
        statusCode: 404,
        message: 'Not found',
      ));

      expect(
        () => service.deleteLocalModel('nonexistent.gguf'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Providers', () {
    test('modelCatalogServiceProvider creates service from apiClient', () {
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(modelCatalogServiceProvider),
        isA<ModelCatalogService>(),
      );
    });

    test('localModelsProvider returns local models', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/local',
          )).thenAnswer((_) async => {
            'data': [
              {
                'filename': 'model.gguf',
                'format': 'gguf',
                'sizeBytes': 1000,
                'isCurrentlyLoaded': false,
              },
            ],
          });

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final models = await container.read(localModelsProvider.future);
      expect(models.length, 1);
      expect(models[0].filename, 'model.gguf');
    });

    test('activeDownloadsProvider returns downloads', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/download',
          )).thenAnswer((_) async => {
            'data': [
              {
                'downloadId': 'dl-1',
                'repoId': 'test/model',
                'filename': 'model.gguf',
                'status': 'DOWNLOADING',
                'bytesDownloaded': 500,
                'totalBytes': 1000,
                'percentComplete': 50.0,
                'speedBytesPerSecond': 100.0,
                'estimatedSecondsRemaining': 5,
              },
            ],
          });

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final downloads = await container.read(activeDownloadsProvider.future);
      expect(downloads.length, 1);
      expect(downloads[0].downloadId, 'dl-1');
    });
  });
}
