import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/services/device_registration_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

class _FakeSecureStorageService extends SecureStorageService {
  String? _deviceId;

  _FakeSecureStorageService({String? deviceId})
      : _deviceId = deviceId,
        super(storage: null);

  @override
  Future<String?> getDeviceId() async => _deviceId;

  @override
  Future<void> saveDeviceId(String deviceId) async {
    _deviceId = deviceId;
  }

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearTokens() async {}

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<String> getServerUrl() async => AppConstants.defaultServerUrl;

  @override
  Future<void> saveServerUrl(String url) async {}

  @override
  Future<String> getThemePreference() async => 'system';

  @override
  Future<void> saveThemePreference(String theme) async {}
}

void main() {
  late MockApiClient mockClient;
  late _FakeSecureStorageService fakeStorage;
  late DeviceRegistrationService service;

  setUp(() {
    mockClient = MockApiClient();
    fakeStorage = _FakeSecureStorageService(deviceId: 'test-device-id');
    service = DeviceRegistrationService(
      client: mockClient,
      storage: fakeStorage,
    );
  });

  group('DeviceRegistrationService', () {
    test('registerDevice() posts with existing device ID', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.registerDevice();

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            captureAny(),
            data: captureAny(named: 'data'),
          )).captured;

      expect(captured[0], AppConstants.devicesBasePath);
      final data = captured[1] as Map<String, dynamic>;
      expect(data['deviceId'], 'test-device-id');
      expect(data['mqttClientId'],
          '${AppConstants.mqttClientIdPrefix}test-device-id');
      expect(data['deviceName'], isA<String>());
      expect(data['platform'], isA<String>());
    });

    test('registerDevice() creates device ID when none exists', () async {
      fakeStorage = _FakeSecureStorageService(deviceId: null);
      service = DeviceRegistrationService(
        client: mockClient,
        storage: fakeStorage,
      );

      when(() => mockClient.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.registerDevice();

      // Should have generated and saved a device ID
      final savedId = await fakeStorage.getDeviceId();
      expect(savedId, isNotNull);
      expect(savedId, isNotEmpty);

      // Verify the post was called
      verify(() => mockClient.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).called(1);
    });

    test('getRegisteredDevices() returns parsed models', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            any(),
          )).thenAnswer((_) async => {
                'data': [
                  {
                    'id': 'reg-1',
                    'deviceId': 'dev-1',
                    'deviceName': 'Test Device',
                    'platform': 'android',
                    'mqttClientId': 'moai-dev-1',
                    'lastSeenAt': '2026-03-14T10:00:00Z',
                  },
                  {
                    'id': 'reg-2',
                    'deviceId': 'dev-2',
                    'deviceName': 'Web Browser',
                    'platform': 'web',
                    'mqttClientId': 'moai-dev-2',
                    'lastSeenAt': null,
                  },
                ],
              });

      final devices = await service.getRegisteredDevices();

      expect(devices, hasLength(2));
      expect(devices[0].id, 'reg-1');
      expect(devices[0].deviceId, 'dev-1');
      expect(devices[1].platform, 'web');
    });

    test('getRegisteredDevices() returns empty list when data is null',
        () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            any(),
          )).thenAnswer((_) async => {'data': null});

      final devices = await service.getRegisteredDevices();

      expect(devices, isEmpty);
    });

    test('unregisterDevice() sends DELETE request', () async {
      when(() => mockClient.delete(any())).thenAnswer((_) async {});

      await service.unregisterDevice('dev-123');

      verify(
        () => mockClient.delete('${AppConstants.devicesBasePath}/dev-123'),
      ).called(1);
    });
  });
}
