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
  final String? createdAt;

  const MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.tokenCount,
    required this.hasRagContext,
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
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Whether this message was sent by the user.
  bool get isUser => role == 'USER';

  /// Whether this message was sent by the assistant.
  bool get isAssistant => role == 'ASSISTANT';
}
