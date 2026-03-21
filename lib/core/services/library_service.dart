import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';

/// Service for the offline library system covering ZIM files, eBooks,
/// Kiwix status, and Project Gutenberg integration.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class LibraryService {
  final MyOffGridAIApiClient _client;

  /// Creates a [LibraryService] with the given API [client].
  LibraryService({required MyOffGridAIApiClient client}) : _client = client;

  // ── ZIM Files ───────────────────────────────────────────────────────────

  /// Lists all ZIM files in the library.
  Future<List<ZimFileModel>> listZimFiles() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/zim',
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => ZimFileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Uploads a ZIM file with the given metadata.
  Future<ZimFileModel> uploadZimFile({
    required String filename,
    required List<int> bytes,
    required String displayName,
    String? category,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'displayName': displayName,
      'category': ?category,
    });
    final response = await _client.postMultipart<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/zim',
      formData,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ZimFileModel.fromJson(data);
  }

  /// Deletes a ZIM file by [id].
  Future<void> deleteZimFile(String id) async {
    await _client.delete('${AppConstants.libraryBasePath}/zim/$id');
  }

  // ── Kiwix ───────────────────────────────────────────────────────────────

  /// Returns the current Kiwix serve status.
  Future<KiwixStatusModel> getKiwixStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/status',
    );
    final data = response['data'] as Map<String, dynamic>;
    return KiwixStatusModel.fromJson(data);
  }

  /// Returns the Kiwix serve URL for WebView embedding.
  Future<String> getKiwixUrl() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/url',
    );
    return response['data'] as String;
  }

  // ── eBooks ──────────────────────────────────────────────────────────────

  /// Lists eBooks with optional search and format filter.
  Future<List<EbookModel>> listEbooks({
    String? search,
    String? format,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (format != null && format.isNotEmpty) queryParams['format'] = format;

    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/ebooks',
      queryParams: queryParams,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => EbookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a single eBook by [id].
  Future<EbookModel> getEbook(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/ebooks/$id',
    );
    final data = response['data'] as Map<String, dynamic>;
    return EbookModel.fromJson(data);
  }

  /// Uploads an eBook file with metadata.
  Future<EbookModel> uploadEbook({
    required String filename,
    required List<int> bytes,
    required String title,
    String? author,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'title': title,
      'author': ?author,
    });
    final response = await _client.postMultipart<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/ebooks',
      formData,
    );
    final data = response['data'] as Map<String, dynamic>;
    return EbookModel.fromJson(data);
  }

  /// Deletes an eBook by [id].
  Future<void> deleteEbook(String id) async {
    await _client.delete('${AppConstants.libraryBasePath}/ebooks/$id');
  }

  /// Downloads the content of an eBook as raw bytes.
  Future<List<int>> downloadEbookContent(String id) async {
    return _client.getBytes(
      '${AppConstants.libraryBasePath}/ebooks/$id/content',
    );
  }

  // ── Kiwix Process Management ────────────────────────────────────────────

  /// Manually triggers kiwix-tools installation (retry after failure).
  Future<void> installKiwix() async {
    await _client.post<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/install',
    );
  }

  /// Starts the kiwix-serve process.
  Future<void> startKiwix() async {
    await _client.post<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/start',
    );
  }

  /// Stops the kiwix-serve process.
  Future<void> stopKiwix() async {
    await _client.post<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/stop',
    );
  }

  /// Browses the Kiwix online catalog.
  Future<KiwixCatalogSearchResultModel> browseKiwixCatalog({
    String? lang,
    String? category,
    int count = 20,
    int start = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'count': count,
      'start': start,
    };
    if (lang != null && lang.isNotEmpty) queryParams['lang'] = lang;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/catalog/browse',
      queryParams: queryParams,
    );
    final data = response['data'] as Map<String, dynamic>;
    return KiwixCatalogSearchResultModel.fromJson(data);
  }

  /// Searches the Kiwix online catalog.
  Future<KiwixCatalogSearchResultModel> searchKiwixCatalog(
    String query, {
    String? lang,
    int count = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'count': count,
    };
    if (lang != null && lang.isNotEmpty) queryParams['lang'] = lang;

    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/catalog/search',
      queryParams: queryParams,
    );
    final data = response['data'] as Map<String, dynamic>;
    return KiwixCatalogSearchResultModel.fromJson(data);
  }

  /// Starts a ZIM file download from the Kiwix catalog.
  Future<String> downloadFromCatalog({
    required String downloadUrl,
    required String filename,
    required String displayName,
    String? category,
    String? language,
    int sizeBytes = 0,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/catalog/download',
      data: {
        'downloadUrl': downloadUrl,
        'filename': filename,
        'displayName': displayName,
        'category': category,
        'language': language,
        'sizeBytes': sizeBytes,
      },
    );
    return response['data'] as String;
  }

  /// Lists all active and recent Kiwix downloads.
  Future<List<KiwixDownloadStatusModel>> listKiwixDownloads() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/downloads',
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) =>
            KiwixDownloadStatusModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets progress for a specific Kiwix download.
  Future<KiwixDownloadStatusModel> getKiwixDownloadProgress(
    String downloadId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/kiwix/downloads/$downloadId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return KiwixDownloadStatusModel.fromJson(data);
  }

  /// Cancels an in-progress Kiwix download.
  Future<void> cancelKiwixDownload(String downloadId) async {
    await _client.delete(
      '${AppConstants.libraryBasePath}/kiwix/downloads/$downloadId',
    );
  }

  // ── Gutenberg ───────────────────────────────────────────────────────────

  /// Browses the Project Gutenberg catalog without a search query.
  ///
  /// Returns books sorted by [sort] (popular, ascending, or descending),
  /// limited to [limit] results.
  Future<GutenbergSearchResultModel> browseGutenberg({
    String sort = 'popular',
    int limit = 10,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/gutenberg/browse',
      queryParams: {'sort': sort, 'limit': limit},
    );
    final data = response['data'] as Map<String, dynamic>;
    return GutenbergSearchResultModel.fromJson(data);
  }

  /// Searches the Project Gutenberg catalog.
  Future<GutenbergSearchResultModel> searchGutenberg(
    String query, {
    int limit = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/gutenberg/search',
      queryParams: {'query': query, 'limit': limit},
    );
    final data = response['data'] as Map<String, dynamic>;
    return GutenbergSearchResultModel.fromJson(data);
  }

  /// Gets metadata for a single Gutenberg book.
  Future<GutenbergBookModel> getGutenbergBook(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/gutenberg/$id',
    );
    final data = response['data'] as Map<String, dynamic>;
    return GutenbergBookModel.fromJson(data);
  }

  /// Imports a Gutenberg book into the local library.
  Future<EbookModel> importGutenbergBook(int gutenbergId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.libraryBasePath}/gutenberg/$gutenbergId/import',
    );
    final data = response['data'] as Map<String, dynamic>;
    return EbookModel.fromJson(data);
  }
}

/// Riverpod provider for [LibraryService].
final libraryServiceProvider = Provider<LibraryService>((ref) {
  final client = ref.watch(apiClientProvider);
  return LibraryService(client: client);
});

/// Provider for the ZIM file list.
final zimFilesProvider =
    FutureProvider.autoDispose<List<ZimFileModel>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return service.listZimFiles();
});

/// Provider for the eBook list with optional search and format.
final ebooksProvider = FutureProvider.autoDispose
    .family<List<EbookModel>, ({String? search, String? format})>(
  (ref, params) async {
    final service = ref.watch(libraryServiceProvider);
    return service.listEbooks(search: params.search, format: params.format);
  },
);

/// Provider for Kiwix server status.
final kiwixStatusProvider =
    FutureProvider.autoDispose<KiwixStatusModel>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return service.getKiwixStatus();
});

/// Provider for the Kiwix serve URL.
final kiwixUrlProvider = FutureProvider.autoDispose<String>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return service.getKiwixUrl();
});

/// Provider for Kiwix catalog browse results, optionally filtered by language.
final kiwixCatalogBrowseProvider = FutureProvider.autoDispose
    .family<KiwixCatalogSearchResultModel, String?>((ref, lang) async {
  final service = ref.watch(libraryServiceProvider);
  return service.browseKiwixCatalog(lang: lang, count: 20);
});

/// Provider for Kiwix catalog browse results filtered by category and language.
final kiwixCatalogBrowseByCategoryProvider = FutureProvider.autoDispose
    .family<KiwixCatalogSearchResultModel,
        ({String? category, String? lang, int count})>((ref, params) async {
  final service = ref.watch(libraryServiceProvider);
  return service.browseKiwixCatalog(
      category: params.category, lang: params.lang, count: params.count);
});

/// Provider for Kiwix catalog search results keyed by query and language.
final kiwixCatalogSearchProvider = FutureProvider.autoDispose
    .family<KiwixCatalogSearchResultModel, ({String query, String? lang})>(
        (ref, params) async {
  final service = ref.watch(libraryServiceProvider);
  return service.searchKiwixCatalog(params.query, lang: params.lang);
});

/// Provider for active Kiwix downloads.
final kiwixDownloadsProvider =
    FutureProvider.autoDispose<List<KiwixDownloadStatusModel>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return service.listKiwixDownloads();
});

/// Provider for browsing the Gutenberg catalog (popular books).
final gutenbergBrowseProvider = FutureProvider.autoDispose
    .family<GutenbergSearchResultModel, ({String sort, int limit})>(
        (ref, params) async {
  final service = ref.watch(libraryServiceProvider);
  return service.browseGutenberg(sort: params.sort, limit: params.limit);
});

/// Provider for searching the Gutenberg catalog by query.
final gutenbergSearchProvider = FutureProvider.autoDispose
    .family<GutenbergSearchResultModel, ({String query, int limit})>(
        (ref, params) async {
  final service = ref.watch(libraryServiceProvider);
  return service.searchGutenberg(params.query, limit: params.limit);
});
