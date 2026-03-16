import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/device_registration_model.dart';

void main() {
  group('DeviceRegistrationModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'reg-1',
        'deviceId': 'dev-abc123',
        'deviceName': 'Android Device',
        'platform': 'android',
        'mqttClientId': 'moai-dev-abc123',
        'lastSeenAt': '2026-03-14T10:00:00Z',
      };

      final model = DeviceRegistrationModel.fromJson(json);

      expect(model.id, 'reg-1');
      expect(model.deviceId, 'dev-abc123');
      expect(model.deviceName, 'Android Device');
      expect(model.platform, 'android');
      expect(model.mqttClientId, 'moai-dev-abc123');
      expect(model.lastSeenAt, '2026-03-14T10:00:00Z');
    });

    test('handles missing fields with empty string defaults', () {
      final json = <String, dynamic>{};

      final model = DeviceRegistrationModel.fromJson(json);

      expect(model.id, '');
      expect(model.deviceId, '');
      expect(model.deviceName, '');
      expect(model.platform, '');
      expect(model.mqttClientId, '');
      expect(model.lastSeenAt, isNull);
    });

    test('handles null lastSeenAt', () {
      final json = {
        'id': 'reg-2',
        'deviceId': 'dev-xyz',
        'deviceName': 'iOS Device',
        'platform': 'ios',
        'mqttClientId': 'moai-dev-xyz',
        'lastSeenAt': null,
      };

      final model = DeviceRegistrationModel.fromJson(json);

      expect(model.lastSeenAt, isNull);
    });

    test('constructor creates model with all fields', () {
      const model = DeviceRegistrationModel(
        id: 'reg-3',
        deviceId: 'dev-test',
        deviceName: 'Test Device',
        platform: 'web',
        mqttClientId: 'moai-dev-test',
        lastSeenAt: '2026-03-15T12:00:00Z',
      );

      expect(model.id, 'reg-3');
      expect(model.deviceId, 'dev-test');
      expect(model.deviceName, 'Test Device');
      expect(model.platform, 'web');
      expect(model.mqttClientId, 'moai-dev-test');
      expect(model.lastSeenAt, '2026-03-15T12:00:00Z');
    });
  });
}
