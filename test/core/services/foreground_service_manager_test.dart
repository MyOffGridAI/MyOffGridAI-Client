import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/services/foreground_service_manager.dart';

void main() {
  group('ForegroundServiceManager', () {
    late ForegroundServiceManager manager;

    setUp(() {
      manager = ForegroundServiceManager();
    });

    test('isRunning is false initially', () {
      expect(manager.isRunning, isFalse);
    });

    test('startService() is a no-op on non-Android (test runs on macOS)', () async {
      // In the Dart test environment, Platform.isAndroid is false,
      // so startService should be a no-op.
      await manager.startService();

      expect(manager.isRunning, isFalse);
    });

    test('stopService() is a no-op on non-Android', () async {
      await manager.stopService();

      expect(manager.isRunning, isFalse);
    });

    test('stopService() is safe to call when not running', () async {
      // Should not throw
      await manager.stopService();
      await manager.stopService();

      expect(manager.isRunning, isFalse);
    });
  });
}
