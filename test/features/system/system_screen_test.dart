import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/features/system/system_screen.dart';

void main() {
  group('SystemScreen', () {
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

    testWidgets('shows ollama health section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Ollama Health'), findsOneWidget);
    });

    testWidgets('shows models section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Models'), findsOneWidget);
    });

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

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows available status for healthy ollama', (tester) async {
      await tester.pumpWidget(buildScreen(
        health: const OllamaHealthDto(available: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
    });
  });
}
