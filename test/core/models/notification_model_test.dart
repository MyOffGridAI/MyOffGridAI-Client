import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'notif-1',
        'title': 'Sensor Alert',
        'body': 'Temperature too high',
        'type': 'SENSOR_ALERT',
        'severity': 'CRITICAL',
        'isRead': false,
        'createdAt': '2026-03-14T10:00:00Z',
        'readAt': null,
        'metadata': '{"sensorId": "sen-1"}',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-1');
      expect(model.title, 'Sensor Alert');
      expect(model.body, 'Temperature too high');
      expect(model.type, 'SENSOR_ALERT');
      expect(model.severity, 'CRITICAL');
      expect(model.isRead, isFalse);
      expect(model.createdAt, '2026-03-14T10:00:00Z');
      expect(model.metadata, '{"sensorId": "sen-1"}');
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'notif-2'};

      final model = NotificationModel.fromJson(json);

      expect(model.title, '');
      expect(model.body, '');
      expect(model.type, 'GENERAL');
      expect(model.severity, 'INFO');
      expect(model.isRead, isFalse);
      expect(model.createdAt, isNull);
      expect(model.readAt, isNull);
      expect(model.metadata, isNull);
    });

    test('parses readAt and metadata when present', () {
      final json = {
        'id': 'notif-3',
        'title': 'Update',
        'body': 'Model updated',
        'type': 'MODEL_UPDATE',
        'severity': 'INFO',
        'isRead': true,
        'createdAt': '2026-03-14T10:00:00Z',
        'readAt': '2026-03-14T10:05:00Z',
        'metadata': '{"version": "2.0"}',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.isRead, isTrue);
      expect(model.readAt, '2026-03-14T10:05:00Z');
      expect(model.metadata, '{"version": "2.0"}');
    });
  });

  group('NotificationType', () {
    test('constants have expected values', () {
      expect(NotificationType.sensorAlert, 'SENSOR_ALERT');
      expect(NotificationType.systemHealth, 'SYSTEM_HEALTH');
      expect(NotificationType.insightReady, 'INSIGHT_READY');
      expect(NotificationType.modelUpdate, 'MODEL_UPDATE');
      expect(NotificationType.general, 'GENERAL');
    });
  });

  group('NotificationSeverity', () {
    test('constants have expected values', () {
      expect(NotificationSeverity.info, 'INFO');
      expect(NotificationSeverity.warning, 'WARNING');
      expect(NotificationSeverity.critical, 'CRITICAL');
    });
  });
}
