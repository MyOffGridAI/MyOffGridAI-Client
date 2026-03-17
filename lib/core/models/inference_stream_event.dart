import 'dart:convert';

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

  /// The AI judge is evaluating the local response quality.
  judgeEvaluating,

  /// Judge evaluation complete — content contains score JSON.
  judgeResult,

  /// Tokens from the cloud frontier model (enhanced response).
  enhancedContent,

  /// Enhanced response stream from the cloud model is complete.
  enhancedDone,
}

/// Maps server-sent snake_case type strings to [InferenceEventType] values.
///
/// The server sends event types as lowercase snake_case (e.g. "judge_evaluating"),
/// while Dart enum names use camelCase. This map bridges the two conventions.
const _serverTypeMap = <String, InferenceEventType>{
  'thinking': InferenceEventType.thinking,
  'content': InferenceEventType.content,
  'done': InferenceEventType.done,
  'error': InferenceEventType.error,
  'judge_evaluating': InferenceEventType.judgeEvaluating,
  'judge_result': InferenceEventType.judgeResult,
  'enhanced_content': InferenceEventType.enhancedContent,
  'enhanced_done': InferenceEventType.enhancedDone,
};

/// Metadata returned with a [InferenceEventType.done] event.
class InferenceMetadata {
  final int tokensGenerated;
  final double tokensPerSecond;
  final double inferenceTimeSeconds;
  final String? stopReason;

  /// Estimated token count for the thinking/reasoning block, if present.
  final int? thinkingTokenCount;

  const InferenceMetadata({
    required this.tokensGenerated,
    required this.tokensPerSecond,
    required this.inferenceTimeSeconds,
    this.stopReason,
    this.thinkingTokenCount,
  });

  /// Creates an [InferenceMetadata] from a JSON map.
  ///
  /// Handles both nested metadata objects and flat done-event JSON where
  /// fields like `totalTokens` and `thinkingTime` appear at the top level.
  factory InferenceMetadata.fromJson(Map<String, dynamic> json) {
    return InferenceMetadata(
      tokensGenerated:
          json['tokensGenerated'] as int? ?? json['totalTokens'] as int? ?? 0,
      tokensPerSecond: (json['tokensPerSecond'] as num?)?.toDouble() ?? 0.0,
      inferenceTimeSeconds:
          (json['inferenceTimeSeconds'] as num?)?.toDouble() ??
              (json['thinkingTime'] as num?)?.toDouble() ??
              0.0,
      stopReason: json['stopReason'] as String?,
      thinkingTokenCount: json['thinkingTokenCount'] as int?,
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
  /// Expects a JSON object with at least a `type` field. Uses [_serverTypeMap]
  /// to handle the server's snake_case type strings.
  factory InferenceStreamEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'content';
    final type = _serverTypeMap[typeStr] ?? InferenceEventType.content;

    InferenceMetadata? metadata;
    if (json['metadata'] is Map<String, dynamic>) {
      metadata =
          InferenceMetadata.fromJson(json['metadata'] as Map<String, dynamic>);
    } else if (type == InferenceEventType.done) {
      // Server sends done-event metadata as flat top-level fields.
      metadata = InferenceMetadata.fromJson(json);
    }

    // For judge_result, content is a nested JSON object (score, reason, needsCloud).
    // We serialize it back to JSON string for the notifier to parse.
    dynamic rawContent = json['content'];
    String? contentStr;
    if (rawContent is Map) {
      contentStr = jsonEncode(rawContent);
    } else {
      contentStr = rawContent as String?;
    }

    return InferenceStreamEvent(
      type: type,
      content: contentStr,
      metadata: metadata,
      messageId: json['messageId'] as String?,
    );
  }
}
