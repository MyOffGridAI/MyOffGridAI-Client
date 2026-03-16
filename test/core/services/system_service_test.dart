import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late SystemService service;

  setUp(() {
    mockClient = MockApiClient();
    service = SystemService(client: mockClient);
  });

  group('getSystemStatus', () {
    test('returns parsed system status', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenAnswer((_) async => {
            'data': {
              'initialized': true,
              'instanceName': 'MyOffGridAI-Home',
              'fortressEnabled': true,
              'wifiConfigured': true,
              'serverVersion': '1.2.0',
              'timestamp': '2026-03-16T12:00:00Z',
            },
          });

      final result = await service.getSystemStatus();

      expect(result.initialized, isTrue);
      expect(result.instanceName, 'MyOffGridAI-Home');
      expect(result.fortressEnabled, isTrue);
      expect(result.wifiConfigured, isTrue);
      expect(result.serverVersion, '1.2.0');
      expect(result.timestamp, '2026-03-16T12:00:00Z');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.getSystemStatus(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('listModels', () {
    test('returns parsed list of models', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.modelsBasePath,
          )).thenAnswer((_) async => {
            'data': [
              {
                'name': 'llama3:8b',
                'size': 4700000000,
                'modifiedAt': '2026-03-10T08:00:00Z',
              },
              {
                'name': 'mistral:7b',
                'size': 3900000000,
                'modifiedAt': '2026-03-12T10:00:00Z',
              },
            ],
          });

      final result = await service.listModels();

      expect(result, hasLength(2));
      expect(result[0].name, 'llama3:8b');
      expect(result[0].size, 4700000000);
      expect(result[1].name, 'mistral:7b');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.modelsBasePath,
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listModels();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.modelsBasePath,
          )).thenThrow(const ApiException(
        statusCode: 503,
        message: 'Ollama not available',
      ));

      expect(
        () => service.listModels(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getActiveModel', () {
    test('returns parsed active model info', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/active',
          )).thenAnswer((_) async => {
            'data': {
              'modelName': 'llama3:8b',
              'embedModelName': 'nomic-embed-text',
            },
          });

      final result = await service.getActiveModel();

      expect(result.modelName, 'llama3:8b');
      expect(result.embedModelName, 'nomic-embed-text');
    });

    test('handles null fields', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/active',
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final result = await service.getActiveModel();

      expect(result.modelName, isNull);
      expect(result.embedModelName, isNull);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/active',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.getActiveModel(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getAiSettings', () {
    test('returns parsed AI settings', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/ai-settings',
          )).thenAnswer((_) async => {
            'data': {
              'modelName': 'llama3:8b',
              'temperature': 0.7,
              'similarityThreshold': 0.45,
              'memoryTopK': 5,
              'ragMaxContextTokens': 2048,
              'contextSize': 4096,
              'contextMessageLimit': 20,
            },
          });

      final result = await service.getAiSettings();

      expect(result.modelName, 'llama3:8b');
      expect(result.temperature, 0.7);
      expect(result.similarityThreshold, 0.45);
      expect(result.memoryTopK, 5);
      expect(result.ragMaxContextTokens, 2048);
      expect(result.contextSize, 4096);
      expect(result.contextMessageLimit, 20);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/ai-settings',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.getAiSettings(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getStorageSettings', () {
    test('returns parsed storage settings', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/storage-settings',
          )).thenAnswer((_) async => {
            'data': {
              'knowledgeStoragePath': '/var/myoffgridai/knowledge',
              'totalSpaceMb': 50000,
              'usedSpaceMb': 12000,
              'freeSpaceMb': 38000,
              'maxUploadSizeMb': 25,
            },
          });

      final result = await service.getStorageSettings();

      expect(result.knowledgeStoragePath, '/var/myoffgridai/knowledge');
      expect(result.totalSpaceMb, 50000);
      expect(result.usedSpaceMb, 12000);
      expect(result.freeSpaceMb, 38000);
      expect(result.maxUploadSizeMb, 25);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/storage-settings',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.getStorageSettings(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateStorageSettings', () {
    test('sends PUT with settings and returns updated model', () async {
      const settings = StorageSettingsModel(
        knowledgeStoragePath: '/mnt/data/knowledge',
        maxUploadSizeMb: 50,
      );

      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/storage-settings',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'knowledgeStoragePath': '/mnt/data/knowledge',
              'totalSpaceMb': 50000,
              'usedSpaceMb': 12000,
              'freeSpaceMb': 38000,
              'maxUploadSizeMb': 50,
            },
          });

      final result = await service.updateStorageSettings(settings);

      expect(result.knowledgeStoragePath, '/mnt/data/knowledge');
      expect(result.maxUploadSizeMb, 50);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/storage-settings',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['knowledgeStoragePath'], '/mnt/data/knowledge');
      expect(sentData['maxUploadSizeMb'], 50);
    });

    test('throws ApiException on API error', () async {
      const settings = StorageSettingsModel();

      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/storage-settings',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Invalid path',
      ));

      expect(
        () => service.updateStorageSettings(settings),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateAiSettings', () {
    test('sends PUT with settings and returns updated model', () async {
      const settings = AiSettingsModel(
        modelName: 'mistral:7b',
        temperature: 0.9,
        similarityThreshold: 0.5,
        memoryTopK: 10,
        ragMaxContextTokens: 4096,
        contextSize: 8192,
        contextMessageLimit: 30,
      );

      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/ai-settings',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'modelName': 'mistral:7b',
              'temperature': 0.9,
              'similarityThreshold': 0.5,
              'memoryTopK': 10,
              'ragMaxContextTokens': 4096,
              'contextSize': 8192,
              'contextMessageLimit': 30,
            },
          });

      final result = await service.updateAiSettings(settings);

      expect(result.modelName, 'mistral:7b');
      expect(result.temperature, 0.9);
      expect(result.contextSize, 8192);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/ai-settings',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['modelName'], 'mistral:7b');
      expect(sentData['temperature'], 0.9);
      expect(sentData['memoryTopK'], 10);
    });

    test('throws ApiException on API error', () async {
      const settings = AiSettingsModel();

      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/ai-settings',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Invalid settings',
      ));

      expect(
        () => service.updateAiSettings(settings),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
