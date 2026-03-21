import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/features/books/gutenberg_book_card.dart';

void main() {
  const testBook = GutenbergBookModel(
    id: 1342,
    title: 'Pride and Prejudice',
    authors: ['Austen, Jane'],
    downloadCount: 50000,
  );

  const testBookNoAuthor = GutenbergBookModel(
    id: 2,
    title: 'Unknown Author Book',
    downloadCount: 100,
  );

  Widget buildCard({
    GutenbergBookModel book = testBook,
    bool isOwnerOrAdmin = true,
    bool isImporting = false,
    VoidCallback? onImport,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 400,
          child: GutenbergBookCard(
            book: book,
            isOwnerOrAdmin: isOwnerOrAdmin,
            isImporting: isImporting,
            onImport: onImport ?? () {},
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('GutenbergBookCard', () {
    testWidgets('displays book title', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
    });

    testWidgets('displays author name', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Austen, Jane'), findsOneWidget);
    });

    testWidgets('hides author when authors list is empty', (tester) async {
      await tester.pumpWidget(buildCard(book: testBookNoAuthor));
      await tester.pumpAndSettle();

      expect(find.text('Austen, Jane'), findsNothing);
    });

    testWidgets('displays formatted download count', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('50.0K'), findsOneWidget);
    });

    testWidgets('shows import button for owner/admin', (tester) async {
      await tester.pumpWidget(buildCard(isOwnerOrAdmin: true));
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('hides import button for non-admin', (tester) async {
      await tester.pumpWidget(buildCard(isOwnerOrAdmin: false));
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsNothing);
    });

    testWidgets('shows spinner when importing', (tester) async {
      await tester.pumpWidget(buildCard(isImporting: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Import'), findsNothing);
    });

    testWidgets('calls onImport when import button tapped', (tester) async {
      var importCalled = false;
      await tester.pumpWidget(buildCard(onImport: () => importCalled = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import'));
      expect(importCalled, isTrue);
    });

    testWidgets('calls onTap when card tapped', (tester) async {
      var tapCalled = false;
      await tester.pumpWidget(buildCard(onTap: () => tapCalled = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pride and Prejudice'));
      expect(tapCalled, isTrue);
    });

    testWidgets('shows placeholder icon when no cover image', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_stories), findsWidgets);
    });
  });
}
