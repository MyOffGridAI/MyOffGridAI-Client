import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/shared/widgets/system_status_bar.dart';

class MockSystemService extends Mock implements SystemService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AiSettingsModel(modelName: 'fallback'));
  });

  Widget buildBar({
    OllamaHealthDto? health,
    int unread = 0,
    List<OllamaModelInfoModel> models = const [],
    AiSettingsModel? aiSettings,
    bool healthError = false,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SystemStatusBar()),
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const Scaffold(body: Text('Insights')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        if (healthError)
          modelHealthProvider.overrideWith(
            (ref) => throw const ApiException(
                statusCode: 500, message: 'Server error'),
          )
        else
          modelHealthProvider.overrideWith(
            (ref) =>
                health ??
                const OllamaHealthDto(
                  available: true,
                  activeModel: 'llama3',
                ),
          ),
        unreadCountProvider.overrideWith((ref) => unread),
        ollamaModelsProvider.overrideWith((ref) => models),
        aiSettingsProvider.overrideWith(
          (ref) =>
              aiSettings ?? const AiSettingsModel(modelName: 'llama3'),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SystemStatusBar', () {
    testWidgets('shows green dot when available', (tester) async {
      await tester.pumpWidget(buildBar(
        health: const OllamaHealthDto(
          available: true,
          activeModel: 'llama3',
        ),
      ));
      await tester.pumpAndSettle();

      // Green dot for available
      final greenIcons = tester.widgetList<Icon>(find.byIcon(Icons.circle));
      final greenIcon =
          greenIcons.firstWhere((icon) => icon.color == Colors.green);
      expect(greenIcon, isNotNull);
    });

    testWidgets('shows red dot when unavailable', (tester) async {
      await tester.pumpWidget(buildBar(
        health: const OllamaHealthDto(available: false),
      ));
      await tester.pumpAndSettle();

      final redIcons = tester.widgetList<Icon>(find.byIcon(Icons.circle));
      final redIcon = redIcons.firstWhere((icon) => icon.color == Colors.red);
      expect(redIcon, isNotNull);
    });

    testWidgets('shows model name text', (tester) async {
      await tester.pumpWidget(buildBar(
        health: const OllamaHealthDto(
          available: true,
          activeModel: 'gemma2:7b',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('gemma2:7b'), findsOneWidget);
    });

    testWidgets('shows "No model" when activeModel is null', (tester) async {
      await tester.pumpWidget(buildBar(
        health: const OllamaHealthDto(available: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No model'), findsOneWidget);
    });

    testWidgets('shows Offline when health errors', (tester) async {
      await tester.pumpWidget(buildBar(healthError: true));
      await tester.pumpAndSettle();

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('shows notification icon', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows dropdown arrow for model selector', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('popup shows "No models available" when list empty',
        (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      // Tap the model name area (the PopupMenuButton)
      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      expect(find.text('No models available'), findsOneWidget);
    });

    testWidgets('popup shows model list when available', (tester) async {
      await tester.pumpWidget(buildBar(
        models: [
          const OllamaModelInfoModel(name: 'llama3', size: 4000000000),
          const OllamaModelInfoModel(name: 'gemma2', size: 2000000000),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      expect(find.text('gemma2'), findsOneWidget);
      // Size formatting: 4000000000 bytes = ~3.7 GB
      expect(find.textContaining('GB'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows check mark on active model in popup', (tester) async {
      await tester.pumpWidget(buildBar(
        models: [
          const OllamaModelInfoModel(name: 'llama3', size: 4000000000),
          const OllamaModelInfoModel(name: 'gemma2', size: 2000000000),
        ],
        aiSettings: const AiSettingsModel(modelName: 'llama3'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('popup shows MB size format', (tester) async {
      await tester.pumpWidget(buildBar(
        models: [
          const OllamaModelInfoModel(name: 'small-model', size: 5242880), // 5 MB
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      expect(find.textContaining('MB'), findsOneWidget);
    });

    testWidgets('popup shows KB size format', (tester) async {
      await tester.pumpWidget(buildBar(
        models: [
          const OllamaModelInfoModel(name: 'tiny-model', size: 512000), // ~500 KB
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      expect(find.textContaining('KB'), findsOneWidget);
    });

    testWidgets('tapping model in popup calls updateAiSettings', (tester) async {
      final mockService = MockSystemService();
      when(() => mockService.updateAiSettings(any()))
          .thenAnswer((_) async => const AiSettingsModel(modelName: 'gemma2'));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SystemStatusBar()),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) =>
                const Scaffold(body: Text('Insights')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          modelHealthProvider.overrideWith(
            (ref) => const OllamaHealthDto(
              available: true,
              activeModel: 'llama3',
            ),
          ),
          unreadCountProvider.overrideWith((ref) => 0),
          ollamaModelsProvider.overrideWith((ref) => [
                const OllamaModelInfoModel(name: 'llama3', size: 4000000000),
                const OllamaModelInfoModel(name: 'gemma2', size: 2000000000),
              ]),
          aiSettingsProvider.overrideWith(
            (ref) => const AiSettingsModel(modelName: 'llama3'),
          ),
          systemServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      // Select different model
      await tester.tap(find.text('gemma2'));
      await tester.pumpAndSettle();

      verify(() => mockService.updateAiSettings(any())).called(1);
    });

    testWidgets('shows error snackbar when model switch fails', (tester) async {
      final mockService = MockSystemService();
      when(() => mockService.updateAiSettings(any()))
          .thenThrow(const ApiException(statusCode: 500, message: 'Failed'));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SystemStatusBar()),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) =>
                const Scaffold(body: Text('Insights')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          modelHealthProvider.overrideWith(
            (ref) => const OllamaHealthDto(
              available: true,
              activeModel: 'llama3',
            ),
          ),
          unreadCountProvider.overrideWith((ref) => 0),
          ollamaModelsProvider.overrideWith((ref) => [
                const OllamaModelInfoModel(name: 'llama3', size: 4000000000),
                const OllamaModelInfoModel(name: 'gemma2', size: 2000000000),
              ]),
          aiSettingsProvider.overrideWith(
            (ref) => const AiSettingsModel(modelName: 'llama3'),
          ),
          systemServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('llama3'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('gemma2'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to switch model'), findsOneWidget);
    });

    testWidgets('notification icon tap navigates to insights', (tester) async {
      await tester.pumpWidget(buildBar(unread: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsOneWidget);
    });

    testWidgets('uses health.activeModel as fallback when aiSettings is null',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SystemStatusBar()),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) =>
                const Scaffold(body: Text('Insights')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          modelHealthProvider.overrideWith(
            (ref) => const OllamaHealthDto(
              available: true,
              activeModel: 'fallback-model',
            ),
          ),
          unreadCountProvider.overrideWith((ref) => 0),
          ollamaModelsProvider.overrideWith((ref) => [
                const OllamaModelInfoModel(
                    name: 'fallback-model', size: 4000000000),
              ]),
          aiSettingsProvider
              .overrideWith((ref) => throw Exception('no settings')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.text('fallback-model'));
      await tester.pumpAndSettle();

      // The active model should have a check mark based on health.activeModel fallback
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows notification icon in error state', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SystemStatusBar()),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) =>
                const Scaffold(body: Text('Insights')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          modelHealthProvider.overrideWith(
            (ref) => const OllamaHealthDto(available: true, activeModel: 'llama3'),
          ),
          unreadCountProvider.overrideWith(
            (ref) => throw const ApiException(statusCode: 500, message: 'err'),
          ),
          ollamaModelsProvider.overrideWith((ref) => []),
          aiSettingsProvider.overrideWith(
            (ref) => const AiSettingsModel(modelName: 'llama3'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // notification icon should still be shown in error state
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows loading indicator when health is loading',
        (tester) async {
      final completer = Completer<OllamaHealthDto>();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SystemStatusBar()),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) =>
                const Scaffold(body: Text('Insights')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          modelHealthProvider.overrideWith((ref) => completer.future),
          unreadCountProvider.overrideWith((ref) => 0),
          ollamaModelsProvider.overrideWith((ref) => []),
          aiSettingsProvider.overrideWith(
            (ref) => const AiSettingsModel(modelName: 'llama3'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(
          const OllamaHealthDto(available: true, activeModel: 'llama3'));
    });

    testWidgets('shows notification icon in loading state', (tester) async {
      final completer = Completer<int>();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SystemStatusBar()),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) =>
                const Scaffold(body: Text('Insights')),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          modelHealthProvider.overrideWith(
            (ref) => const OllamaHealthDto(
                available: true, activeModel: 'llama3'),
          ),
          unreadCountProvider.overrideWith((ref) => completer.future),
          ollamaModelsProvider.overrideWith((ref) => []),
          aiSettingsProvider.overrideWith(
            (ref) => const AiSettingsModel(modelName: 'llama3'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();

      // Notification icon should still show while count is loading
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      completer.complete(0);
    });
  });
}
