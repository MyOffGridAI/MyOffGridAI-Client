import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/epub_bookmark_model.dart';
import 'package:myoffgridai_client/core/services/epub_bookmark_service.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorage;
  late EpubBookmarkService service;

  const bookId = 'book-123';
  final storageKey = '${AppConstants.epubStateKeyPrefix}$bookId';

  setUp(() {
    mockStorage = MockSecureStorageService();
    service = EpubBookmarkService(mockStorage);
  });

  // ── getReadingState ─────────────────────────────────────────────────
  group('getReadingState', () {
    test('returns empty state when no stored data', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);

      final state = await service.getReadingState(bookId);

      expect(state.lastPositionCfi, isNull);
      expect(state.bookmarks, isEmpty);
    });

    test('parses stored JSON into EpubReadingState', () async {
      final storedJson = jsonEncode({
        'lastPositionCfi': 'epubcfi(/6/4)',
        'bookmarks': [
          {
            'cfi': 'epubcfi(/6/4[chap01])',
            'chapterTitle': 'Chapter 1',
            'chapterNumber': 1,
            'createdAt': '2026-03-19T12:00:00.000Z',
          },
        ],
      });

      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => storedJson);

      final state = await service.getReadingState(bookId);

      expect(state.lastPositionCfi, 'epubcfi(/6/4)');
      expect(state.bookmarks.length, 1);
      expect(state.bookmarks[0].chapterTitle, 'Chapter 1');
    });

    test('returns empty state when stored JSON is invalid', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => 'not valid json');

      final state = await service.getReadingState(bookId);

      expect(state.lastPositionCfi, isNull);
      expect(state.bookmarks, isEmpty);
    });

    test('caches state after first load', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);

      await service.getReadingState(bookId);
      await service.getReadingState(bookId);

      // Only one storage read call
      verify(() => mockStorage.readValue(storageKey)).called(1);
    });
  });

  // ── saveLastPosition ────────────────────────────────────────────────
  group('saveLastPosition', () {
    test('updates lastPositionCfi and persists', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);
      when(() => mockStorage.writeValue(storageKey, any()))
          .thenAnswer((_) async {});

      await service.saveLastPosition(bookId, 'epubcfi(/6/8)');

      final captured = verify(
        () => mockStorage.writeValue(storageKey, captureAny()),
      ).captured.single as String;

      final savedState =
          EpubReadingState.fromJson(jsonDecode(captured) as Map<String, dynamic>);
      expect(savedState.lastPositionCfi, 'epubcfi(/6/8)');
    });
  });

  // ── addBookmark ─────────────────────────────────────────────────────
  group('addBookmark', () {
    test('appends bookmark and persists', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);
      when(() => mockStorage.writeValue(storageKey, any()))
          .thenAnswer((_) async {});

      const bookmark = EpubBookmarkModel(
        cfi: 'epubcfi(/6/4[chap01])',
        chapterTitle: 'Chapter 1',
        chapterNumber: 1,
        createdAt: '2026-03-19T12:00:00.000Z',
      );

      await service.addBookmark(bookId, bookmark);

      final captured = verify(
        () => mockStorage.writeValue(storageKey, captureAny()),
      ).captured.single as String;

      final savedState =
          EpubReadingState.fromJson(jsonDecode(captured) as Map<String, dynamic>);
      expect(savedState.bookmarks.length, 1);
      expect(savedState.bookmarks[0].cfi, 'epubcfi(/6/4[chap01])');
    });

    test('appends to existing bookmarks', () async {
      final existing = jsonEncode({
        'bookmarks': [
          {
            'cfi': 'epubcfi(/6/2)',
            'chapterNumber': 1,
            'createdAt': '2026-03-19T11:00:00.000Z',
          },
        ],
      });

      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => existing);
      when(() => mockStorage.writeValue(storageKey, any()))
          .thenAnswer((_) async {});

      const newBookmark = EpubBookmarkModel(
        cfi: 'epubcfi(/6/8)',
        chapterNumber: 3,
        createdAt: '2026-03-19T12:00:00.000Z',
      );

      await service.addBookmark(bookId, newBookmark);

      final captured = verify(
        () => mockStorage.writeValue(storageKey, captureAny()),
      ).captured.single as String;

      final savedState =
          EpubReadingState.fromJson(jsonDecode(captured) as Map<String, dynamic>);
      expect(savedState.bookmarks.length, 2);
    });
  });

  // ── removeBookmark ──────────────────────────────────────────────────
  group('removeBookmark', () {
    test('removes bookmark by CFI match', () async {
      final existing = jsonEncode({
        'bookmarks': [
          {
            'cfi': 'epubcfi(/6/2)',
            'chapterNumber': 1,
            'createdAt': '2026-03-19T11:00:00.000Z',
          },
          {
            'cfi': 'epubcfi(/6/8)',
            'chapterNumber': 3,
            'createdAt': '2026-03-19T12:00:00.000Z',
          },
        ],
      });

      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => existing);
      when(() => mockStorage.writeValue(storageKey, any()))
          .thenAnswer((_) async {});

      await service.removeBookmark(bookId, 'epubcfi(/6/2)');

      final captured = verify(
        () => mockStorage.writeValue(storageKey, captureAny()),
      ).captured.single as String;

      final savedState =
          EpubReadingState.fromJson(jsonDecode(captured) as Map<String, dynamic>);
      expect(savedState.bookmarks.length, 1);
      expect(savedState.bookmarks[0].cfi, 'epubcfi(/6/8)');
    });

    test('no-op when CFI does not match any bookmark', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);
      when(() => mockStorage.writeValue(storageKey, any()))
          .thenAnswer((_) async {});

      await service.removeBookmark(bookId, 'epubcfi(/nonexistent)');

      final captured = verify(
        () => mockStorage.writeValue(storageKey, captureAny()),
      ).captured.single as String;

      final savedState =
          EpubReadingState.fromJson(jsonDecode(captured) as Map<String, dynamic>);
      expect(savedState.bookmarks, isEmpty);
    });
  });

  // ── getBookmarks ────────────────────────────────────────────────────
  group('getBookmarks', () {
    test('returns empty list when no bookmarks', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);

      final bookmarks = await service.getBookmarks(bookId);

      expect(bookmarks, isEmpty);
    });

    test('returns saved bookmarks', () async {
      final existing = jsonEncode({
        'bookmarks': [
          {
            'cfi': 'epubcfi(/6/4)',
            'chapterNumber': 2,
            'createdAt': '2026-03-19T12:00:00.000Z',
          },
        ],
      });

      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => existing);

      final bookmarks = await service.getBookmarks(bookId);

      expect(bookmarks.length, 1);
      expect(bookmarks[0].chapterNumber, 2);
    });
  });

  // ── hasBookmarkAtCfi ────────────────────────────────────────────────
  group('hasBookmarkAtCfi', () {
    test('returns true when bookmark exists at CFI', () async {
      final existing = jsonEncode({
        'bookmarks': [
          {
            'cfi': 'epubcfi(/6/4)',
            'chapterNumber': 1,
            'createdAt': '2026-03-19T12:00:00.000Z',
          },
        ],
      });

      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => existing);

      final has = await service.hasBookmarkAtCfi(bookId, 'epubcfi(/6/4)');

      expect(has, isTrue);
    });

    test('returns false when no bookmark at CFI', () async {
      when(() => mockStorage.readValue(storageKey))
          .thenAnswer((_) async => null);

      final has = await service.hasBookmarkAtCfi(bookId, 'epubcfi(/6/99)');

      expect(has, isFalse);
    });
  });

  // ── Provider ────────────────────────────────────────────────────────
  group('epubBookmarkServiceProvider', () {
    test('creates EpubBookmarkService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bookmarkService = container.read(epubBookmarkServiceProvider);
      expect(bookmarkService, isA<EpubBookmarkService>());
    });
  });
}
