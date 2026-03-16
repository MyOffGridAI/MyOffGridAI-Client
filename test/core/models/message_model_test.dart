import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';

void main() {
  group('MessageModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'msg-1',
        'role': 'USER',
        'content': 'Hello',
        'tokenCount': 3,
        'hasRagContext': true,
        'createdAt': '2026-03-14T10:00:00Z',
      };

      final model = MessageModel.fromJson(json);

      expect(model.id, 'msg-1');
      expect(model.role, 'USER');
      expect(model.content, 'Hello');
      expect(model.tokenCount, 3);
      expect(model.hasRagContext, isTrue);
      expect(model.createdAt, '2026-03-14T10:00:00Z');
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'msg-2'};

      final model = MessageModel.fromJson(json);

      expect(model.id, 'msg-2');
      expect(model.role, 'USER');
      expect(model.content, '');
      expect(model.tokenCount, isNull);
      expect(model.hasRagContext, isFalse);
      expect(model.thinkingContent, isNull);
      expect(model.tokensPerSecond, isNull);
      expect(model.inferenceTimeSeconds, isNull);
      expect(model.stopReason, isNull);
      expect(model.thinkingTokenCount, isNull);
    });

    test('isUser returns true for USER role', () {
      final model = MessageModel.fromJson({'id': '1', 'role': 'USER'});
      expect(model.isUser, isTrue);
      expect(model.isAssistant, isFalse);
    });

    test('isAssistant returns true for ASSISTANT role', () {
      final model = MessageModel.fromJson({'id': '1', 'role': 'ASSISTANT'});
      expect(model.isAssistant, isTrue);
      expect(model.isUser, isFalse);
    });

    // ── P11 new fields ──────────────────────────────────────────────────
    test('parses thinkingContent from JSON', () {
      final json = {
        'id': 'msg-3',
        'role': 'ASSISTANT',
        'content': 'Answer here',
        'thinkingContent': 'Let me reason about this...',
      };

      final model = MessageModel.fromJson(json);

      expect(model.thinkingContent, 'Let me reason about this...');
    });

    test('parses tokensPerSecond from JSON as double', () {
      final json = {
        'id': 'msg-4',
        'role': 'ASSISTANT',
        'content': 'Response',
        'tokensPerSecond': 42.5,
      };

      final model = MessageModel.fromJson(json);

      expect(model.tokensPerSecond, 42.5);
    });

    test('parses tokensPerSecond from JSON integer to double', () {
      final json = {
        'id': 'msg-5',
        'role': 'ASSISTANT',
        'content': 'Response',
        'tokensPerSecond': 30,
      };

      final model = MessageModel.fromJson(json);

      expect(model.tokensPerSecond, 30.0);
    });

    test('parses inferenceTimeSeconds from JSON', () {
      final json = {
        'id': 'msg-6',
        'role': 'ASSISTANT',
        'content': 'Response',
        'inferenceTimeSeconds': 3.14,
      };

      final model = MessageModel.fromJson(json);

      expect(model.inferenceTimeSeconds, 3.14);
    });

    test('parses stopReason from JSON', () {
      final json = {
        'id': 'msg-7',
        'role': 'ASSISTANT',
        'content': 'Response',
        'stopReason': 'stop',
      };

      final model = MessageModel.fromJson(json);

      expect(model.stopReason, 'stop');
    });

    test('parses thinkingTokenCount from JSON', () {
      final json = {
        'id': 'msg-8',
        'role': 'ASSISTANT',
        'content': 'Response',
        'thinkingTokenCount': 150,
      };

      final model = MessageModel.fromJson(json);

      expect(model.thinkingTokenCount, 150);
    });

    test('parses all five new fields together', () {
      final json = {
        'id': 'msg-9',
        'role': 'ASSISTANT',
        'content': 'Full response',
        'tokenCount': 200,
        'hasRagContext': true,
        'thinkingContent': 'Step 1: analyze the question...',
        'tokensPerSecond': 55.3,
        'inferenceTimeSeconds': 4.2,
        'stopReason': 'length',
        'thinkingTokenCount': 80,
        'createdAt': '2026-03-16T10:00:00Z',
      };

      final model = MessageModel.fromJson(json);

      expect(model.id, 'msg-9');
      expect(model.role, 'ASSISTANT');
      expect(model.content, 'Full response');
      expect(model.tokenCount, 200);
      expect(model.hasRagContext, isTrue);
      expect(model.thinkingContent, 'Step 1: analyze the question...');
      expect(model.tokensPerSecond, 55.3);
      expect(model.inferenceTimeSeconds, 4.2);
      expect(model.stopReason, 'length');
      expect(model.thinkingTokenCount, 80);
      expect(model.createdAt, '2026-03-16T10:00:00Z');
    });

    // ── copyWith ────────────────────────────────────────────────────────
    group('copyWith', () {
      late MessageModel base;

      setUp(() {
        base = const MessageModel(
          id: 'base-id',
          role: 'USER',
          content: 'Original content',
          tokenCount: 10,
          hasRagContext: false,
          thinkingContent: null,
          tokensPerSecond: null,
          inferenceTimeSeconds: null,
          stopReason: null,
          thinkingTokenCount: null,
          createdAt: '2026-03-16T08:00:00Z',
        );
      });

      test('returns identical copy when no arguments given', () {
        final copy = base.copyWith();

        expect(copy.id, base.id);
        expect(copy.role, base.role);
        expect(copy.content, base.content);
        expect(copy.tokenCount, base.tokenCount);
        expect(copy.hasRagContext, base.hasRagContext);
        expect(copy.thinkingContent, base.thinkingContent);
        expect(copy.tokensPerSecond, base.tokensPerSecond);
        expect(copy.inferenceTimeSeconds, base.inferenceTimeSeconds);
        expect(copy.stopReason, base.stopReason);
        expect(copy.thinkingTokenCount, base.thinkingTokenCount);
        expect(copy.createdAt, base.createdAt);
      });

      test('replaces content field', () {
        final copy = base.copyWith(content: 'Updated content');

        expect(copy.content, 'Updated content');
        expect(copy.id, base.id);
        expect(copy.role, base.role);
      });

      test('replaces thinkingContent field', () {
        final copy = base.copyWith(thinkingContent: 'Reasoning text');

        expect(copy.thinkingContent, 'Reasoning text');
        expect(copy.content, base.content);
      });

      test('replaces tokensPerSecond field', () {
        final copy = base.copyWith(tokensPerSecond: 42.0);

        expect(copy.tokensPerSecond, 42.0);
      });

      test('replaces inferenceTimeSeconds field', () {
        final copy = base.copyWith(inferenceTimeSeconds: 2.5);

        expect(copy.inferenceTimeSeconds, 2.5);
      });

      test('replaces stopReason field', () {
        final copy = base.copyWith(stopReason: 'stop');

        expect(copy.stopReason, 'stop');
      });

      test('replaces thinkingTokenCount field', () {
        final copy = base.copyWith(thinkingTokenCount: 75);

        expect(copy.thinkingTokenCount, 75);
      });

      test('replaces multiple fields at once', () {
        final copy = base.copyWith(
          content: 'New content',
          role: 'ASSISTANT',
          thinkingContent: 'New thinking',
          tokensPerSecond: 50.0,
          inferenceTimeSeconds: 1.8,
          stopReason: 'length',
          thinkingTokenCount: 100,
        );

        expect(copy.content, 'New content');
        expect(copy.role, 'ASSISTANT');
        expect(copy.thinkingContent, 'New thinking');
        expect(copy.tokensPerSecond, 50.0);
        expect(copy.inferenceTimeSeconds, 1.8);
        expect(copy.stopReason, 'length');
        expect(copy.thinkingTokenCount, 100);
        // Unchanged fields preserved
        expect(copy.id, base.id);
        expect(copy.tokenCount, base.tokenCount);
        expect(copy.hasRagContext, base.hasRagContext);
        expect(copy.createdAt, base.createdAt);
      });
    });
  });
}
