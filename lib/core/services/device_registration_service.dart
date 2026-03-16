import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/device_registration_model.dart';

/// Registers this device with the MyOffGridAI server so that the server
/// knows which MQTT topic to publish notifications to for this user.
///
/// Registration is performed once on login and refreshed on each app start.
/// The server upserts registrations by (userId, deviceId).
class DeviceRegistrationService {
  final MyOffGridAIApiClient _client;
  final SecureStorageService _storage;

  /// Creates a [DeviceRegistrationService].
  DeviceRegistrationService({
    required MyOffGridAIApiClient client,
    required SecureStorageService storage,
  })  : _client = client,
        _storage = storage;

  /// Registers this device with the server for push notifications.
  ///
  /// Sends the device ID, platform, and MQTT client ID so the server
  /// can route notifications to the correct MQTT topic.
  Future<void> registerDevice() async {
    final deviceId = await _getOrCreateDeviceId();
    final platform = _detectPlatform();
    final mqttClientId = '${AppConstants.mqttClientIdPrefix}$deviceId';
    final deviceName = _getDeviceName();

    await _client.post<Map<String, dynamic>>(
      AppConstants.devicesBasePath,
      data: {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'mqttClientId': mqttClientId,
      },
    );
  }

  /// Gets all registered devices for the current user.
  Future<List<DeviceRegistrationModel>> getRegisteredDevices() async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.devicesBasePath,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) =>
            DeviceRegistrationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Unregisters a device by its [deviceId].
  Future<void> unregisterDevice(String deviceId) async {
    await _client.delete('${AppConstants.devicesBasePath}/$deviceId');
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.getDeviceId();
    if (existing != null) return existing;

    final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    await _storage.saveDeviceId(id);
    return id;
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  String _getDeviceName() {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'Flutter Device';
  }
}

/// Riverpod provider for [DeviceRegistrationService].
final deviceRegistrationServiceProvider =
    Provider<DeviceRegistrationService>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return DeviceRegistrationService(client: client, storage: storage);
});
