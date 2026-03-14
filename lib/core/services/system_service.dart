import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';

/// Service for system health and model management operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class SystemService {
  final MyOffGridAIApiClient _client;

  /// Creates a [SystemService] with the given API [client].
  SystemService({required MyOffGridAIApiClient client}) : _client = client;

  /// Gets the full system status.
  Future<SystemStatusModel> getSystemStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.systemBasePath}/status',
    );
    final data = response['data'] as Map<String, dynamic>;
    return SystemStatusModel.fromJson(data);
  }

  /// Lists all Ollama models.
  Future<List<OllamaModelInfoModel>> listModels() async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.modelsBasePath,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => OllamaModelInfoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets the active model information.
  Future<ActiveModelInfo> getActiveModel() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.modelsBasePath}/active',
    );
    final data = response['data'] as Map<String, dynamic>;
    return ActiveModelInfo.fromJson(data);
  }
}

/// Riverpod provider for [SystemService].
final systemServiceProvider = Provider<SystemService>((ref) {
  final client = ref.watch(apiClientProvider);
  return SystemService(client: client);
});

/// Provider for system status with full details.
final systemStatusDetailProvider =
    FutureProvider.autoDispose<SystemStatusModel>((ref) async {
  final service = ref.watch(systemServiceProvider);
  return service.getSystemStatus();
});

/// Provider for the Ollama model list.
final ollamaModelsProvider =
    FutureProvider.autoDispose<List<OllamaModelInfoModel>>((ref) async {
  final service = ref.watch(systemServiceProvider);
  return service.listModels();
});
