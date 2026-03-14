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

  /// Returns the stored access token, or null if not set.
  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  /// Returns the stored refresh token, or null if not set.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  /// Clears both access and refresh tokens from secure storage.
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  /// Saves the server URL to secure storage.
  Future<void> saveServerUrl(String url) async {
    await _storage.write(key: AppConstants.serverUrlKey, value: url);
  }

  /// Returns the stored server URL, or [AppConstants.defaultServerUrl] if not set.
  Future<String> getServerUrl() async {
    final url = await _storage.read(key: AppConstants.serverUrlKey);
    return url ?? AppConstants.defaultServerUrl;
  }

  /// Saves the theme preference ('light', 'dark', or 'system').
  Future<void> saveThemePreference(String theme) async {
    await _storage.write(key: AppConstants.themeKey, value: theme);
  }

  /// Returns the stored theme preference, defaulting to 'system'.
  Future<String> getThemePreference() async {
    final theme = await _storage.read(key: AppConstants.themeKey);
    return theme ?? 'system';
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
