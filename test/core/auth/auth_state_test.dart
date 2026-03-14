import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

class _FakeSecureStorageService extends SecureStorageService {
  String? _accessToken;
  String? _refreshToken;

  _FakeSecureStorageService({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken,
        super(storage: null);

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<void> saveServerUrl(String url) async {}

  @override
  Future<String> getServerUrl() async => AppConstants.defaultServerUrl;

  @override
  Future<void> saveThemePreference(String theme) async {}

  @override
  Future<String> getThemePreference() async => 'system';
}

String _createTestJwt({
  required String userId,
  required String username,
  String role = 'ROLE_MEMBER',
  int? exp,
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode(jsonEncode({
    'sub': username,
    'userId': userId,
    'displayName': username,
    'role': role,
    'exp': exp ?? (DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000),
  })));
  final signature = base64Url.encode(utf8.encode('test-signature'));
  return '$header.$payload.$signature';
}

void main() {
  group('AuthState', () {
    test('unauthenticated state on no stored tokens', () async {
      final storage = _FakeSecureStorageService();
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the async notifier to build
      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.valueOrNull, isNull);
    });

    test('authenticated state with valid stored token', () async {
      final jwt = _createTestJwt(
        userId: 'test-id-123',
        username: 'testuser',
        role: 'ROLE_MEMBER',
      );
      final storage = _FakeSecureStorageService(accessToken: jwt);
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNotNull);
      expect(user!.username, 'testuser');
      expect(user.role, 'ROLE_MEMBER');
    });

    test('unauthenticated with expired token and no refresh available',
        () async {
      final jwt = _createTestJwt(
        userId: 'test-id-123',
        username: 'testuser',
        exp: DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch ~/
            1000,
      );
      final storage = _FakeSecureStorageService(accessToken: jwt);
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNull);
    });

    test('unauthenticated with invalid token format', () async {
      final storage = _FakeSecureStorageService(accessToken: 'not-a-jwt');
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNull);
    });
  });
}
