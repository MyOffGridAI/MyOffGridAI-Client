import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/skill_model.dart';
import 'package:myoffgridai_client/core/services/skills_service.dart';
import 'package:myoffgridai_client/features/skills/skills_screen.dart';

class MockSkillsService extends Mock implements SkillsService {}

void main() {
  late MockSkillsService mockService;

  final enabledBuiltIn = SkillModel.fromJson({
    'id': '1',
    'name': 'weather_check',
    'displayName': 'Weather Check',
    'description': 'Check the weather',
    'isEnabled': true,
    'isBuiltIn': true,
    'category': 'UTILITY',
    'version': '1.0.0',
    'author': 'System',
  });

  final disabledCustom = SkillModel.fromJson({
    'id': '2',
    'name': 'backup',
    'displayName': 'System Backup',
    'description': 'Backup system data',
    'isEnabled': false,
    'isBuiltIn': false,
    'category': 'ADMIN',
  });

  setUp(() {
    mockService = MockSkillsService();
    registerFallbackValue('');
  });

  Widget buildScreen({List<SkillModel> skills = const []}) {
    return ProviderScope(
      overrides: [
        skillsProvider.overrideWith((ref) => skills),
        skillsServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: SkillsScreen()),
    );
  }

  group('SkillsScreen', () {
    testWidgets('shows empty state when no skills', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No skills available'), findsOneWidget);
    });

    testWidgets('displays skills grid', (tester) async {
      await tester.pumpWidget(
          buildScreen(skills: [enabledBuiltIn, disabledCustom]));
      await tester.pumpAndSettle();

      expect(find.text('Weather Check'), findsOneWidget);
      expect(find.text('System Backup'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Skills'), findsOneWidget);
    });

    testWidgets('shows Built-in chip for built-in skills', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      expect(find.text('Built-in'), findsOneWidget);
    });

    testWidgets('hides Built-in chip for custom skills', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [disabledCustom]));
      await tester.pumpAndSettle();

      expect(find.text('Built-in'), findsNothing);
    });

    testWidgets('shows description', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      expect(find.text('Check the weather'), findsOneWidget);
    });

    testWidgets('shows category text', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      expect(find.text('UTILITY'), findsOneWidget);
    });

    testWidgets('shows check_circle for enabled skills', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows cancel_outlined for disabled skills', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [disabledCustom]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });

  group('SkillsScreen error state', () {
    testWidgets('shows API error message', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          skillsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Server down')),
          skillsServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SkillsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load skills'), findsOneWidget);
      expect(find.text('Server down'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          skillsProvider.overrideWith((ref) => throw Exception('unknown')),
          skillsServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SkillsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load skills'), findsOneWidget);
      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          skillsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          skillsServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SkillsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Skill detail sheet', () {
    testWidgets('opens on card tap', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weather Check'));
      await tester.pumpAndSettle();

      // Sheet should show the skill display name as headline
      expect(find.text('Weather Check'), findsWidgets);
      expect(find.text('Check the weather'), findsWidgets);
    });

    testWidgets('shows version and author', (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weather Check'));
      await tester.pumpAndSettle();

      expect(find.text('Version: 1.0.0'), findsOneWidget);
      expect(find.text('Author: System'), findsOneWidget);
    });

    testWidgets('shows enabled Execute button for enabled skill',
        (tester) async {
      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weather Check'));
      await tester.pumpAndSettle();

      expect(find.text('Execute'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Execute'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows disabled Execute button for disabled skill',
        (tester) async {
      await tester.pumpWidget(buildScreen(skills: [disabledCustom]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Execute'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Execute'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('execute shows result on success', (tester) async {
      when(() => mockService.executeSkill('1')).thenAnswer(
        (_) async => const SkillExecutionModel(
          id: 'exec-1',
          skillId: '1',
          skillName: 'weather_check',
          status: 'SUCCESS',
          outputResult: 'Sunny, 72F',
          durationMs: 250,
        ),
      );

      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weather Check'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Execute'));
      await tester.pumpAndSettle();

      verify(() => mockService.executeSkill('1')).called(1);
      expect(find.text('Status: SUCCESS'), findsOneWidget);
      expect(find.text('Result: Sunny, 72F'), findsOneWidget);
      expect(find.text('Duration: 250ms'), findsOneWidget);
    });

    testWidgets('execute shows error result on failure', (tester) async {
      when(() => mockService.executeSkill('1')).thenAnswer(
        (_) async => const SkillExecutionModel(
          id: 'exec-2',
          skillId: '1',
          skillName: 'weather_check',
          status: 'FAILED',
          errorMessage: 'Connection timeout',
        ),
      );

      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weather Check'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Execute'));
      await tester.pumpAndSettle();

      expect(find.text('Status: FAILED'), findsOneWidget);
      expect(find.text('Error: Connection timeout'), findsOneWidget);
    });

    testWidgets('shows error SnackBar on API exception', (tester) async {
      when(() => mockService.executeSkill('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Execution failed'),
      );

      await tester.pumpWidget(buildScreen(skills: [enabledBuiltIn]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weather Check'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Execute'));
      await tester.pumpAndSettle();

      expect(find.text('Execution failed'), findsOneWidget);
    });
  });

  group('Loading state', () {
    testWidgets('shows loading indicator while skills load', (tester) async {
      final completer = Completer<List<SkillModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          skillsProvider.overrideWith((ref) => completer.future),
          skillsServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SkillsScreen()),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(<SkillModel>[]);
    });
  });

  group('Error retry', () {
    testWidgets('retry button reloads skills after error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          skillsProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          skillsServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: SkillsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load skills'), findsOneWidget);
    });
  });
}
