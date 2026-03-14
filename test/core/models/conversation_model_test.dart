import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/conversation_model.dart';

void main() {
  group('ConversationModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'conv-1',
        'title': 'Test Chat',
        'isArchived': true,
        'messageCount': 5,
        'createdAt': '2026-03-14T10:00:00Z',
        'updatedAt': '2026-03-14T11:00:00Z',
      };

      final model = ConversationModel.fromJson(json);

      expect(model.id, 'conv-1');
      expect(model.title, 'Test Chat');
      expect(model.isArchived, isTrue);
      expect(model.messageCount, 5);
      expect(model.createdAt, '2026-03-14T10:00:00Z');
      expect(model.updatedAt, '2026-03-14T11:00:00Z');
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'conv-2'};

      final model = ConversationModel.fromJson(json);

      expect(model.id, 'conv-2');
      expect(model.title, isNull);
      expect(model.isArchived, isFalse);
      expect(model.messageCount, 0);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('ConversationSummaryModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'conv-1',
        'title': 'Summary Title',
        'isArchived': false,
        'messageCount': 10,
        'updatedAt': '2026-03-14T10:00:00Z',
        'lastMessagePreview': 'Hello world',
      };

      final model = ConversationSummaryModel.fromJson(json);

      expect(model.id, 'conv-1');
      expect(model.title, 'Summary Title');
      expect(model.isArchived, isFalse);
      expect(model.messageCount, 10);
      expect(model.updatedAt, '2026-03-14T10:00:00Z');
      expect(model.lastMessagePreview, 'Hello world');
    });

    test('handles missing optional fields', () {
      final json = {'id': 'conv-3'};

      final model = ConversationSummaryModel.fromJson(json);

      expect(model.id, 'conv-3');
      expect(model.lastMessagePreview, isNull);
      expect(model.isArchived, isFalse);
      expect(model.messageCount, 0);
    });
  });
}
