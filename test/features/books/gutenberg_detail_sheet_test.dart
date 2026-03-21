import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/features/books/gutenberg_detail_sheet.dart';

void main() {
  const testBook = GutenbergBookModel(
    id: 1342,
    title: 'Pride and Prejudice',
    authors: ['Austen, Jane'],
    subjects: ['Fiction', 'Romance'],
    downloadCount: 50000,
    formats: {
      'image/jpeg': 'https://example.com/cover.jpg',
      'application/epub+zip': 'https://example.com/book.epub',
      'text/plain': 'https://example.com/book.txt',
    },
  );

  const testBookMinimal = GutenbergBookModel(
    id: 1,
    title: 'Minimal Book',
    downloadCount: 10,
  );

  Widget buildSheet({
    GutenbergBookModel book = testBook,
    bool isOwnerOrAdmin = true,
    bool isImporting = false,
    VoidCallback? onImport,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => GutenbergDetailSheet(
                book: book,
                isOwnerOrAdmin: isOwnerOrAdmin,
                isImporting: isImporting,
                onImport: onImport ?? () {},
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('GutenbergDetailSheet', () {
    testWidgets('shows book title', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
    });

    testWidgets('shows author', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Austen, Jane'), findsOneWidget);
    });

    testWidgets('shows subjects', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Fiction'), findsOneWidget);
      expect(find.text('Romance'), findsOneWidget);
    });

    testWidgets('hides subjects section when none exist', (tester) async {
      await tester.pumpWidget(buildSheet(book: testBookMinimal));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsNothing);
    });

    testWidgets('shows format labels', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Available Formats'), findsOneWidget);
      expect(find.text('EPUB'), findsOneWidget);
      expect(find.text('TXT'), findsOneWidget);
    });

    testWidgets('hides formats section when none exist', (tester) async {
      await tester.pumpWidget(buildSheet(book: testBookMinimal));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Available Formats'), findsNothing);
    });

    testWidgets('shows download count', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('50.0K downloads'), findsOneWidget);
    });

    testWidgets('shows import button for owner/admin', (tester) async {
      await tester.pumpWidget(buildSheet(isOwnerOrAdmin: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Import to Library'), findsOneWidget);
    });

    testWidgets('hides import button for non-admin', (tester) async {
      await tester.pumpWidget(buildSheet(isOwnerOrAdmin: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Import to Library'), findsNothing);
    });

    testWidgets('shows importing state', (tester) async {
      await tester
          .pumpWidget(buildSheet(book: testBookMinimal, isImporting: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      // Use pump() instead of pumpAndSettle() because
      // CircularProgressIndicator animation never settles
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Importing...'), findsOneWidget);
    });

    testWidgets('calls onImport when button tapped', (tester) async {
      var importCalled = false;
      await tester
          .pumpWidget(buildSheet(onImport: () => importCalled = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import to Library'));
      expect(importCalled, isTrue);
    });

    testWidgets('shows drag handle', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The drag handle is a 40x4 container
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });
  });
}
