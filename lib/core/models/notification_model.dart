/// Represents a notification from the system.
///
/// Mirrors the server's NotificationDto. Type uses enum values:
/// ALERT, INFO, WARNING, ERROR, SUCCESS.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? createdAt;
  final String? readAt;
  final String? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
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
      type: json['type'] as String? ?? 'INFO',
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

  static const String alert = 'ALERT';
  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String error = 'ERROR';
  static const String success = 'SUCCESS';
}
