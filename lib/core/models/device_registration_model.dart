/// Represents a registered device for MQTT push notifications.
///
/// Mirrors the server's DeviceRegistrationDto.
class DeviceRegistrationModel {
  /// The server-assigned registration ID.
  final String id;

  /// The client-assigned unique device identifier.
  final String deviceId;

  /// A human-readable name for the device.
  final String deviceName;

  /// The device platform (android, ios, web).
  final String platform;

  /// The MQTT client ID used by this device.
  final String mqttClientId;

  /// When the device was last seen by the server.
  final String? lastSeenAt;

  /// Creates a [DeviceRegistrationModel].
  const DeviceRegistrationModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.mqttClientId,
    this.lastSeenAt,
  });

  /// Creates a [DeviceRegistrationModel] from a JSON map.
  factory DeviceRegistrationModel.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationModel(
      id: json['id'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      mqttClientId: json['mqttClientId'] as String? ?? '',
      lastSeenAt: json['lastSeenAt'] as String?,
    );
  }
}
