/// Represents a chat message.
///
/// Mirrors the server's MessageDto. The [role] field uses the server's
/// enum values: USER, ASSISTANT, SYSTEM. The [sourceTag] indicates
/// whether the response was generated locally or enhanced by a cloud model.
class MessageModel {
  final String id;
  final String role;
  final String content;
  final int? tokenCount;
  final bool hasRagContext;
  final String? thinkingContent;
  final double? tokensPerSecond;
  final double? inferenceTimeSeconds;
  final String? stopReason;
  final int? thinkingTokenCount;
  final String? sourceTag;
  final double? judgeScore;
  final String? judgeReason;
  final String? createdAt;

  const MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.tokenCount,
    required this.hasRagContext,
    this.thinkingContent,
    this.tokensPerSecond,
    this.inferenceTimeSeconds,
    this.stopReason,
    this.thinkingTokenCount,
    this.sourceTag,
    this.judgeScore,
    this.judgeReason,
    this.createdAt,
  });

  /// Creates a [MessageModel] from a JSON map.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'USER',
      content: json['content'] as String? ?? '',
      tokenCount: json['tokenCount'] as int?,
      hasRagContext: json['hasRagContext'] as bool? ?? false,
      thinkingContent: json['thinkingContent'] as String?,
      tokensPerSecond: (json['tokensPerSecond'] as num?)?.toDouble(),
      inferenceTimeSeconds: (json['inferenceTimeSeconds'] as num?)?.toDouble(),
      stopReason: json['stopReason'] as String?,
      thinkingTokenCount: json['thinkingTokenCount'] as int?,
      sourceTag: json['sourceTag'] as String?,
      judgeScore: (json['judgeScore'] as num?)?.toDouble(),
      judgeReason: json['judgeReason'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Whether this message was sent by the user.
  bool get isUser => role == 'USER';

  /// Whether this message was sent by the assistant.
  bool get isAssistant => role == 'ASSISTANT';

  /// Whether this message was enhanced by a cloud frontier model.
  bool get isEnhanced => sourceTag == 'ENHANCED';

  /// Whether the judge scored this message.
  bool get hasJudgeScore => judgeScore != null;

  /// Creates a copy with the given fields replaced.
  MessageModel copyWith({
    String? id,
    String? role,
    String? content,
    int? tokenCount,
    bool? hasRagContext,
    String? thinkingContent,
    double? tokensPerSecond,
    double? inferenceTimeSeconds,
    String? stopReason,
    int? thinkingTokenCount,
    String? sourceTag,
    double? judgeScore,
    String? judgeReason,
    String? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      tokenCount: tokenCount ?? this.tokenCount,
      hasRagContext: hasRagContext ?? this.hasRagContext,
      thinkingContent: thinkingContent ?? this.thinkingContent,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      inferenceTimeSeconds: inferenceTimeSeconds ?? this.inferenceTimeSeconds,
      stopReason: stopReason ?? this.stopReason,
      thinkingTokenCount: thinkingTokenCount ?? this.thinkingTokenCount,
      sourceTag: sourceTag ?? this.sourceTag,
      judgeScore: judgeScore ?? this.judgeScore,
      judgeReason: judgeReason ?? this.judgeReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
