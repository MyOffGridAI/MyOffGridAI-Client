import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/insight_model.dart';

void main() {
  group('InsightModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'ins-1',
        'content': 'Solar panel efficiency dropping',
        'category': 'MAINTENANCE',
        'isRead': true,
        'isDismissed': false,
        'generatedAt': '2026-03-14T10:00:00Z',
        'readAt': '2026-03-14T11:00:00Z',
      };

      final model = InsightModel.fromJson(json);

      expect(model.id, 'ins-1');
      expect(model.content, 'Solar panel efficiency dropping');
      expect(model.category, 'MAINTENANCE');
      expect(model.isRead, isTrue);
      expect(model.isDismissed, isFalse);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'ins-2'};

      final model = InsightModel.fromJson(json);

      expect(model.content, '');
      expect(model.category, 'PLANNING');
      expect(model.isRead, isFalse);
      expect(model.isDismissed, isFalse);
    });
  });

  group('InsightCategory', () {
    test('all contains expected categories', () {
      expect(InsightCategory.all, contains('SECURITY'));
      expect(InsightCategory.all, contains('EFFICIENCY'));
      expect(InsightCategory.all, contains('HEALTH'));
      expect(InsightCategory.all, contains('MAINTENANCE'));
      expect(InsightCategory.all, contains('SUSTAINABILITY'));
      expect(InsightCategory.all, contains('PLANNING'));
      expect(InsightCategory.all.length, 6);
    });
  });
}
