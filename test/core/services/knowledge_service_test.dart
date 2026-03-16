import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late KnowledgeService service;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    mockClient = MockApiClient();
    service = KnowledgeService(client: mockClient);
  });

  // ---------------------------------------------------------------------------
  // listDocuments
  // ---------------------------------------------------------------------------
  group('listDocuments', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'doc-1',
                'filename': 'solar-guide.pdf',
                'displayName': 'Solar Installation Guide',
                'mimeType': 'application/pdf',
                'fileSizeBytes': 1048576,
                'status': 'INDEXED',
                'errorMessage': null,
                'chunkCount': 42,
                'uploadedAt': '2026-03-10T08:00:00Z',
                'processedAt': '2026-03-10T08:05:00Z',
                'hasContent': true,
                'editable': false,
              },
              {
                'id': 'doc-2',
                'filename': 'garden-notes.txt',
                'displayName': null,
                'mimeType': 'text/plain',
                'fileSizeBytes': 2048,
                'status': 'PENDING',
                'errorMessage': null,
                'chunkCount': 0,
                'uploadedAt': '2026-03-16T09:00:00Z',
                'processedAt': null,
                'hasContent': true,
                'editable': true,
              },
            ],
          });

      final result = await service.listDocuments();

      expect(result, hasLength(2));
      expect(result[0].id, 'doc-1');
      expect(result[0].filename, 'solar-guide.pdf');
      expect(result[0].displayName, 'Solar Installation Guide');
      expect(result[0].isIndexed, isTrue);
      expect(result[0].chunkCount, 42);
      expect(result[1].id, 'doc-2');
      expect(result[1].status, 'PENDING');
      expect(result[1].editable, isTrue);
    });

    test('passes pagination query params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listDocuments(page: 2, size: 10);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 2);
      expect(params['size'], 10);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listDocuments();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listDocuments(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getDocument
  // ---------------------------------------------------------------------------
  group('getDocument', () {
    test('returns KnowledgeDocumentModel for given id', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-1',
              'filename': 'solar-guide.pdf',
              'displayName': 'Solar Installation Guide',
              'mimeType': 'application/pdf',
              'fileSizeBytes': 1048576,
              'status': 'INDEXED',
              'errorMessage': null,
              'chunkCount': 42,
              'uploadedAt': '2026-03-10T08:00:00Z',
              'processedAt': '2026-03-10T08:05:00Z',
              'hasContent': true,
              'editable': false,
            },
          });

      final result = await service.getDocument('doc-1');

      expect(result.id, 'doc-1');
      expect(result.filename, 'solar-guide.pdf');
      expect(result.fileSizeBytes, 1048576);
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1',
          )).called(1);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/missing',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Document not found',
      ));

      expect(
        () => service.getDocument('missing'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // uploadDocument
  // ---------------------------------------------------------------------------
  group('uploadDocument', () {
    test('sends multipart form data and returns model', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            any(),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-new',
              'filename': 'compost-guide.pdf',
              'displayName': null,
              'mimeType': 'application/pdf',
              'fileSizeBytes': 512000,
              'status': 'PENDING',
              'errorMessage': null,
              'chunkCount': 0,
              'uploadedAt': '2026-03-16T12:00:00Z',
              'processedAt': null,
              'hasContent': false,
              'editable': false,
            },
          });

      final result = await service.uploadDocument(
        'compost-guide.pdf',
        [0x25, 0x50, 0x44, 0x46], // PDF magic bytes
      );

      expect(result.id, 'doc-new');
      expect(result.filename, 'compost-guide.pdf');
      expect(result.status, 'PENDING');
      verify(() => mockClient.postMultipart<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            any(),
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            any(),
          )).thenThrow(const ApiException(
        statusCode: 413,
        message: 'File too large',
      ));

      expect(
        () => service.uploadDocument('huge.pdf', List.filled(100000, 0)),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateDisplayName
  // ---------------------------------------------------------------------------
  group('updateDisplayName', () {
    test('sends displayName and returns updated model', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/display-name',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-1',
              'filename': 'solar-guide.pdf',
              'displayName': 'My Solar Guide',
              'mimeType': 'application/pdf',
              'fileSizeBytes': 1048576,
              'status': 'INDEXED',
              'errorMessage': null,
              'chunkCount': 42,
              'uploadedAt': '2026-03-10T08:00:00Z',
              'processedAt': '2026-03-10T08:05:00Z',
              'hasContent': true,
              'editable': false,
            },
          });

      final result = await service.updateDisplayName('doc-1', 'My Solar Guide');

      expect(result.id, 'doc-1');
      expect(result.displayName, 'My Solar Guide');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/display-name',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['displayName'], 'My Solar Guide');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/display-name',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Display name too long',
      ));

      expect(
        () => service.updateDisplayName('doc-1', 'x' * 500),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteDocument
  // ---------------------------------------------------------------------------
  group('deleteDocument', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.knowledgeBasePath}/doc-1',
          )).thenAnswer((_) async {});

      await service.deleteDocument('doc-1');

      verify(() => mockClient.delete(
            '${AppConstants.knowledgeBasePath}/doc-1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.knowledgeBasePath}/doc-1',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.deleteDocument('doc-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // retryProcessing
  // ---------------------------------------------------------------------------
  group('retryProcessing', () {
    test('sends POST and returns updated model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/retry',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-1',
              'filename': 'solar-guide.pdf',
              'displayName': 'Solar Installation Guide',
              'mimeType': 'application/pdf',
              'fileSizeBytes': 1048576,
              'status': 'PROCESSING',
              'errorMessage': null,
              'chunkCount': 0,
              'uploadedAt': '2026-03-10T08:00:00Z',
              'processedAt': null,
              'hasContent': false,
              'editable': false,
            },
          });

      final result = await service.retryProcessing('doc-1');

      expect(result.id, 'doc-1');
      expect(result.status, 'PROCESSING');
      expect(result.isProcessing, isTrue);
      verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/retry',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/retry',
          )).thenThrow(const ApiException(
        statusCode: 409,
        message: 'Already processing',
      ));

      expect(
        () => service.retryProcessing('doc-1'),
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
            '${AppConstants.knowledgeBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'chunkId': 'chunk-1',
                'documentId': 'doc-1',
                'documentName': 'Solar Installation Guide',
                'content': 'Connect panels in series for higher voltage...',
                'pageNumber': 15,
                'chunkIndex': 3,
                'similarityScore': 0.92,
              },
              {
                'chunkId': 'chunk-2',
                'documentId': 'doc-1',
                'documentName': 'Solar Installation Guide',
                'content': 'Use MPPT charge controller for best efficiency...',
                'pageNumber': 22,
                'chunkIndex': 7,
                'similarityScore': 0.87,
              },
            ],
          });

      final result = await service.search('solar panel wiring');

      expect(result, hasLength(2));
      expect(result[0].chunkId, 'chunk-1');
      expect(result[0].documentId, 'doc-1');
      expect(result[0].documentName, 'Solar Installation Guide');
      expect(result[0].pageNumber, 15);
      expect(result[0].similarityScore, 0.92);
      expect(result[1].chunkIndex, 7);
    });

    test('passes query and topK in request body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.search('water filtration', topK: 3);

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/search',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['query'], 'water filtration');
      expect(sentData['topK'], 3);
    });

    test('uses default topK of 5', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.search('test');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/search',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['topK'], 5);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/search',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.search('nothing');

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/search',
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
  // getDocumentContent
  // ---------------------------------------------------------------------------
  group('getDocumentContent', () {
    test('returns DocumentContentModel for given id', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/content',
          )).thenAnswer((_) async => {
            'data': {
              'documentId': 'doc-1',
              'title': 'Solar Installation Guide',
              'content': '<h1>Solar Panel Setup</h1><p>Step 1...</p>',
              'mimeType': 'text/html',
              'editable': true,
            },
          });

      final result = await service.getDocumentContent('doc-1');

      expect(result.documentId, 'doc-1');
      expect(result.title, 'Solar Installation Guide');
      expect(result.content, contains('Solar Panel Setup'));
      expect(result.editable, isTrue);
      verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/content',
          )).called(1);
    });

    test('throws ApiException on 404', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/missing/content',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Document not found',
      ));

      expect(
        () => service.getDocumentContent('missing'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // downloadDocument
  // ---------------------------------------------------------------------------
  group('downloadDocument', () {
    test('returns raw bytes from API', () async {
      final fakeBytes = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
      when(() => mockClient.getBytes(
            '${AppConstants.knowledgeBasePath}/doc-1/download',
          )).thenAnswer((_) async => fakeBytes);

      final result = await service.downloadDocument('doc-1');

      expect(result, fakeBytes);
      verify(() => mockClient.getBytes(
            '${AppConstants.knowledgeBasePath}/doc-1/download',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.getBytes(
            '${AppConstants.knowledgeBasePath}/doc-1/download',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'File not found',
      ));

      expect(
        () => service.downloadDocument('doc-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // createDocument
  // ---------------------------------------------------------------------------
  group('createDocument', () {
    test('sends title and content, returns model', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/create',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-created',
              'filename': 'my-notes.html',
              'displayName': 'My Garden Notes',
              'mimeType': 'text/html',
              'fileSizeBytes': 256,
              'status': 'INDEXED',
              'errorMessage': null,
              'chunkCount': 1,
              'uploadedAt': '2026-03-16T14:00:00Z',
              'processedAt': '2026-03-16T14:00:01Z',
              'hasContent': true,
              'editable': true,
            },
          });

      final result = await service.createDocument(
        title: 'My Garden Notes',
        content: '<p>Plant tomatoes in May</p>',
      );

      expect(result.id, 'doc-created');
      expect(result.displayName, 'My Garden Notes');
      expect(result.editable, isTrue);

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/create',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['title'], 'My Garden Notes');
      expect(sentData['content'], '<p>Plant tomatoes in May</p>');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/create',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 400,
        message: 'Title is required',
      ));

      expect(
        () => service.createDocument(title: '', content: 'test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateDocumentContent
  // ---------------------------------------------------------------------------
  group('updateDocumentContent', () {
    test('sends content and returns updated model', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/content',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'doc-1',
              'filename': 'garden-notes.html',
              'displayName': 'My Garden Notes',
              'mimeType': 'text/html',
              'fileSizeBytes': 512,
              'status': 'INDEXED',
              'errorMessage': null,
              'chunkCount': 2,
              'uploadedAt': '2026-03-10T08:00:00Z',
              'processedAt': '2026-03-16T15:00:00Z',
              'hasContent': true,
              'editable': true,
            },
          });

      final result = await service.updateDocumentContent(
        'doc-1',
        '<p>Updated garden notes</p>',
      );

      expect(result.id, 'doc-1');
      expect(result.chunkCount, 2);

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/content',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['content'], '<p>Updated garden notes</p>');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.knowledgeBasePath}/doc-1/content',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Document not found',
      ));

      expect(
        () => service.updateDocumentContent('doc-1', 'content'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('knowledgeServiceProvider', () {
    test('creates KnowledgeService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(knowledgeServiceProvider), isA<KnowledgeService>());
    });
  });

  group('knowledgeDocumentsProvider', () {
    test('returns documents from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.knowledgeBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'doc-1', 'filename': 'test.pdf', 'displayName': 'Test', 'status': 'READY'},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final docs = await container.read(knowledgeDocumentsProvider.future);
      expect(docs, hasLength(1));
    });
  });
}
