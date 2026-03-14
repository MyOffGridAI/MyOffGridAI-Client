import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';
import 'package:myoffgridai_client/core/services/memory_service.dart';
import 'package:myoffgridai_client/features/memory/memory_screen.dart';

void main() {
  group('MemoryScreen', () {
    Widget buildScreen({List<MemoryModel> memories = const []}) {
      return ProviderScope(
        overrides: [
          memoriesProvider.overrideWith((ref) => memories),
        ],
        child: const MaterialApp(home: MemoryScreen()),
      );
    }

    testWidgets('shows empty state when no memories', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No memories yet'), findsOneWidget);
    });

    testWidgets('displays memories list', (tester) async {
      final memories = [
        MemoryModel.fromJson({
          'id': '1',
          'content': 'User prefers dark mode',
          'importance': 'HIGH',
          'accessCount': 3,
        }),
        MemoryModel.fromJson({
          'id': '2',
          'content': 'User lives in Colorado',
          'importance': 'MEDIUM',
          'accessCount': 1,
        }),
      ];

      await tester.pumpWidget(buildScreen(memories: memories));
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User lives in Colorado'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Memory'), findsOneWidget);
    });

    testWidgets('shows importance badges', (tester) async {
      final memories = [
        MemoryModel.fromJson({
          'id': '1',
          'content': 'Important memory',
          'importance': 'HIGH',
          'accessCount': 0,
        }),
      ];

      await tester.pumpWidget(buildScreen(memories: memories));
      await tester.pumpAndSettle();

      expect(find.text('HIGH'), findsOneWidget);
    });
  });
}
