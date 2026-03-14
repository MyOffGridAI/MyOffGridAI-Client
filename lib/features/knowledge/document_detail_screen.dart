import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Provider for a single knowledge document by ID.
final _documentProvider =
    FutureProvider.autoDispose.family<KnowledgeDocumentModel, String>(
  (ref, documentId) async {
    final service = ref.watch(knowledgeServiceProvider);
    return service.getDocument(documentId);
  },
);

/// Detail view for a single knowledge document.
///
/// Shows document metadata, processing status, and allows editing
/// the display name.
class DocumentDetailScreen extends ConsumerStatefulWidget {
  /// The document ID to display.
  final String documentId;

  /// Creates a [DocumentDetailScreen] for the given [documentId].
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(_documentProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: docAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load document',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () =>
              ref.invalidate(_documentProvider(widget.documentId)),
        ),
        data: (doc) => _buildDetail(context, doc),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, KnowledgeDocumentModel doc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc.displayName ?? doc.filename,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editDisplayName(doc),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Filename', doc.filename),
                  _infoRow('Size', SizeFormatter.formatBytes(doc.fileSizeBytes)),
                  if (doc.mimeType != null)
                    _infoRow('Type', doc.mimeType!),
                  _infoRow('Status', doc.status),
                  _infoRow('Chunks', '${doc.chunkCount}'),
                  if (doc.uploadedAt != null)
                    _infoRow('Uploaded',
                        DateFormatter.formatFull(DateTime.parse(doc.uploadedAt!))),
                  if (doc.processedAt != null)
                    _infoRow('Processed',
                        DateFormatter.formatFull(DateTime.parse(doc.processedAt!))),
                  if (doc.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _editDisplayName(KnowledgeDocumentModel doc) async {
    final controller =
        TextEditingController(text: doc.displayName ?? doc.filename);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;

    try {
      final service = ref.read(knowledgeServiceProvider);
      await service.updateDisplayName(widget.documentId, name);
      ref.invalidate(_documentProvider(widget.documentId));
      ref.invalidate(knowledgeDocumentsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}
