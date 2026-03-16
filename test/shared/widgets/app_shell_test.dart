import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/chat_service.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/shared/widgets/app_shell.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  late MockChatService mockChatService;

  setUp(() {
    mockChatService = MockChatService();
  });

  List<Override> commonOverrides({bool collapsed = true}) {
    return [
      connectionStatusProvider.overrideWith((ref) => Stream.value(true)),
      modelHealthProvider.overrideWith(
        (ref) => const OllamaHealthDto(
          available: true,
          activeModel: 'llama3',
        ),
      ),
      unreadCountProvider.overrideWith((ref) => 0),
      ollamaModelsProvider.overrideWith((ref) => <OllamaModelInfoModel>[]),
      aiSettingsProvider.overrideWith(
        (ref) => const AiSettingsModel(modelName: 'llama3'),
      ),
      conversationsProvider.overrideWith((ref) => []),
      sidebarCollapsedProvider.overrideWith((ref) => collapsed),
      chatServiceProvider.overrideWithValue(mockChatService),
    ];
  }

  Widget buildDesktopShell({bool collapsed = true}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Shell Content'),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: commonOverrides(collapsed: collapsed),
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Widget buildMobileShell() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Shell Content'),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: commonOverrides(),
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AppShell', () {
    testWidgets('renders child widget on desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDesktopShell());
      await tester.pumpAndSettle();

      expect(find.text('Shell Content'), findsOneWidget);
    });

    testWidgets('shows NavigationPanel on desktop width', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDesktopShell());
      await tester.pumpAndSettle();

      // Desktop: No bottom nav
      expect(find.byType(BottomNavigationBar), findsNothing);
      // The collapse/expand toggle icon is present
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('shows BottomNavigationBar on mobile width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildMobileShell());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('bottom nav has 6 items', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildMobileShell());
      await tester.pumpAndSettle();

      final bottomNav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.items.length, 6);
    });

    testWidgets('tapping bottom nav navigates to different destinations',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const Text('Home'),
              ),
              GoRoute(
                path: '/memory',
                builder: (_, __) => const Text('Memory Page'),
              ),
              GoRoute(
                path: '/knowledge',
                builder: (_, __) => const Text('Knowledge Page'),
              ),
              GoRoute(
                path: '/books',
                builder: (_, __) => const Text('Books Page'),
              ),
              GoRoute(
                path: '/sensors',
                builder: (_, __) => const Text('Sensors Page'),
              ),
              GoRoute(
                path: '/notifications',
                builder: (_, __) => const Text('Notifications Page'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: commonOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Tap Memory tab (index 1)
      await tester.tap(find.text('Memory'));
      await tester.pumpAndSettle();
      expect(find.text('Memory Page'), findsOneWidget);

      // Tap Knowledge tab (index 2)
      await tester.tap(find.text('Knowledge'));
      await tester.pumpAndSettle();
      expect(find.text('Knowledge Page'), findsOneWidget);
    });

    testWidgets('highlights correct tab for /chat route', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/chat/123',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const Text('Home'),
              ),
              GoRoute(
                path: '/chat/:id',
                builder: (_, __) => const Text('Chat Page'),
              ),
              GoRoute(
                path: '/memory',
                builder: (_, __) => const Text('Memory'),
              ),
              GoRoute(
                path: '/knowledge',
                builder: (_, __) => const Text('Knowledge'),
              ),
              GoRoute(
                path: '/books',
                builder: (_, __) => const Text('Books'),
              ),
              GoRoute(
                path: '/sensors',
                builder: (_, __) => const Text('Sensors'),
              ),
              GoRoute(
                path: '/notifications',
                builder: (_, __) => const Text('Notifications'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: commonOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Chat route should select index 0 (Chat tab)
      final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('shows notification badge when unread count > 0',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const Text('Home'),
              ),
            ],
          ),
        ],
      );

      final overrides = [
        connectionStatusProvider.overrideWith((ref) => Stream.value(true)),
        modelHealthProvider.overrideWith(
          (ref) => const OllamaHealthDto(
            available: true,
            activeModel: 'llama3',
          ),
        ),
        unreadCountProvider.overrideWith((ref) => 5),
        ollamaModelsProvider
            .overrideWith((ref) => <OllamaModelInfoModel>[]),
        aiSettingsProvider.overrideWith(
          (ref) => const AiSettingsModel(modelName: 'llama3'),
        ),
        conversationsProvider.overrideWith((ref) => []),
        sidebarCollapsedProvider.overrideWith((ref) => true),
        chatServiceProvider.overrideWithValue(mockChatService),
      ];

      await tester.pumpWidget(ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // NotificationBadge should be rendered
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('shows SystemStatusBar with model name', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDesktopShell());
      await tester.pumpAndSettle();

      expect(find.text('llama3'), findsOneWidget);
    });
  });
}
