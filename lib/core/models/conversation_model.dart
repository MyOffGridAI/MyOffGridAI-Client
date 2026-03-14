/// Represents a chat conversation.
///
/// Mirrors the server's ConversationDto.
class ConversationModel {
  final String id;
  final String? title;
  final bool isArchived;
  final int messageCount;
  final String? createdAt;
  final String? updatedAt;

  const ConversationModel({
    required this.id,
    this.title,
    required this.isArchived,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [ConversationModel] from a JSON map.
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      messageCount: json['messageCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

/// Summary of a conversation for list display.
///
/// Mirrors the server's ConversationSummaryDto.
class ConversationSummaryModel {
  final String id;
  final String? title;
  final bool isArchived;
  final int messageCount;
  final String? updatedAt;
  final String? lastMessagePreview;

  const ConversationSummaryModel({
    required this.id,
    this.title,
    required this.isArchived,
    required this.messageCount,
    this.updatedAt,
    this.lastMessagePreview,
  });

  /// Creates a [ConversationSummaryModel] from a JSON map.
  factory ConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      messageCount: json['messageCount'] as int? ?? 0,
      updatedAt: json['updatedAt'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }
}
