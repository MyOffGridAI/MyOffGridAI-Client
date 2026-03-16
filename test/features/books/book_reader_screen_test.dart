import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/book_reader_screen.dart';

class MockLibraryService extends Mock implements LibraryService {}

void main() {
  late MockLibraryService mockService;

  setUp(() {
    mockService = MockLibraryService();
  });

  Widget buildScreen(EbookModel ebook) {
    return ProviderScope(
      overrides: [
        libraryServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(home: BookReaderScreen(ebook: ebook)),
    );
  }

  group('BookReaderScreen', () {
    testWidgets('shows book title in app bar', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'My Test Book',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => 'Hello World'.codeUnits);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pump();

      expect(find.text('My Test Book'), findsOneWidget);
    });

    testWidgets('shows author in app bar when available', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Test',
        author: 'Jane Austen',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => 'Content'.codeUnits);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pump();

      expect(find.text('Jane Austen'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Test',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      // Use a Completer to keep the future pending without timer
      final completer = Completer<List<int>>();
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending future leak
      completer.complete(<int>[]);
    });

    testWidgets('shows error view on API failure', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Test',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenThrow(const ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders text content for TXT format', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Text Book',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => 'This is the book content.'.codeUnits);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(find.text('This is the book content.'), findsOneWidget);
    });

    testWidgets('shows unsupported format message for MOBI', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Mobi Book',
        format: 'MOBI',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => [0x01, 0x02, 0x03]);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('not yet supported'),
        findsOneWidget,
      );
    });

    testWidgets('shows unsupported format message for EPUB', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Epub Book',
        format: 'EPUB',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => [0x50, 0x4B, 0x03, 0x04]);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('not yet supported'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty content error for empty bytes', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Empty',
        format: 'TXT',
        fileSizeBytes: 0,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => <int>[]);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(find.text('No content available for this book'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Test',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenThrow(Exception('network down'));

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load book content'), findsOneWidget);
    });

    testWidgets('retry button reloads content', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Test',
        format: 'TXT',
        fileSizeBytes: 100,
      );
      int callCount = 0;
      when(() => mockService.downloadEbookContent('e1')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(statusCode: 500, message: 'Error');
        }
        return Future.value('Loaded content'.codeUnits);
      });

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Loaded content'), findsOneWidget);
    });

    testWidgets('shows info icon for unsupported format', (tester) async {
      const ebook = EbookModel(
        id: 'e1',
        title: 'Html Book',
        format: 'HTML',
        fileSizeBytes: 100,
      );
      when(() => mockService.downloadEbookContent('e1'))
          .thenAnswer((_) async => [0x01]);

      await tester.pumpWidget(buildScreen(ebook));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
