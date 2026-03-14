import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/features/knowledge/knowledge_screen.dart';

void main() {
  group('KnowledgeScreen', () {
    Widget buildScreen({List<KnowledgeDocumentModel> documents = const []}) {
      return ProviderScope(
        overrides: [
          knowledgeDocumentsProvider.overrideWith((ref) => documents),
        ],
        child: const MaterialApp(home: KnowledgeScreen()),
      );
    }

    testWidgets('shows empty state when no documents', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Vault is empty'), findsOneWidget);
    });

    testWidgets('displays document list', (tester) async {
      final docs = [
        KnowledgeDocumentModel.fromJson({
          'id': '1',
          'filename': 'guide.pdf',
          'displayName': 'User Guide',
          'fileSizeBytes': 1024,
          'status': 'INDEXED',
          'chunkCount': 10,
        }),
        KnowledgeDocumentModel.fromJson({
          'id': '2',
          'filename': 'notes.txt',
          'fileSizeBytes': 256,
          'status': 'PENDING',
          'chunkCount': 0,
        }),
      ];

      await tester.pumpWidget(buildScreen(documents: docs));
      await tester.pumpAndSettle();

      expect(find.text('User Guide'), findsOneWidget);
      expect(find.text('notes.txt'), findsOneWidget);
    });

    testWidgets('shows upload FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Vault'), findsOneWidget);
    });
  });
}
