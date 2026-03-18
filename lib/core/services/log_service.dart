import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Log severity levels ordered from least to most severe.
enum LogLevel {
  /// Fine-grained diagnostic information.
  debug,

  /// General operational information.
  info,

  /// Potentially harmful situations.
  warn,

  /// Error events that might still allow the app to continue.
  error,
}

/// Centralized file-based logging service.
///
/// Writes structured log lines to a rotating log file in the app's
/// documents directory. No console output.
///
/// Log format: `2026-03-18T14:30:00.123 [INFO] [SSE] message text`
///
/// File rotation: when the current log file exceeds [_maxFileSize] (10 MB),
/// it is rotated. Up to [_maxFiles] (5) rotated files are kept.
class LogService {
  static LogService? _instance;
  static final LogService _noop = LogService();

  /// Returns the initialized [LogService] singleton.
  ///
  /// If [initialize] has not been called, returns a no-op instance that
  /// silently discards all log calls.
  static LogService get instance => _instance ?? _noop;

  RandomAccessFile? _raf;
  File? _logFile;
  int _bytesWritten = 0;
  bool _isRotating = false;

  /// Maximum size of a single log file before rotation (10 MB).
  static const int _maxFileSize = 10 * 1024 * 1024;

  /// Maximum number of rotated log files to retain.
  static const int _maxFiles = 5;

  /// Base name for the log file.
  static const String _logFileName = 'myoffgridai.log';

  /// Initializes the log service by opening the log file in append mode.
  ///
  /// Must be called once before any logging. Sets the singleton [_instance].
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _openLogFile('${dir.path}/$_logFileName');
    _instance = this;
  }

  /// Initializes the log service with a specific directory path.
  ///
  /// Used for testing to avoid depending on [getApplicationDocumentsDirectory].
  Future<void> initializeWithPath(String dirPath) async {
    _openLogFile('$dirPath/$_logFileName');
    _instance = this;
  }

  /// Writes a log line at the given [level] with a [tag] and [message].
  ///
  /// Optionally accepts an [error] object and [stackTrace] for error-level
  /// entries. Checks file size after each write and rotates if necessary.
  void log(LogLevel level, String tag, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (_raf == null) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final buffer = StringBuffer('$timestamp [$levelName] [$tag] $message');

    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  StackTrace: $stackTrace');
    }

    final line = '${buffer.toString()}\n';
    _raf!.writeStringSync(line);
    _bytesWritten += line.length;

    _checkRotation();
  }

  /// Logs a message at [LogLevel.debug].
  void debug(String tag, String message) => log(LogLevel.debug, tag, message);

  /// Logs a message at [LogLevel.info].
  void info(String tag, String message) => log(LogLevel.info, tag, message);

  /// Logs a message at [LogLevel.warn].
  void warn(String tag, String message) => log(LogLevel.warn, tag, message);

  /// Logs a message at [LogLevel.error], with optional [error] and [stackTrace].
  void error(String tag, String message, [Object? error, StackTrace? stackTrace]) =>
      log(LogLevel.error, tag, message, error, stackTrace);

  /// Flushes pending writes and closes the underlying file handle.
  Future<void> dispose() async {
    _raf?.flushSync();
    _raf?.closeSync();
    _raf = null;
    _instance = null;
  }

  void _openLogFile(String path) {
    _logFile = File(path);

    if (!_logFile!.existsSync()) {
      _logFile!.createSync(recursive: true);
    }

    _raf = _logFile!.openSync(mode: FileMode.append);
    _bytesWritten = _logFile!.lengthSync();
  }

  /// Checks if tracked bytes exceed [_maxFileSize] and rotates if so.
  void _checkRotation() {
    if (_isRotating || _logFile == null) return;
    if (_bytesWritten < _maxFileSize) return;

    _rotate();
  }

  /// Rotates log files: deletes the oldest, shifts others up by one index,
  /// and opens a fresh log file.
  void _rotate() {
    _isRotating = true;

    _raf?.flushSync();
    _raf?.closeSync();
    _raf = null;

    final dir = _logFile!.parent.path;
    final baseName = _logFileName;

    // Delete the oldest file if it exists
    final oldest = File('$dir/$baseName.$_maxFiles');
    if (oldest.existsSync()) {
      oldest.deleteSync();
    }

    // Shift files: .4 → .5, .3 → .4, etc.
    for (var i = _maxFiles - 1; i >= 1; i--) {
      final source = File('$dir/$baseName.$i');
      if (source.existsSync()) {
        source.renameSync('$dir/$baseName.${i + 1}');
      }
    }

    // Current file becomes .1
    if (_logFile!.existsSync()) {
      _logFile!.renameSync('$dir/$baseName.1');
    }

    // Create fresh log file
    _logFile = File('$dir/$baseName');
    _logFile!.createSync();
    _raf = _logFile!.openSync(mode: FileMode.append);
    _bytesWritten = 0;

    _isRotating = false;
  }
}

/// Riverpod provider for [LogService].
final logServiceProvider = Provider<LogService>((ref) {
  throw UnimplementedError(
    'logServiceProvider must be overridden at startup after initialization',
  );
});
