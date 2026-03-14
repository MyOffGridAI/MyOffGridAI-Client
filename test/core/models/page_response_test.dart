import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/page_response.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';

void main() {
  group('PageResponse', () {
    test('parses from JSON with item factory', () {
      final json = {
        'content': [
          {
            'id': '1',
            'username': 'user1',
            'displayName': 'User One',
            'role': 'ROLE_MEMBER',
            'isActive': true,
          },
          {
            'id': '2',
            'username': 'user2',
            'displayName': 'User Two',
            'role': 'ROLE_ADMIN',
            'isActive': true,
          },
        ],
        'totalElements': 2,
        'totalPages': 1,
        'number': 0,
        'size': 20,
        'first': true,
        'last': true,
        'empty': false,
      };

      final page = PageResponse.fromJson(
        json,
        (item) => UserModel.fromJson(item),
      );

      expect(page.content.length, 2);
      expect(page.content[0].username, 'user1');
      expect(page.content[1].username, 'user2');
      expect(page.totalElements, 2);
      expect(page.totalPages, 1);
      expect(page.number, 0);
      expect(page.size, 20);
      expect(page.first, isTrue);
      expect(page.last, isTrue);
      expect(page.empty, isFalse);
    });

    test('handles empty content', () {
      final json = {
        'content': <dynamic>[],
        'totalElements': 0,
        'totalPages': 0,
        'number': 0,
        'size': 20,
        'first': true,
        'last': true,
        'empty': true,
      };

      final page = PageResponse.fromJson(
        json,
        (item) => UserModel.fromJson(item),
      );

      expect(page.content, isEmpty);
      expect(page.empty, isTrue);
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final page = PageResponse.fromJson(
        json,
        (item) => UserModel.fromJson(item),
      );

      expect(page.content, isEmpty);
      expect(page.totalElements, 0);
      expect(page.first, isTrue);
      expect(page.last, isTrue);
      expect(page.empty, isTrue);
    });
  });
}
