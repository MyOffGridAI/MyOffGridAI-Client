import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myoffgridai_client/config/constants.dart';

/// Wrapper around [FlutterSecureStorage] for secure token and preference storage.
///
/// Provides typed access to JWT tokens, server URL, and theme preference
/// with platform-appropriate encryption options. Maintains an in-memory cache
/// so values remain available even when the underlying platform storage
/// (e.g. Web Crypto API on Chrome) fails to read back stored data.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  /// In-memory cache keyed by storage key. Ensures tokens survive within a
  /// session even if [FlutterSecureStorage] read operations fail on web.
  final Map<String, String> _cache = {};

  /// Creates a [SecureStorageService] with the given [FlutterSecureStorage] instance.
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  /// Saves both [accessToken] and [refreshToken] to secure storage.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cache[AppConstants.accessTokenKey] = accessToken;
    _cache[AppConstants.refreshTokenKey] = refreshToken;
    try {
      await Future.wait([
        _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
        _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
      ]);
    } catch (_) {
      // Tokens are cached in memory — persistent write is best-effort
    }
  }

  /// Returns the stored access token, or null if not set.
  Future<String?> getAccessToken() async {
    final cached = _cache[AppConstants.accessTokenKey];
    if (cached != null) return cached;
    try {
      final value = await _storage.read(key: AppConstants.accessTokenKey);
      if (value != null) _cache[AppConstants.accessTokenKey] = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Returns the stored refresh token, or null if not set.
  Future<String?> getRefreshToken() async {
    final cached = _cache[AppConstants.refreshTokenKey];
    if (cached != null) return cached;
    try {
      final value = await _storage.read(key: AppConstants.refreshTokenKey);
      if (value != null) _cache[AppConstants.refreshTokenKey] = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Clears both access and refresh tokens from secure storage.
  Future<void> clearTokens() async {
    _cache.remove(AppConstants.accessTokenKey);
    _cache.remove(AppConstants.refreshTokenKey);
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.accessTokenKey),
        _storage.delete(key: AppConstants.refreshTokenKey),
      ]);
    } catch (_) {
      // Cache is already cleared — persistent delete is best-effort
    }
  }

  /// Saves the server URL to secure storage.
  Future<void> saveServerUrl(String url) async {
    _cache[AppConstants.serverUrlKey] = url;
    try {
      await _storage.write(key: AppConstants.serverUrlKey, value: url);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Returns the stored server URL, or [AppConstants.defaultServerUrl] if not set.
  Future<String> getServerUrl() async {
    final cached = _cache[AppConstants.serverUrlKey];
    if (cached != null) return cached;
    try {
      final url = await _storage.read(key: AppConstants.serverUrlKey);
      if (url != null) _cache[AppConstants.serverUrlKey] = url;
      return url ?? AppConstants.defaultServerUrl;
    } catch (_) {
      return AppConstants.defaultServerUrl;
    }
  }

  /// Saves the theme preference ('light', 'dark', or 'system').
  Future<void> saveThemePreference(String theme) async {
    _cache[AppConstants.themeKey] = theme;
    try {
      await _storage.write(key: AppConstants.themeKey, value: theme);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Saves the device ID to secure storage.
  Future<void> saveDeviceId(String deviceId) async {
    _cache[AppConstants.deviceIdKey] = deviceId;
    try {
      await _storage.write(key: AppConstants.deviceIdKey, value: deviceId);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Returns the stored device ID, or null if not set.
  Future<String?> getDeviceId() async {
    final cached = _cache[AppConstants.deviceIdKey];
    if (cached != null) return cached;
    try {
      final value = await _storage.read(key: AppConstants.deviceIdKey);
      if (value != null) _cache[AppConstants.deviceIdKey] = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Returns the stored theme preference, defaulting to 'system'.
  Future<String> getThemePreference() async {
    final cached = _cache[AppConstants.themeKey];
    if (cached != null) return cached;
    try {
      final theme = await _storage.read(key: AppConstants.themeKey);
      if (theme != null) _cache[AppConstants.themeKey] = theme;
      return theme ?? 'system';
    } catch (_) {
      return 'system';
    }
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
