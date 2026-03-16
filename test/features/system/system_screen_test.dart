import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/features/system/system_screen.dart';

void main() {
  Widget buildScreen({
    SystemStatusModel? status,
    OllamaHealthDto? health,
    List<OllamaModelInfoModel>? models,
  }) {
    return ProviderScope(
      overrides: [
        systemStatusDetailProvider.overrideWith((ref) =>
            status ??
            const SystemStatusModel(
              initialized: true,
              fortressEnabled: true,
              wifiConfigured: true,
            )),
        modelHealthProvider.overrideWith((ref) =>
            health ?? const OllamaHealthDto(available: true)),
        ollamaModelsProvider.overrideWith((ref) => models ?? []),
      ],
      child: const MaterialApp(home: SystemScreen()),
    );
  }

  group('SystemScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('shows system status section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('System Status'), findsOneWidget);
    });

    testWidgets('shows inference provider section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Inference Provider'), findsOneWidget);
    });

    testWidgets('shows models section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Models'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('Refresh and errors', () {
    testWidgets('refresh button invalidates providers', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Screen should still be visible after refresh
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('shows status error view', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith(
            (ref) => throw const ApiException(
                statusCode: 500, message: 'Status error'),
          ),
          modelHealthProvider.overrideWith(
              (ref) => const OllamaHealthDto(available: true)),
          ollamaModelsProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load status'), findsOneWidget);
      expect(find.text('Status error'), findsOneWidget);
    });

    testWidgets('shows generic status error for non-API exception',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider
              .overrideWith((ref) => throw Exception('unknown')),
          modelHealthProvider.overrideWith(
              (ref) => const OllamaHealthDto(available: true)),
          ollamaModelsProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows health error card', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith((ref) =>
              const SystemStatusModel(
                initialized: true,
                fortressEnabled: true,
                wifiConfigured: true,
              )),
          modelHealthProvider.overrideWith(
              (ref) => throw Exception('ollama down')),
          ollamaModelsProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Inference provider unavailable'), findsOneWidget);
    });

    testWidgets('shows models error text', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith((ref) =>
              const SystemStatusModel(
                initialized: true,
                fortressEnabled: true,
                wifiConfigured: true,
              )),
          modelHealthProvider.overrideWith(
              (ref) => const OllamaHealthDto(available: true)),
          ollamaModelsProvider
              .overrideWith((ref) => throw Exception('model error')),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load models'), findsOneWidget);
    });
  });

  group('System status', () {
    testWidgets('shows initialized check_circle when true', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: const SystemStatusModel(
          initialized: true,
          fortressEnabled: false,
          wifiConfigured: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Initialized'), findsOneWidget);
      // At least one check_circle for initialized
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows cancel icon when not initialized', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: const SystemStatusModel(
          initialized: false,
          fortressEnabled: false,
          wifiConfigured: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Initialized'), findsOneWidget);
      // All three are false, so three cancel icons
      expect(find.byIcon(Icons.cancel), findsNWidgets(3));
    });

    testWidgets('shows fortress status row', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Fortress'), findsOneWidget);
    });

    testWidgets('shows WiFi status row', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('WiFi'), findsOneWidget);
    });

    testWidgets('shows instance name when present', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: const SystemStatusModel(
          initialized: true,
          fortressEnabled: true,
          wifiConfigured: true,
          instanceName: 'offgrid-1',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Instance'), findsOneWidget);
      expect(find.text('offgrid-1'), findsOneWidget);
    });

    testWidgets('shows server version when present', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: const SystemStatusModel(
          initialized: true,
          fortressEnabled: true,
          wifiConfigured: true,
          serverVersion: '2.1.0',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('2.1.0'), findsOneWidget);
    });

    testWidgets('hides instance name when null', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: const SystemStatusModel(
          initialized: true,
          fortressEnabled: true,
          wifiConfigured: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Instance'), findsNothing);
    });
  });

  group('Ollama health', () {
    testWidgets('shows available status for healthy ollama', (tester) async {
      await tester.pumpWidget(buildScreen(
        health: const OllamaHealthDto(available: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('shows unavailable status for unhealthy ollama',
        (tester) async {
      await tester.pumpWidget(buildScreen(
        health: const OllamaHealthDto(available: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('shows active model when present', (tester) async {
      await tester.pumpWidget(buildScreen(
        health: const OllamaHealthDto(
          available: true,
          activeModel: 'llama3:8b',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Active Model'), findsOneWidget);
      expect(find.text('llama3:8b'), findsOneWidget);
    });

    testWidgets('shows embed model when present', (tester) async {
      await tester.pumpWidget(buildScreen(
        health: const OllamaHealthDto(
          available: true,
          embedModelName: 'nomic-embed-text',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Embed Model'), findsOneWidget);
      expect(find.text('nomic-embed-text'), findsOneWidget);
    });

    testWidgets('shows response time when present', (tester) async {
      await tester.pumpWidget(buildScreen(
        health: const OllamaHealthDto(
          available: true,
          responseTimeMs: 250,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Response Time'), findsOneWidget);
      expect(find.text('250ms'), findsOneWidget);
    });
  });

  group('Models', () {
    testWidgets('shows no models message when empty', (tester) async {
      await tester.pumpWidget(buildScreen(models: []));
      await tester.pumpAndSettle();

      expect(find.text('No models installed'), findsOneWidget);
    });

    testWidgets('displays model names', (tester) async {
      await tester.pumpWidget(buildScreen(
        models: [
          OllamaModelInfoModel.fromJson({
            'name': 'llama3:8b',
            'size': 4700000000,
          }),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('llama3:8b'), findsOneWidget);
    });

    testWidgets('displays multiple models', (tester) async {
      await tester.pumpWidget(buildScreen(
        models: [
          OllamaModelInfoModel.fromJson({
            'name': 'llama3:8b',
            'size': 4700000000,
          }),
          OllamaModelInfoModel.fromJson({
            'name': 'mistral:7b',
            'size': 4100000000,
          }),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('llama3:8b'), findsOneWidget);
      expect(find.text('mistral:7b'), findsOneWidget);
    });

    testWidgets('shows smart_toy icon for models', (tester) async {
      await tester.pumpWidget(buildScreen(
        models: [
          OllamaModelInfoModel.fromJson({
            'name': 'llama3:8b',
            'size': 4700000000,
          }),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });
  });

  group('Loading states', () {
    testWidgets('shows loading indicator for status section', (tester) async {
      final completer = Completer<SystemStatusModel>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith((ref) => completer.future),
          modelHealthProvider.overrideWith(
              (ref) => const OllamaHealthDto(available: true)),
          ollamaModelsProvider.overrideWith((ref) => <OllamaModelInfoModel>[]),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(const SystemStatusModel(
        initialized: true,
        fortressEnabled: true,
        wifiConfigured: true,
      ));
    });

    testWidgets('shows loading indicator for health section', (tester) async {
      final completer = Completer<OllamaHealthDto>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith((ref) =>
              const SystemStatusModel(
                initialized: true,
                fortressEnabled: true,
                wifiConfigured: true,
              )),
          modelHealthProvider.overrideWith((ref) => completer.future),
          ollamaModelsProvider.overrideWith((ref) => <OllamaModelInfoModel>[]),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(const OllamaHealthDto(available: true));
    });

    testWidgets('shows loading indicator for models section', (tester) async {
      final completer = Completer<List<OllamaModelInfoModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith((ref) =>
              const SystemStatusModel(
                initialized: true,
                fortressEnabled: true,
                wifiConfigured: true,
              )),
          modelHealthProvider.overrideWith(
              (ref) => const OllamaHealthDto(available: true)),
          ollamaModelsProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(<OllamaModelInfoModel>[]);
    });

    testWidgets('status error retry invalidates provider', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          systemStatusDetailProvider.overrideWith(
            (ref) => throw const ApiException(
                statusCode: 500, message: 'Status error'),
          ),
          modelHealthProvider.overrideWith(
              (ref) => const OllamaHealthDto(available: true)),
          ollamaModelsProvider.overrideWith((ref) => <OllamaModelInfoModel>[]),
        ],
        child: const MaterialApp(home: SystemScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Screen should still show error (provider re-throws)
      expect(find.text('Failed to load status'), findsOneWidget);
    });
  });
}
