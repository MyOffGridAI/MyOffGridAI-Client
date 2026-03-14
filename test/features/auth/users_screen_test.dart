import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';
import 'package:myoffgridai_client/features/auth/users_screen.dart';

void main() {
  group('UsersScreen', () {
    Widget buildScreen({List<UserModel> users = const []}) {
      return ProviderScope(
        overrides: [
          usersListProvider.overrideWith((ref) => users),
        ],
        child: const MaterialApp(home: UsersScreen()),
      );
    }

    testWidgets('shows empty state when no users', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('displays user list', (tester) async {
      final users = [
        UserModel.fromJson({
          'id': '1',
          'username': 'adam',
          'displayName': 'Adam',
          'role': 'ROLE_OWNER',
          'isActive': true,
        }),
        UserModel.fromJson({
          'id': '2',
          'username': 'jane',
          'displayName': 'Jane',
          'role': 'ROLE_MEMBER',
          'isActive': true,
        }),
      ];

      await tester.pumpWidget(buildScreen(users: users));
      await tester.pumpAndSettle();

      expect(find.text('Adam'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('shows role badges', (tester) async {
      final users = [
        UserModel.fromJson({
          'id': '1',
          'username': 'adam',
          'displayName': 'Adam',
          'role': 'ROLE_OWNER',
          'isActive': true,
        }),
      ];

      await tester.pumpWidget(buildScreen(users: users));
      await tester.pumpAndSettle();

      expect(find.text('OWNER'), findsOneWidget);
    });

    testWidgets('shows add user FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
    });

    testWidgets('shows active status indicators', (tester) async {
      final users = [
        UserModel.fromJson({
          'id': '1',
          'username': 'adam',
          'displayName': 'Adam',
          'role': 'ROLE_OWNER',
          'isActive': true,
        }),
      ];

      await tester.pumpWidget(buildScreen(users: users));
      await tester.pumpAndSettle();

      // Active user should show green circle
      expect(find.byIcon(Icons.circle), findsOneWidget);
    });
  });
}
