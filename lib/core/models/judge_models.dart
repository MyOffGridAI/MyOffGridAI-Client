/// Models for the AI judge evaluation subsystem.
///
/// These models mirror the server-side DTOs in the judge package.
/// [JudgeStatusModel] maps to JudgeStatusDto, [JudgeTestResultModel]
/// maps to JudgeTestResultDto.
library;

/// Status snapshot of the AI judge subsystem.
///
/// Mirrors the server's JudgeStatusDto. Returned from the
/// `GET /api/ai/judge/status` endpoint.
class JudgeStatusModel {
  /// Whether the judge pipeline is enabled in settings.
  final bool enabled;

  /// Whether the judge llama-server process is alive.
  final bool processRunning;

  /// The configured judge model GGUF filename.
  final String? judgeModelFilename;

  /// The HTTP port the judge process listens on.
  final int port;

  /// The minimum score below which cloud refinement is triggered.
  final double scoreThreshold;

  /// Creates a [JudgeStatusModel].
  const JudgeStatusModel({
    required this.enabled,
    required this.processRunning,
    this.judgeModelFilename,
    required this.port,
    required this.scoreThreshold,
  });

  /// Creates a [JudgeStatusModel] from a JSON map.
  factory JudgeStatusModel.fromJson(Map<String, dynamic> json) {
    return JudgeStatusModel(
      enabled: json['enabled'] as bool? ?? false,
      processRunning: json['processRunning'] as bool? ?? false,
      judgeModelFilename: json['judgeModelFilename'] as String?,
      port: json['port'] as int? ?? 0,
      scoreThreshold: (json['scoreThreshold'] as num?)?.toDouble() ?? 7.0,
    );
  }
}

/// Result of a manual judge test invocation.
///
/// Mirrors the server's JudgeTestResultDto. Returned from the
/// `POST /api/ai/judge/test` endpoint.
class JudgeTestResultModel {
  /// The assistant response that was evaluated (generated or user-provided).
  final String? assistantResponse;

  /// Quality score from 1 to 10 (0.0 if unavailable).
  final double score;

  /// Brief explanation of the score (null if unavailable).
  final String? reason;

  /// Whether the judge recommends cloud refinement.
  final bool needsCloud;

  /// Whether the judge was available to perform the evaluation.
  final bool judgeAvailable;

  /// Error message if the evaluation failed (null on success).
  final String? error;

  /// Creates a [JudgeTestResultModel].
  const JudgeTestResultModel({
    this.assistantResponse,
    required this.score,
    this.reason,
    required this.needsCloud,
    required this.judgeAvailable,
    this.error,
  });

  /// Creates a [JudgeTestResultModel] from a JSON map.
  factory JudgeTestResultModel.fromJson(Map<String, dynamic> json) {
    return JudgeTestResultModel(
      assistantResponse: json['assistantResponse'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
      needsCloud: json['needsCloud'] as bool? ?? false,
      judgeAvailable: json['judgeAvailable'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}
