/// Represents a chat message.
///
/// Mirrors the server's MessageDto. The [role] field uses the server's
/// enum values: USER, ASSISTANT, SYSTEM.
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
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Whether this message was sent by the user.
  bool get isUser => role == 'USER';

  /// Whether this message was sent by the assistant.
  bool get isAssistant => role == 'ASSISTANT';

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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
