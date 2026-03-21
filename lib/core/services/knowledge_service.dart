import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';

/// Service for Knowledge Vault operations including upload and search.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class KnowledgeService {
  final MyOffGridAIApiClient _client;

  /// Creates a [KnowledgeService] with the given API [client].
  KnowledgeService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists knowledge documents with pagination, optionally filtered by scope.
  Future<List<KnowledgeDocumentModel>> listDocuments({
    int page = 0,
    int size = 20,
    String scope = 'MINE',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.knowledgeBasePath,
      queryParams: {'page': page, 'size': size, 'scope': scope},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) =>
            KnowledgeDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a single document by [documentId].
  Future<KnowledgeDocumentModel> getDocument(String documentId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/$documentId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Uploads a document file.
  Future<KnowledgeDocumentModel> uploadDocument(
    String filename,
    List<int> bytes,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.postMultipart<Map<String, dynamic>>(
      AppConstants.knowledgeBasePath,
      formData,
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Updates the display name of a document.
  Future<KnowledgeDocumentModel> updateDisplayName(
    String documentId,
    String displayName,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/$documentId/display-name',
      data: {'displayName': displayName},
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Deletes a document by [documentId].
  Future<void> deleteDocument(String documentId) async {
    await _client.delete('${AppConstants.knowledgeBasePath}/$documentId');
  }

  /// Retries processing a failed document.
  Future<KnowledgeDocumentModel> retryProcessing(String documentId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/$documentId/retry',
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Updates the sharing status of a document.
  Future<KnowledgeDocumentModel> updateSharing(
    String documentId,
    bool shared,
  ) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/$documentId/sharing',
      data: {'shared': shared},
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Performs a semantic search across knowledge documents.
  Future<List<KnowledgeSearchResultModel>> search(
    String query, {
    int topK = 5,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/search',
      data: {'query': query, 'topK': topK},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) =>
            KnowledgeSearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves the content of a document for viewing or editing.
  Future<DocumentContentModel> getDocumentContent(String documentId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/$documentId/content',
    );
    final data = response['data'] as Map<String, dynamic>;
    return DocumentContentModel.fromJson(data);
  }

  /// Downloads the original file of a document as raw bytes.
  Future<List<int>> downloadDocument(String documentId) async {
    final response = await _client.getBytes(
      '${AppConstants.knowledgeBasePath}/$documentId/download',
    );
    return response;
  }

  /// Creates a new document from the rich text editor.
  Future<KnowledgeDocumentModel> createDocument({
    required String title,
    required String content,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/create',
      data: {'title': title, 'content': content},
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }

  /// Updates the content of a document from the rich text editor.
  Future<KnowledgeDocumentModel> updateDocumentContent(
    String documentId,
    String content,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.knowledgeBasePath}/$documentId/content',
      data: {'content': content},
    );
    final data = response['data'] as Map<String, dynamic>;
    return KnowledgeDocumentModel.fromJson(data);
  }
}

/// Riverpod provider for [KnowledgeService].
final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  final client = ref.watch(apiClientProvider);
  return KnowledgeService(client: client);
});

/// Provider for the current vault scope ("MINE" or "SHARED").
final knowledgeVaultScopeProvider = StateProvider<String>((ref) => 'MINE');

/// Provider for the knowledge document list, filtered by scope.
final knowledgeDocumentsProvider = FutureProvider.autoDispose
    .family<List<KnowledgeDocumentModel>, String>((ref, scope) async {
  final service = ref.watch(knowledgeServiceProvider);
  return service.listDocuments(scope: scope);
});

/// Provider for a document's content.
final documentContentProvider =
    FutureProvider.autoDispose.family<DocumentContentModel, String>(
  (ref, documentId) async {
    final service = ref.watch(knowledgeServiceProvider);
    return service.getDocumentContent(documentId);
  },
);
