import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around [FlutterSecureStorage] for secure token and preference storage.
///
/// Provides typed access to JWT tokens, server URL, and theme preference
/// with platform-appropriate encryption options. Maintains an in-memory cache
/// so values remain available even when the underlying platform storage
/// (e.g. Web Crypto API on Chrome) fails to read back stored data.
class SecureStorageService {
  final FlutterSecureStorage _storage;
  final SharedPreferencesAsync _prefs;

  /// In-memory cache keyed by storage key. Ensures tokens survive within a
  /// session even if [FlutterSecureStorage] read operations fail on web.
  final Map<String, String> _cache = {};

  /// Creates a [SecureStorageService] with the given [FlutterSecureStorage] instance.
  ///
  /// Non-sensitive preferences (Remember Me, remembered username, biometric
  /// enabled) are stored via [SharedPreferences] (NSUserDefaults on macOS)
  /// for reliable cross-launch persistence. Actual secrets (tokens, deviceId)
  /// remain in [FlutterSecureStorage] (Keychain).
  SecureStorageService({FlutterSecureStorage? storage, SharedPreferencesAsync? prefs})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            ),
        _prefs = prefs ?? SharedPreferencesAsync();

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

  /// Saves the remembered username to [SharedPreferences].
  Future<void> saveRememberedUsername(String username) async {
    await _prefs.setString(AppConstants.rememberedUsernameKey, username);
  }

  /// Returns the stored remembered username, or null if not set.
  Future<String?> getRememberedUsername() async {
    return _prefs.getString(AppConstants.rememberedUsernameKey);
  }

  /// Clears the remembered username from [SharedPreferences].
  Future<void> clearRememberedUsername() async {
    await _prefs.remove(AppConstants.rememberedUsernameKey);
  }

  /// Saves the Remember Me preference to [SharedPreferences].
  Future<void> saveRememberMe(bool enabled) async {
    await _prefs.setBool(AppConstants.rememberMeKey, enabled);
  }

  /// Returns the stored Remember Me preference, defaulting to false.
  Future<bool> getRememberMe() async {
    return await _prefs.getBool(AppConstants.rememberMeKey) ?? false;
  }

  /// Saves the biometric enabled preference to [SharedPreferences].
  Future<void> saveBiometricEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.biometricEnabledKey, enabled);
  }

  /// Returns the stored biometric enabled preference, defaulting to false.
  Future<bool> getBiometricEnabled() async {
    return await _prefs.getBool(AppConstants.biometricEnabledKey) ?? false;
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
