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
