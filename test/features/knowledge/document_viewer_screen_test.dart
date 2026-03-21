import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:myoffgridai_client/features/knowledge/document_viewer_screen.dart';

class MockKnowledgeService extends Mock implements KnowledgeService {}

void main() {
  late MockKnowledgeService mockService;

  const pdfDoc = KnowledgeDocumentModel(
    id: 'd1',
    filename: 'report.pdf',
    displayName: 'Annual Report',
    mimeType: 'application/pdf',
    fileSizeBytes: 1048576,
    status: 'INDEXED',
    chunkCount: 10,
    hasContent: false,
    editable: false,
  );

  const textDoc = KnowledgeDocumentModel(
    id: 'd2',
    filename: 'notes.txt',
    displayName: 'My Notes',
    mimeType: 'text/plain',
    fileSizeBytes: 512,
    status: 'INDEXED',
    chunkCount: 1,
    hasContent: true,
    editable: true,
  );

  const markdownDoc = KnowledgeDocumentModel(
    id: 'd3',
    filename: 'readme.md',
    displayName: 'README',
    mimeType: 'text/markdown',
    fileSizeBytes: 1024,
    status: 'INDEXED',
    chunkCount: 1,
    hasContent: true,
    editable: false,
  );

  const imageDoc = KnowledgeDocumentModel(
    id: 'd4',
    filename: 'photo.png',
    displayName: 'Photo',
    mimeType: 'image/png',
    fileSizeBytes: 2048,
    status: 'INDEXED',
    chunkCount: 0,
    hasContent: false,
    editable: false,
  );

  const quillDoc = KnowledgeDocumentModel(
    id: 'd5',
    filename: 'rich-doc.json',
    displayName: 'Rich Document',
    mimeType: 'application/x-quill-delta',
    fileSizeBytes: 256,
    status: 'INDEXED',
    chunkCount: 1,
    hasContent: true,
    editable: true,
  );

  const textContent = DocumentContentModel(
    documentId: 'd2',
    title: 'My Notes',
    content: 'Hello, this is plain text content for the viewer.',
    editable: true,
  );

  const markdownContent = DocumentContentModel(
    documentId: 'd3',
    title: 'README',
    content: '# Hello\n\nThis is **markdown** content.',
    editable: false,
  );

  const quillContent = DocumentContentModel(
    documentId: 'd5',
    title: 'Rich Document',
    content: '[{"insert":"Hello Quill\\n"}]',
    editable: true,
  );

  const emptyContent = DocumentContentModel(
    documentId: 'd2',
    title: 'My Notes',
    content: null,
    editable: true,
  );

  setUp(() {
    mockService = MockKnowledgeService();
  });

  Widget buildScreen({String documentId = 'd1'}) {
    final router = GoRouter(
      initialLocation: '/knowledge/$documentId/view',
      routes: [
        GoRoute(
          path: '/knowledge/:documentId/view',
          builder: (context, state) => DocumentViewerScreen(
            documentId: state.pathParameters['documentId']!,
          ),
        ),
        GoRoute(
          path: '/knowledge/:documentId',
          builder: (context, state) => const Scaffold(
            body: Text('Detail Screen'),
          ),
        ),
        GoRoute(
          path: '/knowledge/:documentId/edit',
          builder: (context, state) => const Scaffold(
            body: Text('Editor Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        knowledgeServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('DocumentViewerScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final completer = Completer<KnowledgeDocumentModel>();
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAny);

      // Complete to avoid pending futures
      completer.complete(textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error view when document fetch fails', (tester) async {
      when(() => mockService.getDocument('d1')).thenThrow(
        const ApiException(statusCode: 404, message: 'Document not found'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load document'), findsOneWidget);
      expect(find.text('Document not found'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API exception', (tester) async {
      when(() => mockService.getDocument('d1')).thenThrow(Exception('oops'));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('An unexpected error occurred.'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      when(() => mockService.getDocument('d1')).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry re-fetches document', (tester) async {
      int callCount = 0;
      when(() => mockService.getDocument('d2')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(statusCode: 500, message: 'Error');
        }
        return Future.value(textDoc);
      });
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // After retry, document title should appear
      expect(find.text('My Notes'), findsOneWidget);
    });

    testWidgets('shows document title in app bar', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.text('My Notes'), findsOneWidget);
    });

    testWidgets('shows download button in app bar', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('download button calls downloadDocument', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);
      when(() => mockService.downloadDocument('d2'))
          .thenAnswer((_) async => [0x48, 0x65, 0x6C, 0x6C, 0x6F]);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockService.downloadDocument('d2')).called(1);
    });

    testWidgets('download shows error snackbar on failure', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);
      when(() => mockService.downloadDocument('d2')).thenThrow(
        const ApiException(statusCode: 500, message: 'Download failed'),
      );

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Download failed'), findsOneWidget);
    });

    testWidgets('shows edit button for editable docs', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_document), findsOneWidget);
    });

    testWidgets('hides edit button for non-editable docs', (tester) async {
      when(() => mockService.getDocument('d3'))
          .thenAnswer((_) async => markdownDoc);
      when(() => mockService.getDocumentContent('d3'))
          .thenAnswer((_) async => markdownContent);

      await tester.pumpWidget(buildScreen(documentId: 'd3'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_document), findsNothing);
    });

    testWidgets('edit button navigates to edit screen', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_document));
      await tester.pumpAndSettle();

      expect(find.text('Editor Screen'), findsOneWidget);
    });

    testWidgets('back button navigates to detail screen', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Detail Screen'), findsOneWidget);
    });

    testWidgets('text doc displays full text content', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      // Text is rendered through the Markdown widget
      expect(find.byType(Markdown), findsOneWidget);
      expect(
        find.textContaining(
            'Hello, this is plain text content for the viewer.'),
        findsAny,
      );
    });

    testWidgets('text doc extracts plain text from Quill Delta',
        (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd2',
                title: 'My Notes',
                content: '[{"insert":"Delta content here\\n"}]',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      // Text is rendered through the Markdown widget after Quill extraction
      expect(find.byType(Markdown), findsOneWidget);
      expect(find.textContaining('Delta content here'), findsAny);
    });

    testWidgets('markdown doc renders with Markdown widget', (tester) async {
      when(() => mockService.getDocument('d3'))
          .thenAnswer((_) async => markdownDoc);
      when(() => mockService.getDocumentContent('d3'))
          .thenAnswer((_) async => markdownContent);

      await tester.pumpWidget(buildScreen(documentId: 'd3'));
      await tester.pumpAndSettle();

      // Markdown widget renders "Hello" as a heading, "markdown" as bold
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('quill delta doc renders with QuillEditor', (tester) async {
      when(() => mockService.getDocument('d5'))
          .thenAnswer((_) async => quillDoc);
      when(() => mockService.getDocumentContent('d5'))
          .thenAnswer((_) async => quillContent);

      await tester.pumpWidget(buildScreen(documentId: 'd5'));
      await tester.pumpAndSettle();

      // QuillEditor widget is present (it renders rich text internally)
      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('shows empty content error for null text content',
        (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => emptyContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.text('Empty Content'), findsOneWidget);
      expect(
        find.text('No content available for this document.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when content fetch fails', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2')).thenThrow(
        const ApiException(statusCode: 500, message: 'Content unavailable'),
      );

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);
      expect(find.text('Content unavailable'), findsOneWidget);
    });

    testWidgets('shows generic error for non-API content fetch failure',
        (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load document content.'), findsOneWidget);
    });

    testWidgets('content retry re-fetches content', (tester) async {
      int callCount = 0;
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(statusCode: 500, message: 'Error');
        }
        return Future.value(textContent);
      });

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.text('Load Failed'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'Hello, this is plain text content for the viewer.'),
        findsAny,
      );
    });

    testWidgets('PDF doc calls downloadDocument for bytes', (tester) async {
      when(() => mockService.getDocument('d1'))
          .thenAnswer((_) async => pdfDoc);
      // Return minimal bytes — PdfViewPinch will fail to parse, which is fine for the test
      when(() => mockService.downloadDocument('d1'))
          .thenAnswer((_) async => [0x25, 0x50, 0x44, 0x46]);

      await tester.pumpWidget(buildScreen());
      // Use pump instead of pumpAndSettle — PdfViewPinch has ongoing animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockService.downloadDocument('d1')).called(1);
    });

    testWidgets('image doc calls downloadDocument for bytes', (tester) async {
      when(() => mockService.getDocument('d4'))
          .thenAnswer((_) async => imageDoc);
      // 1x1 red PNG
      when(() => mockService.downloadDocument('d4')).thenAnswer(
        (_) async => [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
          0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
          0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
          0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
          0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
          0x44, 0xAE, 0x42, 0x60, 0x82,
        ],
      );

      await tester.pumpWidget(buildScreen(documentId: 'd4'));
      await tester.pumpAndSettle();

      verify(() => mockService.downloadDocument('d4')).called(1);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('text doc calls getDocumentContent', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => textContent);

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      verify(() => mockService.getDocumentContent('d2')).called(1);
      // Should NOT call downloadDocument for text
      verifyNever(() => mockService.downloadDocument('d2'));
    });

    testWidgets('shows filename as title when displayName is null',
        (tester) async {
      const noNameDoc = KnowledgeDocumentModel(
        id: 'd6',
        filename: 'unnamed.txt',
        displayName: null,
        mimeType: 'text/plain',
        fileSizeBytes: 100,
        status: 'INDEXED',
        chunkCount: 1,
        hasContent: true,
        editable: false,
      );

      when(() => mockService.getDocument('d6'))
          .thenAnswer((_) async => noNameDoc);
      when(() => mockService.getDocumentContent('d6'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd6',
                title: 'unnamed.txt',
                content: 'Some content',
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd6'));
      await tester.pumpAndSettle();

      expect(find.text('unnamed.txt'), findsOneWidget);
    });

    testWidgets('text doc renders structured content with markdown formatting',
        (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd2',
                title: 'My Notes',
                content: 'Ingredients:\n2 cups flour\n1 cup sugar',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      // Header and list items are rendered
      expect(find.textContaining('Ingredients'), findsAny);
      expect(find.textContaining('2 cups flour'), findsAny);
      expect(find.textContaining('1 cup sugar'), findsAny);
    });

    testWidgets('text doc formats numbered lists', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd2',
                title: 'My Notes',
                content: '1. First step\n2. Second step',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      expect(find.textContaining('First step'), findsAny);
      expect(find.textContaining('Second step'), findsAny);
    });

    testWidgets('text doc formats key-value pairs with bold labels',
        (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd2',
                title: 'My Notes',
                content: 'Prep Time: 30 min\nServes: 8',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      expect(find.textContaining('Prep Time'), findsAny);
      expect(find.textContaining('30 min'), findsAny);
      expect(find.textContaining('Serves'), findsAny);
    });

    testWidgets('text doc preserves existing markdown syntax',
        (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd2',
                title: 'My Notes',
                content: '# My Title\n\nSome **bold** text.',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      // Heading text rendered (without the # prefix)
      expect(find.textContaining('My Title'), findsAny);
      // Bold text rendered
      expect(find.textContaining('bold'), findsAny);
    });

    testWidgets('text doc detects title from first line', (tester) async {
      when(() => mockService.getDocument('d2'))
          .thenAnswer((_) async => textDoc);
      when(() => mockService.getDocumentContent('d2'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd2',
                title: 'My Notes',
                content: 'Chocolate Cake\n\nA delicious recipe.',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd2'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
      // Title "Chocolate Cake" rendered as heading
      expect(find.textContaining('Chocolate Cake'), findsAny);
      expect(find.textContaining('delicious recipe'), findsAny);
    });

    testWidgets('edit button hidden for non-owned shared docs',
        (tester) async {
      const sharedDoc = KnowledgeDocumentModel(
        id: 'd20',
        filename: 'shared-notes.txt',
        displayName: 'Shared Notes',
        mimeType: 'text/plain',
        fileSizeBytes: 256,
        status: 'INDEXED',
        chunkCount: 1,
        hasContent: true,
        editable: true,
        isShared: true,
        isOwner: false,
        ownerDisplayName: 'Jane',
      );

      when(() => mockService.getDocument('d20'))
          .thenAnswer((_) async => sharedDoc);
      when(() => mockService.getDocumentContent('d20'))
          .thenAnswer((_) async => const DocumentContentModel(
                documentId: 'd20',
                title: 'Shared Notes',
                content: 'Some shared content',
                editable: true,
              ));

      await tester.pumpWidget(buildScreen(documentId: 'd20'));
      await tester.pumpAndSettle();

      // editable is true from server but isOwner is false, so canEdit is false
      expect(find.byIcon(Icons.edit_document), findsNothing);
    });
  });
}
