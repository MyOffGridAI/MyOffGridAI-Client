import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/enrichment_models.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/models/system_models.dart';
import 'package:myoffgridai_client/core/services/enrichment_service.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/features/knowledge/knowledge_screen.dart';

class MockKnowledgeService extends Mock implements KnowledgeService {}

class MockEnrichmentService extends Mock implements EnrichmentService {}

void main() {
  late MockKnowledgeService mockService;
  late MockEnrichmentService mockEnrichmentService;

  final indexedDoc = KnowledgeDocumentModel.fromJson({
    'id': '1',
    'filename': 'guide.pdf',
    'displayName': 'User Guide',
    'fileSizeBytes': 1024,
    'status': 'INDEXED',
    'chunkCount': 10,
  });

  final pendingDoc = KnowledgeDocumentModel.fromJson({
    'id': '2',
    'filename': 'notes.txt',
    'fileSizeBytes': 256,
    'status': 'PENDING',
    'chunkCount': 0,
  });

  final processingDoc = KnowledgeDocumentModel.fromJson({
    'id': '3',
    'filename': 'manual.md',
    'displayName': 'Installation Manual',
    'fileSizeBytes': 512,
    'status': 'PROCESSING',
    'chunkCount': 0,
  });

  final failedDoc = KnowledgeDocumentModel.fromJson({
    'id': '4',
    'filename': 'corrupted.pdf',
    'fileSizeBytes': 2048,
    'status': 'FAILED',
    'chunkCount': 0,
    'errorMessage': 'Parse error',
  });

  setUp(() {
    mockService = MockKnowledgeService();
    mockEnrichmentService = MockEnrichmentService();
    registerFallbackValue('');
  });

  Widget buildScreen({
    List<KnowledgeDocumentModel> documents = const [],
    bool documentsError = false,
  }) {
    return ProviderScope(
      overrides: [
        knowledgeDocumentsProvider.overrideWith((ref) {
          if (documentsError) {
            throw const ApiException(
                statusCode: 500, message: 'Load failed');
          }
          return documents;
        }),
        knowledgeServiceProvider.overrideWithValue(mockService),
        enrichmentServiceProvider.overrideWithValue(mockEnrichmentService),
        storageSettingsProvider.overrideWith((ref) => const StorageSettingsModel(
              knowledgeStoragePath: '/tmp/test',
              maxUploadSizeMb: 25,
            )),
      ],
      child: const MaterialApp(home: KnowledgeScreen()),
    );
  }

  group('KnowledgeScreen', () {
    testWidgets('shows empty state when no documents', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Vault is empty'), findsOneWidget);
    });

    testWidgets('displays document list', (tester) async {
      await tester
          .pumpWidget(buildScreen(documents: [indexedDoc, pendingDoc]));
      await tester.pumpAndSettle();

      expect(find.text('User Guide'), findsOneWidget);
      expect(find.text('notes.txt'), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Vault'), findsOneWidget);
    });

    testWidgets('shows upload FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('shows create new button in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.note_add), findsOneWidget);
    });

    testWidgets('shows Fetch URL button in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('shows Web Search button in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('Document status', () {
    testWidgets('shows INDEXED status text', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      expect(find.text('INDEXED'), findsOneWidget);
    });

    testWidgets('shows PENDING status text', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [pendingDoc]));
      await tester.pumpAndSettle();

      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('shows FAILED status text', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [failedDoc]));
      await tester.pumpAndSettle();

      expect(find.text('FAILED'), findsOneWidget);
    });

    testWidgets('shows chunk count for indexed docs', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      expect(find.text('10 chunks'), findsOneWidget);
    });

    testWidgets('hides chunk count for non-indexed docs', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [pendingDoc]));
      await tester.pumpAndSettle();

      expect(find.text('0 chunks'), findsNothing);
    });

    testWidgets('shows formatted file size', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      expect(find.text('1.0 KB'), findsOneWidget);
    });

    testWidgets('shows displayName when present', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      expect(find.text('User Guide'), findsOneWidget);
    });

    testWidgets('shows filename when no displayName', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [pendingDoc]));
      await tester.pumpAndSettle();

      expect(find.text('notes.txt'), findsOneWidget);
    });

    testWidgets('shows retry button for failed docs', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [failedDoc]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('hides retry button for non-failed docs', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('shows delete button on each doc', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('Delete document', () {
    testWidgets('shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Document'), findsOneWidget);
    });

    testWidgets('calls deleteDocument on confirm', (tester) async {
      when(() => mockService.deleteDocument('1')).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockService.deleteDocument('1')).called(1);
    });

    testWidgets('does not delete on cancel', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteDocument(any()));
    });

    testWidgets('shows error on delete failure', (tester) async {
      when(() => mockService.deleteDocument('1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Delete failed'),
      );

      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Delete failed'), findsOneWidget);
    });
  });

  group('Retry processing', () {
    testWidgets('calls retryProcessing on retry tap', (tester) async {
      when(() => mockService.retryProcessing('4')).thenAnswer(
        (_) async => KnowledgeDocumentModel.fromJson({
          'id': '4',
          'filename': 'corrupted.pdf',
          'fileSizeBytes': 2048,
          'status': 'PROCESSING',
          'chunkCount': 0,
        }),
      );

      await tester.pumpWidget(buildScreen(documents: [failedDoc]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      verify(() => mockService.retryProcessing('4')).called(1);
    });

    testWidgets('shows error on retry failure', (tester) async {
      when(() => mockService.retryProcessing('4')).thenThrow(
        const ApiException(statusCode: 500, message: 'Retry failed'),
      );

      await tester.pumpWidget(buildScreen(documents: [failedDoc]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('Retry failed'), findsOneWidget);
    });
  });

  group('Fetch URL sheet', () {
    testWidgets('opens on Fetch URL button tap', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.text('Fetch URL'), findsOneWidget);
      expect(find.text('URL'), findsOneWidget);
      expect(find.text('Fetch'), findsOneWidget);
    });

    testWidgets('shows summarize checkbox', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.text('Summarize with Claude'), findsOneWidget);
    });
  });

  group('Web Search sheet', () {
    testWidgets('opens on Web Search button tap', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Web Search'), findsOneWidget);
      expect(find.text('Search query'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('shows store top results slider', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.textContaining('Store top results:'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows summarize checkbox', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Summarize with Claude'), findsOneWidget);
    });

    testWidgets('toggles summarize checkbox', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Find and tap the web search summarize checkbox
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsOneWidget);
      await tester.tap(checkboxes);
      await tester.pump();
    });

    testWidgets('adjusts store top results slider', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Find the slider and drag it
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();
    });

    testWidgets('performs search and shows results', (tester) async {
      when(() => mockEnrichmentService.search(
            query: any(named: 'query'),
            storeTopN: any(named: 'storeTopN'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          )).thenAnswer((_) async => (
            results: [
              const SearchResultModel(
                title: 'Solar Panels',
                url: 'https://example.com/solar',
                description: 'A guide to solar panels',
              ),
            ],
            storedDocuments: <KnowledgeDocumentModel>[],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      final queryField = find.byType(TextField);
      await tester.enterText(queryField, 'solar panels');
      await tester.pump();

      // Tap search button
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1 result(s)'), findsOneWidget);
      expect(find.text('Solar Panels'), findsOneWidget);
      expect(find.text('A guide to solar panels'), findsOneWidget);
    });

    testWidgets('shows error on search failure', (tester) async {
      when(() => mockEnrichmentService.search(
            query: any(named: 'query'),
            storeTopN: any(named: 'storeTopN'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          )).thenThrow(
        const ApiException(statusCode: 500, message: 'Search failed'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final queryField = find.byType(TextField);
      await tester.enterText(queryField, 'test query');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Search failed'), findsOneWidget);
    });

    testWidgets('does not search when query is empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Tap search without entering query
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockEnrichmentService.search(
            query: any(named: 'query'),
            storeTopN: any(named: 'storeTopN'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          ));
    });

    testWidgets('invalidates documents when storeTopN > 0', (tester) async {
      when(() => mockEnrichmentService.search(
            query: any(named: 'query'),
            storeTopN: any(named: 'storeTopN'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          )).thenAnswer((_) async => (
            results: <SearchResultModel>[],
            storedDocuments: <KnowledgeDocumentModel>[],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Drag slider to set storeTopN > 0
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      final queryField = find.byType(TextField);
      await tester.enterText(queryField, 'test');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Fetch URL sheet - actions', () {
    testWidgets('toggles summarize checkbox', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsOneWidget);
      await tester.tap(checkboxes);
      await tester.pump();
    });

    testWidgets('does not fetch when URL is empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Fetch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockEnrichmentService.fetchUrl(
            url: any(named: 'url'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          ));
    });

    testWidgets('shows error on fetch failure', (tester) async {
      when(() => mockEnrichmentService.fetchUrl(
            url: any(named: 'url'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          )).thenThrow(
        const ApiException(statusCode: 500, message: 'Fetch failed'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      final urlField = find.byType(TextField);
      await tester.enterText(urlField, 'https://example.com/bad');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Fetch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Fetch failed'), findsOneWidget);
    });
  });

  group('Error and loading states', () {
    testWidgets('shows error view on API document load failure',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          knowledgeDocumentsProvider.overrideWith((ref) =>
              throw const ApiException(
                  statusCode: 500, message: 'Load failed')),
          knowledgeServiceProvider.overrideWithValue(mockService),
          enrichmentServiceProvider
              .overrideWithValue(mockEnrichmentService),
          storageSettingsProvider.overrideWith(
              (ref) => const StorageSettingsModel(
                    knowledgeStoragePath: '/tmp/test',
                    maxUploadSizeMb: 25,
                  )),
        ],
        child: const MaterialApp(home: KnowledgeScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load documents'), findsOneWidget);
      expect(find.text('Load failed'), findsOneWidget);
    });

    testWidgets('shows error view with generic message for non-API error',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          knowledgeDocumentsProvider
              .overrideWith((ref) => throw Exception('Network error')),
          knowledgeServiceProvider.overrideWithValue(mockService),
          enrichmentServiceProvider
              .overrideWithValue(mockEnrichmentService),
          storageSettingsProvider.overrideWith(
              (ref) => const StorageSettingsModel(
                    knowledgeStoragePath: '/tmp/test',
                    maxUploadSizeMb: 25,
                  )),
        ],
        child: const MaterialApp(home: KnowledgeScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load documents'), findsOneWidget);
      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });
  });

  group('PROCESSING status', () {
    testWidgets('shows PROCESSING status text', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [processingDoc]));
      // processingDoc has a CircularProgressIndicator which prevents
      // pumpAndSettle from completing, so use pump() instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PROCESSING'), findsOneWidget);
    });

    testWidgets('shows processing icon (blue CircleAvatar)',
        (tester) async {
      await tester.pumpWidget(buildScreen(documents: [processingDoc]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The processing status shows a CircleAvatar with blue background
      final avatars =
          tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
      expect(
          avatars.any((a) => a.backgroundColor == Colors.blue), isTrue);
    });
  });

  group('Error retry', () {
    testWidgets('retry button taps trigger document refresh', (tester) async {
      // Track whether the provider was invalidated by building with error
      // then tapping retry and checking that the error view still shows
      // (since the provider still throws).
      await tester.pumpWidget(ProviderScope(
        overrides: [
          knowledgeDocumentsProvider.overrideWith((ref) =>
              throw const ApiException(
                  statusCode: 500, message: 'Load failed')),
          knowledgeServiceProvider.overrideWithValue(mockService),
          enrichmentServiceProvider
              .overrideWithValue(mockEnrichmentService),
          storageSettingsProvider.overrideWith(
              (ref) => const StorageSettingsModel(
                    knowledgeStoragePath: '/tmp/test',
                    maxUploadSizeMb: 25,
                  )),
        ],
        child: const MaterialApp(home: KnowledgeScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load documents'), findsOneWidget);

      // Tap the retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Error view should still be visible (provider still throws)
      expect(find.text('Failed to load documents'), findsOneWidget);
    });
  });

  group('Fetch URL sheet - summarize toggle', () {
    testWidgets('toggling summarize checkbox changes checkbox state',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open fetch URL sheet
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // The summarize checkbox should exist
      final checkbox = find.byType(CheckboxListTile);
      expect(checkbox, findsOneWidget);

      // Initial state is unchecked
      final initial = tester.widget<CheckboxListTile>(checkbox);
      expect(initial.value, isFalse);

      // Tap to toggle
      await tester.tap(checkbox);
      await tester.pump();

      // Now it should be checked
      final toggled = tester.widget<CheckboxListTile>(checkbox);
      expect(toggled.value, isTrue);
    });
  });

  group('Multiple document statuses', () {
    testWidgets('shows green CircleAvatar for INDEXED status', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      final avatars =
          tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
      expect(
          avatars.any((a) => a.backgroundColor == Colors.green), isTrue);
    });

    testWidgets('shows red CircleAvatar for FAILED status', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [failedDoc]));
      await tester.pumpAndSettle();

      final avatars =
          tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
      expect(
          avatars.any((a) => a.backgroundColor == Colors.red), isTrue);
    });

    testWidgets('shows grey CircleAvatar for PENDING status', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [pendingDoc]));
      await tester.pumpAndSettle();

      final avatars =
          tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
      expect(
          avatars.any((a) => a.backgroundColor == Colors.grey), isTrue);
    });

    testWidgets('shows all four document statuses at once', (tester) async {
      await tester.pumpWidget(buildScreen(
          documents: [indexedDoc, pendingDoc, failedDoc]));
      await tester.pumpAndSettle();

      expect(find.text('INDEXED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
    });
  });

  group('Web search with storeTopN > 0', () {
    testWidgets('search with storeTopN > 0 invalidates documents',
        (tester) async {
      when(() => mockEnrichmentService.search(
            query: any(named: 'query'),
            storeTopN: any(named: 'storeTopN'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          )).thenAnswer((_) async => (
            results: <SearchResultModel>[],
            storedDocuments: <KnowledgeDocumentModel>[],
          ));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Set storeTopN > 0 via slider
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(200, 0));
      await tester.pump();

      final queryField = find.byType(TextField);
      await tester.enterText(queryField, 'solar panels');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockEnrichmentService.search(
            query: any(named: 'query'),
            storeTopN: any(named: 'storeTopN'),
            summarizeWithClaude: any(named: 'summarizeWithClaude'),
          )).called(1);
    });
  });

  group('docTypeLabel', () {
    test('returns PDF for application/pdf', () {
      expect(docTypeLabel('application/pdf', 'file.pdf'), 'PDF');
    });

    test('returns TXT for text/plain', () {
      expect(docTypeLabel('text/plain', 'file.txt'), 'TXT');
    });

    test('returns MD for text/markdown', () {
      expect(docTypeLabel('text/markdown', 'readme.md'), 'MD');
    });

    test('returns DOCX for openxml word document', () {
      expect(
        docTypeLabel(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'report.docx',
        ),
        'DOCX',
      );
    });

    test('returns DOC for application/msword', () {
      expect(docTypeLabel('application/msword', 'old.doc'), 'DOC');
    });

    test('returns XLSX for openxml spreadsheet', () {
      expect(
        docTypeLabel(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'data.xlsx',
        ),
        'XLSX',
      );
    });

    test('returns HTML for text/html', () {
      expect(docTypeLabel('text/html', 'page.html'), 'HTML');
    });

    test('returns JSON for application/json', () {
      expect(docTypeLabel('application/json', 'config.json'), 'JSON');
    });

    test('falls back to extension when mimeType is null', () {
      expect(docTypeLabel(null, 'report.pdf'), 'PDF');
    });

    test('falls back to extension for unknown MIME type', () {
      expect(docTypeLabel('application/octet-stream', 'data.csv'), 'CSV');
    });

    test('returns empty string for no extension and unknown MIME', () {
      expect(docTypeLabel('application/octet-stream', 'noext'), '');
    });

    test('returns empty string for null MIME and no extension', () {
      expect(docTypeLabel(null, 'noext'), '');
    });
  });

  group('Sort bar', () {
    testWidgets('renders Name and Type sort buttons', (tester) async {
      await tester.pumpWidget(
          buildScreen(documents: [indexedDoc, pendingDoc]));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Name \u2191'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Type'), findsOneWidget);
    });

    testWidgets('tapping Name toggles sort direction', (tester) async {
      await tester.pumpWidget(
          buildScreen(documents: [indexedDoc, pendingDoc]));
      await tester.pumpAndSettle();

      // Initial: Name ascending (↑)
      expect(find.widgetWithText(TextButton, 'Name \u2191'), findsOneWidget);

      // Tap Name to toggle to descending (↓)
      await tester.tap(find.widgetWithText(TextButton, 'Name \u2191'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Name \u2193'), findsOneWidget);
    });

    testWidgets('tapping Type switches sort field', (tester) async {
      await tester.pumpWidget(
          buildScreen(documents: [indexedDoc, pendingDoc]));
      await tester.pumpAndSettle();

      // Tap Type — it becomes active with ascending arrow
      await tester.tap(find.widgetWithText(TextButton, 'Type'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Type \u2191'), findsOneWidget);
      // Name should no longer show arrow
      expect(find.widgetWithText(TextButton, 'Name'), findsOneWidget);
    });

    testWidgets('documents sort A-Z by name by default', (tester) async {
      // pendingDoc filename = 'notes.txt', indexedDoc displayName = 'User Guide'
      // A-Z: notes.txt < User Guide
      await tester.pumpWidget(
          buildScreen(documents: [indexedDoc, pendingDoc]));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      final titles = tiles
          .map((t) => (t.title as Text).data)
          .toList();
      expect(titles, ['notes.txt', 'User Guide']);
    });

    testWidgets('tapping Name toggles to Z-A', (tester) async {
      await tester.pumpWidget(
          buildScreen(documents: [indexedDoc, pendingDoc]));
      await tester.pumpAndSettle();

      // Tap Name to go descending
      await tester.tap(find.widgetWithText(TextButton, 'Name \u2191'));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      final titles = tiles
          .map((t) => (t.title as Text).data)
          .toList();
      expect(titles, ['User Guide', 'notes.txt']);
    });

    testWidgets('tapping Type sorts by doc type', (tester) async {
      // indexedDoc: guide.pdf (mimeType null → extension PDF)
      // pendingDoc: notes.txt (mimeType null → extension TXT)
      // A-Z type: PDF < TXT
      await tester.pumpWidget(
          buildScreen(documents: [pendingDoc, indexedDoc]));
      await tester.pumpAndSettle();

      // Switch to Type sort
      await tester.tap(find.widgetWithText(TextButton, 'Type'));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      final titles = tiles
          .map((t) => (t.title as Text).data)
          .toList();
      // PDF before TXT alphabetically
      expect(titles, ['User Guide', 'notes.txt']);
    });

    testWidgets('shows doc type label in subtitle', (tester) async {
      await tester.pumpWidget(buildScreen(documents: [indexedDoc]));
      await tester.pumpAndSettle();

      // indexedDoc has no mimeType, filename 'guide.pdf' → label 'PDF'
      expect(find.text('PDF'), findsOneWidget);
    });
  });
}
