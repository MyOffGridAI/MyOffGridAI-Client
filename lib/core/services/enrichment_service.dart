import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/enrichment_models.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';

/// Service for web enrichment operations: fetching URLs, web search,
/// and managing external API settings (Anthropic, Brave).
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class EnrichmentService {
  final MyOffGridAIApiClient _client;

  /// Creates an [EnrichmentService] with the given API [client].
  EnrichmentService({required MyOffGridAIApiClient client}) : _client = client;

  /// Gets the current external API settings.
  ///
  /// Returns an [ExternalApiSettingsModel] with boolean flags indicating
  /// whether keys are configured. Actual key values are never exposed.
  Future<ExternalApiSettingsModel> getExternalApiSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.externalApiSettingsPath,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ExternalApiSettingsModel.fromJson(data);
  }

  /// Updates the external API settings.
  ///
  /// Only non-null key fields are sent; null preserves the existing value.
  Future<ExternalApiSettingsModel> updateExternalApiSettings(
    UpdateExternalApiSettingsRequest request,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      AppConstants.externalApiSettingsPath,
      data: request.toJson(),
    );
    final data = response['data'] as Map<String, dynamic>;
    return ExternalApiSettingsModel.fromJson(data);
  }

  /// Fetches a URL and stores it as a knowledge document.
  ///
  /// The server extracts text from HTML, optionally summarizes it using
  /// Claude, and saves it to the Knowledge Vault.
  Future<KnowledgeDocumentModel> fetchUrl({
    required String url,
    bool summarizeWithClaude = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.enrichmentBasePath}/fetch-url',
      data: {
        'url': url,
        'summarizeWithClaude': summarizeWithClaude,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Searches the web via Brave Search and optionally stores top results.
  ///
  /// Returns a map with 'results' (list of [SearchResultModel]) and
  /// 'storedDocuments' (list of [KnowledgeDocumentModel]) when [storeTopN]
  /// is greater than zero.
  Future<({List<SearchResultModel> results, List<KnowledgeDocumentModel> storedDocuments})>
      search({
    required String query,
    int storeTopN = 0,
    bool summarizeWithClaude = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.enrichmentBasePath}/search',
      data: {
        'query': query,
        'storeTopN': storeTopN,
        'summarizeWithClaude': summarizeWithClaude,
      },
    );
    final data = response['data'] as Map<String, dynamic>;

    final resultsList = (data['results'] as List<dynamic>?)
            ?.map((e) =>
                SearchResultModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final storedList = (data['storedDocuments'] as List<dynamic>?)
            ?.map((e) =>
                KnowledgeDocumentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return (results: resultsList, storedDocuments: storedList);
  }

  /// Gets the current enrichment service availability status.
  ///
  /// Returns which external services (Claude, Brave) are configured
  /// and available for use.
  Future<EnrichmentStatusModel> getStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.enrichmentBasePath}/status',
    );
    final data = response['data'] as Map<String, dynamic>;
    return EnrichmentStatusModel.fromJson(data);
  }
}

/// Riverpod provider for [EnrichmentService].
final enrichmentServiceProvider = Provider<EnrichmentService>((ref) {
  final client = ref.watch(apiClientProvider);
  return EnrichmentService(client: client);
});

/// Provider for enrichment service status.
final enrichmentStatusProvider =
    FutureProvider.autoDispose<EnrichmentStatusModel>((ref) async {
  final service = ref.watch(enrichmentServiceProvider);
  return service.getStatus();
});

/// Provider for external API settings.
final externalApiSettingsProvider =
    FutureProvider.autoDispose<ExternalApiSettingsModel>((ref) async {
  final service = ref.watch(enrichmentServiceProvider);
  return service.getExternalApiSettings();
});
