import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/api_response.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';

void main() {
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
}
