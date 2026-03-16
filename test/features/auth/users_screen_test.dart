import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/user_service.dart';
import 'package:myoffgridai_client/features/auth/users_screen.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockService;

  final activeOwner = UserModel.fromJson({
    'id': '1',
    'username': 'adam',
    'displayName': 'Adam',
    'role': 'ROLE_OWNER',
    'isActive': true,
  });

  final activeMember = UserModel.fromJson({
    'id': '2',
    'username': 'jane',
    'displayName': 'Jane',
    'role': 'ROLE_MEMBER',
    'isActive': true,
  });

  final inactiveViewer = UserModel.fromJson({
    'id': '3',
    'username': 'bob',
    'displayName': 'Bob',
    'role': 'ROLE_VIEWER',
    'isActive': false,
  });

  final emptyDisplayNameUser = UserModel.fromJson({
    'id': '4',
    'username': 'noname',
    'displayName': '',
    'role': 'ROLE_CHILD',
    'isActive': true,
  });

  setUp(() {
    mockService = MockUserService();
    registerFallbackValue('');
  });

  Widget buildScreen({List<UserModel> users = const []}) {
    return ProviderScope(
      overrides: [
        usersListProvider.overrideWith((ref) => users),
        userServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: UsersScreen()),
    );
  }

  group('UsersScreen', () {
    testWidgets('shows empty state when no users', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('displays user list', (tester) async {
      await tester.pumpWidget(
          buildScreen(users: [activeOwner, activeMember]));
      await tester.pumpAndSettle();

      expect(find.text('Adam'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('shows role badges', (tester) async {
      await tester
          .pumpWidget(buildScreen(users: [activeOwner, activeMember]));
      await tester.pumpAndSettle();

      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
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
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.circle), findsOneWidget);
    });

    testWidgets('shows green circle for active user', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.circle));
      expect(icon.color, Colors.green);
    });

    testWidgets('shows grey circle for inactive user', (tester) async {
      await tester.pumpWidget(buildScreen(users: [inactiveViewer]));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.circle));
      expect(icon.color, Colors.grey);
    });

    testWidgets('shows username as subtitle', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      expect(find.text('adam'), findsOneWidget);
    });

    testWidgets('shows avatar with first letter of display name',
        (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows ? for empty display name', (tester) async {
      await tester.pumpWidget(buildScreen(users: [emptyDisplayNameUser]));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows CHILD role badge', (tester) async {
      await tester.pumpWidget(buildScreen(users: [emptyDisplayNameUser]));
      await tester.pumpAndSettle();

      expect(find.text('CHILD'), findsOneWidget);
    });
  });

  group('FAB navigation', () {
    testWidgets('FAB navigates to register screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/users',
        routes: [
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (_, __) =>
                const Scaffold(body: Text('Register Screen')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          usersListProvider.overrideWith((ref) => <UserModel>[]),
          userServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });
  });

  group('UsersScreen error state', () {
    testWidgets('shows API error message', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          usersListProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Server down')),
          userServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: UsersScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load users'), findsOneWidget);
      expect(find.text('Server down'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          usersListProvider.overrideWith((ref) => throw Exception('unknown')),
          userServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: UsersScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          usersListProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          userServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: UsersScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('User actions bottom sheet', () {
    testWidgets('opens on tile tap', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Change Role'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
      expect(find.text('Delete User'), findsOneWidget);
    });

    testWidgets('shows Activate for inactive user', (tester) async {
      await tester.pumpWidget(buildScreen(users: [inactiveViewer]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      expect(find.text('Activate'), findsOneWidget);
    });
  });

  group('View Details', () {
    testWidgets('shows user detail bottom sheet', (tester) async {
      when(() => mockService.getUser('1')).thenAnswer((_) async =>
          UserDetailModel(
            id: '1',
            username: 'adam',
            displayName: 'Adam',
            role: 'ROLE_OWNER',
            isActive: true,
            email: 'adam@test.com',
            createdAt: '2026-01-01T00:00:00Z',
            lastLoginAt: '2026-03-15T10:00:00Z',
          ));

      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.text('Username: adam'), findsOneWidget);
      expect(find.text('Email: adam@test.com'), findsOneWidget);
      expect(find.text('Role: OWNER'), findsOneWidget);
      expect(find.text('Active: Yes'), findsOneWidget);
    });

    testWidgets('shows error on detail fetch failure', (tester) async {
      when(() => mockService.getUser('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );

      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
    });
  });

  group('Change Role', () {
    testWidgets('shows role selection dialog', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Role'));
      await tester.pumpAndSettle();

      expect(find.text('Change role for Adam'), findsOneWidget);
      expect(find.text('OWNER'), findsWidgets);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('MEMBER'), findsOneWidget);
      expect(find.text('VIEWER'), findsOneWidget);
      expect(find.text('CHILD'), findsOneWidget);
    });

    testWidgets('shows check icon on current role', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Role'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('calls updateUser when different role selected',
        (tester) async {
      when(() => mockService.updateUser('1', role: 'ROLE_ADMIN'))
          .thenAnswer((_) async => UserDetailModel(
                id: '1',
                username: 'adam',
                displayName: 'Adam',
                role: 'ROLE_ADMIN',
                isActive: true,
              ));

      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Role'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADMIN'));
      await tester.pumpAndSettle();

      verify(() => mockService.updateUser('1', role: 'ROLE_ADMIN')).called(1);
    });

    testWidgets('shows error on role change failure', (tester) async {
      when(() => mockService.updateUser('1', role: 'ROLE_ADMIN'))
          .thenThrow(
        const ApiException(statusCode: 403, message: 'Forbidden'),
      );

      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Role'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADMIN'));
      await tester.pumpAndSettle();

      expect(find.text('Forbidden'), findsOneWidget);
    });
  });

  group('Deactivate', () {
    testWidgets('shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Adam?'), findsOneWidget);
      expect(find.text('This user will no longer be able to log in.'),
          findsOneWidget);
    });

    testWidgets('calls deactivateUser on confirm', (tester) async {
      when(() => mockService.deactivateUser('1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.deactivateUser('1')).called(1);
    });

    testWidgets('does not call service on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deactivateUser(any()));
    });

    testWidgets('shows error SnackBar on deactivate failure', (tester) async {
      when(() => mockService.deactivateUser('1')).thenThrow(
        const ApiException(statusCode: 403, message: 'Not allowed'),
      );

      await tester.pumpWidget(buildScreen(users: [activeOwner]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Not allowed'), findsOneWidget);
    });
  });

  group('Delete', () {
    testWidgets('shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeMember]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jane'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete User'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Jane?'), findsOneWidget);
      expect(
          find.text(
              'This will permanently delete the user and all their data.'),
          findsOneWidget);
    });

    testWidgets('calls deleteUser on confirm', (tester) async {
      when(() => mockService.deleteUser('2')).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(users: [activeMember]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jane'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete User'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteUser('2')).called(1);
    });

    testWidgets('does not call service on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(users: [activeMember]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jane'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete User'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteUser(any()));
    });

    testWidgets('shows error SnackBar on delete failure', (tester) async {
      when(() => mockService.deleteUser('2')).thenThrow(
        const ApiException(statusCode: 500, message: 'Delete failed'),
      );

      await tester.pumpWidget(buildScreen(users: [activeMember]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jane'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete User'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Delete failed'), findsOneWidget);
    });
  });
}
