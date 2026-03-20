import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/features/auth/device_not_setup_screen.dart';
import 'package:myoffgridai_client/features/auth/login_screen.dart';
import 'package:myoffgridai_client/features/auth/register_screen.dart';
import 'package:myoffgridai_client/features/auth/users_screen.dart';
import 'package:myoffgridai_client/features/books/book_reader_screen.dart';
import 'package:myoffgridai_client/features/books/books_screen.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/features/chat/chat_conversation_screen.dart';
import 'package:myoffgridai_client/features/chat/chat_list_screen.dart';
import 'package:myoffgridai_client/features/conversations/conversations_screen.dart';
import 'package:myoffgridai_client/features/insights/insights_screen.dart';
import 'package:myoffgridai_client/features/notifications/notifications_screen.dart';
import 'package:myoffgridai_client/features/inventory/inventory_screen.dart';
import 'package:myoffgridai_client/features/knowledge/document_detail_screen.dart';
import 'package:myoffgridai_client/features/knowledge/document_editor_screen.dart';
import 'package:myoffgridai_client/features/knowledge/document_viewer_screen.dart';
import 'package:myoffgridai_client/features/knowledge/knowledge_screen.dart';
import 'package:myoffgridai_client/features/memory/memory_screen.dart';
import 'package:myoffgridai_client/features/privacy/privacy_screen.dart';
import 'package:myoffgridai_client/features/search/search_screen.dart';
import 'package:myoffgridai_client/features/sensors/add_sensor_screen.dart';
import 'package:myoffgridai_client/features/sensors/sensor_detail_screen.dart';
import 'package:myoffgridai_client/features/events/events_screen.dart';
import 'package:myoffgridai_client/features/sensors/sensors_screen.dart';
import 'package:myoffgridai_client/features/settings/settings_screen.dart';
import 'package:myoffgridai_client/features/skills/skills_screen.dart';
import 'package:myoffgridai_client/features/system/system_screen.dart';
import 'package:myoffgridai_client/shared/widgets/app_shell.dart';

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
          // Chat routes — no longer wrapped in ChatShell;
          // sidebar is now part of NavigationPanel inside AppShell.
          GoRoute(
            path: AppConstants.routeHome,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
          GoRoute(
            path: AppConstants.routeChat,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
          GoRoute(
            path: AppConstants.routeChatConversation,
            pageBuilder: (context, state) => NoTransitionPage(
              child: ChatConversationScreen(
                conversationId:
                    state.pathParameters['conversationId'] ?? '',
                initialMessage: state.extra as String?,
              ),
            ),
          ),
          GoRoute(
            path: AppConstants.routeConversations,
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSettings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSearch,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppConstants.routeBooks,
            builder: (context, state) => const BooksScreen(),
          ),
          GoRoute(
            path: AppConstants.routeBookReader,
            builder: (context, state) => BookReaderScreen(
              ebook: state.extra as EbookModel,
            ),
          ),
          GoRoute(
            path: AppConstants.routeMemory,
            builder: (context, state) => const MemoryScreen(),
          ),
          GoRoute(
            path: AppConstants.routeKnowledge,
            builder: (context, state) => const KnowledgeScreen(),
          ),
          GoRoute(
            path: AppConstants.routeKnowledgeNew,
            builder: (context, state) => const DocumentEditorScreen(),
          ),
          GoRoute(
            path: AppConstants.routeKnowledgeEdit,
            builder: (context, state) => DocumentEditorScreen(
              documentId: state.pathParameters['documentId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppConstants.routeKnowledgeView,
            builder: (context, state) => DocumentViewerScreen(
              documentId: state.pathParameters['documentId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppConstants.routeKnowledgeDetail,
            builder: (context, state) => DocumentDetailScreen(
              documentId: state.pathParameters['documentId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppConstants.routeSkills,
            builder: (context, state) => const SkillsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeInventory,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSensors,
            builder: (context, state) => const SensorsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSensorAdd,
            builder: (context, state) => const AddSensorScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSensorDetail,
            builder: (context, state) => SensorDetailScreen(
              sensorId: state.pathParameters['sensorId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppConstants.routeEvents,
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeInsights,
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: AppConstants.routeNotifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppConstants.routePrivacy,
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: AppConstants.routeSystem,
            builder: (context, state) => const SystemScreen(),
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
