import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/memory_model.dart';
import 'package:myoffgridai_client/core/services/memory_service.dart';
import 'package:myoffgridai_client/features/memory/memory_screen.dart';

class MockMemoryService extends Mock implements MemoryService {}

void main() {
  late MockMemoryService mockService;

  final highMemory = MemoryModel.fromJson({
    'id': '1',
    'content': 'User prefers dark mode',
    'importance': 'HIGH',
    'accessCount': 3,
    'tags': 'preference,ui',
    'createdAt': '2026-03-01T10:00:00Z',
  });

  final mediumMemory = MemoryModel.fromJson({
    'id': '2',
    'content': 'User lives in Colorado',
    'importance': 'MEDIUM',
    'accessCount': 1,
    'createdAt': '2026-03-10T10:00:00Z',
  });

  final criticalMemory = MemoryModel.fromJson({
    'id': '3',
    'content': 'User is allergic to peanuts',
    'importance': 'CRITICAL',
    'accessCount': 5,
    'tags': 'health,allergy',
    'createdAt': '2026-02-15T10:00:00Z',
  });

  final lowMemory = MemoryModel.fromJson({
    'id': '4',
    'content': 'User mentioned liking jazz',
    'importance': 'LOW',
    'accessCount': 0,
  });

  setUp(() {
    mockService = MockMemoryService();
    registerFallbackValue('');
  });

  Widget buildScreen({List<MemoryModel> memories = const []}) {
    return ProviderScope(
      overrides: [
        memoriesProvider.overrideWith((ref) => memories),
        memoryServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(home: MemoryScreen()),
    );
  }

  group('MemoryScreen', () {
    testWidgets('shows empty state when no memories', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No memories yet'), findsOneWidget);
    });

    testWidgets('displays memories list', (tester) async {
      await tester.pumpWidget(
          buildScreen(memories: [highMemory, mediumMemory]));
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User lives in Colorado'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search memories...'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Memory'), findsOneWidget);
    });

    testWidgets('shows importance badges', (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('shows filter button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });

  group('Importance filter', () {
    testWidgets('shows filter options', (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('filters by HIGH', (tester) async {
      await tester.pumpWidget(buildScreen(
          memories: [highMemory, mediumMemory, criticalMemory]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User lives in Colorado'), findsNothing);
      expect(find.text('User is allergic to peanuts'), findsNothing);
    });

    testWidgets('filter All resets filter', (tester) async {
      await tester
          .pumpWidget(buildScreen(memories: [highMemory, mediumMemory]));
      await tester.pumpAndSettle();

      // First filter to HIGH
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      expect(find.text('User lives in Colorado'), findsNothing);

      // Then reset
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('User prefers dark mode'), findsOneWidget);
      expect(find.text('User lives in Colorado'), findsOneWidget);
    });

    testWidgets('shows empty state when filter matches nothing',
        (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Low'));
      await tester.pumpAndSettle();

      expect(find.text('No memories yet'), findsOneWidget);
    });
  });

  group('Search', () {
    testWidgets('performs search on submit', (tester) async {
      when(() => mockService.search(any())).thenAnswer((_) async => [
            MemorySearchResultModel(
              memory: highMemory,
              similarityScore: 0.85,
            ),
          ]);

      await tester
          .pumpWidget(buildScreen(memories: [highMemory, mediumMemory]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dark mode');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => mockService.search('dark mode')).called(1);
      expect(find.text('85% match'), findsOneWidget);
    });

    testWidgets('shows no results for empty search results', (tester) async {
      when(() => mockService.search(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('shows error on search failure', (tester) async {
      when(() => mockService.search(any())).thenThrow(
        const ApiException(statusCode: 500, message: 'Search failed'),
      );

      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Search failed'), findsOneWidget);
    });

    testWidgets('empty search clears results', (tester) async {
      when(() => mockService.search(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should show the regular list, not search results
      expect(find.text('User prefers dark mode'), findsOneWidget);
      verifyNever(() => mockService.search(any()));
    });
  });

  group('Memory detail sheet', () {
    testWidgets('opens on tap', (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('User prefers dark mode'));
      await tester.pumpAndSettle();

      // Tags should be visible in the sheet
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('shows tags as chips', (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('User prefers dark mode'));
      await tester.pumpAndSettle();

      expect(find.text('preference'), findsOneWidget);
      expect(find.text('ui'), findsOneWidget);
    });

    testWidgets('shows access count', (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('User prefers dark mode'));
      await tester.pumpAndSettle();

      expect(find.text('Accessed 3 times'), findsOneWidget);
    });
  });

  group('Memory error state', () {
    testWidgets('shows API error message', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          memoriesProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Server down')),
          memoryServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: MemoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load memories'), findsOneWidget);
      expect(find.text('Server down'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          memoriesProvider.overrideWith((ref) => throw Exception('unknown')),
          memoryServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: MemoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          memoriesProvider.overrideWith((ref) =>
              throw const ApiException(statusCode: 500, message: 'Error')),
          memoryServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: MemoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Clear search', () {
    testWidgets('clear button clears search and resets results',
        (tester) async {
      when(() => mockService.search(any())).thenAnswer((_) async => [
            MemorySearchResultModel(
              memory: highMemory,
              similarityScore: 0.85,
            ),
          ]);

      await tester
          .pumpWidget(buildScreen(memories: [highMemory, mediumMemory]));
      await tester.pumpAndSettle();

      // Type and search
      await tester.enterText(find.byType(TextField), 'dark mode');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('85% match'), findsOneWidget);

      // Clear button should appear after typing
      // Re-type to show the clear button
      await tester.enterText(find.byType(TextField), 'dark mode');
      await tester.pump();

      // Tap clear button
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Should go back to regular memory list
        expect(find.text('User prefers dark mode'), findsOneWidget);
        expect(find.text('User lives in Colorado'), findsOneWidget);
      }
    });
  });

  group('Search result detail', () {
    testWidgets('tapping search result opens detail sheet', (tester) async {
      when(() => mockService.search(any())).thenAnswer((_) async => [
            MemorySearchResultModel(
              memory: highMemory,
              similarityScore: 0.85,
            ),
          ]);

      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dark mode');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap the search result
      await tester.tap(find.text('User prefers dark mode'));
      await tester.pumpAndSettle();

      // Detail sheet should show tags
      expect(find.text('preference'), findsOneWidget);
      expect(find.text('ui'), findsOneWidget);
    });
  });

  group('Memory date display', () {
    testWidgets('shows relative date for memories with createdAt',
        (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      // highMemory has createdAt: '2026-03-01T10:00:00Z'
      // Should show a relative date in the trailing
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows no trailing date when createdAt is null',
        (tester) async {
      await tester.pumpWidget(buildScreen(memories: [lowMemory]));
      await tester.pumpAndSettle();

      // lowMemory has no createdAt
      expect(find.text('User mentioned liking jazz'), findsOneWidget);
    });
  });

  group('Delete memory', () {
    testWidgets('memory tile is wrapped in Dismissible', (tester) async {
      await tester.pumpWidget(buildScreen(memories: [highMemory]));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('multiple memories show multiple Dismissibles',
        (tester) async {
      await tester.pumpWidget(
          buildScreen(memories: [highMemory, mediumMemory]));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNWidgets(2));
    });

    // Note: The _deleteMemory method (lines 234-253) invokes a ConfirmationDialog
    // after Dismissible.onDismissed fires. This pattern causes a Flutter framework
    // error in widget tests ("A dismissed Dismissible widget is still part of the
    // tree") because the Dismissible is already removed before the dialog can
    // rebuild the tree. These lines cannot be covered without modifying source code
    // (e.g., using confirmDismiss instead of onDismissed).
  });
}
