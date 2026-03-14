import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';

void main() {
  group('KnowledgeDocumentModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'id': 'doc-1',
        'filename': 'guide.pdf',
        'displayName': 'User Guide',
        'mimeType': 'application/pdf',
        'fileSizeBytes': 1024000,
        'status': 'INDEXED',
        'errorMessage': null,
        'chunkCount': 42,
        'uploadedAt': '2026-03-14T10:00:00Z',
        'processedAt': '2026-03-14T10:05:00Z',
      };

      final model = KnowledgeDocumentModel.fromJson(json);

      expect(model.id, 'doc-1');
      expect(model.filename, 'guide.pdf');
      expect(model.displayName, 'User Guide');
      expect(model.mimeType, 'application/pdf');
      expect(model.fileSizeBytes, 1024000);
      expect(model.status, 'INDEXED');
      expect(model.chunkCount, 42);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'id': 'doc-2'};

      final model = KnowledgeDocumentModel.fromJson(json);

      expect(model.filename, '');
      expect(model.fileSizeBytes, 0);
      expect(model.status, 'PENDING');
      expect(model.chunkCount, 0);
    });

    test('isProcessing returns true for PROCESSING status', () {
      final model = KnowledgeDocumentModel.fromJson(
          {'id': '1', 'status': 'PROCESSING'});
      expect(model.isProcessing, isTrue);
      expect(model.isIndexed, isFalse);
      expect(model.isFailed, isFalse);
    });

    test('isIndexed returns true for INDEXED status', () {
      final model =
          KnowledgeDocumentModel.fromJson({'id': '1', 'status': 'INDEXED'});
      expect(model.isIndexed, isTrue);
      expect(model.isProcessing, isFalse);
    });

    test('isFailed returns true for FAILED status', () {
      final model =
          KnowledgeDocumentModel.fromJson({'id': '1', 'status': 'FAILED'});
      expect(model.isFailed, isTrue);
      expect(model.isIndexed, isFalse);
    });
  });

  group('KnowledgeSearchResultModel', () {
    test('parses from JSON with all fields', () {
      final json = {
        'chunkId': 'chunk-1',
        'documentId': 'doc-1',
        'documentName': 'Guide',
        'content': 'Some content',
        'pageNumber': 5,
        'chunkIndex': 2,
        'similarityScore': 0.92,
      };

      final model = KnowledgeSearchResultModel.fromJson(json);

      expect(model.chunkId, 'chunk-1');
      expect(model.documentId, 'doc-1');
      expect(model.documentName, 'Guide');
      expect(model.content, 'Some content');
      expect(model.pageNumber, 5);
      expect(model.chunkIndex, 2);
      expect(model.similarityScore, 0.92);
    });
  });
}
