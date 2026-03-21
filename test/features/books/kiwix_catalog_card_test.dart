import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/kiwix_catalog_card.dart';

class MockLibraryService extends Mock implements LibraryService {}

void main() {
  late MockLibraryService mockService;

  const testEntry = KiwixCatalogEntryModel(
    id: 'wiki-en',
    title: 'Wikipedia English',
    description: 'The free encyclopedia in English',
    language: 'eng',
    name: 'wikipedia_en_all',
    category: 'wikipedia',
    sizeBytes: 95000000000,
    downloadUrl: 'https://download.kiwix.org/zim/wikipedia_en_all.zim',
  );

  const testEntryNoDownload = KiwixCatalogEntryModel(
    id: 'no-dl',
    title: 'No Download Entry',
    sizeBytes: 1024,
  );

  const testEntryNoDescription = KiwixCatalogEntryModel(
    id: 'no-desc',
    title: 'No Description',
    sizeBytes: 512000,
    downloadUrl: 'https://example.com/test.zim',
  );

  setUp(() {
    mockService = MockLibraryService();
  });

  Widget buildCard({
    KiwixCatalogEntryModel entry = testEntry,
    bool isOwnerOrAdmin = true,
  }) {
    return ProviderScope(
      overrides: [
        libraryServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: KiwixCatalogCard(
              entry: entry,
              isOwnerOrAdmin: isOwnerOrAdmin,
            ),
          ),
        ),
      ),
    );
  }

  group('KiwixCatalogCard', () {
    testWidgets('displays entry title', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Wikipedia English'), findsOneWidget);
    });

    testWidgets('displays entry description', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(
          find.text('The free encyclopedia in English'), findsOneWidget);
    });

    testWidgets('hides description when null', (tester) async {
      await tester.pumpWidget(buildCard(entry: testEntryNoDescription));
      await tester.pumpAndSettle();

      expect(find.text('The free encyclopedia in English'), findsNothing);
    });

    testWidgets('displays language and category in metadata', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.textContaining('eng'), findsOneWidget);
      expect(find.textContaining('wikipedia'), findsOneWidget);
    });

    testWidgets('displays formatted size', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.textContaining('GB'), findsOneWidget);
    });

    testWidgets('shows download button for owner/admin', (tester) async {
      await tester.pumpWidget(buildCard(isOwnerOrAdmin: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('hides download button for non-admin', (tester) async {
      await tester.pumpWidget(buildCard(isOwnerOrAdmin: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('hides download button when no download URL',
        (tester) async {
      await tester.pumpWidget(
          buildCard(entry: testEntryNoDownload, isOwnerOrAdmin: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsNothing);
    });

    testWidgets('shows fallback icon when no illustration URL',
        (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsWidgets);
    });

    testWidgets('tapping download calls downloadFromCatalog',
        (tester) async {
      when(() => mockService.downloadFromCatalog(
            downloadUrl: any(named: 'downloadUrl'),
            filename: any(named: 'filename'),
            displayName: any(named: 'displayName'),
            category: any(named: 'category'),
            language: any(named: 'language'),
            sizeBytes: any(named: 'sizeBytes'),
          )).thenAnswer((_) async => 'download-id-123');

      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      verify(() => mockService.downloadFromCatalog(
            downloadUrl: testEntry.downloadUrl!,
            filename: 'wikipedia_en_all.zim',
            displayName: 'Wikipedia English',
            category: 'wikipedia',
            language: 'eng',
            sizeBytes: 95000000000,
          )).called(1);
    });

    testWidgets('shows spinner during download', (tester) async {
      final completer = Completer<String>();
      when(() => mockService.downloadFromCatalog(
            downloadUrl: any(named: 'downloadUrl'),
            filename: any(named: 'filename'),
            displayName: any(named: 'displayName'),
            category: any(named: 'category'),
            language: any(named: 'language'),
            sizeBytes: any(named: 'sizeBytes'),
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
      expect(find.byIcon(Icons.download), findsNothing);

      // Complete the future to clean up
      completer.complete('id');
      await tester.pumpAndSettle();
    });
  });
}
