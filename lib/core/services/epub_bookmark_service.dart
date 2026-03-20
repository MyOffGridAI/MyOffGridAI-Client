import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/epub_bookmark_model.dart';

/// Manages EPUB reading state persistence (last position and bookmarks).
///
/// Uses [SecureStorageService] to persist [EpubReadingState] as JSON under
/// the key `epub_state_{bookId}`. Maintains an in-memory cache per book
/// to avoid redundant reads during a session.
class EpubBookmarkService {
  final SecureStorageService _storage;

  /// In-memory cache of reading states keyed by book ID.
  final Map<String, EpubReadingState> _stateCache = {};

  /// Creates an [EpubBookmarkService] backed by the given [SecureStorageService].
  EpubBookmarkService(this._storage);

  /// Returns the storage key for a given [bookId].
  String _keyFor(String bookId) => '${AppConstants.epubStateKeyPrefix}$bookId';

  /// Returns the persisted [EpubReadingState] for [bookId].
  ///
  /// Returns a default empty state if nothing has been saved yet.
  Future<EpubReadingState> getReadingState(String bookId) async {
    final cached = _stateCache[bookId];
    if (cached != null) return cached;

    final json = await _storage.readValue(_keyFor(bookId));
    if (json == null) {
      const empty = EpubReadingState();
      _stateCache[bookId] = empty;
      return empty;
    }

    try {
      final state = EpubReadingState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      _stateCache[bookId] = state;
      return state;
    } catch (_) {
      const empty = EpubReadingState();
      _stateCache[bookId] = empty;
      return empty;
    }
  }

  /// Persists the given [state] for [bookId].
  Future<void> _saveState(String bookId, EpubReadingState state) async {
    _stateCache[bookId] = state;
    await _storage.writeValue(_keyFor(bookId), jsonEncode(state.toJson()));
  }

  /// Updates the last reading position CFI for [bookId].
  Future<void> saveLastPosition(String bookId, String cfi) async {
    final state = await getReadingState(bookId);
    await _saveState(bookId, state.copyWith(lastPositionCfi: cfi));
  }

  /// Adds a [bookmark] to the saved bookmarks for [bookId].
  Future<void> addBookmark(String bookId, EpubBookmarkModel bookmark) async {
    final state = await getReadingState(bookId);
    final updated = List<EpubBookmarkModel>.from(state.bookmarks)..add(bookmark);
    await _saveState(bookId, state.copyWith(bookmarks: updated));
  }

  /// Removes the bookmark matching [cfi] from [bookId].
  Future<void> removeBookmark(String bookId, String cfi) async {
    final state = await getReadingState(bookId);
    final updated = state.bookmarks.where((b) => b.cfi != cfi).toList();
    await _saveState(bookId, state.copyWith(bookmarks: updated));
  }

  /// Returns all saved bookmarks for [bookId].
  Future<List<EpubBookmarkModel>> getBookmarks(String bookId) async {
    final state = await getReadingState(bookId);
    return state.bookmarks;
  }

  /// Returns `true` if a bookmark exists at the given [cfi] for [bookId].
  ///
  /// Checks the in-memory cache first; falls back to loading from storage.
  Future<bool> hasBookmarkAtCfi(String bookId, String cfi) async {
    final state = await getReadingState(bookId);
    return state.bookmarks.any((b) => b.cfi == cfi);
  }
}

/// Riverpod provider for [EpubBookmarkService].
final epubBookmarkServiceProvider = Provider<EpubBookmarkService>((ref) {
  return EpubBookmarkService(ref.watch(secureStorageProvider));
});
