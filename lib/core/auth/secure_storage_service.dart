import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myoffgridai_client/config/constants.dart';

/// Wrapper around [FlutterSecureStorage] for secure token and preference storage.
///
/// Provides typed access to JWT tokens, server URL, and theme preference
/// with platform-appropriate encryption options.
class SecureStorageService {
  final FlutterSecureStorage _storage;

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
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Returns the stored access token, or null if not set or on read failure.
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Returns the stored refresh token, or null if not set or on read failure.
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Clears both access and refresh tokens from secure storage.
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.accessTokenKey),
        _storage.delete(key: AppConstants.refreshTokenKey),
      ]);
    } catch (_) {
      // Storage may be unavailable — tokens are effectively cleared
    }
  }

  /// Saves the server URL to secure storage.
  Future<void> saveServerUrl(String url) async {
    try {
      await _storage.write(key: AppConstants.serverUrlKey, value: url);
    } catch (_) {
      // Best-effort persist — URL is already held in memory by caller
    }
  }

  /// Returns the stored server URL, or [AppConstants.defaultServerUrl] if not set.
  Future<String> getServerUrl() async {
    try {
      final url = await _storage.read(key: AppConstants.serverUrlKey);
      return url ?? AppConstants.defaultServerUrl;
    } catch (_) {
      return AppConstants.defaultServerUrl;
    }
  }

  /// Saves the theme preference ('light', 'dark', or 'system').
  Future<void> saveThemePreference(String theme) async {
    try {
      await _storage.write(key: AppConstants.themeKey, value: theme);
    } catch (_) {
      // Best-effort persist
    }
  }

  /// Returns the stored theme preference, defaulting to 'system'.
  Future<String> getThemePreference() async {
    try {
      final theme = await _storage.read(key: AppConstants.themeKey);
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
