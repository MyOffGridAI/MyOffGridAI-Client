import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

void main() {
  late MockApiClient mockClient;
  late UserService service;

  setUp(() {
    mockClient = MockApiClient();
    service = UserService(client: mockClient);
  });

  group('listUsers', () {
    test('returns parsed list from API response', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {
                'id': 'u1',
                'username': 'adam',
                'displayName': 'Adam Allard',
                'role': 'ROLE_OWNER',
                'isActive': true,
              },
              {
                'id': 'u2',
                'username': 'jane',
                'displayName': 'Jane Doe',
                'role': 'ROLE_MEMBER',
                'isActive': true,
              },
            ],
          });

      final result = await service.listUsers();

      expect(result, hasLength(2));
      expect(result[0].id, 'u1');
      expect(result[0].username, 'adam');
      expect(result[0].displayName, 'Adam Allard');
      expect(result[0].role, 'ROLE_OWNER');
      expect(result[0].isActive, isTrue);
      expect(result[1].username, 'jane');
    });

    test('passes default pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listUsers();

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 0);
      expect(params['size'], 100);
    });

    test('passes custom pagination params', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': <dynamic>[]});

      await service.listUsers(page: 2, size: 25);

      final captured = verify(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: captureAny(named: 'queryParams'),
          )).captured;

      final params = captured.first as Map<String, dynamic>;
      expect(params['page'], 2);
      expect(params['size'], 25);
    });

    test('returns empty list when data is null', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'data': null});

      final result = await service.listUsers();

      expect(result, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Only OWNER or ADMIN can list users',
      ));

      expect(
        () => service.listUsers(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getUser', () {
    test('returns parsed user detail', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u1',
          )).thenAnswer((_) async => {
            'data': {
              'id': 'u1',
              'username': 'adam',
              'email': 'adam@allard.com',
              'displayName': 'Adam Allard',
              'role': 'ROLE_OWNER',
              'isActive': true,
              'createdAt': '2026-01-01T00:00:00Z',
              'updatedAt': '2026-03-15T10:00:00Z',
              'lastLoginAt': '2026-03-16T08:00:00Z',
            },
          });

      final result = await service.getUser('u1');

      expect(result.id, 'u1');
      expect(result.username, 'adam');
      expect(result.email, 'adam@allard.com');
      expect(result.displayName, 'Adam Allard');
      expect(result.role, 'ROLE_OWNER');
      expect(result.isActive, isTrue);
      expect(result.createdAt, '2026-01-01T00:00:00Z');
      expect(result.lastLoginAt, '2026-03-16T08:00:00Z');
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/bad-id',
          )).thenThrow(const ApiException(
        statusCode: 404,
        message: 'User not found',
      ));

      expect(
        () => service.getUser('bad-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('updateUser', () {
    test('sends PUT with all optional fields and returns updated detail',
        () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'u2',
              'username': 'jane',
              'email': 'jane@doe.com',
              'displayName': 'Jane Smith',
              'role': 'ROLE_ADMIN',
              'isActive': true,
              'createdAt': '2026-02-01T00:00:00Z',
              'updatedAt': '2026-03-16T12:00:00Z',
            },
          });

      final result = await service.updateUser(
        'u2',
        displayName: 'Jane Smith',
        email: 'jane@doe.com',
        role: 'ROLE_ADMIN',
      );

      expect(result.id, 'u2');
      expect(result.displayName, 'Jane Smith');
      expect(result.email, 'jane@doe.com');
      expect(result.role, 'ROLE_ADMIN');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['displayName'], 'Jane Smith');
      expect(sentData['email'], 'jane@doe.com');
      expect(sentData['role'], 'ROLE_ADMIN');
    });

    test('sends PUT with only displayName', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'u2',
              'username': 'jane',
              'displayName': 'Jane Updated',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            },
          });

      await service.updateUser('u2', displayName: 'Jane Updated');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData['displayName'], 'Jane Updated');
      expect(sentData.containsKey('email'), isFalse);
      expect(sentData.containsKey('role'), isFalse);
    });

    test('sends empty map when no optional fields provided', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: any(named: 'data'),
          )).thenAnswer((_) async => {
            'data': {
              'id': 'u2',
              'username': 'jane',
              'displayName': 'Jane Doe',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            },
          });

      await service.updateUser('u2');

      final captured = verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: captureAny(named: 'data'),
          )).captured;

      final sentData = captured.first as Map<String, dynamic>;
      expect(sentData, isEmpty);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2',
            data: any(named: 'data'),
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Forbidden',
      ));

      expect(
        () => service.updateUser('u2', displayName: 'test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('deactivateUser', () {
    test('calls PUT on deactivate endpoint', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2/deactivate',
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.deactivateUser('u2');

      verify(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2/deactivate',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '${AppConstants.usersBasePath}/u2/deactivate',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Cannot deactivate owner',
      ));

      expect(
        () => service.deactivateUser('u2'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('UserDetailModel.fromJson', () {
    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 'u1',
        'username': 'adam',
      };

      final model = UserDetailModel.fromJson(json);

      expect(model.id, 'u1');
      expect(model.username, 'adam');
      expect(model.email, isNull);
      expect(model.displayName, '');
      expect(model.role, 'ROLE_MEMBER');
      expect(model.isActive, isTrue);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
      expect(model.lastLoginAt, isNull);
    });
  });

  group('deleteUser', () {
    test('calls DELETE on correct path', () async {
      when(() => mockClient.delete(
            '${AppConstants.usersBasePath}/u2',
          )).thenAnswer((_) async {});

      await service.deleteUser('u2');

      verify(() => mockClient.delete(
            '${AppConstants.usersBasePath}/u2',
          )).called(1);
    });

    test('throws ApiException on API error', () async {
      when(() => mockClient.delete(
            '${AppConstants.usersBasePath}/u2',
          )).thenThrow(const ApiException(
        statusCode: 403,
        message: 'Cannot delete owner',
      ));

      expect(
        () => service.deleteUser('u2'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── Provider body tests ───────────────────────────────────────────────
  group('userServiceProvider', () {
    test('creates UserService from apiClientProvider', () {
      final mockClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      expect(container.read(userServiceProvider), isA<UserService>());
    });
  });

  group('usersListProvider', () {
    test('returns users from service', () async {
      final mockClient = MockApiClient();
      when(() => mockClient.get<Map<String, dynamic>>(
            AppConstants.usersBasePath,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': [
              {'id': 'u1', 'username': 'adam', 'displayName': 'Adam', 'role': 'ROLE_OWNER', 'isActive': true},
            ],
          });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);
      final users = await container.read(usersListProvider.future);
      expect(users, hasLength(1));
    });
  });
}
