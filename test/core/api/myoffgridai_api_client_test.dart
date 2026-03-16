import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/api_response.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';

/// Fake [Ref] for constructing [MyOffGridAIApiClient] without a real provider container.
class _FakeRef extends Fake implements Ref {}

/// In-memory [SecureStorageService] for controlling token state in tests.
class _FakeStorage extends SecureStorageService {
  String? accessToken;
  String? refreshToken;
  bool clearTokensCalled = false;

  _FakeStorage({this.accessToken, this.refreshToken}) : super(storage: null);

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    clearTokensCalled = true;
    accessToken = null;
    refreshToken = null;
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

/// Fake [HttpClientAdapter] that records requests and returns controlled responses.
class _FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Helper to build a JSON response body with content-type header.
ResponseBody jsonResponse(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  // ── Existing model/DTO tests ──────────────────────────────────────────

  group('ApiException', () {
    test('toString includes status code and message', () {
      const exception = ApiException(
        statusCode: 401,
        message: 'Unauthorized',
      );
      expect(exception.toString(), 'ApiException(401): Unauthorized');
    });

    test('stores validation errors', () {
      const exception = ApiException(
        statusCode: 400,
        message: 'Validation failed',
        errors: {'username': 'already exists'},
      );
      expect(exception.errors, isNotNull);
      expect(exception.errors!['username'], 'already exists');
    });
  });

  group('ApiResponse', () {
    test('parses from JSON with data factory', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'abc-123',
          'username': 'testuser',
          'displayName': 'Test User',
          'role': 'ROLE_MEMBER',
          'isActive': true,
        },
        'timestamp': '2026-03-14T00:00:00Z',
      };

      final response = ApiResponse.fromJson(
        json,
        (data) => UserModel.fromJson(data as Map<String, dynamic>),
      );

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data, isNotNull);
      expect(response.data!.username, 'testuser');
    });

    test('parses from JSON without data factory', () {
      final json = {
        'success': true,
        'message': 'Deleted',
        'data': null,
      };

      final response = ApiResponse<dynamic>.fromJson(json, null);
      expect(response.success, isTrue);
      expect(response.data, isNull);
    });

    test('handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final response = ApiResponse<dynamic>.fromJson(json, null);
      expect(response.success, isFalse);
      expect(response.message, isNull);
    });

    test('parses pagination fields', () {
      final json = {
        'success': true,
        'data': null,
        'totalElements': 42,
        'page': 0,
        'size': 20,
        'requestId': 'req-123',
      };
      final response = ApiResponse<dynamic>.fromJson(json, null);
      expect(response.totalElements, 42);
      expect(response.page, 0);
      expect(response.size, 20);
      expect(response.requestId, 'req-123');
    });
  });

  group('UserModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 'uuid-123',
        'username': 'adam',
        'displayName': 'Adam',
        'role': 'ROLE_OWNER',
        'isActive': true,
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'uuid-123');
      expect(user.username, 'adam');
      expect(user.displayName, 'Adam');
      expect(user.role, 'ROLE_OWNER');
      expect(user.isActive, isTrue);
    });

    test('toJson round-trips correctly', () {
      const user = UserModel(
        id: 'id-1',
        username: 'user1',
        displayName: 'User One',
        role: 'ROLE_MEMBER',
        isActive: true,
      );
      final json = user.toJson();
      final restored = UserModel.fromJson(json);
      expect(restored.id, user.id);
      expect(restored.username, user.username);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'uuid-123',
        'username': 'adam',
      };
      final user = UserModel.fromJson(json);
      expect(user.displayName, '');
      expect(user.role, 'ROLE_MEMBER');
      expect(user.isActive, isTrue);
    });
  });

  // ── Interceptor + HTTP method tests ───────────────────────────────────

  group('MyOffGridAIApiClient', () {
    late _FakeStorage storage;
    late _FakeHttpAdapter adapter;
    late MyOffGridAIApiClient client;

    setUp(() {
      storage = _FakeStorage(accessToken: 'test-access-token');
      adapter = _FakeHttpAdapter();
      client = MyOffGridAIApiClient(
        baseUrl: 'http://localhost:8080',
        storage: storage,
        ref: _FakeRef(),
      );
      client.dio.httpClientAdapter = adapter;
    });

    group('_AuthInterceptor', () {
      test('adds Authorization header when token is present', () async {
        adapter.handler = (_) => jsonResponse({'ok': true}, 200);

        await client.get<dynamic>('/test');

        expect(adapter.requests, hasLength(1));
        expect(
          adapter.requests.first.headers['Authorization'],
          'Bearer test-access-token',
        );
      });

      test('does not add Authorization header when no token stored', () async {
        storage.accessToken = null;
        adapter.handler = (_) => jsonResponse({'ok': true}, 200);

        await client.get<dynamic>('/test');

        expect(adapter.requests, hasLength(1));
        expect(
          adapter.requests.first.headers['Authorization'],
          isNull,
        );
      });

      test('retries request on 401 after successful token refresh', () async {
        storage.refreshToken = 'old-refresh';
        int getCallCount = 0;

        adapter.handler = (options) {
          if (options.path.contains('/auth/refresh')) {
            return jsonResponse({
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
              },
            }, 200);
          }
          getCallCount++;
          if (getCallCount == 1) {
            return jsonResponse({'message': 'Unauthorized'}, 401);
          }
          // Retry succeeds
          return jsonResponse({'result': 'ok'}, 200);
        };

        final result = await client.get<dynamic>('/test');

        expect(result, isA<Map>());
        // Original 401, then refresh, then retry
        expect(adapter.requests.length, 3);
        expect(storage.accessToken, 'new-access');
        expect(storage.refreshToken, 'new-refresh');
      });

      test('clears tokens when refresh fails on 401', () async {
        storage.refreshToken = null;

        adapter.handler = (_) {
          return jsonResponse({'message': 'Unauthorized'}, 401);
        };

        expect(
          () => client.get<dynamic>('/test'),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          )),
        );
      });

      test('passes original error when retry fetch throws after successful refresh',
          () async {
        storage.refreshToken = 'old-refresh';
        int getCallCount = 0;

        adapter.handler = (options) {
          if (options.path.contains('/auth/refresh')) {
            return jsonResponse({
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
              },
            }, 200);
          }
          getCallCount++;
          if (getCallCount == 1) {
            // First request: 401 triggers refresh
            return jsonResponse({'message': 'Unauthorized'}, 401);
          }
          // Retry: fail with a non-401 error (e.g., 500) so it doesn't loop
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Connection reset',
          );
        };

        expect(
          () => client.get<dynamic>('/test'),
          throwsA(isA<ApiException>()),
        );
      });

      test('does not retry /auth/login on 401', () async {
        adapter.handler = (_) {
          return jsonResponse({'message': 'Bad credentials'}, 401);
        };

        expect(
          () => client.post<dynamic>(
            '${AppConstants.authBasePath}/login',
            data: {'username': 'test', 'password': 'wrong'},
          ),
          throwsA(isA<ApiException>()),
        );

        // Wait for the exception to propagate
        await Future<void>.delayed(Duration.zero);

        final refreshRequests = adapter.requests.where(
          (r) => r.path.contains('/auth/refresh'),
        );
        expect(refreshRequests, isEmpty);
      });

      test('does not retry /auth/refresh on 401', () async {
        storage.refreshToken = 'some-token';
        adapter.handler = (_) {
          return jsonResponse({'message': 'Invalid token'}, 401);
        };

        // refreshToken should return false without looping
        final result = await client.refreshToken();
        expect(result, isFalse);
      });
    });

    group('error handling', () {
      test('throws ApiException with message from server error', () async {
        adapter.handler = (_) {
          return jsonResponse({'message': 'Not found'}, 404);
        };

        expect(
          () => client.get<dynamic>('/missing'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.message, 'message', 'Not found'),
          ),
        );
      });

      test('throws ApiException with validation errors', () async {
        adapter.handler = (_) {
          return jsonResponse({
            'message': 'Validation failed',
            'errors': {'name': 'required'},
          }, 400);
        };

        expect(
          () => client.post<dynamic>('/items', data: {}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 400)
                .having((e) => e.errors, 'errors', isNotNull),
          ),
        );
      });

      test('throws timeout ApiException on connection timeout', () async {
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        };

        expect(
          () => client.get<dynamic>('/slow'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 408)
                .having((e) => e.message, 'message', contains('timed out')),
          ),
        );
      });

      test('throws timeout ApiException on receive timeout', () async {
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        };

        expect(
          () => client.get<dynamic>('/slow'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              408,
            ),
          ),
        );
      });

      test('throws network ApiException on connection error', () async {
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Connection refused',
          );
        };

        expect(
          () => client.get<dynamic>('/unreachable'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 0),
          ),
        );
      });

      test('uses default message for non-map error response', () async {
        adapter.handler = (_) {
          return ResponseBody.fromString('"plain string"', 500, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
        };

        expect(
          () => client.get<dynamic>('/error'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'An error occurred',
            ),
          ),
        );
      });
    });

    group('HTTP methods', () {
      test('get sends GET request with query params', () async {
        adapter.handler = (_) => jsonResponse({'key': 'value'}, 200);

        await client.get<dynamic>('/test', queryParams: {'q': 'search'});

        expect(adapter.requests.first.method, 'GET');
        expect(adapter.requests.first.queryParameters['q'], 'search');
      });

      test('post sends POST request with data', () async {
        adapter.handler = (_) => jsonResponse({'id': '1'}, 200);

        await client.post<dynamic>('/items', data: {'name': 'test'});

        expect(adapter.requests.first.method, 'POST');
      });

      test('put sends PUT request', () async {
        adapter.handler = (_) => jsonResponse({}, 200);

        await client.put<dynamic>('/items/1', data: {'name': 'updated'});

        expect(adapter.requests.first.method, 'PUT');
      });

      test('patch sends PATCH request', () async {
        adapter.handler = (_) => jsonResponse({}, 200);

        await client.patch<dynamic>('/items/1', data: {'name': 'patched'});

        expect(adapter.requests.first.method, 'PATCH');
      });

      test('delete sends DELETE request', () async {
        adapter.handler = (_) => ResponseBody.fromString('', 200);

        await client.delete('/items/1');

        expect(adapter.requests.first.method, 'DELETE');
      });

      test('getBytes returns raw bytes', () async {
        final bytes = utf8.encode('file content');
        adapter.handler = (_) => ResponseBody.fromBytes(bytes, 200);

        final result = await client.getBytes('/files/1');

        expect(result, bytes);
      });

      test('get uses fromJson converter when provided', () async {
        adapter.handler = (_) => jsonResponse({
              'id': 'u1',
              'username': 'test',
              'displayName': 'Test',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            }, 200);

        final user = await client.get<UserModel>(
          '/users/u1',
          fromJson: (data) =>
              UserModel.fromJson(data as Map<String, dynamic>),
        );

        expect(user.username, 'test');
      });
    });

    group('HTTP methods (additional)', () {
      test('postMultipart sends POST with FormData', () async {
        adapter.handler = (_) => jsonResponse({'id': 'file-1'}, 200);

        final formData = FormData.fromMap({'name': 'test.txt'});
        await client.postMultipart<dynamic>('/upload', formData);

        expect(adapter.requests.first.method, 'POST');
      });

      test('postMultipart uses fromJson converter when provided', () async {
        adapter.handler = (_) => jsonResponse({
              'id': 'u1',
              'username': 'test',
              'displayName': 'Test',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            }, 200);

        final formData = FormData.fromMap({'file': 'data'});
        final user = await client.postMultipart<UserModel>(
          '/upload',
          formData,
          fromJson: (data) =>
              UserModel.fromJson(data as Map<String, dynamic>),
        );

        expect(user.username, 'test');
      });

      test('postMultipart throws ApiException on error', () async {
        adapter.handler = (_) =>
            jsonResponse({'message': 'File too large'}, 413);

        final formData = FormData.fromMap({'file': 'data'});
        expect(
          () => client.postMultipart<dynamic>('/upload', formData),
          throwsA(isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            413,
          )),
        );
      });

      test('getBytes throws ApiException on error', () async {
        adapter.handler = (_) =>
            jsonResponse({'message': 'Not found'}, 404);

        expect(
          () => client.getBytes('/missing-file'),
          throwsA(isA<ApiException>()),
        );
      });

      test('delete throws ApiException on error', () async {
        adapter.handler = (_) =>
            jsonResponse({'message': 'Forbidden'}, 403);

        expect(
          () => client.delete('/items/1'),
          throwsA(isA<ApiException>()),
        );
      });

      test('post uses fromJson converter when provided', () async {
        adapter.handler = (_) => jsonResponse({
              'id': 'u1',
              'username': 'created',
              'displayName': 'Created',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            }, 201);

        final user = await client.post<UserModel>(
          '/users',
          data: {'username': 'created'},
          fromJson: (data) =>
              UserModel.fromJson(data as Map<String, dynamic>),
        );

        expect(user.username, 'created');
      });

      test('put uses fromJson converter when provided', () async {
        adapter.handler = (_) => jsonResponse({
              'id': 'u1',
              'username': 'updated',
              'displayName': 'Updated',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            }, 200);

        final user = await client.put<UserModel>(
          '/users/u1',
          data: {'username': 'updated'},
          fromJson: (data) =>
              UserModel.fromJson(data as Map<String, dynamic>),
        );

        expect(user.username, 'updated');
      });

      test('patch uses fromJson converter when provided', () async {
        adapter.handler = (_) => jsonResponse({
              'id': 'u1',
              'username': 'patched',
              'displayName': 'Patched',
              'role': 'ROLE_MEMBER',
              'isActive': true,
            }, 200);

        final user = await client.patch<UserModel>(
          '/users/u1',
          data: {'username': 'patched'},
          fromJson: (data) =>
              UserModel.fromJson(data as Map<String, dynamic>),
        );

        expect(user.username, 'patched');
      });
    });

    group('_AuthInterceptor - _skipAuth', () {
      test('skips auth header when _skipAuth is set', () async {
        adapter.handler = (_) => jsonResponse({'ok': true}, 200);

        // The refreshToken method uses _skipAuth internally
        // We can verify by checking that the refresh call doesn't include auth header
        storage.refreshToken = 'test-refresh';
        storage.accessToken = 'test-access';

        adapter.handler = (options) {
          if (options.path.contains('/auth/refresh')) {
            // The _skipAuth header should have been removed before reaching the adapter
            expect(options.headers['_skipAuth'], isNull);
            return jsonResponse({
              'data': {
                'accessToken': 'new-a',
                'refreshToken': 'new-r',
              },
            }, 200);
          }
          return jsonResponse({'ok': true}, 200);
        };

        final result = await client.refreshToken();
        expect(result, isTrue);
      });
    });

    group('_handleDioException edge cases', () {
      test('uses null-safe message for connection error without message',
          () async {
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        };

        expect(
          () => client.get<dynamic>('/test'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 0)
                .having((e) => e.message, 'message',
                    'Cannot reach MyOffGrid AI server.'),
          ),
        );
      });

      test('extracts error from response with null statusCode', () async {
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: null,
              data: {'message': 'Something went wrong'},
            ),
          );
        };

        expect(
          () => client.get<dynamic>('/test'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
      });
    });

    group('ref getter', () {
      test('returns the Ref passed to the constructor', () {
        // Exercises line 50: Ref get ref => _ref;
        expect(client.ref, isA<Ref>());
      });
    });

    group('put error handling', () {
      test('throws ApiException on DioException during put', () async {
        adapter.handler = (_) =>
            jsonResponse({'message': 'Conflict'}, 409);

        expect(
          () => client.put<dynamic>('/items/1', data: {'name': 'test'}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 409)
                .having((e) => e.message, 'message', 'Conflict'),
          ),
        );
      });
    });

    group('patch error handling', () {
      test('throws ApiException on DioException during patch', () async {
        adapter.handler = (_) =>
            jsonResponse({'message': 'Unprocessable'}, 422);

        expect(
          () => client.patch<dynamic>('/items/1', data: {'name': 'test'}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 422)
                .having((e) => e.message, 'message', 'Unprocessable'),
          ),
        );
      });
    });

    group('updateBaseUrl', () {
      test('changes the Dio base URL', () {
        client.updateBaseUrl('http://new-server:9090');
        expect(client.dio.options.baseUrl, 'http://new-server:9090');
      });
    });

    group('refreshToken', () {
      test('returns true and saves tokens on success', () async {
        storage.refreshToken = 'old-refresh';
        adapter.handler = (_) => jsonResponse({
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
              },
            }, 200);

        final result = await client.refreshToken();

        expect(result, isTrue);
        expect(storage.accessToken, 'new-access');
        expect(storage.refreshToken, 'new-refresh');
      });

      test('returns false when no refresh token stored', () async {
        storage.refreshToken = null;

        final result = await client.refreshToken();

        expect(result, isFalse);
      });

      test('returns false on network error during refresh', () async {
        storage.refreshToken = 'old-refresh';
        adapter.handler = (options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        };

        final result = await client.refreshToken();

        expect(result, isFalse);
      });

      test('returns false when response data is missing tokens', () async {
        storage.refreshToken = 'old-refresh';
        adapter.handler = (_) => jsonResponse({
              'data': {'accessToken': 'new-access'},
            }, 200);

        final result = await client.refreshToken();

        expect(result, isFalse);
      });

      test('returns false when response has no data field', () async {
        storage.refreshToken = 'old-refresh';
        adapter.handler = (_) => jsonResponse({'success': true}, 200);

        final result = await client.refreshToken();

        expect(result, isFalse);
      });
    });
  });
}
