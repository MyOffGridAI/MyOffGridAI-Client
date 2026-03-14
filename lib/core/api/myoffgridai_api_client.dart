import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';

/// Dio-based HTTP client for communicating with the MyOffGridAI server.
///
/// Provides JWT authentication via interceptors, automatic token refresh
/// on 401 responses, and typed error handling through [ApiException].
class MyOffGridAIApiClient {
  final Dio _dio;
  final SecureStorageService _storage;
  final Ref _ref;

  /// Creates a [MyOffGridAIApiClient] with the given [baseUrl], [storage], and [ref].
  MyOffGridAIApiClient({
    required String baseUrl,
    required SecureStorageService storage,
    required Ref ref,
  })  : _storage = storage,
        _ref = ref,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(_AuthInterceptor(storage: _storage, client: this));
    if (kDebugMode) {
      _dio.interceptors.add(_LoggingInterceptor());
    }
  }

  /// The underlying [Dio] instance, exposed for testing.
  @visibleForTesting
  Dio get dio => _dio;

  /// The Riverpod [Ref], used for invalidating auth state on token failure.
  Ref get ref => _ref;

  /// Performs a GET request to [path] with optional [queryParams].
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParams,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Performs a POST request to [path] with optional [data] body.
  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Performs a PUT request to [path] with optional [data] body.
  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Performs a PATCH request to [path] with optional [data] body.
  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: data);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Performs a DELETE request to [path].
  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Performs a multipart POST request to [path] with [formData].
  Future<T> postMultipart<T>(
    String path,
    FormData formData, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: formData);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  T _handleResponse<T>(Response<dynamic> response, T Function(dynamic)? fromJson) {
    if (fromJson != null) {
      return fromJson(response.data);
    }
    return response.data as T;
  }

  ApiException _handleDioException(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      String message = 'An error occurred';
      Map<String, dynamic>? errors;
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
        errors = data['errors'] as Map<String, dynamic>?;
      }
      return ApiException(
        statusCode: e.response!.statusCode ?? 500,
        message: message,
        errors: errors,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        statusCode: 408,
        message: 'Connection timed out. Check your network connection.',
      );
    }
    return ApiException(
      statusCode: 0,
      message: e.message ?? 'Cannot reach MyOffGrid AI server.',
    );
  }

  /// Attempts to refresh the access token using the stored refresh token.
  ///
  /// Returns true if refresh succeeded, false otherwise.
  Future<bool> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post<dynamic>(
        '${AppConstants.authBasePath}/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'_skipAuth': 'true'}),
      );
      final data = response.data as Map<String, dynamic>;
      final authData = data['data'] as Map<String, dynamic>?;
      if (authData != null) {
        final newAccess = authData['accessToken'] as String?;
        final newRefresh = authData['refreshToken'] as String?;
        if (newAccess != null && newRefresh != null) {
          await _storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService storage;
  final MyOffGridAIApiClient client;
  bool _isRefreshing = false;

  _AuthInterceptor({required this.storage, required this.client});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers['_skipAuth'] == 'true') {
      options.headers.remove('_skipAuth');
      handler.next(options);
      return;
    }
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final path = err.requestOptions.path;
      if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
        handler.next(err);
        return;
      }

      _isRefreshing = true;
      final success = await client.refreshToken();
      _isRefreshing = false;

      if (success) {
        final token = await storage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await client.dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(err);
          return;
        }
      } else {
        await storage.clearTokens();
      }
    }
    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}

/// Riverpod provider for [MyOffGridAIApiClient].
final apiClientProvider = Provider<MyOffGridAIApiClient>((ref) {
  throw UnimplementedError(
    'apiClientProvider must be overridden at startup after resolving server URL',
  );
});
