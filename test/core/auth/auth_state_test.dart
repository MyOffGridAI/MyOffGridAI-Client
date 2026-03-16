import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/auth_service.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/device_registration_service.dart';
import 'package:myoffgridai_client/core/services/foreground_service_manager.dart';
import 'package:myoffgridai_client/core/services/mqtt_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockDeviceRegistrationService extends Mock
    implements DeviceRegistrationService {}

class MockForegroundServiceManager extends Mock
    implements ForegroundServiceManager {}

class MockMqttServiceNotifier extends Mock implements MqttServiceNotifier {}

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

  @override
  Future<void> saveDeviceId(String deviceId) async {}

  @override
  Future<String?> getDeviceId() async => null;
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

/// Helper to create a JWT with a fully custom payload map.
String _createTestJwtCustom(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = base64Url.encode(utf8.encode('test-signature'));
  return '$header.$body.$signature';
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

    test('returns null when JWT payload has invalid base64', () async {
      // 3 parts but the payload is garbage base64
      final storage =
          _FakeSecureStorageService(accessToken: 'header.!!!invalid!!!.sig');
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNull);
      // _decodeJwtPayload returns null, so build returns null without clearing tokens
    });

    test('returns user when token has no exp claim (never expires)', () async {
      final jwt = _createTestJwtCustom({
        'userId': 'u-no-exp',
        'sub': 'noexp',
        'displayName': 'No Exp',
        'role': 'ROLE_MEMBER',
      });
      final storage = _FakeSecureStorageService(accessToken: jwt);
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNotNull);
      expect(user!.id, 'u-no-exp');
      expect(user.username, 'noexp');
    });

    test('uses sub as userId fallback when userId is absent', () async {
      final jwt = _createTestJwtCustom({
        'sub': 'sub-as-id',
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      });
      final storage = _FakeSecureStorageService(accessToken: jwt);
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNotNull);
      expect(user!.id, 'sub-as-id');
      expect(user.username, 'sub-as-id');
      expect(user.displayName, 'sub-as-id'); // falls back to username
      expect(user.role, 'ROLE_MEMBER');
    });

    test('returns null when neither userId nor sub are present', () async {
      final jwt = _createTestJwtCustom({
        'displayName': 'Ghost',
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      });
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

    test('attempts refresh when token is expired and succeeds', () async {
      final mockAuth = MockAuthService();
      final expiredJwt = _createTestJwt(
        userId: 'u1',
        username: 'adam',
        exp: DateTime.now()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );
      final storage = _FakeSecureStorageService(accessToken: expiredJwt);

      const refreshedUser = UserModel(
        id: 'u1',
        username: 'adam',
        displayName: 'Adam Refreshed',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      when(() => mockAuth.refresh()).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          tokenType: 'Bearer',
          expiresIn: 3600,
          user: refreshedUser,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNotNull);
      expect(user!.displayName, 'Adam Refreshed');
      verify(() => mockAuth.refresh()).called(1);
    });
  });

  group('AuthNotifier.login()', () {
    test('sets state to AsyncData with user on success', () async {
      final mockAuth = MockAuthService();
      final mockDeviceReg = MockDeviceRegistrationService();
      final mockForeground = MockForegroundServiceManager();
      final mockMqtt = MockMqttServiceNotifier();
      final storage = _FakeSecureStorageService();

      const user = UserModel(
        id: 'u1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      when(() => mockAuth.login('adam', 'pass')).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          tokenType: 'Bearer',
          expiresIn: 3600,
          user: user,
        ),
      );

      when(() => mockDeviceReg.registerDevice()).thenAnswer((_) async {});
      when(() => mockForeground.startService()).thenAnswer((_) async {});
      when(() => mockMqtt.connect(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          deviceRegistrationServiceProvider
              .overrideWithValue(mockDeviceReg),
          foregroundServiceManagerProvider
              .overrideWithValue(mockForeground),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
        ],
      );
      addTearDown(container.dispose);

      // Wait for build() to complete (returns null — no token stored)
      await container.read(authStateProvider.future);

      // Perform login
      await container.read(authStateProvider.notifier).login('adam', 'pass');

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNotNull);
      expect(state.value!.id, 'u1');
      expect(state.value!.username, 'adam');
    });

    test('sets state to AsyncError on login failure', () async {
      final mockAuth = MockAuthService();
      final storage = _FakeSecureStorageService();

      when(() => mockAuth.login('adam', 'wrong'))
          .thenThrow(Exception('Invalid credentials'));

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).login('adam', 'wrong');

      final state = container.read(authStateProvider);
      expect(state.hasError, isTrue);
    });
  });

  group('AuthNotifier.register()', () {
    test('sets state to AsyncData with user on success', () async {
      final mockAuth = MockAuthService();
      final mockDeviceReg = MockDeviceRegistrationService();
      final mockForeground = MockForegroundServiceManager();
      final mockMqtt = MockMqttServiceNotifier();
      final storage = _FakeSecureStorageService();

      const user = UserModel(
        id: 'u2',
        username: 'newuser',
        displayName: 'New User',
        role: 'ROLE_MEMBER',
        isActive: true,
      );

      when(() => mockAuth.register(
            username: 'newuser',
            displayName: 'New User',
            password: 'pass',
            email: 'new@user.com',
          )).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          tokenType: 'Bearer',
          expiresIn: 3600,
          user: user,
        ),
      );

      when(() => mockDeviceReg.registerDevice()).thenAnswer((_) async {});
      when(() => mockForeground.startService()).thenAnswer((_) async {});
      when(() => mockMqtt.connect(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          deviceRegistrationServiceProvider
              .overrideWithValue(mockDeviceReg),
          foregroundServiceManagerProvider
              .overrideWithValue(mockForeground),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).register(
            username: 'newuser',
            displayName: 'New User',
            password: 'pass',
            email: 'new@user.com',
          );

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.id, 'u2');
    });

    test('sets state to AsyncError on registration failure', () async {
      final mockAuth = MockAuthService();
      final storage = _FakeSecureStorageService();

      when(() => mockAuth.register(
            username: 'existing',
            displayName: 'User',
            password: 'pass',
          )).thenThrow(Exception('Username taken'));

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).register(
            username: 'existing',
            displayName: 'User',
            password: 'pass',
          );

      final state = container.read(authStateProvider);
      expect(state.hasError, isTrue);
    });
  });

  group('AuthNotifier.logout()', () {
    test('calls authService.logout() and sets state to null', () async {
      final mockAuth = MockAuthService();
      final mockMqtt = MockMqttServiceNotifier();
      final mockForeground = MockForegroundServiceManager();
      final storage = _FakeSecureStorageService();

      when(() => mockAuth.logout()).thenAnswer((_) async {});
      when(() => mockMqtt.disconnect()).thenReturn(null);
      when(() => mockForeground.stopService()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
          foregroundServiceManagerProvider
              .overrideWithValue(mockForeground),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNull);
      verify(() => mockAuth.logout()).called(1);
    });
  });

  group('AuthNotifier.build() catch block', () {
    test('clears tokens and returns null when exp cast throws', () async {
      // Create a valid JWT where 'exp' is a non-int type that causes
      // 'as int?' cast to fail at runtime, triggering the outer catch on line 61-62.
      final jwt = _createTestJwtCustom({
        'sub': 'user1',
        'userId': 'u1',
        'exp': 'not-an-int', // This will cause a TypeError on `as int?`
      });
      final storage = _FakeSecureStorageService(accessToken: jwt);
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authStateProvider.future);
      expect(user, isNull);
      // Tokens should have been cleared (line 62)
      expect(await storage.getAccessToken(), isNull);
    });
  });

  group('AuthNotifier._startNotificationServices() catch blocks', () {
    test('login succeeds even when device registration throws', () async {
      final mockAuth = MockAuthService();
      final mockDeviceReg = MockDeviceRegistrationService();
      final mockForeground = MockForegroundServiceManager();
      final mockMqtt = MockMqttServiceNotifier();
      final storage = _FakeSecureStorageService();

      const user = UserModel(
        id: 'u1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      when(() => mockAuth.login('adam', 'pass')).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          tokenType: 'Bearer',
          expiresIn: 3600,
          user: user,
        ),
      );

      // Device registration throws — exercising line 125
      when(() => mockDeviceReg.registerDevice())
          .thenThrow(Exception('Device reg failed'));
      when(() => mockForeground.startService()).thenAnswer((_) async {});
      when(() => mockMqtt.connect(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          deviceRegistrationServiceProvider.overrideWithValue(mockDeviceReg),
          foregroundServiceManagerProvider.overrideWithValue(mockForeground),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).login('adam', 'pass');

      // Login should still succeed despite device registration failure
      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.id, 'u1');

      // Allow microtask to complete
      await Future<void>.delayed(Duration.zero);
    });

    test('login succeeds even when foreground service throws', () async {
      final mockAuth = MockAuthService();
      final mockDeviceReg = MockDeviceRegistrationService();
      final mockForeground = MockForegroundServiceManager();
      final mockMqtt = MockMqttServiceNotifier();
      final storage = _FakeSecureStorageService();

      const user = UserModel(
        id: 'u1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      when(() => mockAuth.login('adam', 'pass')).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          tokenType: 'Bearer',
          expiresIn: 3600,
          user: user,
        ),
      );

      when(() => mockDeviceReg.registerDevice()).thenAnswer((_) async {});
      // Foreground service throws — exercising line 130
      when(() => mockForeground.startService())
          .thenThrow(Exception('Foreground start failed'));
      when(() => mockMqtt.connect(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          deviceRegistrationServiceProvider.overrideWithValue(mockDeviceReg),
          foregroundServiceManagerProvider.overrideWithValue(mockForeground),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).login('adam', 'pass');

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.id, 'u1');

      await Future<void>.delayed(Duration.zero);
    });

    test('login succeeds even when MQTT connect throws', () async {
      final mockAuth = MockAuthService();
      final mockDeviceReg = MockDeviceRegistrationService();
      final mockForeground = MockForegroundServiceManager();
      final mockMqtt = MockMqttServiceNotifier();
      final storage = _FakeSecureStorageService();

      const user = UserModel(
        id: 'u1',
        username: 'adam',
        displayName: 'Adam',
        role: 'ROLE_OWNER',
        isActive: true,
      );

      when(() => mockAuth.login('adam', 'pass')).thenAnswer(
        (_) async => const AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          tokenType: 'Bearer',
          expiresIn: 3600,
          user: user,
        ),
      );

      when(() => mockDeviceReg.registerDevice()).thenAnswer((_) async {});
      when(() => mockForeground.startService()).thenAnswer((_) async {});
      // MQTT connect throws — exercising line 137
      when(() => mockMqtt.connect(any()))
          .thenThrow(Exception('MQTT connect failed'));

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          deviceRegistrationServiceProvider.overrideWithValue(mockDeviceReg),
          foregroundServiceManagerProvider.overrideWithValue(mockForeground),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).login('adam', 'pass');

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.id, 'u1');

      await Future<void>.delayed(Duration.zero);
    });
  });

  group('AuthNotifier._stopNotificationServices() catch blocks', () {
    test('logout succeeds even when MQTT disconnect throws', () async {
      final mockAuth = MockAuthService();
      final mockMqtt = MockMqttServiceNotifier();
      final mockForeground = MockForegroundServiceManager();
      final storage = _FakeSecureStorageService();

      when(() => mockAuth.logout()).thenAnswer((_) async {});
      // MQTT disconnect throws — exercising line 150
      when(() => mockMqtt.disconnect()).thenThrow(Exception('MQTT disconnect failed'));
      when(() => mockForeground.stopService()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
          foregroundServiceManagerProvider.overrideWithValue(mockForeground),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNull);
    });

    test('logout succeeds even when foreground service stop throws', () async {
      final mockAuth = MockAuthService();
      final mockMqtt = MockMqttServiceNotifier();
      final mockForeground = MockForegroundServiceManager();
      final storage = _FakeSecureStorageService();

      when(() => mockAuth.logout()).thenAnswer((_) async {});
      when(() => mockMqtt.disconnect()).thenReturn(null);
      // Foreground stop throws — exercising line 157
      when(() => mockForeground.stopService())
          .thenThrow(Exception('Foreground stop failed'));

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(mockAuth),
          mqttServiceProvider.overrideWith((_) => mockMqtt),
          foregroundServiceManagerProvider.overrideWithValue(mockForeground),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNull);
    });
  });

  group('AuthResponse', () {
    test('fromJson parses all fields', () {
      final json = {
        'accessToken': 'access-123',
        'refreshToken': 'refresh-456',
        'tokenType': 'Bearer',
        'expiresIn': 7200,
        'user': {
          'id': 'u1',
          'username': 'adam',
          'displayName': 'Adam',
          'role': 'ROLE_OWNER',
          'isActive': true,
        },
      };

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'access-123');
      expect(response.refreshToken, 'refresh-456');
      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 7200);
      expect(response.user.id, 'u1');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'accessToken': 'a',
        'refreshToken': 'r',
        'user': {
          'id': 'u1',
          'username': 'test',
        },
      };

      final response = AuthResponse.fromJson(json);

      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 0);
    });
  });
}
