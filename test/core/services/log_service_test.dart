import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';

void main() {
  late Directory tempDir;
  late LogService logService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('log_service_test_');
    logService = LogService();
  });

  tearDown(() async {
    await logService.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('initializes and creates log file in directory', () async {
    await logService.initializeWithPath(tempDir.path);

    final logFile = File('${tempDir.path}/myoffgridai.log');
    expect(logFile.existsSync(), isTrue);
  });

  test('writes formatted log lines to file', () async {
    await logService.initializeWithPath(tempDir.path);

    logService.info('TEST', 'Hello world');
    await logService.dispose();

    final logFile = File('${tempDir.path}/myoffgridai.log');
    final contents = logFile.readAsStringSync();
    expect(contents, contains('Hello world'));
  });

  test('includes timestamp, level, tag, and message in log lines', () async {
    await logService.initializeWithPath(tempDir.path);

    logService.info('MY_TAG', 'Test message');
    await logService.dispose();

    final logFile = File('${tempDir.path}/myoffgridai.log');
    final contents = logFile.readAsStringSync();

    // Verify ISO 8601 timestamp pattern
    expect(contents, matches(RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')));
    expect(contents, contains('[INFO]'));
    expect(contents, contains('[MY_TAG]'));
    expect(contents, contains('Test message'));
  });

  test('error() includes error and stack trace', () async {
    await logService.initializeWithPath(tempDir.path);

    final error = Exception('Something broke');
    final stackTrace = StackTrace.current;
    logService.error('ERR_TAG', 'Failure occurred', error, stackTrace);
    await logService.dispose();

    final logFile = File('${tempDir.path}/myoffgridai.log');
    final contents = logFile.readAsStringSync();

    expect(contents, contains('[ERROR]'));
    expect(contents, contains('[ERR_TAG]'));
    expect(contents, contains('Failure occurred'));
    expect(contents, contains('Error: Exception: Something broke'));
    expect(contents, contains('StackTrace:'));
  });

  test('rotates files when exceeding 10MB', () async {
    await logService.initializeWithPath(tempDir.path);

    // Write enough data to exceed 10MB
    final largeMessage = 'X' * 10000;
    // 10MB / 10KB per line = ~1000 lines + some extra
    for (var i = 0; i < 1100; i++) {
      logService.info('BULK', largeMessage);
    }
    await logService.dispose();

    // After rotation, the rotated file should exist
    final rotatedFile = File('${tempDir.path}/myoffgridai.log.1');
    expect(rotatedFile.existsSync(), isTrue);

    // The current log file should still exist (new one after rotation)
    final currentFile = File('${tempDir.path}/myoffgridai.log');
    expect(currentFile.existsSync(), isTrue);
  });

  test('limits rotation to 5 files', () async {
    await logService.initializeWithPath(tempDir.path);

    // Write enough data to trigger multiple rotations (need > 50MB total)
    final largeMessage = 'Y' * 10000;
    // Each rotation at 10MB, need 6+ rotations to test the limit
    for (var i = 0; i < 7000; i++) {
      logService.info('BULK', largeMessage);
    }
    await logService.dispose();

    // Files .1 through .5 may exist
    for (var i = 1; i <= 5; i++) {
      // At least some rotated files should exist
      final file = File('${tempDir.path}/myoffgridai.log.$i');
      if (i <= 3) {
        // Should definitely have at least a few rotated files
        expect(file.existsSync(), isTrue,
            reason: 'Expected myoffgridai.log.$i to exist');
      }
    }

    // File .6 should NOT exist (max 5 rotated files)
    final tooMany = File('${tempDir.path}/myoffgridai.log.6');
    expect(tooMany.existsSync(), isFalse,
        reason: 'Should not have more than 5 rotated files');
  });

  test('dispose() flushes and closes sink', () async {
    await logService.initializeWithPath(tempDir.path);

    logService.info('DISPOSE', 'Before dispose');
    await logService.dispose();

    // After dispose, the log content should be flushed to disk
    final logFile = File('${tempDir.path}/myoffgridai.log');
    final contents = logFile.readAsStringSync();
    expect(contents, contains('Before dispose'));

    // Writing after dispose should be a no-op (no crash)
    logService.info('DISPOSE', 'After dispose');
  });

  test('convenience methods map to correct log levels', () async {
    await logService.initializeWithPath(tempDir.path);

    logService.debug('TAG', 'debug message');
    logService.info('TAG', 'info message');
    logService.warn('TAG', 'warn message');
    logService.error('TAG', 'error message');
    await logService.dispose();

    final logFile = File('${tempDir.path}/myoffgridai.log');
    final contents = logFile.readAsStringSync();

    expect(contents, contains('[DEBUG] [TAG] debug message'));
    expect(contents, contains('[INFO] [TAG] info message'));
    expect(contents, contains('[WARN] [TAG] warn message'));
    expect(contents, contains('[ERROR] [TAG] error message'));
  });

  test('singleton instance is accessible after initialize', () async {
    await logService.initializeWithPath(tempDir.path);

    expect(LogService.instance, same(logService));
  });
}
