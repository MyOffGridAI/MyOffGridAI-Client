import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';

void main() {
  group('ZimFileModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'zim-1',
        'filename': 'wikipedia.zim',
        'displayName': 'Wikipedia',
        'description': 'Full English Wikipedia',
        'language': 'en',
        'category': 'reference',
        'fileSizeBytes': 2048000,
        'articleCount': 100000,
        'mediaCount': 5000,
        'createdDate': '2026-01-01',
        'kiwixBookId': 'wiki-en',
        'uploadedAt': '2026-01-15T10:00:00Z',
        'uploadedBy': 'user-1',
      };

      final model = ZimFileModel.fromJson(json);

      expect(model.id, 'zim-1');
      expect(model.filename, 'wikipedia.zim');
      expect(model.displayName, 'Wikipedia');
      expect(model.description, 'Full English Wikipedia');
      expect(model.language, 'en');
      expect(model.category, 'reference');
      expect(model.fileSizeBytes, 2048000);
      expect(model.articleCount, 100000);
      expect(model.mediaCount, 5000);
      expect(model.createdDate, '2026-01-01');
      expect(model.kiwixBookId, 'wiki-en');
      expect(model.uploadedAt, '2026-01-15T10:00:00Z');
      expect(model.uploadedBy, 'user-1');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'zim-2',
        'filename': 'test.zim',
        'fileSizeBytes': 1024,
      };

      final model = ZimFileModel.fromJson(json);

      expect(model.id, 'zim-2');
      expect(model.displayName, isNull);
      expect(model.description, isNull);
      expect(model.language, isNull);
      expect(model.category, isNull);
      expect(model.articleCount, 0);
      expect(model.mediaCount, 0);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'id': 'zim-3',
        'filename': null,
        'fileSizeBytes': null,
        'articleCount': null,
        'mediaCount': null,
      };

      final model = ZimFileModel.fromJson(json);

      expect(model.filename, '');
      expect(model.fileSizeBytes, 0);
      expect(model.articleCount, 0);
      expect(model.mediaCount, 0);
    });
  });

  group('EbookModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'ebook-1',
        'title': 'Pride and Prejudice',
        'author': 'Jane Austen',
        'description': 'A classic novel',
        'isbn': '978-0-123456-78-9',
        'publisher': 'Penguin',
        'publishedYear': '1813',
        'language': 'en',
        'format': 'EPUB',
        'fileSizeBytes': 512000,
        'gutenbergId': '1342',
        'downloadCount': 50,
        'hasCoverImage': true,
        'uploadedAt': '2026-03-01T12:00:00Z',
        'uploadedBy': 'user-1',
      };

      final model = EbookModel.fromJson(json);

      expect(model.id, 'ebook-1');
      expect(model.title, 'Pride and Prejudice');
      expect(model.author, 'Jane Austen');
      expect(model.description, 'A classic novel');
      expect(model.isbn, '978-0-123456-78-9');
      expect(model.publisher, 'Penguin');
      expect(model.publishedYear, '1813');
      expect(model.language, 'en');
      expect(model.format, 'EPUB');
      expect(model.fileSizeBytes, 512000);
      expect(model.gutenbergId, '1342');
      expect(model.downloadCount, 50);
      expect(model.hasCoverImage, isTrue);
      expect(model.isFromGutenberg, isTrue);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'ebook-2',
        'title': 'Test',
        'format': 'PDF',
        'fileSizeBytes': 1024,
      };

      final model = EbookModel.fromJson(json);

      expect(model.author, isNull);
      expect(model.gutenbergId, isNull);
      expect(model.downloadCount, 0);
      expect(model.hasCoverImage, isFalse);
      expect(model.isFromGutenberg, isFalse);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'id': 'ebook-3',
        'title': null,
        'format': null,
        'fileSizeBytes': null,
        'downloadCount': null,
        'hasCoverImage': null,
      };

      final model = EbookModel.fromJson(json);

      expect(model.title, '');
      expect(model.format, 'EPUB');
      expect(model.fileSizeBytes, 0);
      expect(model.downloadCount, 0);
      expect(model.hasCoverImage, isFalse);
    });

    test('isFromGutenberg returns true when gutenbergId is set', () {
      const model = EbookModel(
        id: 'e1',
        title: 'Test',
        format: 'EPUB',
        fileSizeBytes: 100,
        gutenbergId: '42',
      );
      expect(model.isFromGutenberg, isTrue);
    });

    test('isFromGutenberg returns false when gutenbergId is null', () {
      const model = EbookModel(
        id: 'e2',
        title: 'Test',
        format: 'EPUB',
        fileSizeBytes: 100,
      );
      expect(model.isFromGutenberg, isFalse);
    });
  });

  group('KiwixStatusModel', () {
    test('fromJson parses available status', () {
      final json = {
        'available': true,
        'url': 'http://localhost:8888',
        'bookCount': 5,
      };

      final model = KiwixStatusModel.fromJson(json);

      expect(model.available, isTrue);
      expect(model.url, 'http://localhost:8888');
      expect(model.bookCount, 5);
    });

    test('fromJson handles unavailable status', () {
      final json = {
        'available': false,
        'url': null,
        'bookCount': 0,
      };

      final model = KiwixStatusModel.fromJson(json);

      expect(model.available, isFalse);
      expect(model.url, isNull);
      expect(model.bookCount, 0);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{
        'available': null,
        'bookCount': null,
      };

      final model = KiwixStatusModel.fromJson(json);

      expect(model.available, isFalse);
      expect(model.bookCount, 0);
    });
  });

  group('GutenbergBookModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 1342,
        'title': 'Pride and Prejudice',
        'authors': ['Austen, Jane'],
        'subjects': ['Fiction', 'Love stories'],
        'languages': ['en'],
        'downloadCount': 50000,
        'formats': {
          'application/epub+zip': 'https://gutenberg.org/1342.epub',
          'text/plain; charset=us-ascii': 'https://gutenberg.org/1342.txt',
        },
      };

      final model = GutenbergBookModel.fromJson(json);

      expect(model.id, 1342);
      expect(model.title, 'Pride and Prejudice');
      expect(model.authors, ['Austen, Jane']);
      expect(model.subjects, hasLength(2));
      expect(model.languages, ['en']);
      expect(model.downloadCount, 50000);
      expect(model.formats, hasLength(2));
      expect(model.hasEpub, isTrue);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 42,
        'title': 'Test',
      };

      final model = GutenbergBookModel.fromJson(json);

      expect(model.authors, isEmpty);
      expect(model.subjects, isEmpty);
      expect(model.languages, isEmpty);
      expect(model.downloadCount, 0);
      expect(model.formats, isEmpty);
      expect(model.hasEpub, isFalse);
    });

    test('hasEpub returns true when epub format exists', () {
      const model = GutenbergBookModel(
        id: 1,
        title: 'Test',
        formats: {'application/epub+zip': 'url'},
      );
      expect(model.hasEpub, isTrue);
    });

    test('hasEpub returns false when no epub format', () {
      const model = GutenbergBookModel(
        id: 1,
        title: 'Test',
        formats: {'text/plain': 'url'},
      );
      expect(model.hasEpub, isFalse);
    });
  });

  group('GutenbergSearchResultModel', () {
    test('fromJson parses full response', () {
      final json = {
        'count': 2,
        'next': 'https://gutendex.com/books?page=2',
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
          {
            'id': 84,
            'title': 'Frankenstein',
            'authors': ['Shelley, Mary'],
            'subjects': <String>[],
            'languages': ['en'],
            'downloadCount': 100000,
            'formats': <String, String>{},
          },
        ],
      };

      final model = GutenbergSearchResultModel.fromJson(json);

      expect(model.count, 2);
      expect(model.next, isNotNull);
      expect(model.previous, isNull);
      expect(model.results, hasLength(2));
      expect(model.results[0].title, 'Pride and Prejudice');
      expect(model.results[1].title, 'Frankenstein');
    });

    test('fromJson handles empty results', () {
      final json = {
        'count': 0,
        'next': null,
        'previous': null,
        'results': <dynamic>[],
      };

      final model = GutenbergSearchResultModel.fromJson(json);

      expect(model.count, 0);
      expect(model.results, isEmpty);
    });

    test('fromJson handles null results list', () {
      final json = <String, dynamic>{
        'count': 0,
      };

      final model = GutenbergSearchResultModel.fromJson(json);

      expect(model.results, isEmpty);
    });
  });
}
