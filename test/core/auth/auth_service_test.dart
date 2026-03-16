import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/auth_service.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late MockApiClient mockClient;
  late MockSecureStorage mockStorage;
  late AuthService service;

  setUp(() {
    mockClient = MockApiClient();
    mockStorage = MockSecureStorage();
    service = AuthService(client: mockClient, storage: mockStorage);
  });

  /// Convenience: the standard auth data returned by login/register/refresh.
  Map<String, dynamic> authResponseData({
    String accessToken = 'access-tok-123',
    String refreshToken = 'refresh-tok-456',
    String tokenType = 'Bearer',
    int expiresIn = 3600,
  }) {
    return {
      'data': {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresIn': expiresIn,
        'user': {
          'id': 'u1',
          'username': 'adam',
          'displayName': 'Adam Allard',
          'role': 'ROLE_OWNER',
          'isActive': true,
        },
      },
    };
  }

  group('login', () {
    test('returns AuthResponse and saves tokens on success', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/login',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      final result = await service.login('adam', 'pass');

      expect(result.accessToken, 'access-tok-123');
      expect(result.refreshToken, 'refresh-tok-456');
      expect(result.tokenType, 'Bearer');
      expect(result.expiresIn, 3600);
      expect(result.user.id, 'u1');
      expect(result.user.username, 'adam');
      expect(result.user.displayName, 'Adam Allard');
      expect(result.user.role, 'ROLE_OWNER');

      verify(() => mockStorage.saveTokens(
            accessToken: 'access-tok-123',
            refreshToken: 'refresh-tok-456',
          )).called(1);
    });

    test('sends correct credentials in request body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/login',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await service.login('adam', 'pass');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/login',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['username'], 'adam');
      expect(sentData['password'], 'pass');
    });

    test('throws ApiException on invalid credentials', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/login',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 401,
        message: 'Invalid credentials',
      ));

      expect(
        () => service.login('adam', 'wrong'),
        throwsA(isA<ApiException>()),
      );

      verifyNever(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });
  });

  group('register', () {
    test('returns AuthResponse and saves tokens on success', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      final result = await service.register(
        username: 'adam',
        displayName: 'Adam Allard',
        password: 'pass',
        email: 'adam@allard.com',
      );

      expect(result.accessToken, 'access-tok-123');
      expect(result.user.username, 'adam');

      verify(() => mockStorage.saveTokens(
            accessToken: 'access-tok-123',
            refreshToken: 'refresh-tok-456',
          )).called(1);
    });

    test('sends correct body with email', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await service.register(
        username: 'newuser',
        displayName: 'New User',
        password: 'pass',
        email: 'new@user.com',
        role: 'ROLE_MEMBER',
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['username'], 'newuser');
      expect(sentData['displayName'], 'New User');
      expect(sentData['password'], 'pass');
      expect(sentData['email'], 'new@user.com');
      expect(sentData['role'], 'ROLE_MEMBER');
    });

    test('omits email when null', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await service.register(
        username: 'nomail',
        displayName: 'No Mail',
        password: 'pass',
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData.containsKey('email'), isFalse);
    });

    test('omits email when empty string', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await service.register(
        username: 'nomail',
        displayName: 'No Mail',
        password: 'pass',
        email: '',
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData.containsKey('email'), isFalse);
    });

    test('uses ROLE_MEMBER as default role', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData());

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      await service.register(
        username: 'test',
        displayName: 'Test',
        password: 'pass',
      );

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['role'], 'ROLE_MEMBER');
    });

    test('throws ApiException on duplicate username', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/register',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 409,
        message: 'Username already taken',
      ));

      expect(
        () => service.register(
          username: 'adam',
          displayName: 'Adam',
          password: 'pass',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('logout', () {
    test('calls server logout and clears tokens', () async {
      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'access-tok-123');

      when(() => mockClient.post<dynamic>(
            '${AppConstants.authBasePath}/logout',
            data: any(named: 'data'),
          )).thenAnswer((_) async => <String, dynamic>{});

      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      await service.logout();

      verify(() => mockClient.post<dynamic>(
            '${AppConstants.authBasePath}/logout',
            data: any(named: 'data'),
          )).called(1);
      verify(() => mockStorage.clearTokens()).called(1);
    });

    test('clears tokens even when server logout fails', () async {
      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'access-tok-123');

      when(() => mockClient.post<dynamic>(
            '${AppConstants.authBasePath}/logout',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      await service.logout();

      verify(() => mockStorage.clearTokens()).called(1);
    });

    test('skips server call and clears tokens when no access token', () async {
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      await service.logout();

      verifyNever(() => mockClient.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ));
      verify(() => mockStorage.clearTokens()).called(1);
    });
  });

  group('refresh', () {
    test('refreshes tokens and saves new ones', () async {
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-tok-456');

      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/refresh',
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponseData(
            accessToken: 'new-access-tok',
            refreshToken: 'new-refresh-tok',
          ));

      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      final result = await service.refresh();

      expect(result.accessToken, 'new-access-tok');
      expect(result.refreshToken, 'new-refresh-tok');

      final captured = verify(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/refresh',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['refreshToken'], 'refresh-tok-456');

      verify(() => mockStorage.saveTokens(
            accessToken: 'new-access-tok',
            refreshToken: 'new-refresh-tok',
          )).called(1);
    });

    test('throws ApiException when no refresh token stored', () async {
      when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);

      expect(
        () => service.refresh(),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('throws ApiException on server error during refresh', () async {
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh-tok-456');

      when(() => mockClient.post<Map<String, dynamic>>(
            '${AppConstants.authBasePath}/refresh',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 401,
        message: 'Refresh token expired',
      ));

      expect(
        () => service.refresh(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getCurrentUser', () {
    test('returns parsed user model', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'u1',
              'username': 'adam',
              'displayName': 'Adam Allard',
              'role': 'ROLE_OWNER',
              'isActive': true,
            },
          });

      final result = await service.getCurrentUser('u1');

      expect(result.id, 'u1');
      expect(result.username, 'adam');
      expect(result.displayName, 'Adam Allard');
      expect(result.role, 'ROLE_OWNER');
      expect(result.isActive, isTrue);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/bad-id',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'User not found',
      ));

      expect(
        () => service.getCurrentUser('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
