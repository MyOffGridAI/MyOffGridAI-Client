import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/event_model.dart';

void main() {
  group('ScheduledEventModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'evt-1',
        'userId': 'user-1',
        'name': 'Daily Report',
        'description': 'Generate a daily report',
        'eventType': 'SCHEDULED',
        'isEnabled': true,
        'cronExpression': '0 0 8 * * *',
        'recurringIntervalMinutes': null,
        'sensorId': null,
        'thresholdOperator': null,
        'thresholdValue': null,
        'actionType': 'AI_PROMPT',
        'actionPayload': 'Summarize today',
        'lastTriggeredAt': '2026-03-14T08:00:00Z',
        'nextFireAt': '2026-03-15T08:00:00Z',
        'createdAt': '2026-03-14T10:00:00Z',
        'updatedAt': '2026-03-14T11:00:00Z',
      };

      final model = ScheduledEventModel.fromJson(json);

      expect(model.id, 'evt-1');
      expect(model.userId, 'user-1');
      expect(model.name, 'Daily Report');
      expect(model.description, 'Generate a daily report');
      expect(model.eventType, 'SCHEDULED');
      expect(model.isEnabled, isTrue);
      expect(model.cronExpression, '0 0 8 * * *');
      expect(model.actionType, 'AI_PROMPT');
      expect(model.actionPayload, 'Summarize today');
      expect(model.lastTriggeredAt, '2026-03-14T08:00:00Z');
      expect(model.nextFireAt, '2026-03-15T08:00:00Z');
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'evt-2'};

      final model = ScheduledEventModel.fromJson(json);

      expect(model.name, '');
      expect(model.eventType, 'SCHEDULED');
      expect(model.isEnabled, isTrue);
      expect(model.actionType, 'PUSH_NOTIFICATION');
      expect(model.actionPayload, '');
      expect(model.description, isNull);
      expect(model.cronExpression, isNull);
      expect(model.sensorId, isNull);
      expect(model.thresholdOperator, isNull);
      expect(model.thresholdValue, isNull);
    });

    test('toJson round-trip preserves data', () {
      final json = {
        'id': 'evt-3',
        'userId': 'user-1',
        'name': 'Test',
        'description': null,
        'eventType': 'RECURRING',
        'isEnabled': false,
        'cronExpression': null,
        'recurringIntervalMinutes': 60,
        'sensorId': null,
        'thresholdOperator': null,
        'thresholdValue': null,
        'actionType': 'PUSH_NOTIFICATION',
        'actionPayload': 'Check sensors',
        'lastTriggeredAt': null,
        'nextFireAt': null,
        'createdAt': null,
        'updatedAt': null,
      };

      final model = ScheduledEventModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], 'evt-3');
      expect(output['eventType'], 'RECURRING');
      expect(output['recurringIntervalMinutes'], 60);
      expect(output['isEnabled'], false);
    });
  });

  group('EventType', () {
    test('all contains expected types', () {
      expect(EventType.all, contains('SCHEDULED'));
      expect(EventType.all, contains('SENSOR_THRESHOLD'));
      expect(EventType.all, contains('RECURRING'));
      expect(EventType.all.length, 3);
    });

    test('label returns readable names', () {
      expect(EventType.label('SCHEDULED'), 'Scheduled');
      expect(EventType.label('SENSOR_THRESHOLD'), 'Sensor Threshold');
      expect(EventType.label('RECURRING'), 'Recurring');
    });
  });

  group('ActionType', () {
    test('all contains expected types', () {
      expect(ActionType.all, contains('PUSH_NOTIFICATION'));
      expect(ActionType.all, contains('AI_PROMPT'));
      expect(ActionType.all, contains('AI_SUMMARY'));
      expect(ActionType.all.length, 3);
    });

    test('label returns readable names', () {
      expect(ActionType.label('PUSH_NOTIFICATION'), 'Push Notification');
      expect(ActionType.label('AI_PROMPT'), 'AI Prompt');
      expect(ActionType.label('AI_SUMMARY'), 'AI Summary');
    });
  });

  group('ThresholdOperator', () {
    test('all contains expected operators', () {
      expect(ThresholdOperator.all, contains('ABOVE'));
      expect(ThresholdOperator.all, contains('BELOW'));
      expect(ThresholdOperator.all, contains('EQUALS'));
      expect(ThresholdOperator.all.length, 3);
    });

    test('label returns readable names', () {
      expect(ThresholdOperator.label('ABOVE'), 'Above');
      expect(ThresholdOperator.label('BELOW'), 'Below');
      expect(ThresholdOperator.label('EQUALS'), 'Equals');
    });
  });
}
