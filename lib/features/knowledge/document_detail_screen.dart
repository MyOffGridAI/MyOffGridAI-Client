import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/utils/download_utils.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
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
/// Shows document metadata, processing status, content preview,
/// and allows editing the display name, downloading, and editing content.
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
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(_documentProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/knowledge'),
        ),
        title: const Text('Document Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete document',
            onPressed: () => _deleteDocument(),
          ),
        ],
      ),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (doc.editable)
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.go('/knowledge/${doc.id}/edit'),
                          icon: const Icon(Icons.edit_document, size: 18),
                          label: const Text('Edit'),
                        ),
                      if (doc.editable) const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isDownloading
                            ? null
                            : () => _downloadDocument(doc),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (doc.hasContent) ...[
            const SizedBox(height: 16),
            _buildContentPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    final contentAsync =
        ref.watch(documentContentProvider(widget.documentId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            contentAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Failed to load content preview.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (content) {
                String plainText = '';
                if (content.content != null && content.content!.isNotEmpty) {
                  try {
                    final ops =
                        jsonDecode(content.content!) as List<dynamic>;
                    final buffer = StringBuffer();
                    for (final op in ops) {
                      if (op is Map<String, dynamic>) {
                        final insert = op['insert'];
                        if (insert is String) {
                          buffer.write(insert);
                        }
                      }
                    }
                    plainText = buffer.toString().trim();
                  } catch (_) {
                    plainText = content.content!;
                  }
                }

                if (plainText.isEmpty) {
                  return const Text(
                    'No content available.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  );
                }

                // Show first 2000 characters
                final preview = plainText.length > 2000
                    ? '${plainText.substring(0, 2000)}...'
                    : plainText;

                return SelectableText(
                  preview,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
          ],
        ),
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

  Future<void> _deleteDocument() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Document',
      message: 'This document and all its chunks will be permanently deleted.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(knowledgeServiceProvider);
      await service.deleteDocument(widget.documentId);
      ref.invalidate(knowledgeDocumentsProvider);
      if (mounted) {
        context.go('/knowledge');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _downloadDocument(KnowledgeDocumentModel doc) async {
    setState(() => _isDownloading = true);
    try {
      final service = ref.read(knowledgeServiceProvider);
      final bytes = await service.downloadDocument(doc.id);
      DownloadUtils.downloadBytes(bytes, doc.filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
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
