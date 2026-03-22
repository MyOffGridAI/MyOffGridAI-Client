import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/services/log_service.dart';
import 'package:window_manager/window_manager.dart';

/// Service that persists and restores the application window's position and size.
///
/// Listens for window move/resize events via [WindowListener], debounces saves
/// (500 ms) to avoid hammering storage during drag operations, and restores
/// the saved geometry on startup before the window is shown.
///
/// All methods are no-ops on platforms other than macOS (and on web).
class WindowService with WindowListener {
  static const String _tag = 'WindowService';

  static const double _defaultWidth = 800;
  static const double _defaultHeight = 600;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Returns `true` when this service can operate (macOS desktop only).
  static bool get isSupported => !kIsWeb && Platform.isMacOS;

  final SecureStorageService _storage;
  final LogService _log;
  Timer? _debounceTimer;

  /// Creates a [WindowService].
  ///
  /// Requires a [SecureStorageService] for persistence and a [LogService]
  /// for structured logging.
  WindowService({
    required SecureStorageService storage,
    required LogService log,
  })  : _storage = storage,
        _log = log;

  /// Initializes the window manager, restores saved geometry, and begins
  /// listening for move/resize events.
  ///
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized] and
  /// before [runApp]. Does nothing when [isSupported] is false.
  Future<void> initialize() async {
    if (!isSupported) return;

    await windowManager.ensureInitialized();

    final x = await _readDouble(AppConstants.windowXKey);
    final y = await _readDouble(AppConstants.windowYKey);
    final width = await _readDouble(AppConstants.windowWidthKey) ?? _defaultWidth;
    final height = await _readDouble(AppConstants.windowHeightKey) ?? _defaultHeight;

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
  void onWindowClose() {
    _debounceTimer?.cancel();
    _saveGeometry();
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Debounces geometry saves so rapid drag/resize events don't flood storage.
  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _saveGeometry);
  }

  /// Reads the current window bounds and persists them to secure storage.
  Future<void> _saveGeometry() async {
    try {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();

      await Future.wait([
        _storage.writeValue(AppConstants.windowXKey, position.dx.toString()),
        _storage.writeValue(AppConstants.windowYKey, position.dy.toString()),
        _storage.writeValue(AppConstants.windowWidthKey, size.width.toString()),
        _storage.writeValue(AppConstants.windowHeightKey, size.height.toString()),
      ]);

      _log.debug(_tag, 'Saved geometry: ${size.width}x${size.height} at (${position.dx}, ${position.dy})');
    } catch (e, st) {
      _log.error(_tag, 'Failed to save geometry', e, st);
    }
  }

  /// Reads a double value from secure storage by [key], returning `null`
  /// if the key is absent or the stored value is not a valid double.
  Future<double?> _readDouble(String key) async {
    final raw = await _storage.readValue(key);
    if (raw == null) return null;
    return double.tryParse(raw);
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
