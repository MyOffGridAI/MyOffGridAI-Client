import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/enrichment_models.dart';
import 'package:myoffgridai_client/core/services/enrichment_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late EnrichmentService service;

  setUp(() {
    mockClient = MockApiClient();
    service = EnrichmentService(client: mockClient);
  });

  group('getExternalApiSettings', () {
    test('returns parsed model from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.externalApiSettingsPath,
          )).thenAnswer((_) async => {
            'data': {
              'anthropicEnabled': true,
              'anthropicModel': 'claude-sonnet-4-20250514',
              'anthropicKeyConfigured': true,
              'braveEnabled': false,
              'braveKeyConfigured': false,
              'maxWebFetchSizeKb': 512,
              'searchResultLimit': 5,
            },
          });

      final result = await service.getExternalApiSettings();

      expect(result.anthropicEnabled, isTrue);
      expect(result.anthropicKeyConfigured, isTrue);
      expect(result.braveEnabled, isFalse);
    });
  });

  group('updateExternalApiSettings', () {
    test('sends request and returns updated model', () async {
      const request = UpdateExternalApiSettingsRequest(
        anthropicApiKey: 'new-key',
        anthropicModel: 'claude-sonnet-4-20250514',
        anthropicEnabled: true,
        braveEnabled: false,
        maxWebFetchSizeKb: 1024,
        searchResultLimit: 10,
      );

      when(() => mockClient.put<Map<String, dynamic>>(
            AppConstants.externalApiSettingsPath,
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'anthropicEnabled': true,
              'anthropicModel': 'claude-sonnet-4-20250514',
              'anthropicKeyConfigured': true,
              'braveEnabled': false,
              'braveKeyConfigured': false,
              'maxWebFetchSizeKb': 1024,
              'searchResultLimit': 10,
            },
          });

      final result = await service.updateExternalApiSettings(request);

      expect(result.anthropicEnabled, isTrue);
      expect(result.maxWebFetchSizeKb, 1024);
      verify(() => mockClient.put<Map<String, dynamic>>(
            AppConstants.externalApiSettingsPath,
            data: any(named: 'data'),
          )).called(1);
    });
  });

  group('fetchUrl', () {
    test('posts URL and returns knowledge document model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/fetch-url',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-1',
              'filename': 'article.txt',
              'displayName': 'Article Title',
              'status': 'PENDING',
            },
          });

      final result = await service.fetchUrl(
        url: 'https://example.com/article',
        summarizeWithClaude: false,
      );

      expect(result.id, 'doc-1');
      expect(result.displayName, 'Article Title');
    });

    test('passes summarizeWithClaude flag', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/fetch-url',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-2',
              'filename': 'page.txt',
              'status': 'PENDING',
            },
          });

      await service.fetchUrl(
        url: 'https://example.com',
        summarizeWithClaude: true,
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/fetch-url',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['url'], 'https://example.com');
      expect(sentData['summarizeWithClaude'], isTrue);
    });
  });

  group('search', () {
    test('posts query and returns results with stored documents', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'results': [
                {
                  'title': 'Result 1',
                  'url': 'https://example.com/1',
                  'description': 'Description 1',
                },
                {
                  'title': 'Result 2',
                  'url': 'https://example.com/2',
                  'description': 'Description 2',
                },
              ],
              'storedDocuments': [
                {
                  'id': 'doc-1',
                  'filename': 'result_1.txt',
                  'status': 'PENDING',
                },
              ],
            },
          });

      final result = await service.search(
        query: 'solar panels',
        storeTopN: 1,
      );

      expect(result.results, hasLength(2));
      expect(result.results[0].title, 'Result 1');
      expect(result.storedDocuments, hasLength(1));
      expect(result.storedDocuments[0].id, 'doc-1');
    });

    test('handles empty results', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'results': <dynamic>[],
              'storedDocuments': <dynamic>[],
            },
          });

      final result = await service.search(query: 'nothing');

      expect(result.results, isEmpty);
      expect(result.storedDocuments, isEmpty);
    });

    test('handles null results and storedDocuments in response', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      final result = await service.search(query: 'test');

      expect(result.results, isEmpty);
      expect(result.storedDocuments, isEmpty);
    });
  });

  group('getStatus', () {
    test('returns enrichment status model', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.enrichmentBasePath}/status',
          )).thenAnswer((_) async => {
            'data': {
              'claudeAvailable': true,
              'braveAvailable': false,
              'maxWebFetchSizeKb': 512,
              'searchResultLimit': 5,
            },
          });

      final result = await service.getStatus();

      expect(result.claudeAvailable, isTrue);
      expect(result.braveAvailable, isFalse);
      expect(result.maxWebFetchSizeKb, 512);
      expect(result.searchResultLimit, 5);
    });
  });
}
