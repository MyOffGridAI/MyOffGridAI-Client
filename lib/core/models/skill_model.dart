/// Represents a skill that the AI can execute.
///
/// Mirrors the server's SkillDto.
class SkillModel {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final String? version;
  final String? author;
  final String? category;
  final bool isEnabled;
  final bool isBuiltIn;
  final String? parametersSchema;
  final String? createdAt;
  final String? updatedAt;

  const SkillModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.version,
    this.author,
    this.category,
    required this.isEnabled,
    required this.isBuiltIn,
    this.parametersSchema,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [SkillModel] from a JSON map.
  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String?,
      version: json['version'] as String?,
      author: json['author'] as String?,
      category: json['category'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? false,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      parametersSchema: json['parametersSchema'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

/// Result of executing a skill.
///
/// Mirrors the server's SkillExecutionDto.
class SkillExecutionModel {
  final String id;
  final String skillId;
  final String skillName;
  final String? userId;
  final String status;
  final String? inputParams;
  final String? outputResult;
  final String? errorMessage;
  final String? startedAt;
  final String? completedAt;
  final int? durationMs;

  const SkillExecutionModel({
    required this.id,
    required this.skillId,
    required this.skillName,
    this.userId,
    required this.status,
    this.inputParams,
    this.outputResult,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
    this.durationMs,
  });

  /// Creates a [SkillExecutionModel] from a JSON map.
  factory SkillExecutionModel.fromJson(Map<String, dynamic> json) {
    return SkillExecutionModel(
      id: json['id'] as String,
      skillId: json['skillId'] as String,
      skillName: json['skillName'] as String? ?? '',
      userId: json['userId'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      inputParams: json['inputParams'] as String?,
      outputResult: json['outputResult'] as String?,
      errorMessage: json['errorMessage'] as String?,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      durationMs: json['durationMs'] as int?,
    );
  }

  /// Whether execution is still running.
  bool get isRunning => status == 'RUNNING';

  /// Whether execution completed successfully.
  bool get isSuccess => status == 'SUCCESS';

  /// Whether execution failed.
  bool get isFailed => status == 'FAILED';
}
