import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/judge_models.dart';

/// Service for AI judge model management and testing.
///
/// Wraps [MyOffGridAIApiClient] to interact with the `/api/ai/judge`
/// endpoints. Provides methods to query status, start/stop the judge
/// process, and test evaluations.
class JudgeService {
  final MyOffGridAIApiClient _client;

  /// Creates a [JudgeService] with the given API [client].
  JudgeService({required MyOffGridAIApiClient client}) : _client = client;

  /// Returns the current judge subsystem status.
  Future<JudgeStatusModel> getStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.judgeBasePath}/status',
    );
    final data = response['data'] as Map<String, dynamic>;
    return JudgeStatusModel.fromJson(data);
  }

  /// Starts the judge llama-server process.
  ///
  /// Returns the updated status after the start attempt.
  Future<JudgeStatusModel> start() async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.judgeBasePath}/start',
    );
    final data = response['data'] as Map<String, dynamic>;
    return JudgeStatusModel.fromJson(data);
  }

  /// Stops the judge llama-server process.
  ///
  /// Returns the updated status after stopping.
  Future<JudgeStatusModel> stop() async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.judgeBasePath}/stop',
    );
    final data = response['data'] as Map<String, dynamic>;
    return JudgeStatusModel.fromJson(data);
  }

  /// Tests the judge evaluation pipeline for a given query.
  ///
  /// The server generates a response from the local LLM, then evaluates
  /// it with the judge. Returns the generated response, score, and reason.
  Future<JudgeTestResultModel> test({required String query}) async {
    final apiResponse = await _client.post<Map<String, dynamic>>(
      '${AppConstants.judgeBasePath}/test',
      data: {'query': query},
    );
    final data = apiResponse['data'] as Map<String, dynamic>;
    return JudgeTestResultModel.fromJson(data);
  }
}

/// Riverpod provider for [JudgeService].
final judgeServiceProvider = Provider<JudgeService>((ref) {
  final client = ref.watch(apiClientProvider);
  return JudgeService(client: client);
});

/// Provider for the current judge status.
///
/// Auto-disposes when no longer watched. Invalidate to refresh.
final judgeStatusProvider =
    FutureProvider.autoDispose<JudgeStatusModel>((ref) async {
  final service = ref.watch(judgeServiceProvider);
  return service.getStatus();
});
