/// Represents a notification from the system.
///
/// Mirrors the server's NotificationDto. Type uses enum values:
/// SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL.
/// Severity uses: INFO, WARNING, CRITICAL.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String severity;
  final bool isRead;
  final String? createdAt;
  final String? readAt;
  final String? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.severity = 'INFO',
    required this.isRead,
    this.createdAt,
    this.readAt,
    this.metadata,
  });

  /// Creates a [NotificationModel] from a JSON map.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
      severity: json['severity'] as String? ?? 'INFO',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      readAt: json['readAt'] as String?,
      metadata: json['metadata'] as String?,
    );
  }
}

/// Valid notification types matching the server enum.
class NotificationType {
  NotificationType._();

  static const String sensorAlert = 'SENSOR_ALERT';
  static const String systemHealth = 'SYSTEM_HEALTH';
  static const String insightReady = 'INSIGHT_READY';
  static const String modelUpdate = 'MODEL_UPDATE';
  static const String general = 'GENERAL';
}

/// Valid notification severity levels matching the server enum.
class NotificationSeverity {
  NotificationSeverity._();

  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String critical = 'CRITICAL';
}
