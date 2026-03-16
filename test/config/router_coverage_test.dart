import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/config/router.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/auth/secure_storage_service.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements MyOffGridAIApiClient {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockChatService extends Mock implements ChatService {}

class MockLibraryService extends Mock implements LibraryService {}

class MockSystemService extends Mock implements SystemService {}

// ── Fake Auth Notifier ───────────────────────────────────────────────────────

/// A fake [AuthNotifier] that resolves immediately with a predetermined user.
/// Uses [SynchronousFuture]-like behavior by returning a completed future.
class _FakeAuthNotifier extends AuthNotifier {
  final UserModel? _user;
  _FakeAuthNotifier(this._user);

  @override
  Future<UserModel?> build() {
    // Return an already-completed future so the state transitions to
    // AsyncData on the very first microtask, before the router redirect fires.
    return Future.value(_user);
  }

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

// ── Test Users ───────────────────────────────────────────────────────────────

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

// ── Provider overrides shared by all tests ───────────────────────────────────

List<Override> _commonOverrides({
  required UserModel? user,
  MockLibraryService? libraryService,
}) {
  final mockApi = MockApiClient();
  final mockStorage = MockSecureStorageService();
  final mockChat = MockChatService();
  final mockLibrary = libraryService ?? MockLibraryService();
  final mockSystem = MockSystemService();

  when(() => mockStorage.getServerUrl())
      .thenAnswer((_) async => 'http://localhost:8080');
  when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);
  when(() => mockStorage.getThemePreference())
      .thenAnswer((_) async => 'system');
  when(() => mockStorage.saveThemePreference(any()))
      .thenAnswer((_) async {});

  return [
    authStateProvider.overrideWith(() => _FakeAuthNotifier(user)),
    apiClientProvider.overrideWithValue(mockApi),
    secureStorageProvider.overrideWithValue(mockStorage),
    chatServiceProvider.overrideWithValue(mockChat),
    libraryServiceProvider.overrideWithValue(mockLibrary),
    systemServiceProvider.overrideWithValue(mockSystem),
    connectionStatusProvider.overrideWith((ref) {
      final controller = StreamController<bool>();
      controller.add(true);
      ref.onDispose(() => controller.close());
      return controller.stream;
    }),
    modelHealthProvider.overrideWith((ref) async =>
        const OllamaHealthDto(available: true, activeModel: 'test-model')),
    unreadCountProvider.overrideWith((ref) async => 0),
    ollamaModelsProvider
        .overrideWith((ref) async => <OllamaModelInfoModel>[]),
    aiSettingsProvider.overrideWith((ref) async => const AiSettingsModel(
          modelName: 'test-model',
          temperature: 0.7,
          similarityThreshold: 0.45,
          memoryTopK: 5,
          ragMaxContextTokens: 2048,
        )),
    conversationsProvider.overrideWith((ref) async => []),
    sidebarCollapsedProvider.overrideWith((ref) => false),
  ];
}

/// Builds a MaterialApp.router using the REAL routerProvider.
Widget _buildRouterApp({
  required UserModel? user,
  MockLibraryService? libraryService,
}) {
  return ProviderScope(
    overrides: _commonOverrides(user: user, libraryService: libraryService),
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        );
      },
    ),
  );
}

/// Navigates to [path] using the GoRouter from within the widget tree.
Future<void> _navigateTo(WidgetTester tester, String path) async {
  final scaffoldFinder = find.byType(Scaffold);
  expect(scaffoldFinder, findsWidgets);
  final context = tester.element(scaffoldFinder.first);
  GoRouter.of(context).go(path);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0);
  });

  group('createRouter - redirect logic (real provider)', () {
    testWidgets('unauthenticated user at / redirects to /login',
        (tester) async {
      await tester.pumpWidget(_buildRouterApp(user: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('Login'), findsWidgets);
    });

    testWidgets('authenticated user can reach home', (tester) async {
      // Increase surface size to avoid overflow from NavigationPanel
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      // Let auth state resolve
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // After auth resolves, navigate to home explicitly
      await _navigateTo(tester, AppConstants.routeHome);

      expect(find.text('How can I help you today?'), findsOneWidget);
    });

    testWidgets('authenticated MEMBER at /users redirects to home',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeUsers);

      // MEMBER should be redirected to home
      expect(find.text('How can I help you today?'), findsOneWidget);
    });

    testWidgets('authenticated OWNER can access /users', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _ownerUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeUsers);

      expect(find.text('Users'), findsWidgets);
    });

    testWidgets('authenticated ADMIN can access /users', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _adminUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeUsers);

      expect(find.text('Users'), findsWidgets);
    });

    testWidgets('unauthenticated user sees register screen', (tester) async {
      await tester.pumpWidget(_buildRouterApp(user: null));
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeRegister);

      expect(find.textContaining('Register'), findsWidgets);
    });

    testWidgets('authenticated user on /register redirects to home',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeRegister);

      expect(find.text('How can I help you today?'), findsOneWidget);
    });

    testWidgets('unauthenticated user can access /device-not-setup',
        (tester) async {
      await tester.pumpWidget(_buildRouterApp(user: null));
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeDeviceNotSetup);

      expect(find.text('MyOffGrid AI Not Set Up'), findsOneWidget);
    });

    testWidgets('authenticated user on /login redirects to home',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeLogin);

      expect(find.text('How can I help you today?'), findsOneWidget);
    });
  });

  group('createRouter - route builders (real provider)', () {
    testWidgets('/chat renders ChatListScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeChat);

      expect(find.text('How can I help you today?'), findsOneWidget);
    });

    testWidgets('/settings renders SettingsScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeSettings);

      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('/books renders BooksScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockLibrary = MockLibraryService();
      when(() => mockLibrary.listEbooks(
            search: any(named: 'search'),
            format: any(named: 'format'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => <EbookModel>[]);
      when(() => mockLibrary.getKiwixStatus())
          .thenAnswer((_) async => const KiwixStatusModel(
                available: false,
                bookCount: 0,
              ));

      await tester.pumpWidget(
          _buildRouterApp(user: _memberUser, libraryService: mockLibrary));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeBooks);

      expect(find.text('Books'), findsWidgets);
    });

    testWidgets('/knowledge renders KnowledgeScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeKnowledge);

      expect(find.text('Knowledge Vault'), findsWidgets);
    });

    testWidgets('/memory renders MemoryScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeMemory);

      expect(find.text('Memory'), findsWidgets);
    });

    testWidgets('/skills renders SkillsScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeSkills);

      expect(find.text('Skills'), findsWidgets);
    });

    testWidgets('/inventory renders InventoryScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeInventory);

      expect(find.text('Inventory'), findsWidgets);
    });

    testWidgets('/sensors renders SensorsScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeSensors);

      expect(find.text('Sensors'), findsWidgets);
    });

    testWidgets('/sensors/add renders AddSensorScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeSensorAdd);

      expect(find.textContaining('Sensor'), findsWidgets);
    });

    testWidgets('/sensors/:sensorId renders SensorDetailScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, '/sensors/test-sensor-id');

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('/events renders EventsScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeEvents);

      expect(find.text('Events'), findsWidgets);
    });

    testWidgets('/insights renders InsightsScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeInsights);

      expect(find.text('Insights'), findsWidgets);
    });

    testWidgets('/notifications renders NotificationsScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeNotifications);

      expect(find.text('Notifications'), findsWidgets);
    });

    testWidgets('/privacy renders PrivacyScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routePrivacy);

      expect(find.text('Privacy'), findsWidgets);
    });

    testWidgets('/system renders SystemScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeSystem);

      expect(find.text('System'), findsWidgets);
    });

    testWidgets('/search renders SearchScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeSearch);

      expect(find.text('Search'), findsWidgets);
    });

    testWidgets('/knowledge/new renders DocumentEditorScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, AppConstants.routeKnowledgeNew);

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('/knowledge/:documentId renders DocumentDetailScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, '/knowledge/test-doc-id');

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('/knowledge/:docId/edit renders DocumentEditorScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, '/knowledge/test-doc-id/edit');

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('/chat/:conversationId renders ChatConversationScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildRouterApp(user: _memberUser));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      await _navigateTo(tester, '/chat/test-conv-id');

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
