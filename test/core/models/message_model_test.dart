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
  });
}
