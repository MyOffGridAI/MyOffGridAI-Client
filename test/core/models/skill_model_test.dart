import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/skill_model.dart';

void main() {
  group('SkillModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'skill-1',
        'name': 'weather_check',
        'displayName': 'Weather Check',
        'description': 'Checks the weather',
        'version': '1.0.0',
        'author': 'system',
        'category': 'UTILITY',
        'isEnabled': true,
        'isBuiltIn': true,
        'parametersSchema': '{}',
        'createdAt': '2026-03-14T10:00:00Z',
        'updatedAt': '2026-03-14T11:00:00Z',
      };

      final model = SkillModel.fromJson(json);

      expect(model.id, 'skill-1');
      expect(model.name, 'weather_check');
      expect(model.displayName, 'Weather Check');
      expect(model.description, 'Checks the weather');
      expect(model.isEnabled, isTrue);
      expect(model.isBuiltIn, isTrue);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'skill-2', 'skillId': 'skill-2'};

      final model = SkillModel.fromJson(json);

      expect(model.name, '');
      expect(model.displayName, '');
      expect(model.isEnabled, isFalse);
      expect(model.isBuiltIn, isFalse);
    });
  });

  group('SkillExecutionModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'exec-1',
        'skillId': 'skill-1',
        'skillName': 'weather_check',
        'userId': 'user-1',
        'status': 'SUCCESS',
        'inputParams': '{"city": "Denver"}',
        'outputResult': 'Sunny, 72F',
        'errorMessage': null,
        'startedAt': '2026-03-14T10:00:00Z',
        'completedAt': '2026-03-14T10:00:05Z',
        'durationMs': 5000,
      };

      final model = SkillExecutionModel.fromJson(json);

      expect(model.id, 'exec-1');
      expect(model.skillId, 'skill-1');
      expect(model.skillName, 'weather_check');
      expect(model.status, 'SUCCESS');
      expect(model.durationMs, 5000);
    });

    test('isRunning returns true for RUNNING status', () {
      final model = SkillExecutionModel.fromJson(
          {'id': '1', 'skillId': 's1', 'status': 'RUNNING'});
      expect(model.isRunning, isTrue);
      expect(model.isSuccess, isFalse);
      expect(model.isFailed, isFalse);
    });

    test('isSuccess returns true for SUCCESS status', () {
      final model = SkillExecutionModel.fromJson(
          {'id': '1', 'skillId': 's1', 'status': 'SUCCESS'});
      expect(model.isSuccess, isTrue);
    });

    test('isFailed returns true for FAILED status', () {
      final model = SkillExecutionModel.fromJson(
          {'id': '1', 'skillId': 's1', 'status': 'FAILED'});
      expect(model.isFailed, isTrue);
    });
  });
}
