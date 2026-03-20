import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/skill_model.dart';

/// Service for skill management and execution.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class SkillsService {
  final MyOffGridAIApiClient _client;

  /// Creates a [SkillsService] with the given API [client].
  SkillsService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists all available skills.
  Future<List<SkillModel>> listSkills() async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.skillsBasePath,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new custom skill.
  Future<SkillModel> createSkill({
    required String name,
    required String displayName,
    required String description,
    required String category,
    String? version,
    String? parametersSchema,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppConstants.skillsBasePath,
      data: {
        'name': name,
        'displayName': displayName,
        'description': description,
        'category': category,
        'version': version,
        'parametersSchema': parametersSchema,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return SkillModel.fromJson(data);
  }

  /// Gets a single skill by [skillId].
  Future<SkillModel> getSkill(String skillId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.skillsBasePath}/$skillId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return SkillModel.fromJson(data);
  }

  /// Toggles a skill's enabled state.
  Future<SkillModel> toggleSkill(String skillId, bool enabled) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '${AppConstants.skillsBasePath}/$skillId/toggle',
      data: {'enabled': enabled},
    );
    final data = response['data'] as Map<String, dynamic>;
    return SkillModel.fromJson(data);
  }

  /// Executes a skill with optional parameters.
  Future<SkillExecutionModel> executeSkill(
    String skillId, {
    Map<String, dynamic>? params,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.skillsBasePath}/execute',
      data: {'skillId': skillId, 'params': ?params},
    );
    final data = response['data'] as Map<String, dynamic>;
    return SkillExecutionModel.fromJson(data);
  }

  /// Lists skill executions with pagination.
  Future<List<SkillExecutionModel>> listExecutions({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.skillsBasePath}/executions',
      queryParams: {'page': page, 'size': size},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => SkillExecutionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Riverpod provider for [SkillsService].
final skillsServiceProvider = Provider<SkillsService>((ref) {
  final client = ref.watch(apiClientProvider);
  return SkillsService(client: client);
});

/// Provider for the skills list.
final skillsProvider =
    FutureProvider.autoDispose<List<SkillModel>>((ref) async {
  final service = ref.watch(skillsServiceProvider);
  return service.listSkills();
});
