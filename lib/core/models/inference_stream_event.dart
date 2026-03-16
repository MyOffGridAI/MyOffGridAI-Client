/// The type of event emitted during an inference SSE stream.
enum InferenceEventType {
  /// Thinking/reasoning content (from `<think>` blocks).
  thinking,

  /// Regular response content.
  content,

  /// Stream complete, includes metadata.
  done,

  /// An error occurred during inference.
  error,
}

/// Metadata returned with a [InferenceEventType.done] event.
class InferenceMetadata {
  final int tokensGenerated;
  final double tokensPerSecond;
  final double inferenceTimeSeconds;
  final String? stopReason;

  const InferenceMetadata({
    required this.tokensGenerated,
    required this.tokensPerSecond,
    required this.inferenceTimeSeconds,
    this.stopReason,
  });

  /// Creates an [InferenceMetadata] from a JSON map.
  factory InferenceMetadata.fromJson(Map<String, dynamic> json) {
    return InferenceMetadata(
      tokensGenerated: json['tokensGenerated'] as int? ?? 0,
      tokensPerSecond: (json['tokensPerSecond'] as num?)?.toDouble() ?? 0.0,
      inferenceTimeSeconds:
          (json['inferenceTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      stopReason: json['stopReason'] as String?,
    );
  }
}

/// A single typed event from an inference SSE stream.
///
/// The server emits JSON events with a `type` field and optional `content`
/// and `metadata` fields. This model parses those events for the client.
class InferenceStreamEvent {
  final InferenceEventType type;
  final String? content;
  final InferenceMetadata? metadata;
  final String? messageId;

  const InferenceStreamEvent({
    required this.type,
    this.content,
    this.metadata,
    this.messageId,
  });

  /// Parses an SSE data line into an [InferenceStreamEvent].
  ///
  /// Expects a JSON object with at least a `type` field.
  factory InferenceStreamEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'content';
    final type = InferenceEventType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => InferenceEventType.content,
    );

    InferenceMetadata? metadata;
    if (json['metadata'] is Map<String, dynamic>) {
      metadata =
          InferenceMetadata.fromJson(json['metadata'] as Map<String, dynamic>);
    }

    return InferenceStreamEvent(
      type: type,
      content: json['content'] as String?,
      metadata: metadata,
      messageId: json['messageId'] as String?,
    );
  }
}
