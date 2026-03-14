import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';

void main() {
  group('SensorModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'sen-1',
        'name': 'Greenhouse Temp',
        'type': 'TEMPERATURE',
        'portPath': '/dev/ttyUSB0',
        'baudRate': 9600,
        'dataFormat': 'JSON_LINE',
        'valueField': 'temp',
        'unit': '°C',
        'isActive': true,
        'pollIntervalSeconds': 30,
        'lowThreshold': 5.0,
        'highThreshold': 40.0,
        'createdAt': '2026-03-14T10:00:00Z',
        'updatedAt': '2026-03-14T11:00:00Z',
      };

      final model = SensorModel.fromJson(json);

      expect(model.id, 'sen-1');
      expect(model.name, 'Greenhouse Temp');
      expect(model.type, 'TEMPERATURE');
      expect(model.portPath, '/dev/ttyUSB0');
      expect(model.baudRate, 9600);
      expect(model.unit, '°C');
      expect(model.isActive, isTrue);
      expect(model.pollIntervalSeconds, 30);
      expect(model.lowThreshold, 5.0);
      expect(model.highThreshold, 40.0);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'sen-2'};

      final model = SensorModel.fromJson(json);

      expect(model.name, '');
      expect(model.type, 'TEMPERATURE');
      expect(model.baudRate, 9600);
      expect(model.isActive, isFalse);
      expect(model.pollIntervalSeconds, 60);
      expect(model.lowThreshold, isNull);
      expect(model.highThreshold, isNull);
    });
  });

  group('SensorReadingModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'read-1',
        'sensorId': 'sen-1',
        'value': 23.5,
        'rawData': '{"temp": 23.5}',
        'recordedAt': '2026-03-14T10:00:00Z',
      };

      final model = SensorReadingModel.fromJson(json);

      expect(model.id, 'read-1');
      expect(model.sensorId, 'sen-1');
      expect(model.value, 23.5);
      expect(model.rawData, '{"temp": 23.5}');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = SensorReadingModel.fromJson(json);

      expect(model.id, '');
      expect(model.sensorId, '');
      expect(model.value, 0.0);
    });
  });

  group('SensorTestResultModel', () {
    test('parses from JSON', () {
      final json = {
        'success': true,
        'portPath': '/dev/ttyUSB0',
        'baudRate': 9600,
        'sampleData': '23.5',
        'message': 'Connection successful',
      };

      final model = SensorTestResultModel.fromJson(json);

      expect(model.success, isTrue);
      expect(model.portPath, '/dev/ttyUSB0');
      expect(model.baudRate, 9600);
      expect(model.sampleData, '23.5');
      expect(model.message, 'Connection successful');
    });
  });

  group('SensorType', () {
    test('all contains expected types', () {
      expect(SensorType.all, contains('TEMPERATURE'));
      expect(SensorType.all, contains('HUMIDITY'));
      expect(SensorType.all, contains('PRESSURE'));
      expect(SensorType.all, contains('SOIL_MOISTURE'));
      expect(SensorType.all, contains('WIND_SPEED'));
      expect(SensorType.all, contains('SOLAR_RADIATION'));
      expect(SensorType.all.length, 6);
    });
  });

  group('DataFormat', () {
    test('all contains expected formats', () {
      expect(DataFormat.all, contains('CSV_LINE'));
      expect(DataFormat.all, contains('JSON_LINE'));
      expect(DataFormat.all, contains('RAW_TEXT'));
      expect(DataFormat.all.length, 3);
    });
  });
}
