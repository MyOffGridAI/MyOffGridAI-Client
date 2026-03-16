import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  group('OllamaHealthDto', () {
    test('parses from JSON with all fields', () {
      final json = {
        'available': true,
        'activeModel': 'llama3:8b',
        'embedModelName': 'nomic-embed-text',
        'responseTimeMs': 250,
      };

      final dto = OllamaHealthDto.fromJson(json);

      expect(dto.available, isTrue);
      expect(dto.activeModel, 'llama3:8b');
      expect(dto.embedModelName, 'nomic-embed-text');
      expect(dto.responseTimeMs, 250);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final dto = OllamaHealthDto.fromJson(json);

      expect(dto.available, isFalse);
      expect(dto.activeModel, isNull);
      expect(dto.embedModelName, isNull);
      expect(dto.responseTimeMs, isNull);
    });

    test('handles partial fields', () {
      final json = {
        'available': true,
        'activeModel': 'mistral:7b',
      };

      final dto = OllamaHealthDto.fromJson(json);

      expect(dto.available, isTrue);
      expect(dto.activeModel, 'mistral:7b');
      expect(dto.embedModelName, isNull);
      expect(dto.responseTimeMs, isNull);
    });

    test('constructor with named params', () {
      const dto = OllamaHealthDto(
        available: true,
        activeModel: 'llama3:8b',
        embedModelName: 'nomic-embed-text',
        responseTimeMs: 100,
      );

      expect(dto.available, isTrue);
      expect(dto.activeModel, 'llama3:8b');
      expect(dto.embedModelName, 'nomic-embed-text');
      expect(dto.responseTimeMs, 100);
    });

    test('constructor defaults', () {
      const dto = OllamaHealthDto(available: false);

      expect(dto.available, isFalse);
      expect(dto.activeModel, isNull);
      expect(dto.embedModelName, isNull);
      expect(dto.responseTimeMs, isNull);
    });
  });

  group('SystemStatusDto', () {
    test('parses from JSON with initialized true', () {
      final json = {'initialized': true};

      final dto = SystemStatusDto.fromJson(json);

      expect(dto.initialized, isTrue);
    });

    test('parses from JSON with initialized false', () {
      final json = {'initialized': false};

      final dto = SystemStatusDto.fromJson(json);

      expect(dto.initialized, isFalse);
    });

    test('handles missing initialized field with default false', () {
      final json = <String, dynamic>{};

      final dto = SystemStatusDto.fromJson(json);

      expect(dto.initialized, isFalse);
    });

    test('constructor with named params', () {
      const dto = SystemStatusDto(initialized: true);

      expect(dto.initialized, isTrue);
    });
  });

  group('systemStatusProvider', () {
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
    });

    test('returns SystemStatusDto from server response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenAnswer((_) async => {
            'data': {'initialized': true},
          });

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(systemStatusProvider.future);

      expect(result.initialized, isTrue);
    });

    test('returns initialized=true when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenAnswer((_) async => {'data': null});

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(systemStatusProvider.future);

      expect(result.initialized, isTrue);
    });

    test('returns initialized=true on network error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(systemStatusProvider.future);

      expect(result.initialized, isTrue);
    });
  });

  group('modelHealthProvider', () {
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
    });

    test('returns OllamaHealthDto from server response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/health',
          )).thenAnswer((_) async => {
            'data': {
              'available': true,
              'activeModel': 'llama3:8b',
              'responseTimeMs': 150,
            },
          });

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(modelHealthProvider.future);

      expect(result.available, isTrue);
      expect(result.activeModel, 'llama3:8b');
      expect(result.responseTimeMs, 150);
    });

    test('returns available=false when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/health',
          )).thenAnswer((_) async => {'data': null});

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(modelHealthProvider.future);

      expect(result.available, isFalse);
    });

    test('returns available=false on network error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.modelsBasePath}/health',
          )).thenThrow(Exception('unreachable'));

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(modelHealthProvider.future);

      expect(result.available, isFalse);
    });
  });

  group('unreadCountProvider', () {
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
    });

    test('returns count when data is int', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {'data': 7});

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(unreadCountProvider.future);

      expect(result, 7);
    });

    test('returns 0 when data is not int', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenAnswer((_) async => {'data': 'not-an-int'});

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(unreadCountProvider.future);

      expect(result, 0);
    });

    test('returns 0 on error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.notificationsBasePath}/unread-count',
          )).thenThrow(Exception('error'));

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(unreadCountProvider.future);

      expect(result, 0);
    });
  });

  group('connectionStatusProvider', () {
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
    });

    test('emits true when server is reachable', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenAnswer((_) async => {'data': {'initialized': true}});

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      // The stream emits the first value from check()
      final result = await container.read(connectionStatusProvider.future);

      expect(result, isTrue);
    });

    test('emits false when server is unreachable', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.systemBasePath}/status',
          )).thenThrow(Exception('unreachable'));

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final result = await container.read(connectionStatusProvider.future);

      expect(result, isFalse);
    });
  });

  group('serverUrlProvider', () {
    test('returns URL from secure storage', () async {
      final mockStorage = MockSecureStorage();
      when(() => mockStorage.getServerUrl())
          .thenAnswer((_) async => 'http://192.168.1.100:8080');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(serverUrlProvider.future);

      expect(result, 'http://192.168.1.100:8080');
    });
  });
}
