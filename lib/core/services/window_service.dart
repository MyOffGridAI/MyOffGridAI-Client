import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Service that persists and restores the application window's position and size.
///
/// Listens for window move/resize events via [WindowListener], debounces saves
/// (500 ms) to avoid hammering storage during drag operations, and restores
/// the saved geometry on startup before the window is shown.
///
/// Uses [SharedPreferences] (NSUserDefaults on macOS) for reliable persistence.
/// Window geometry is not sensitive data and does not need Keychain encryption.
///
/// All methods are no-ops on platforms other than macOS (and on web).
class WindowService with WindowListener {
  static const String _tag = 'WindowService';

  static const double _defaultWidth = 800;
  static const double _defaultHeight = 600;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Returns `true` when this service can operate (macOS desktop only).
  static bool get isSupported => !kIsWeb && Platform.isMacOS;

  final LogService _log;
  final SharedPreferences _prefs;
  Timer? _debounceTimer;

  /// Creates a [WindowService].
  ///
  /// Requires a [SharedPreferences] instance for persistence and a [LogService]
  /// for structured logging.
  WindowService({
    required SharedPreferences prefs,
    required LogService log,
  })  : _prefs = prefs,
        _log = log;

  /// Initializes the window manager, restores saved geometry, and begins
  /// listening for move/resize events.
  ///
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized] and
  /// before [runApp]. Does nothing when [isSupported] is false.
  Future<void> initialize() async {
    if (!isSupported) return;

    await windowManager.ensureInitialized();

    final x = _prefs.getDouble(AppConstants.windowXKey);
    final y = _prefs.getDouble(AppConstants.windowYKey);
    final width = _prefs.getDouble(AppConstants.windowWidthKey) ?? _defaultWidth;
    final height = _prefs.getDouble(AppConstants.windowHeightKey) ?? _defaultHeight;

    final hasPosition = x != null && y != null;

    final windowOptions = WindowOptions(
      size: Size(width, height),
      center: !hasPosition,
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (hasPosition) {
        await windowManager.setPosition(Offset(x!, y!));
      }
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });

    windowManager.addListener(this);
    _log.info(_tag, 'Initialized — restored ${hasPosition ? 'saved' : 'default'} geometry');
  }

  /// Cancels the debounce timer and removes the window listener.
  void dispose() {
    _debounceTimer?.cancel();
    if (isSupported) {
      windowManager.removeListener(this);
    }
  }

  // ── WindowListener overrides ──────────────────────────────────────────

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowClose() async {
    _debounceTimer?.cancel();
    await _saveGeometry();
    await windowManager.destroy();
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Debounces geometry saves so rapid drag/resize events don't flood storage.
  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _saveGeometry);
  }

  /// Reads the current window bounds and persists them to shared preferences.
  Future<void> _saveGeometry() async {
    try {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();

      await Future.wait([
        _prefs.setDouble(AppConstants.windowXKey, position.dx),
        _prefs.setDouble(AppConstants.windowYKey, position.dy),
        _prefs.setDouble(AppConstants.windowWidthKey, size.width),
        _prefs.setDouble(AppConstants.windowHeightKey, size.height),
      ]);

      _log.debug(_tag, 'Saved geometry: ${size.width}x${size.height} at (${position.dx}, ${position.dy})');
    } catch (e, st) {
      _log.error(_tag, 'Failed to save geometry', e, st);
    }
  }
}

/// Riverpod provider for [WindowService].
///
/// Must be overridden at startup after initialization on supported platforms.
final windowServiceProvider = Provider<WindowService>((ref) {
  throw UnimplementedError(
    'windowServiceProvider must be overridden at startup after initialization',
  );
});
