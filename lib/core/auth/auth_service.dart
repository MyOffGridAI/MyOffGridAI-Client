import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';

/// Response from authentication endpoints (login, register, refresh).
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 0,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Handles all authentication operations against the MyOffGridAI server.
///
/// Manages login, registration, logout, and token refresh, persisting
/// tokens via [SecureStorageService].
class AuthService {
  final MyOffGridAIApiClient _client;
  final SecureStorageService _storage;

  /// Creates an [AuthService] with the given API [client] and [storage].
  AuthService({
    required MyOffGridAIApiClient client,
    required SecureStorageService storage,
  })  : _client = client,
        _storage = storage;

  /// Logs in with [username] and [password]. Returns [AuthResponse] on success.
  Future<AuthResponse> login(String username, String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.authBasePath}/login',
      data: {'username': username, 'password': password},
    );
    final data = response['data'] as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(data);
    await _storage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  }

  /// Registers a new user account. Returns [AuthResponse] on success.
  Future<AuthResponse> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
    String role = 'ROLE_MEMBER',
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'displayName': displayName,
      'password': password,
      'role': role,
    };
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.authBasePath}/register',
      data: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(data);
    await _storage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  }

  /// Logs out the current user by clearing local tokens and calling the server.
  ///
  /// When [preserveRefreshToken] is true, only the access token is cleared
  /// so the refresh token remains available for biometric re-login.
  Future<void> logout({bool preserveRefreshToken = false}) async {
    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        await _client.post<dynamic>(
          '${AppConstants.authBasePath}/logout',
          data: {},
        );
      }
    } catch (_) {
      // Server logout is best-effort; always clear local tokens
    }
    if (preserveRefreshToken) {
      await _storage.clearAccessToken();
    } else {
      await _storage.clearTokens();
    }
  }

  /// Refreshes the access token using the stored refresh token.
  Future<AuthResponse> refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'No refresh token available',
      );
    }
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.authBasePath}/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response['data'] as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(data);
    await _storage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    return authResponse;
  }

  /// Retrieves the current user's profile from the server.
  Future<UserModel> getCurrentUser(String userId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.usersBasePath}/$userId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}

/// Riverpod provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthService(client: client, storage: storage);
});
