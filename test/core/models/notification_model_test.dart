import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'notif-1',
        'title': 'Sensor Alert',
        'body': 'Temperature too high',
        'type': 'ALERT',
        'isRead': false,
        'createdAt': '2026-03-14T10:00:00Z',
        'readAt': null,
        'metadata': '{"sensorId": "sen-1"}',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-1');
      expect(model.title, 'Sensor Alert');
      expect(model.body, 'Temperature too high');
      expect(model.type, 'ALERT');
      expect(model.isRead, isFalse);
      expect(model.metadata, '{"sensorId": "sen-1"}');
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'notif-2'};

      final model = NotificationModel.fromJson(json);

      expect(model.title, '');
      expect(model.body, '');
      expect(model.type, 'INFO');
      expect(model.isRead, isFalse);
    });
  });

  group('NotificationType', () {
    test('constants have expected values', () {
      expect(NotificationType.alert, 'ALERT');
      expect(NotificationType.info, 'INFO');
      expect(NotificationType.warning, 'WARNING');
      expect(NotificationType.error, 'ERROR');
      expect(NotificationType.success, 'SUCCESS');
    });
  });
}
