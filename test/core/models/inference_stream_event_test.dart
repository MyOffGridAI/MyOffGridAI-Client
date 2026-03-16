import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/inference_stream_event.dart';

void main() {
  // ---------------------------------------------------------------------------
  // InferenceEventType
  // ---------------------------------------------------------------------------
  group('InferenceEventType', () {
    test('has four values', () {
      expect(InferenceEventType.values, hasLength(4));
    });

    test('contains thinking, content, done, error', () {
      expect(InferenceEventType.values, contains(InferenceEventType.thinking));
      expect(InferenceEventType.values, contains(InferenceEventType.content));
      expect(InferenceEventType.values, contains(InferenceEventType.done));
      expect(InferenceEventType.values, contains(InferenceEventType.error));
    });

    test('name values match expected strings', () {
      expect(InferenceEventType.thinking.name, 'thinking');
      expect(InferenceEventType.content.name, 'content');
      expect(InferenceEventType.done.name, 'done');
      expect(InferenceEventType.error.name, 'error');
    });
  });

  // ---------------------------------------------------------------------------
  // InferenceMetadata
  // ---------------------------------------------------------------------------
  group('InferenceMetadata', () {
    test('parses from JSON with all fields', () {
      final json = {
        'tokensGenerated': 200,
        'tokensPerSecond': 45.3,
        'inferenceTimeSeconds': 4.42,
        'stopReason': 'stop',
      };

      final metadata = InferenceMetadata.fromJson(json);

      expect(metadata.tokensGenerated, 200);
      expect(metadata.tokensPerSecond, 45.3);
      expect(metadata.inferenceTimeSeconds, 4.42);
      expect(metadata.stopReason, 'stop');
    });

    test('defaults tokensGenerated to 0 when null', () {
      final json = <String, dynamic>{
        'tokensPerSecond': 10.0,
        'inferenceTimeSeconds': 1.0,
      };

      final metadata = InferenceMetadata.fromJson(json);

      expect(metadata.tokensGenerated, 0);
    });

    test('defaults tokensPerSecond to 0.0 when null', () {
      final json = <String, dynamic>{
        'tokensGenerated': 50,
        'inferenceTimeSeconds': 2.0,
      };

      final metadata = InferenceMetadata.fromJson(json);

      expect(metadata.tokensPerSecond, 0.0);
    });

    test('defaults inferenceTimeSeconds to 0.0 when null', () {
      final json = <String, dynamic>{
        'tokensGenerated': 50,
        'tokensPerSecond': 25.0,
      };

      final metadata = InferenceMetadata.fromJson(json);

      expect(metadata.inferenceTimeSeconds, 0.0);
    });

    test('leaves stopReason null when absent', () {
      final json = <String, dynamic>{
        'tokensGenerated': 100,
        'tokensPerSecond': 30.0,
        'inferenceTimeSeconds': 3.33,
      };

      final metadata = InferenceMetadata.fromJson(json);

      expect(metadata.stopReason, isNull);
    });

    test('converts integer tokensPerSecond to double', () {
      final json = {
        'tokensGenerated': 100,
        'tokensPerSecond': 30,
        'inferenceTimeSeconds': 3,
      };

      final metadata = InferenceMetadata.fromJson(json);

      expect(metadata.tokensPerSecond, 30.0);
      expect(metadata.inferenceTimeSeconds, 3.0);
    });

    test('handles all fields missing with defaults', () {
      final metadata = InferenceMetadata.fromJson(<String, dynamic>{});

      expect(metadata.tokensGenerated, 0);
      expect(metadata.tokensPerSecond, 0.0);
      expect(metadata.inferenceTimeSeconds, 0.0);
      expect(metadata.stopReason, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // InferenceStreamEvent
  // ---------------------------------------------------------------------------
  group('InferenceStreamEvent', () {
    test('parses thinking event', () {
      final json = {
        'type': 'thinking',
        'content': 'Let me analyze this...',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.thinking);
      expect(event.content, 'Let me analyze this...');
      expect(event.metadata, isNull);
      expect(event.messageId, isNull);
    });

    test('parses content event', () {
      final json = {
        'type': 'content',
        'content': 'Here is the answer:',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.content);
      expect(event.content, 'Here is the answer:');
      expect(event.metadata, isNull);
    });

    test('parses done event with metadata', () {
      final json = {
        'type': 'done',
        'messageId': 'msg-42',
        'metadata': {
          'tokensGenerated': 150,
          'tokensPerSecond': 38.7,
          'inferenceTimeSeconds': 3.87,
          'stopReason': 'stop',
        },
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.done);
      expect(event.messageId, 'msg-42');
      expect(event.content, isNull);
      expect(event.metadata, isNotNull);
      expect(event.metadata!.tokensGenerated, 150);
      expect(event.metadata!.tokensPerSecond, 38.7);
      expect(event.metadata!.inferenceTimeSeconds, 3.87);
      expect(event.metadata!.stopReason, 'stop');
    });

    test('parses done event without metadata', () {
      final json = {
        'type': 'done',
        'messageId': 'msg-99',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.done);
      expect(event.messageId, 'msg-99');
      expect(event.metadata, isNull);
    });

    test('parses error event', () {
      final json = {
        'type': 'error',
        'content': 'Model failed to respond',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.error);
      expect(event.content, 'Model failed to respond');
    });

    test('defaults to content type when type is missing', () {
      final json = {
        'content': 'Some text without a type field',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.content);
      expect(event.content, 'Some text without a type field');
    });

    test('defaults to content type for unknown type string', () {
      final json = {
        'type': 'unknown_type_xyz',
        'content': 'Fallback content',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.content);
      expect(event.content, 'Fallback content');
    });

    test('ignores metadata when it is not a Map', () {
      final json = {
        'type': 'done',
        'metadata': 'not a map',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.type, InferenceEventType.done);
      expect(event.metadata, isNull);
    });

    test('parses messageId from JSON', () {
      final json = {
        'type': 'content',
        'content': 'Hello',
        'messageId': 'msg-abc-123',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.messageId, 'msg-abc-123');
    });

    test('leaves messageId null when absent', () {
      final json = {
        'type': 'content',
        'content': 'Hello',
      };

      final event = InferenceStreamEvent.fromJson(json);

      expect(event.messageId, isNull);
    });
  });
}
