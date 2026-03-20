import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/epub_bookmark_model.dart';

void main() {
  // ── EpubBookmarkModel ─────────────────────────────────────────────────
  group('EpubBookmarkModel', () {
    test('fromJson / toJson round-trip preserves all fields', () {
      final original = EpubBookmarkModel(
        cfi: 'epubcfi(/6/4[chap01]!/4/2/2)',
        chapterTitle: 'Chapter One',
        chapterNumber: 1,
        label: 'Important passage',
        createdAt: '2026-03-19T12:00:00.000Z',
      );

      final json = original.toJson();
      final restored = EpubBookmarkModel.fromJson(json);

      expect(restored.cfi, original.cfi);
      expect(restored.chapterTitle, original.chapterTitle);
      expect(restored.chapterNumber, original.chapterNumber);
      expect(restored.label, original.label);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'cfi': 'epubcfi(/6/8)',
        'chapterNumber': 3,
        'createdAt': '2026-03-19T00:00:00.000Z',
      };

      final bookmark = EpubBookmarkModel.fromJson(json);

      expect(bookmark.cfi, 'epubcfi(/6/8)');
      expect(bookmark.chapterTitle, isNull);
      expect(bookmark.chapterNumber, 3);
      expect(bookmark.label, isNull);
      expect(bookmark.createdAt, '2026-03-19T00:00:00.000Z');
    });

    test('fromJson defaults chapterNumber to 1 when missing', () {
      final json = {
        'cfi': 'epubcfi(/6/2)',
        'createdAt': '2026-03-19T00:00:00.000Z',
      };

      final bookmark = EpubBookmarkModel.fromJson(json);

      expect(bookmark.chapterNumber, 1);
    });

    test('toJson includes null optional fields', () {
      const bookmark = EpubBookmarkModel(
        cfi: 'epubcfi(/6/2)',
        chapterNumber: 2,
        createdAt: '2026-03-19T00:00:00.000Z',
      );

      final json = bookmark.toJson();

      expect(json.containsKey('chapterTitle'), isTrue);
      expect(json['chapterTitle'], isNull);
      expect(json.containsKey('label'), isTrue);
      expect(json['label'], isNull);
    });
  });

  // ── EpubReadingState ──────────────────────────────────────────────────
  group('EpubReadingState', () {
    test('fromJson / toJson round-trip preserves all fields', () {
      final original = EpubReadingState(
        lastPositionCfi: 'epubcfi(/6/4)',
        bookmarks: [
          const EpubBookmarkModel(
            cfi: 'epubcfi(/6/4[chap01]!/4/2/2)',
            chapterTitle: 'Chapter One',
            chapterNumber: 1,
            createdAt: '2026-03-19T12:00:00.000Z',
          ),
          const EpubBookmarkModel(
            cfi: 'epubcfi(/6/8)',
            chapterNumber: 3,
            label: 'Favorite',
            createdAt: '2026-03-19T13:00:00.000Z',
          ),
        ],
      );

      final json = original.toJson();
      final restored = EpubReadingState.fromJson(json);

      expect(restored.lastPositionCfi, original.lastPositionCfi);
      expect(restored.bookmarks.length, 2);
      expect(restored.bookmarks[0].cfi, original.bookmarks[0].cfi);
      expect(restored.bookmarks[1].label, 'Favorite');
    });

    test('fromJson handles null lastPositionCfi', () {
      final json = <String, dynamic>{
        'bookmarks': <dynamic>[],
      };

      final state = EpubReadingState.fromJson(json);

      expect(state.lastPositionCfi, isNull);
      expect(state.bookmarks, isEmpty);
    });

    test('fromJson handles missing bookmarks list', () {
      final json = <String, dynamic>{
        'lastPositionCfi': 'epubcfi(/6/2)',
      };

      final state = EpubReadingState.fromJson(json);

      expect(state.lastPositionCfi, 'epubcfi(/6/2)');
      expect(state.bookmarks, isEmpty);
    });

    test('default constructor produces empty state', () {
      const state = EpubReadingState();

      expect(state.lastPositionCfi, isNull);
      expect(state.bookmarks, isEmpty);
    });

    test('copyWith replaces lastPositionCfi', () {
      const original = EpubReadingState(lastPositionCfi: 'old');
      final updated = original.copyWith(lastPositionCfi: 'new');

      expect(updated.lastPositionCfi, 'new');
      expect(updated.bookmarks, isEmpty);
    });

    test('copyWith replaces bookmarks', () {
      const original = EpubReadingState();
      final updated = original.copyWith(
        bookmarks: [
          const EpubBookmarkModel(
            cfi: 'epubcfi(/6/2)',
            chapterNumber: 1,
            createdAt: '2026-03-19T00:00:00.000Z',
          ),
        ],
      );

      expect(updated.bookmarks.length, 1);
      expect(updated.lastPositionCfi, isNull);
    });

    test('copyWith with no arguments returns equivalent state', () {
      const original = EpubReadingState(lastPositionCfi: 'keep');
      final copied = original.copyWith();

      expect(copied.lastPositionCfi, 'keep');
      expect(copied.bookmarks, isEmpty);
    });
  });
}
