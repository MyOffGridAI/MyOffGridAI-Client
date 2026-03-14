import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';

void main() {
  group('MemoryModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'mem-1',
        'content': 'User prefers dark mode',
        'importance': 'HIGH',
        'tags': 'preference, ui',
        'sourceConversationId': 'conv-1',
        'createdAt': '2026-03-14T10:00:00Z',
        'updatedAt': '2026-03-14T11:00:00Z',
        'lastAccessedAt': '2026-03-14T12:00:00Z',
        'accessCount': 5,
      };

      final model = MemoryModel.fromJson(json);

      expect(model.id, 'mem-1');
      expect(model.content, 'User prefers dark mode');
      expect(model.importance, 'HIGH');
      expect(model.tags, 'preference, ui');
      expect(model.sourceConversationId, 'conv-1');
      expect(model.accessCount, 5);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'mem-2'};

      final model = MemoryModel.fromJson(json);

      expect(model.content, '');
      expect(model.importance, 'LOW');
      expect(model.tags, isNull);
      expect(model.accessCount, 0);
    });

    test('tagList splits comma-separated tags', () {
      final model = MemoryModel.fromJson({
        'id': '1',
        'tags': 'tag1, tag2, tag3',
      });
      expect(model.tagList, ['tag1', 'tag2', 'tag3']);
    });

    test('tagList returns empty for null tags', () {
      final model = MemoryModel.fromJson({'id': '1'});
      expect(model.tagList, isEmpty);
    });

    test('tagList returns empty for empty string tags', () {
      final model = MemoryModel.fromJson({'id': '1', 'tags': ''});
      expect(model.tagList, isEmpty);
    });
  });

  group('MemorySearchResultModel', () {
    test('parses from JSON', () {
      final json = {
        'memory': {
          'id': 'mem-1',
          'content': 'Test memory',
          'importance': 'MEDIUM',
          'accessCount': 0,
        },
        'similarityScore': 0.85,
      };

      final model = MemorySearchResultModel.fromJson(json);

      expect(model.memory.id, 'mem-1');
      expect(model.memory.content, 'Test memory');
      expect(model.similarityScore, 0.85);
    });
  });
}
