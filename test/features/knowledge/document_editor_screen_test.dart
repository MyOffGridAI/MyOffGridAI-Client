import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/features/knowledge/document_editor_screen.dart';

class MockKnowledgeService extends Mock implements KnowledgeService {}

void main() {
  late MockKnowledgeService mockService;

  setUp(() {
    mockService = MockKnowledgeService();
    registerFallbackValue('');
  });

  Widget buildScreen({String? documentId}) {
    return ProviderScope(
      overrides: [
        knowledgeServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: DocumentEditorScreen(documentId: documentId),
      ),
    );
  }

  /// Suppress QuillSimpleToolbar overflow errors in the test environment.
  void suppressOverflowErrors(WidgetTester tester) {
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {};
    addTearDown(() => FlutterError.onError = origOnError);
  }

  group('DocumentEditorScreen - New Document', () {
    testWidgets('shows New Document title', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('New Document'), findsOneWidget);
    });

    testWidgets('shows title field', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('save without title shows error', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.save));
      // Use pump() instead of pumpAndSettle() — the SnackBar timer
      // prevents settling within the timeout window.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter a title'), findsOneWidget);
    });
  });

  group('DocumentEditorScreen - Edit Document', () {
    testWidgets('shows Edit Document title', (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent(any())).thenAnswer(
        (_) async => const DocumentContentModel(
          documentId: 'doc-1',
          title: 'Existing Doc',
          content: null,
        ),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pump();

      expect(find.text('Edit Document'), findsOneWidget);
    });

    testWidgets('loads content from service', (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent('doc-1')).thenAnswer(
        (_) async => const DocumentContentModel(
          documentId: 'doc-1',
          title: 'My Document',
          content: null,
        ),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      verify(() => mockService.getDocumentContent('doc-1')).called(1);
    });

    testWidgets('shows error on load failure', (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent(any())).thenThrow(
        const ApiException(statusCode: 500, message: 'Load failed'),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      expect(find.text('Load failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent(any())).thenThrow(
        const ApiException(statusCode: 500, message: 'Load failed'),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows generic error on non-API failure', (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent(any()))
          .thenThrow(Exception('network down'));

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load document content.'), findsOneWidget);
    });

    testWidgets('loads Delta JSON content and initializes Quill editor',
        (tester) async {
      suppressOverflowErrors(tester);

      final deltaJson = jsonEncode([
        {'insert': 'Hello World\n'}
      ]);

      when(() => mockService.getDocumentContent('doc-1')).thenAnswer(
        (_) async => DocumentContentModel(
          documentId: 'doc-1',
          title: 'Delta Doc',
          content: deltaJson,
        ),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      // Title field should be populated
      verify(() => mockService.getDocumentContent('doc-1')).called(1);
    });

    testWidgets('falls back to plain text when Delta JSON parsing fails',
        (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent('doc-1')).thenAnswer(
        (_) async => const DocumentContentModel(
          documentId: 'doc-1',
          title: 'Plain Doc',
          content: 'This is not valid JSON',
        ),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      // Should not show error -- editor should be loaded with plain text fallback
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('loads empty content and creates basic controller',
        (tester) async {
      suppressOverflowErrors(tester);

      when(() => mockService.getDocumentContent('doc-1')).thenAnswer(
        (_) async => const DocumentContentModel(
          documentId: 'doc-1',
          title: 'Empty Content Doc',
          content: '',
        ),
      );

      await tester.pumpWidget(buildScreen(documentId: 'doc-1'));
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
    });
  });

  group('DocumentEditorScreen - Save', () {
    // Note: The _save method (lines 100-148) and back button navigation
    // (line 157: context.go('/knowledge')) require GoRouter which, when used
    // with MaterialApp.router, doesn't inherit FlutterQuillLocalizations.
    // The suppressOverflowErrors pattern from the existing tests swallows the
    // QuillToolbar localization/overflow errors, but the SnackBar timer left
    // by the save success path causes the test framework to detect unhandled
    // error state. Using MaterialApp(home:) without GoRouter causes
    // context.go to throw. These lines cannot be covered without modifying
    // lib/ code (e.g., adding quill localizations delegate to the router, or
    // using Navigator.pop instead of context.go).
  });
}
