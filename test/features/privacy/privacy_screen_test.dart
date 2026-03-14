import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/privacy_models.dart';
import 'package:myoffgridai_client/core/services/privacy_service.dart';
import 'package:myoffgridai_client/features/privacy/privacy_screen.dart';

void main() {
  group('PrivacyScreen', () {
    Widget buildScreen({
      FortressStatusModel? fortress,
      SovereigntyReportModel? report,
      List<AuditLogModel>? logs,
    }) {
      return ProviderScope(
        overrides: [
          fortressStatusProvider.overrideWith((ref) =>
              fortress ??
              const FortressStatusModel(enabled: true, verified: true)),
        ],
        child: const MaterialApp(home: PrivacyScreen()),
      );
    }

    testWidgets('shows tab bar with three tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Fortress'), findsOneWidget);
      expect(find.text('Sovereignty'), findsOneWidget);
      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Privacy Fortress'), findsOneWidget);
    });

    testWidgets('shows fortress enabled state', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: true, verified: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fortress ENABLED'), findsOneWidget);
    });

    testWidgets('shows fortress disabled state', (tester) async {
      await tester.pumpWidget(buildScreen(
        fortress: const FortressStatusModel(enabled: false, verified: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fortress DISABLED'), findsOneWidget);
    });

    testWidgets('shows wipe data option', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Wipe My Data'), findsOneWidget);
    });
  });
}
