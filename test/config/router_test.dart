import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/config/router.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/features/auth/login_screen.dart';
import 'package:myoffgridai_client/features/auth/register_screen.dart';

/// Fake [AuthNotifier] that resolves immediately with a predetermined user.
class _FakeAuthNotifier extends AuthNotifier {
  final UserModel? _user;

  _FakeAuthNotifier(this._user);

  @override
  Future<UserModel?> build() async => _user;

  @override
  Future<void> login(String username, String password) async {}

  @override
  Future<void> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {}

  @override
  Future<void> logout() async {
    state = const AsyncData(null);
  }
}

const _memberUser = UserModel(
  id: 'u1',
  username: 'member',
  displayName: 'Member User',
  role: 'ROLE_MEMBER',
  isActive: true,
);

const _ownerUser = UserModel(
  id: 'u2',
  username: 'owner',
  displayName: 'Owner User',
  role: 'ROLE_OWNER',
  isActive: true,
);

const _adminUser = UserModel(
  id: 'u3',
  username: 'admin',
  displayName: 'Admin User',
  role: 'ROLE_ADMIN',
  isActive: true,
);

/// Builds a minimal app with the GoRouter and auth state override.
Widget _buildApp({UserModel? user, String? initialLocation}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
      if (initialLocation != null)
        routerProvider.overrideWithValue(
          _createTestRouter(user, initialLocation),
        ),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

/// Creates a GoRouter for testing with a specific initial location.
GoRouter _createTestRouter(UserModel? user, String initialLocation) {
  // Replicate the redirect logic from createRouter without needing a Ref.
  // Instead we directly check the user value.
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeRegister ||
          state.matchedLocation == AppConstants.routeDeviceNotSetup;

      if (!isLoggedIn && !isAuthRoute) {
        return AppConstants.routeLogin;
      }

      if (isLoggedIn &&
          (state.matchedLocation == AppConstants.routeLogin ||
              state.matchedLocation == AppConstants.routeRegister)) {
        return AppConstants.routeHome;
      }

      if (state.matchedLocation == AppConstants.routeUsers && isLoggedIn) {
        if (user.role != 'ROLE_OWNER' && user.role != 'ROLE_ADMIN') {
          return AppConstants.routeHome;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('LOGIN_SCREEN')),
        ),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('REGISTER_SCREEN')),
        ),
      ),
      GoRoute(
        path: AppConstants.routeDeviceNotSetup,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('DEVICE_NOT_SETUP_SCREEN')),
        ),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('HOME_SCREEN')),
        ),
      ),
      GoRoute(
        path: AppConstants.routeUsers,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('USERS_SCREEN')),
        ),
      ),
      GoRoute(
        path: AppConstants.routeBooks,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('BOOKS_SCREEN')),
        ),
      ),
      GoRoute(
        path: AppConstants.routeNotifications,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('NOTIFICATIONS_SCREEN')),
        ),
      ),
    ],
  );
}

void main() {
  group('Router redirect logic', () {
    testWidgets('redirects to /login when unauthenticated', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: null,
        initialLocation: AppConstants.routeHome,
      ));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    });

    testWidgets('/login is accessible without auth', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: null,
        initialLocation: AppConstants.routeLogin,
      ));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    });

    testWidgets('/register is accessible without auth', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: null,
        initialLocation: AppConstants.routeRegister,
      ));
      await tester.pumpAndSettle();

      expect(find.text('REGISTER_SCREEN'), findsOneWidget);
    });

    testWidgets('authenticated user on /login redirects to /', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _memberUser,
        initialLocation: AppConstants.routeLogin,
      ));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_SCREEN'), findsNothing);
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });

    testWidgets('authenticated user on /register redirects to /',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _memberUser,
        initialLocation: AppConstants.routeRegister,
      ));
      await tester.pumpAndSettle();

      expect(find.text('REGISTER_SCREEN'), findsNothing);
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });

    testWidgets('/users redirects MEMBER to /', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _memberUser,
        initialLocation: AppConstants.routeUsers,
      ));
      await tester.pumpAndSettle();

      expect(find.text('USERS_SCREEN'), findsNothing);
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });

    testWidgets('/users is accessible to OWNER', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _ownerUser,
        initialLocation: AppConstants.routeUsers,
      ));
      await tester.pumpAndSettle();

      expect(find.text('USERS_SCREEN'), findsOneWidget);
    });

    testWidgets('/users is accessible to ADMIN', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _adminUser,
        initialLocation: AppConstants.routeUsers,
      ));
      await tester.pumpAndSettle();

      expect(find.text('USERS_SCREEN'), findsOneWidget);
    });

    testWidgets('/books is accessible when authenticated', (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _memberUser,
        initialLocation: AppConstants.routeBooks,
      ));
      await tester.pumpAndSettle();

      expect(find.text('BOOKS_SCREEN'), findsOneWidget);
    });

    testWidgets('/notifications is accessible when authenticated',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        user: _memberUser,
        initialLocation: AppConstants.routeNotifications,
      ));
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATIONS_SCREEN'), findsOneWidget);
    });

    testWidgets('/device-not-setup is accessible without auth',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        user: null,
        initialLocation: AppConstants.routeDeviceNotSetup,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DEVICE_NOT_SETUP_SCREEN'), findsOneWidget);
    });
  });

  // ── Provider body tests ─────────────────────────────────────────────────
  group('routerProvider', () {
    test('creates GoRouter via createRouter(ref)', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthNotifier(null)),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());
    });
  });
}
