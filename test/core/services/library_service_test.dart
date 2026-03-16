import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late LibraryService service;

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

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.libraryBasePath}/ebooks',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listEbooks();

      expect(result, isEmpty);
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
  });
}
