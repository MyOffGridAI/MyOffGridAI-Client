/// Represents a memory entry.
///
/// Mirrors the server's MemoryDto. Importance uses enum values:
/// LOW, MEDIUM, HIGH, CRITICAL.
class MemoryModel {
  final String id;
  final String content;
  final String importance;
  final String? tags;
  final String? sourceConversationId;
  final String? createdAt;
  final String? updatedAt;
  final String? lastAccessedAt;
  final int accessCount;

  const MemoryModel({
    required this.id,
    required this.content,
    required this.importance,
    this.tags,
    this.sourceConversationId,
    this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    required this.accessCount,
  });

  /// Creates a [MemoryModel] from a JSON map.
  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      importance: json['importance'] as String? ?? 'LOW',
      tags: json['tags'] as String?,
      sourceConversationId: json['sourceConversationId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      lastAccessedAt: json['lastAccessedAt'] as String?,
      accessCount: json['accessCount'] as int? ?? 0,
    );
  }

  /// Returns the tags as a list of strings.
  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }
}

/// Result of a semantic memory search.
///
/// Mirrors the server's MemorySearchResultDto.
class MemorySearchResultModel {
  final MemoryModel memory;
  final double similarityScore;

  const MemorySearchResultModel({
    required this.memory,
    required this.similarityScore,
  });

  /// Creates a [MemorySearchResultModel] from a JSON map.
  factory MemorySearchResultModel.fromJson(Map<String, dynamic> json) {
    return MemorySearchResultModel(
      memory: MemoryModel.fromJson(json['memory'] as Map<String, dynamic>),
      similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
