/// Data models for EPUB reading state persistence.
///
/// [EpubBookmarkModel] represents a single bookmark with a CFI location,
/// chapter context, and optional user label. [EpubReadingState] aggregates
/// the last reading position and all bookmarks for a single book.
library;

/// A single saved bookmark within an EPUB book.
///
/// Stores the EPUB CFI string for precise navigation, along with chapter
/// context captured at the time the bookmark was created.
class EpubBookmarkModel {
  /// EPUB CFI string for precise position navigation.
  final String cfi;

  /// Chapter title at the time this bookmark was created.
  final String? chapterTitle;

  /// 1-based chapter index.
  final int chapterNumber;

  /// Optional user-provided label for this bookmark.
  final String? label;

  /// ISO-8601 timestamp of when this bookmark was created.
  final String createdAt;

  /// Creates an [EpubBookmarkModel].
  const EpubBookmarkModel({
    required this.cfi,
    this.chapterTitle,
    required this.chapterNumber,
    this.label,
    required this.createdAt,
  });

  /// Creates an [EpubBookmarkModel] from a JSON map.
  factory EpubBookmarkModel.fromJson(Map<String, dynamic> json) {
    return EpubBookmarkModel(
      cfi: json['cfi'] as String,
      chapterTitle: json['chapterTitle'] as String?,
      chapterNumber: json['chapterNumber'] as int? ?? 1,
      label: json['label'] as String?,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Serializes this bookmark to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'cfi': cfi,
      'chapterTitle': chapterTitle,
      'chapterNumber': chapterNumber,
      'label': label,
      'createdAt': createdAt,
    };
  }
}

/// All persisted reading state for a single EPUB book.
///
/// Tracks the last reading position for resume-on-open and a list of
/// user-created bookmarks.
class EpubReadingState {
  /// CFI string for the last reading position, used to resume on open.
  final String? lastPositionCfi;

  /// All saved bookmarks for this book.
  final List<EpubBookmarkModel> bookmarks;

  /// Creates an [EpubReadingState].
  const EpubReadingState({
    this.lastPositionCfi,
    this.bookmarks = const [],
  });

  /// Creates an [EpubReadingState] from a JSON map.
  factory EpubReadingState.fromJson(Map<String, dynamic> json) {
    return EpubReadingState(
      lastPositionCfi: json['lastPositionCfi'] as String?,
      bookmarks: (json['bookmarks'] as List<dynamic>?)
              ?.map((e) => EpubBookmarkModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serializes this reading state to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'lastPositionCfi': lastPositionCfi,
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    };
  }

  /// Creates a copy of this state with the given fields replaced.
  EpubReadingState copyWith({
    String? lastPositionCfi,
    List<EpubBookmarkModel>? bookmarks,
  }) {
    return EpubReadingState(
      lastPositionCfi: lastPositionCfi ?? this.lastPositionCfi,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
