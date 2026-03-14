import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';

/// Service for memory operations including search and CRUD.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class MemoryService {
  final MyOffGridAIApiClient _client;

  /// Creates a [MemoryService] with the given API [client].
  MemoryService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists memories with pagination and optional filters.
  Future<List<MemoryModel>> listMemories({
    int page = 0,
    int size = 20,
    String? importance,
    String? tag,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (importance != null) params['importance'] = importance;
    if (tag != null) params['tag'] = tag;

    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.memoryBasePath,
      queryParams: params,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => MemoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a single memory by [id].
  Future<MemoryModel> getMemory(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.memoryBasePath}/$id',
    );
    final data = response['data'] as Map<String, dynamic>;
    return MemoryModel.fromJson(data);
  }

  /// Deletes a memory by [id].
  Future<void> deleteMemory(String id) async {
    await _client.delete('${AppConstants.memoryBasePath}/$id');
  }

  /// Updates the tags on a memory.
  Future<MemoryModel> updateTags(String id, String tags) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.memoryBasePath}/$id/tags',
      data: {'tags': tags},
    );
    final data = response['data'] as Map<String, dynamic>;
    return MemoryModel.fromJson(data);
  }

  /// Updates the importance level of a memory.
  Future<MemoryModel> updateImportance(String id, String importance) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.memoryBasePath}/$id/importance',
      data: {'importance': importance},
    );
    final data = response['data'] as Map<String, dynamic>;
    return MemoryModel.fromJson(data);
  }

  /// Performs a semantic search across memories.
  Future<List<MemorySearchResultModel>> search(
    String query, {
    int topK = 10,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.memoryBasePath}/search',
      data: {'query': query, 'topK': topK},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => MemorySearchResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Exports all memories.
  Future<List<MemoryModel>> exportMemories() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.memoryBasePath}/export',
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => MemoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Riverpod provider for [MemoryService].
final memoryServiceProvider = Provider<MemoryService>((ref) {
  final client = ref.watch(apiClientProvider);
  return MemoryService(client: client);
});

/// Provider for the memory list.
final memoriesProvider =
    FutureProvider.autoDispose<List<MemoryModel>>((ref) async {
  final service = ref.watch(memoryServiceProvider);
  return service.listMemories();
});
