import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/skill_model.dart';
import 'package:myoffgridai_client/core/services/skills_service.dart';
import 'package:myoffgridai_client/features/skills/skills_screen.dart';

void main() {
  group('SkillsScreen', () {
    Widget buildScreen({List<SkillModel> skills = const []}) {
      return ProviderScope(
        overrides: [
          skillsProvider.overrideWith((ref) => skills),
        ],
        child: const MaterialApp(home: SkillsScreen()),
      );
    }

    testWidgets('shows empty state when no skills', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No skills available'), findsOneWidget);
    });

    testWidgets('displays skills grid', (tester) async {
      final skills = [
        SkillModel.fromJson({
          'id': '1',
          'name': 'weather_check',
          'displayName': 'Weather Check',
          'description': 'Check the weather',
          'isEnabled': true,
          'isBuiltIn': true,
        }),
        SkillModel.fromJson({
          'id': '2',
          'name': 'backup',
          'displayName': 'System Backup',
          'description': 'Backup system data',
          'isEnabled': false,
          'isBuiltIn': false,
        }),
      ];

      await tester.pumpWidget(buildScreen(skills: skills));
      await tester.pumpAndSettle();

      expect(find.text('Weather Check'), findsOneWidget);
      expect(find.text('System Backup'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Skills'), findsOneWidget);
    });
  });
}
