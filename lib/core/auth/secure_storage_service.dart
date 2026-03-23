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

  /// Saves the remembered username to secure storage.
  Future<void> saveRememberedUsername(String username) async {
    _cache[AppConstants.rememberedUsernameKey] = username;
    try {
      await _storage.write(
          key: AppConstants.rememberedUsernameKey, value: username);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Returns the stored remembered username, or null if not set.
  Future<String?> getRememberedUsername() async {
    final cached = _cache[AppConstants.rememberedUsernameKey];
    if (cached != null) return cached;
    try {
      final value =
          await _storage.read(key: AppConstants.rememberedUsernameKey);
      if (value != null) _cache[AppConstants.rememberedUsernameKey] = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Clears the remembered username from secure storage.
  Future<void> clearRememberedUsername() async {
    _cache.remove(AppConstants.rememberedUsernameKey);
    try {
      await _storage.delete(key: AppConstants.rememberedUsernameKey);
    } catch (_) {
      // Cache is already cleared — persistent delete is best-effort
    }
  }

  /// Saves the Remember Me preference ('true' or 'false').
  Future<void> saveRememberMe(bool enabled) async {
    final value = enabled.toString();
    _cache[AppConstants.rememberMeKey] = value;
    try {
      await _storage.write(key: AppConstants.rememberMeKey, value: value);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Returns the stored Remember Me preference, defaulting to false.
  Future<bool> getRememberMe() async {
    final cached = _cache[AppConstants.rememberMeKey];
    if (cached != null) return cached == 'true';
    try {
      final value = await _storage.read(key: AppConstants.rememberMeKey);
      if (value != null) _cache[AppConstants.rememberMeKey] = value;
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Saves the biometric enabled preference ('true' or 'false').
  Future<void> saveBiometricEnabled(bool enabled) async {
    final value = enabled.toString();
    _cache[AppConstants.biometricEnabledKey] = value;
    try {
      await _storage.write(key: AppConstants.biometricEnabledKey, value: value);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Returns the stored biometric enabled preference, defaulting to false.
  Future<bool> getBiometricEnabled() async {
    final cached = _cache[AppConstants.biometricEnabledKey];
    if (cached != null) return cached == 'true';
    try {
      final value = await _storage.read(key: AppConstants.biometricEnabledKey);
      if (value != null) _cache[AppConstants.biometricEnabledKey] = value;
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Clears only the access token, preserving the refresh token for biometric re-login.
  Future<void> clearAccessToken() async {
    _cache.remove(AppConstants.accessTokenKey);
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
    } catch (_) {
      // Cache is already cleared — persistent delete is best-effort
    }
  }

  /// Writes an arbitrary [value] to secure storage under [key].
  ///
  /// The value is cached in memory and persisted on a best-effort basis.
  Future<void> writeValue(String key, String value) async {
    _cache[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Cached in memory — persistent write is best-effort
    }
  }

  /// Reads an arbitrary value from secure storage by [key].
  ///
  /// Returns the cached value if available, otherwise reads from persistent
  /// storage. Returns `null` if the key has never been written.
  Future<String?> readValue(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final value = await _storage.read(key: key);
      if (value != null) _cache[key] = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Deletes an arbitrary value from secure storage by [key].
  ///
  /// Clears both the in-memory cache and persistent storage on a best-effort basis.
  Future<void> deleteValue(String key) async {
    _cache.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Cache is already cleared — persistent delete is best-effort
    }
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
