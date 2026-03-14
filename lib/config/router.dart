import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/features/auth/device_not_setup_screen.dart';
import 'package:myoffgridai_client/features/auth/login_screen.dart';
import 'package:myoffgridai_client/features/auth/register_screen.dart';
import 'package:myoffgridai_client/features/auth/users_screen.dart';
import 'package:myoffgridai_client/shared/widgets/app_shell.dart';

/// Stub screen used for MC-002 feature placeholders.
class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Coming soon')),
    );
  }
}

/// Creates the application [GoRouter] with auth guards and device status checks.
///
/// Unauthenticated users are redirected to [LoginScreen]. If the device
/// is not initialized, all users are redirected to [DeviceNotSetupScreen].
GoRouter createRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppConstants.routeHome,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeRegister ||
          state.matchedLocation == AppConstants.routeDeviceNotSetup;

      if (!isLoggedIn && !isAuthRoute) {
        return AppConstants.routeLogin;
      }

      if (isLoggedIn && (state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeRegister)) {
        return AppConstants.routeHome;
      }

      // Users screen: OWNER or ADMIN only
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDeviceNotSetup,
        builder: (context, state) => const DeviceNotSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeHome,
            builder: (context, state) => const _StubScreen(title: 'Chat'),
          ),
          GoRoute(
            path: AppConstants.routeChat,
            builder: (context, state) => const _StubScreen(title: 'Chat'),
          ),
          GoRoute(
            path: AppConstants.routeChatConversation,
            builder: (context, state) => _StubScreen(
              title: 'Conversation ${state.pathParameters['conversationId'] ?? ''}',
            ),
          ),
          GoRoute(
            path: AppConstants.routeMemory,
            builder: (context, state) => const _StubScreen(title: 'Memory'),
          ),
          GoRoute(
            path: AppConstants.routeKnowledge,
            builder: (context, state) => const _StubScreen(title: 'Knowledge'),
          ),
          GoRoute(
            path: AppConstants.routeSkills,
            builder: (context, state) => const _StubScreen(title: 'Skills'),
          ),
          GoRoute(
            path: AppConstants.routeInventory,
            builder: (context, state) => const _StubScreen(title: 'Inventory'),
          ),
          GoRoute(
            path: AppConstants.routeSensors,
            builder: (context, state) => const _StubScreen(title: 'Sensors'),
          ),
          GoRoute(
            path: AppConstants.routeInsights,
            builder: (context, state) => const _StubScreen(title: 'Insights'),
          ),
          GoRoute(
            path: AppConstants.routePrivacy,
            builder: (context, state) => const _StubScreen(title: 'Privacy'),
          ),
          GoRoute(
            path: AppConstants.routeSystem,
            builder: (context, state) => const _StubScreen(title: 'System'),
          ),
          GoRoute(
            path: AppConstants.routeUsers,
            builder: (context, state) => const UsersScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Riverpod provider for the application [GoRouter].
final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});
