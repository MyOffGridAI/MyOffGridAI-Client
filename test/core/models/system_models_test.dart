import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';

void main() {
  group('SystemStatusModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'initialized': true,
        'instanceName': 'MyOffGrid-Home',
        'fortressEnabled': true,
        'wifiConfigured': true,
        'serverVersion': '1.0.0',
        'timestamp': '2026-03-14T10:00:00Z',
      };

      final model = SystemStatusModel.fromJson(json);

      expect(model.initialized, isTrue);
      expect(model.instanceName, 'MyOffGrid-Home');
      expect(model.fortressEnabled, isTrue);
      expect(model.wifiConfigured, isTrue);
      expect(model.serverVersion, '1.0.0');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = SystemStatusModel.fromJson(json);

      expect(model.initialized, isFalse);
      expect(model.fortressEnabled, isFalse);
      expect(model.wifiConfigured, isFalse);
      expect(model.instanceName, isNull);
    });
  });

  group('OllamaModelInfoModel', () {
    test('parses from JSON', () {
      final json = {
        'name': 'llama3:8b',
        'size': 4700000000,
        'modifiedAt': '2026-03-14T10:00:00Z',
      };

      final model = OllamaModelInfoModel.fromJson(json);

      expect(model.name, 'llama3:8b');
      expect(model.size, 4700000000);
      expect(model.modifiedAt, '2026-03-14T10:00:00Z');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = OllamaModelInfoModel.fromJson(json);

      expect(model.name, '');
      expect(model.size, 0);
    });
  });

  group('AiSettingsModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'modelName': 'llama3:8b',
        'temperature': 0.9,
        'similarityThreshold': 0.5,
        'memoryTopK': 10,
        'ragMaxContextTokens': 4096,
        'contextSize': 8192,
        'contextMessageLimit': 50,
      };

      final model = AiSettingsModel.fromJson(json);

      expect(model.modelName, 'llama3:8b');
      expect(model.temperature, 0.9);
      expect(model.similarityThreshold, 0.5);
      expect(model.memoryTopK, 10);
      expect(model.ragMaxContextTokens, 4096);
      expect(model.contextSize, 8192);
      expect(model.contextMessageLimit, 50);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = AiSettingsModel.fromJson(json);

      expect(model.modelName, '');
      expect(model.temperature, 0.7);
      expect(model.similarityThreshold, 0.45);
      expect(model.memoryTopK, 5);
      expect(model.ragMaxContextTokens, 2048);
      expect(model.contextSize, 4096);
      expect(model.contextMessageLimit, 20);
    });

    test('toJson includes all fields', () {
      const model = AiSettingsModel(
        modelName: 'test-model',
        temperature: 1.0,
        similarityThreshold: 0.6,
        memoryTopK: 8,
        ragMaxContextTokens: 3072,
        contextSize: 16384,
        contextMessageLimit: 40,
      );

      final json = model.toJson();

      expect(json['modelName'], 'test-model');
      expect(json['temperature'], 1.0);
      expect(json['similarityThreshold'], 0.6);
      expect(json['memoryTopK'], 8);
      expect(json['ragMaxContextTokens'], 3072);
      expect(json['contextSize'], 16384);
      expect(json['contextMessageLimit'], 40);
    });
  });

  group('ActiveModelInfo', () {
    test('parses from JSON', () {
      final json = {
        'modelName': 'llama3:8b',
        'embedModelName': 'nomic-embed-text',
      };

      final model = ActiveModelInfo.fromJson(json);

      expect(model.modelName, 'llama3:8b');
      expect(model.embedModelName, 'nomic-embed-text');
    });

    test('handles all null fields', () {
      final json = <String, dynamic>{};

      final model = ActiveModelInfo.fromJson(json);

      expect(model.modelName, isNull);
      expect(model.embedModelName, isNull);
    });
  });
}
