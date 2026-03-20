import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/judge_models.dart';

void main() {
  group('JudgeStatusModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'enabled': true,
        'processRunning': true,
        'judgeModelFilename': 'judge-model.gguf',
        'port': 1235,
        'scoreThreshold': 7.5,
      };

      final model = JudgeStatusModel.fromJson(json);

      expect(model.enabled, isTrue);
      expect(model.processRunning, isTrue);
      expect(model.judgeModelFilename, 'judge-model.gguf');
      expect(model.port, 1235);
      expect(model.scoreThreshold, 7.5);
    });

    test('handles missing optional fields with defaults', () {
      final json = <String, dynamic>{};

      final model = JudgeStatusModel.fromJson(json);

      expect(model.enabled, isFalse);
      expect(model.processRunning, isFalse);
      expect(model.judgeModelFilename, isNull);
      expect(model.port, 0);
      expect(model.scoreThreshold, 7.0);
    });

    test('parses scoreThreshold from integer to double', () {
      final json = {
        'scoreThreshold': 8,
      };

      final model = JudgeStatusModel.fromJson(json);

      expect(model.scoreThreshold, 8.0);
    });
  });

  group('JudgeTestResultModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'assistantResponse': 'Java is a programming language.',
        'score': 8.5,
        'reason': 'Good response with relevant detail',
        'needsCloud': false,
        'judgeAvailable': true,
        'error': null,
      };

      final model = JudgeTestResultModel.fromJson(json);

      expect(model.assistantResponse, 'Java is a programming language.');
      expect(model.score, 8.5);
      expect(model.reason, 'Good response with relevant detail');
      expect(model.needsCloud, isFalse);
      expect(model.judgeAvailable, isTrue);
      expect(model.error, isNull);
    });

    test('handles unavailable judge', () {
      final json = {
        'score': 0.0,
        'reason': null,
        'needsCloud': false,
        'judgeAvailable': false,
        'error': 'Judge is not available',
      };

      final model = JudgeTestResultModel.fromJson(json);

      expect(model.judgeAvailable, isFalse);
      expect(model.error, 'Judge is not available');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = JudgeTestResultModel.fromJson(json);

      expect(model.assistantResponse, isNull);
      expect(model.score, 0.0);
      expect(model.reason, isNull);
      expect(model.needsCloud, isFalse);
      expect(model.judgeAvailable, isFalse);
      expect(model.error, isNull);
    });

    test('parses score from integer to double', () {
      final json = {
        'score': 7,
        'judgeAvailable': true,
      };

      final model = JudgeTestResultModel.fromJson(json);

      expect(model.score, 7.0);
    });
  });
}
