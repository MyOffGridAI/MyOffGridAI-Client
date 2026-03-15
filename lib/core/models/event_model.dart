/// Represents a scheduled event.
///
/// Mirrors the server's ScheduledEventDto.
class ScheduledEventModel {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String eventType;
  final bool isEnabled;
  final String? cronExpression;
  final int? recurringIntervalMinutes;
  final String? sensorId;
  final String? thresholdOperator;
  final double? thresholdValue;
  final String actionType;
  final String actionPayload;
  final String? lastTriggeredAt;
  final String? nextFireAt;
  final String? createdAt;
  final String? updatedAt;

  const ScheduledEventModel({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    required this.eventType,
    required this.isEnabled,
    this.cronExpression,
    this.recurringIntervalMinutes,
    this.sensorId,
    this.thresholdOperator,
    this.thresholdValue,
    required this.actionType,
    required this.actionPayload,
    this.lastTriggeredAt,
    this.nextFireAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [ScheduledEventModel] from a JSON map.
  factory ScheduledEventModel.fromJson(Map<String, dynamic> json) {
    return ScheduledEventModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      eventType: json['eventType'] as String? ?? 'SCHEDULED',
      isEnabled: json['isEnabled'] as bool? ?? true,
      cronExpression: json['cronExpression'] as String?,
      recurringIntervalMinutes: json['recurringIntervalMinutes'] as int?,
      sensorId: json['sensorId'] as String?,
      thresholdOperator: json['thresholdOperator'] as String?,
      thresholdValue: (json['thresholdValue'] as num?)?.toDouble(),
      actionType: json['actionType'] as String? ?? 'PUSH_NOTIFICATION',
      actionPayload: json['actionPayload'] as String? ?? '',
      lastTriggeredAt: json['lastTriggeredAt'] as String?,
      nextFireAt: json['nextFireAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'eventType': eventType,
      'isEnabled': isEnabled,
      'cronExpression': cronExpression,
      'recurringIntervalMinutes': recurringIntervalMinutes,
      'sensorId': sensorId,
      'thresholdOperator': thresholdOperator,
      'thresholdValue': thresholdValue,
      'actionType': actionType,
      'actionPayload': actionPayload,
      'lastTriggeredAt': lastTriggeredAt,
      'nextFireAt': nextFireAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Valid event types matching the server enum.
class EventType {
  EventType._();

  static const String scheduled = 'SCHEDULED';
  static const String sensorThreshold = 'SENSOR_THRESHOLD';
  static const String recurring = 'RECURRING';

  static const List<String> all = [scheduled, sensorThreshold, recurring];

  /// Returns a human-readable label for the given event type.
  static String label(String type) {
    switch (type) {
      case scheduled:
        return 'Scheduled';
      case sensorThreshold:
        return 'Sensor Threshold';
      case recurring:
        return 'Recurring';
      default:
        return type;
    }
  }
}

/// Valid action types matching the server enum.
class ActionType {
  ActionType._();

  static const String pushNotification = 'PUSH_NOTIFICATION';
  static const String aiPrompt = 'AI_PROMPT';
  static const String aiSummary = 'AI_SUMMARY';

  static const List<String> all = [pushNotification, aiPrompt, aiSummary];

  /// Returns a human-readable label for the given action type.
  static String label(String type) {
    switch (type) {
      case pushNotification:
        return 'Push Notification';
      case aiPrompt:
        return 'AI Prompt';
      case aiSummary:
        return 'AI Summary';
      default:
        return type;
    }
  }
}

/// Valid threshold operators matching the server enum.
class ThresholdOperator {
  ThresholdOperator._();

  static const String above = 'ABOVE';
  static const String below = 'BELOW';
  static const String equals = 'EQUALS';

  static const List<String> all = [above, below, equals];

  /// Returns a human-readable label for the given operator.
  static String label(String op) {
    switch (op) {
      case above:
        return 'Above';
      case below:
        return 'Below';
      case equals:
        return 'Equals';
      default:
        return op;
    }
  }
}
