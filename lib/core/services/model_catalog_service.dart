import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';

/// Service for the HuggingFace model catalog, download management,
/// and local model operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models. Screens access
/// this service via Riverpod providers.
class ModelCatalogService {
  final MyOffGridAIApiClient _client;

  /// Creates a [ModelCatalogService] with the given API [client].
  ModelCatalogService({required MyOffGridAIApiClient client}) : _client = client;

  // ── Catalog ──────────────────────────────────────────────────────────

  /// Searches the HuggingFace model catalog.
  ///
  /// Returns a list of [HfModelModel] matching the [query].
  /// [format] filters by model format ("gguf", "mlx", or "all").
  /// [limit] caps the number of results (default 20).
  Future<List<HfModelModel>> searchCatalog({
    required String query,
    String format = 'gguf',
    int limit = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/catalog/search',
      queryParams: {'q': query, 'format': format, 'limit': limit},
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) return [];
    final models = data['models'] as List<dynamic>? ?? [];
    return models
        .map((e) => HfModelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns full model details for a HuggingFace repository.
  Future<HfModelModel> getModelDetails(String author, String modelId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/catalog/$author/$modelId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return HfModelModel.fromJson(data);
  }

  /// Returns the file list for a HuggingFace model repository.
  Future<List<HfModelFileModel>> getModelFiles(
    String author,
    String modelId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/catalog/$author/$modelId/files',
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => HfModelFileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Downloads ────────────────────────────────────────────────────────

  /// Starts a model file download.
  ///
  /// Returns a map with `downloadId`, `targetPath`, and `estimatedSizeBytes`.
  Future<Map<String, dynamic>> startDownload({
    required String repoId,
    required String filename,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/download',
      data: {'repoId': repoId, 'filename': filename},
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// Returns all active and recent downloads.
  Future<List<DownloadProgressModel>> getAllDownloads() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/download',
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DownloadProgressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Streams download progress via SSE for a specific download.
  ///
  /// Yields [DownloadProgressModel] events until the download completes,
  /// fails, or is cancelled.
  Stream<DownloadProgressModel> streamDownloadProgress(
    String downloadId,
  ) async* {
    final responseBody = await _client.getStream(
      '${AppConstants.modelsBasePath}/download/$downloadId/progress',
      receiveTimeout: const Duration(minutes: 120),
    );

    final stream = responseBody?.stream;
    if (stream == null) return;

    final lineBuffer = StringBuffer();
    await for (final chunk in stream) {
      final text = utf8.decode(chunk, allowMalformed: true);
      lineBuffer.write(text);

      final buffered = lineBuffer.toString();
      final lines = buffered.split('\n');

      lineBuffer.clear();
      if (!buffered.endsWith('\n')) {
        lineBuffer.write(lines.removeLast());
      } else {
        lines.removeLast();
      }

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('data:')) {
          final payload = trimmed.substring(5).trim();
          if (payload.isEmpty) continue;

          try {
            final json = jsonDecode(payload) as Map<String, dynamic>;
            yield DownloadProgressModel.fromJson(json);
          } catch (_) {
            // Skip malformed JSON lines
          }
        }
      }
    }
  }

  /// Cancels an in-progress download.
  Future<void> cancelDownload(String downloadId) async {
    await _client.delete(
      '${AppConstants.modelsBasePath}/download/$downloadId',
    );
  }

  // ── Local models ─────────────────────────────────────────────────────

  /// Returns the list of model files in the LM Studio models directory.
  Future<List<LocalModelFileModel>> listLocalModels() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/local',
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => LocalModelFileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a local model file from disk.
  Future<void> deleteLocalModel(String filename) async {
    await _client.delete(
      '${AppConstants.modelsBasePath}/local/$filename',
    );
  }
}

/// Riverpod provider for [ModelCatalogService].
final modelCatalogServiceProvider = Provider<ModelCatalogService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ModelCatalogService(client: client);
});

/// Provider for local model files in LM Studio.
final localModelsProvider =
    FutureProvider.autoDispose<List<LocalModelFileModel>>((ref) async {
  final service = ref.watch(modelCatalogServiceProvider);
  return service.listLocalModels();
});

/// Provider for all active/recent downloads.
final activeDownloadsProvider =
    FutureProvider.autoDispose<List<DownloadProgressModel>>((ref) async {
  final service = ref.watch(modelCatalogServiceProvider);
  return service.getAllDownloads();
});
