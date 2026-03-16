import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

class FakeFormData extends Fake implements FormData {}

void main() {
  late MockApiClient mockClient;
  late LibraryService service;

  setUpAll(() {
    registerFallbackValue(FakeFormData());
  });

  setUp(() {
    mockClient = MockApiClient();
    service = LibraryService(client: mockClient);
  });

  // ── ZIM Files ───────────────────────────────────────────────────────────

  group('listZimFiles', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'z1',
                'filename': 'wiki.zim',
                'displayName': 'Wikipedia',
                'fileSizeBytes': 1024,
              },
              {
                'id': 'z2',
                'filename': 'medical.zim',
                'displayName': 'Medical',
                'fileSizeBytes': 2048,
              },
            ],
          });

      final result = await service.listZimFiles();

      expect(result, hasLength(2));
      expect(result[0].filename, 'wiki.zim');
      expect(result[1].displayName, 'Medical');
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listZimFiles();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listZimFiles(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('uploadZimFile', () {
    test('sends multipart POST and returns parsed ZIM file', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
            any(),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'z-new',
              'filename': 'wiki.zim',
              'displayName': 'Wikipedia Offline',
              'category': 'REFERENCE',
              'fileSizeBytes': 50000,
              'articleCount': 1000,
            },
          });

      final result = await service.uploadZimFile(
        filename: 'wiki.zim',
        bytes: [0x5A, 0x49, 0x4D],
        displayName: 'Wikipedia Offline',
        category: 'REFERENCE',
      );

      expect(result.id, 'z-new');
      expect(result.filename, 'wiki.zim');
      expect(result.displayName, 'Wikipedia Offline');
      expect(result.category, 'REFERENCE');
      verify(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
            any(),
          )).called(1);
    });

    test('sends without category when null', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
            any(),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'z-no-cat',
              'filename': 'simple.zim',
              'displayName': 'Simple File',
              'fileSizeBytes': 1024,
            },
          });

      final result = await service.uploadZimFile(
        filename: 'simple.zim',
        bytes: [0x5A],
        displayName: 'Simple File',
      );

      expect(result.id, 'z-no-cat');
      verify(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
            any(),
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
            any(),
          )).thenThrow(const ApiException(
        statusCode: 413,
        message: 'File too large',
      ));

      expect(
        () => service.uploadZimFile(
          filename: 'huge.zim',
          bytes: [0x00],
          displayName: 'Huge File',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deleteZimFile', () {
    test('calls delete on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.libraryBasePath}/zim/z1',
          )).thenAnswer((_) async {});

      await service.deleteZimFile('z1');

      verify(() => mockClient.delete(
            '${AppConstants.libraryBasePath}/zim/z1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.libraryBasePath}/zim/z1',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'ZIM file not found',
      ));

      expect(
        () => service.deleteZimFile('z1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Kiwix ───────────────────────────────────────────────────────────────

  group('getKiwixStatus', () {
    test('returns parsed status', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/kiwix/status',
          )).thenAnswer((_) async => {
            'data': {
              'available': true,
              'url': 'http://localhost:8888',
              'bookCount': 3,
            },
          });

      final result = await service.getKiwixStatus();

      expect(result.available, isTrue);
      expect(result.url, 'http://localhost:8888');
      expect(result.bookCount, 3);
    });
  });

  group('getKiwixUrl', () {
    test('returns URL string', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/kiwix/url',
          )).thenAnswer((_) async => {
            'data': 'http://localhost:8888',
          });

      final result = await service.getKiwixUrl();

      expect(result, 'http://localhost:8888');
    });
  });

  // ── eBooks ──────────────────────────────────────────────────────────────

  group('listEbooks', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'e1',
                'title': 'Test Book',
                'format': 'EPUB',
                'fileSizeBytes': 5000,
              },
            ],
          });

      final result = await service.listEbooks();

      expect(result, hasLength(1));
      expect(result[0].title, 'Test Book');
    });

    test('passes search and format params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listEbooks(search: 'pride', format: 'EPUB');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['search'], 'pride');
      expect(params['format'], 'EPUB');
      expect(params['page'], 0);
      expect(params['size'], 20);
    });

    test('omits search and format when empty strings', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listEbooks(search: '', format: '');

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params.containsKey('search'), isFalse);
      expect(params.containsKey('format'), isFalse);
      expect(params['page'], 0);
      expect(params['size'], 20);
    });

    test('passes custom pagination', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listEbooks(page: 3, size: 50);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 3);
      expect(params['size'], 50);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listEbooks();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Internal server error',
      ));

      expect(
        () => service.listEbooks(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getEbook', () {
    test('returns parsed ebook', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks/e1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'e1',
              'title': 'My Book',
              'format': 'PDF',
              'fileSizeBytes': 3000,
            },
          });

      final result = await service.getEbook('e1');

      expect(result.title, 'My Book');
      expect(result.format, 'PDF');
    });
  });

  group('deleteEbook', () {
    test('calls delete on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.libraryBasePath}/ebooks/e1',
          )).thenAnswer((_) async {});

      await service.deleteEbook('e1');

      verify(() => mockClient.delete(
            '${AppConstants.libraryBasePath}/ebooks/e1',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.libraryBasePath}/ebooks/e1',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'eBook not found',
      ));

      expect(
        () => service.deleteEbook('e1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('uploadEbook', () {
    test('sends multipart POST and returns parsed eBook', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            any(),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'e-new',
              'title': 'Survival Guide',
              'author': 'Bear Grylls',
              'format': 'EPUB',
              'fileSizeBytes': 12000,
            },
          });

      final result = await service.uploadEbook(
        filename: 'survival.epub',
        bytes: [0x50, 0x4B],
        title: 'Survival Guide',
        author: 'Bear Grylls',
      );

      expect(result.id, 'e-new');
      expect(result.title, 'Survival Guide');
      expect(result.author, 'Bear Grylls');
      expect(result.format, 'EPUB');
      verify(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            any(),
          )).called(1);
    });

    test('sends without author when null', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            any(),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'e-no-author',
              'title': 'Unknown Author Book',
              'format': 'EPUB',
              'fileSizeBytes': 4000,
            },
          });

      final result = await service.uploadEbook(
        filename: 'book.epub',
        bytes: [0x50, 0x4B],
        title: 'Unknown Author Book',
      );

      expect(result.id, 'e-no-author');
      expect(result.title, 'Unknown Author Book');
      verify(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            any(),
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.postMultipart<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            any(),
          )).thenThrow(const ApiException(
        statusCode: 413,
        message: 'File too large',
      ));

      expect(
        () => service.uploadEbook(
          filename: 'huge.epub',
          bytes: [0x00],
          title: 'Huge Book',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('downloadEbookContent', () {
    test('returns raw bytes', () async {
      final bytes = [0x50, 0x44, 0x46]; // "PDF"
      when(() => mockClient.getBytes(
            '${AppConstants.libraryBasePath}/ebooks/e1/content',
          )).thenAnswer((_) async => bytes);

      final result = await service.downloadEbookContent('e1');

      expect(result, bytes);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.getBytes(
            '${AppConstants.libraryBasePath}/ebooks/e1/content',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Content not found',
      ));

      expect(
        () => service.downloadEbookContent('e1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Gutenberg ───────────────────────────────────────────────────────────

  group('searchGutenberg', () {
    test('returns parsed search results', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/gutenberg/search',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {
              'count': 1,
              'next': null,
              'previous': null,
              'results': [
                {
                  'id': 1342,
                  'title': 'Pride and Prejudice',
                  'authors': ['Austen, Jane'],
                  'subjects': <String>[],
                  'languages': ['en'],
                  'downloadCount': 50000,
                  'formats': <String, String>{},
                },
              ],
            },
          });

      final result = await service.searchGutenberg('pride');

      expect(result.count, 1);
      expect(result.results, hasLength(1));
      expect(result.results[0].title, 'Pride and Prejudice');
    });

    test('passes query and limit params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/gutenberg/search',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {
              'count': 0,
              'results': <dynamic>[],
            },
          });

      await service.searchGutenberg('test', limit: 10);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/gutenberg/search',
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['query'], 'test');
      expect(params['limit'], 10);
    });
  });

  group('getGutenbergBook', () {
    test('returns parsed book metadata', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/gutenberg/84',
          )).thenAnswer((_) async => {
            'data': {
              'id': 84,
              'title': 'Frankenstein',
              'authors': ['Shelley, Mary'],
              'subjects': <String>[],
              'languages': ['en'],
              'downloadCount': 100000,
              'formats': <String, String>{},
            },
          });

      final result = await service.getGutenbergBook(84);

      expect(result.id, 84);
      expect(result.title, 'Frankenstein');
    });
  });

  group('importGutenbergBook', () {
    test('returns imported ebook', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/gutenberg/1342/import',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'e-imported',
              'title': 'Pride and Prejudice',
              'format': 'EPUB',
              'fileSizeBytes': 5000,
              'gutenbergId': '1342',
            },
          });

      final result = await service.importGutenbergBook(1342);

      expect(result.id, 'e-imported');
      expect(result.title, 'Pride and Prejudice');
      expect(result.gutenbergId, '1342');
      expect(result.isFromGutenberg, isTrue);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/gutenberg/9999/import',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'Gutenberg book not found',
      ));

      expect(
        () => service.importGutenbergBook(9999),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('libraryServiceProvider', () {
    test('creates LibraryService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(libraryServiceProvider), isA<LibraryService>());
    });
  });

  group('zimFilesProvider', () {
    test('returns ZIM files from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/zim',
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'zim-1', 'filename': 'wiki.zim', 'displayName': 'Wikipedia'},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final files = await container.read(zimFilesProvider.future);
      expect(files, hasLength(1));
    });
  });

  group('ebooksProvider', () {
    test('returns ebooks from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'book-1', 'title': 'Test Book', 'format': 'epub'},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final books = await container.read(
          ebooksProvider((search: null, format: null)).future);
      expect(books, hasLength(1));
    });
  });

  group('kiwixStatusProvider', () {
    test('returns Kiwix status from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/kiwix/status',
          )).thenAnswer((_) async => {
            'data': {'available': true, 'url': 'http://localhost:8888', 'bookCount': 3},
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final status = await container.read(kiwixStatusProvider.future);
      expect(status.available, isTrue);
      expect(status.bookCount, 3);
    });
  });

  group('kiwixUrlProvider', () {
    test('returns Kiwix URL from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/kiwix/url',
          )).thenAnswer((_) async => {
            'data': 'http://localhost:8888',
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final url = await container.read(kiwixUrlProvider.future);
      expect(url, 'http://localhost:8888');
    });
  });
}
