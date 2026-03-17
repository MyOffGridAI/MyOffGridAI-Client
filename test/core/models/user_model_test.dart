import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'user-1',
        'username': 'admin',
        'displayName': 'Admin User',
        'role': 'ROLE_ADMIN',
        'isActive': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-1');
      expect(user.username, 'admin');
      expect(user.displayName, 'Admin User');
      expect(user.role, 'ROLE_ADMIN');
      expect(user.isActive, isTrue);
    });

    test('fromJson defaults displayName to empty string when null', () {
      final json = {
        'id': 'user-2',
        'username': 'member',
      };

      final user = UserModel.fromJson(json);

      expect(user.displayName, '');
    });

    test('fromJson defaults role to ROLE_MEMBER when null', () {
      final json = {
        'id': 'user-3',
        'username': 'newuser',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, 'ROLE_MEMBER');
    });

    test('fromJson defaults isActive to true when null', () {
      final json = {
        'id': 'user-4',
        'username': 'active',
      };

      final user = UserModel.fromJson(json);

      expect(user.isActive, isTrue);
    });

    test('fromJson handles isActive false', () {
      final json = {
        'id': 'user-5',
        'username': 'inactive',
        'isActive': false,
      };

      final user = UserModel.fromJson(json);

      expect(user.isActive, isFalse);
    });

    test('toJson produces correct map', () {
      const user = UserModel(
        id: 'user-1',
        username: 'admin',
        displayName: 'Admin User',
        role: 'ROLE_ADMIN',
        isActive: true,
      );

      final json = user.toJson();

      expect(json['id'], 'user-1');
      expect(json['username'], 'admin');
      expect(json['displayName'], 'Admin User');
      expect(json['role'], 'ROLE_ADMIN');
      expect(json['isActive'], isTrue);
    });

    test('toJson roundtrips through fromJson', () {
      const original = UserModel(
        id: 'user-rt',
        username: 'roundtrip',
        displayName: 'Roundtrip Test',
        role: 'ROLE_MEMBER',
        isActive: false,
      );

      final roundtripped = UserModel.fromJson(original.toJson());

      expect(roundtripped.id, original.id);
      expect(roundtripped.username, original.username);
      expect(roundtripped.displayName, original.displayName);
      expect(roundtripped.role, original.role);
      expect(roundtripped.isActive, original.isActive);
    });
  });
}
