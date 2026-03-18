import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';

/// Manages the Android foreground service that keeps the MQTT connection alive
/// when the app is in the background.
///
/// On iOS and web, this class is a no-op — background MQTT is not supported
/// on those platforms.
class ForegroundServiceManager {
  bool _running = false;

  /// Whether the foreground service is currently running.
  bool get isRunning => _running;

  /// Starts the foreground service on Android.
  ///
  /// On non-Android platforms this is a no-op.
  Future<void> startService() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_running) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConstants.foregroundServiceChannelId,
        channelName: AppConstants.foregroundServiceChannelName,
        channelImportance: NotificationChannelImportance.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: AppConstants.foregroundServiceNotificationTitle,
      notificationText: AppConstants.foregroundServiceNotificationBody,
    );

    _running = true;
    LogService.instance.info('FG_SVC', 'Foreground service started');
  }

  /// Stops the foreground service on Android.
  ///
  /// On non-Android platforms this is a no-op.
  Future<void> stopService() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!_running) return;

    await FlutterForegroundTask.stopService();
    _running = false;
    LogService.instance.info('FG_SVC', 'Foreground service stopped');
  }
}

/// Riverpod provider for [ForegroundServiceManager].
final foregroundServiceManagerProvider =
    Provider<ForegroundServiceManager>((ref) {
  return ForegroundServiceManager();
});
