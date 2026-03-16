/// Models for the offline library system including ZIM files, eBooks,
/// Kiwix status, and Project Gutenberg integration.
///
/// Mirrors the server-side DTOs: ZimFileDto, EbookDto, KiwixStatusDto,
/// GutenbergBookDto, and GutenbergSearchResultDto.
library;

/// Represents a ZIM file in the offline library.
///
/// ZIM files contain compressed wiki-style content (e.g. Wikipedia,
/// medical references) served via Kiwix.
class ZimFileModel {
  final String id;
  final String filename;
  final String? displayName;
  final String? description;
  final String? language;
  final String? category;
  final int fileSizeBytes;
  final int articleCount;
  final int mediaCount;
  final String? createdDate;
  final String? kiwixBookId;
  final String? uploadedAt;
  final String? uploadedBy;

  const ZimFileModel({
    required this.id,
    required this.filename,
    this.displayName,
    this.description,
    this.language,
    this.category,
    required this.fileSizeBytes,
    this.articleCount = 0,
    this.mediaCount = 0,
    this.createdDate,
    this.kiwixBookId,
    this.uploadedAt,
    this.uploadedBy,
  });

  /// Creates a [ZimFileModel] from a JSON map.
  factory ZimFileModel.fromJson(Map<String, dynamic> json) {
    return ZimFileModel(
      id: json['id'] as String,
      filename: json['filename'] as String? ?? '',
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      language: json['language'] as String?,
      category: json['category'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      articleCount: json['articleCount'] as int? ?? 0,
      mediaCount: json['mediaCount'] as int? ?? 0,
      createdDate: json['createdDate'] as String?,
      kiwixBookId: json['kiwixBookId'] as String?,
      uploadedAt: json['uploadedAt'] as String?,
      uploadedBy: json['uploadedBy'] as String?,
    );
  }
}

/// Represents an eBook in the offline library.
///
/// Supports multiple formats (EPUB, PDF, MOBI, AZW, TXT, HTML).
/// Books imported from Project Gutenberg include a [gutenbergId].
class EbookModel {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? isbn;
  final String? publisher;
  final String? publishedYear;
  final String? language;
  final String format;
  final int fileSizeBytes;
  final String? gutenbergId;
  final int downloadCount;
  final bool hasCoverImage;
  final String? uploadedAt;
  final String? uploadedBy;

  const EbookModel({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.isbn,
    this.publisher,
    this.publishedYear,
    this.language,
    required this.format,
    required this.fileSizeBytes,
    this.gutenbergId,
    this.downloadCount = 0,
    this.hasCoverImage = false,
    this.uploadedAt,
    this.uploadedBy,
  });

  /// Creates an [EbookModel] from a JSON map.
  factory EbookModel.fromJson(Map<String, dynamic> json) {
    return EbookModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String?,
      description: json['description'] as String?,
      isbn: json['isbn'] as String?,
      publisher: json['publisher'] as String?,
      publishedYear: json['publishedYear'] as String?,
      language: json['language'] as String?,
      format: json['format'] as String? ?? 'EPUB',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      gutenbergId: json['gutenbergId'] as String?,
      downloadCount: json['downloadCount'] as int? ?? 0,
      hasCoverImage: json['hasCoverImage'] as bool? ?? false,
      uploadedAt: json['uploadedAt'] as String?,
      uploadedBy: json['uploadedBy'] as String?,
    );
  }

  /// Whether this book was imported from Project Gutenberg.
  bool get isFromGutenberg => gutenbergId != null;
}

/// Status of the Kiwix serve instance.
///
/// Indicates whether the Kiwix server is reachable and how many
/// ZIM files are loaded.
class KiwixStatusModel {
  final bool available;
  final String? url;
  final int bookCount;

  const KiwixStatusModel({
    required this.available,
    this.url,
    required this.bookCount,
  });

  /// Creates a [KiwixStatusModel] from a JSON map.
  factory KiwixStatusModel.fromJson(Map<String, dynamic> json) {
    return KiwixStatusModel(
      available: json['available'] as bool? ?? false,
      url: json['url'] as String?,
      bookCount: json['bookCount'] as int? ?? 0,
    );
  }
}

/// Represents a book from the Project Gutenberg catalog.
///
/// Returned by the Gutendex API search and metadata endpoints.
class GutenbergBookModel {
  final int id;
  final String title;
  final List<String> authors;
  final List<String> subjects;
  final List<String> languages;
  final int downloadCount;
  final Map<String, String> formats;

  const GutenbergBookModel({
    required this.id,
    required this.title,
    this.authors = const [],
    this.subjects = const [],
    this.languages = const [],
    this.downloadCount = 0,
    this.formats = const {},
  });

  /// Creates a [GutenbergBookModel] from a JSON map.
  factory GutenbergBookModel.fromJson(Map<String, dynamic> json) {
    return GutenbergBookModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      downloadCount: json['downloadCount'] as int? ?? 0,
      formats: (json['formats'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
    );
  }

  /// Whether an EPUB download is available.
  bool get hasEpub => formats.containsKey('application/epub+zip');
}

/// Paginated search results from the Gutenberg catalog.
///
/// Wraps the Gutendex API response structure.
class GutenbergSearchResultModel {
  final int count;
  final String? next;
  final String? previous;
  final List<GutenbergBookModel> results;

  const GutenbergSearchResultModel({
    required this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  /// Creates a [GutenbergSearchResultModel] from a JSON map.
  factory GutenbergSearchResultModel.fromJson(Map<String, dynamic> json) {
    return GutenbergSearchResultModel(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) =>
                  GutenbergBookModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
