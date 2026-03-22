import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages display of local push notifications using flutter_local_notifications.
///
/// Handles initialization, notification channel setup (Android), permission
/// requests (Android 13+ / iOS), and display of incoming MQTT-delivered
/// notifications.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Creates a [LocalNotificationService] with an optional plugin override.
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initializes the notification plugin and creates the Android channel.
  ///
  /// Must be called once during app startup before showing any notifications.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await _plugin.initialize(settings);

    // Create the notification channel on Android
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  /// Requests notification permission from the OS.
  ///
  /// Returns true if permission was granted, false otherwise.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Displays a local notification with the given [id], [title], [body],
  /// and optional [payload].
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Displays a notification for an MQTT-delivered [notification].
  ///
  /// Maps severity to Android importance: CRITICAL = max, WARNING = high,
  /// INFO = default.
  Future<void> showAlertNotification(NotificationModel notification) async {
    if (!_initialized) return;

    final importance = _importanceForSeverity(notification.severity);
    final priority = _priorityForSeverity(notification.severity);

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: importance,
      priority: priority,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.id,
    );
  }

  Importance _importanceForSeverity(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return Importance.max;
      case NotificationSeverity.warning:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _priorityForSeverity(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return Priority.max;
      case NotificationSeverity.warning:
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }
}

/// Riverpod provider for [LocalNotificationService].
final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
