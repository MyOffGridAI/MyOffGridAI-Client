import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays the Knowledge Vault with document list and upload capability.
///
/// Shows documents with their processing status (PENDING, PROCESSING,
/// INDEXED, FAILED). Supports file upload via [FilePicker] and navigation
/// to document detail view.
class KnowledgeScreen extends ConsumerStatefulWidget {
  /// Creates a [KnowledgeScreen].
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(knowledgeDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Vault')),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadDocument,
        child: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.upload_file),
      ),
      body: docsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load documents',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(knowledgeDocumentsProvider),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.library_books_outlined,
              title: 'Knowledge Vault is empty',
              subtitle: 'Upload documents to teach your AI',
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _DocumentTile(
                document: doc,
                onTap: () => context.go('/knowledge/${doc.id}'),
                onDelete: () => _deleteDocument(doc.id),
                onRetry: doc.isFailed ? () => _retryProcessing(doc.id) : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final service = ref.read(knowledgeServiceProvider);
      await service.uploadDocument(file.name, file.bytes!);
      ref.invalidate(knowledgeDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Document',
      message:
          'This document and all its chunks will be permanently deleted.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(knowledgeServiceProvider);
      await service.deleteDocument(documentId);
      ref.invalidate(knowledgeDocumentsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _retryProcessing(String documentId) async {
    try {
      final service = ref.read(knowledgeServiceProvider);
      await service.retryProcessing(documentId);
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

class _DocumentTile extends StatelessWidget {
  final KnowledgeDocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRetry;

  const _DocumentTile({
    required this.document,
    required this.onTap,
    required this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(document.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: _statusIcon(document.status),
        title: Text(
          document.displayName ?? document.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text('${document.fileSizeBytes} bytes'),
            const SizedBox(width: 8),
            _statusChip(context, document.status),
            if (document.isIndexed) ...[
              const SizedBox(width: 8),
              Text('${document.chunkCount} chunks'),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
                tooltip: 'Retry processing',
              ),
            if (document.uploadedAt != null)
              Text(
                document.uploadedAt ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'INDEXED':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white, size: 18),
        );
      case 'PROCESSING':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          ),
        );
      case 'FAILED':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error, color: Colors.white, size: 18),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.schedule, color: Colors.white, size: 18),
        );
    }
  }

  Widget _statusChip(BuildContext context, String status) {
    final colors = {
      'INDEXED': Colors.green,
      'PROCESSING': Colors.blue,
      'FAILED': Colors.red,
      'PENDING': Colors.grey,
    };
    return Text(
      status,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors[status] ?? Colors.grey,
      ),
    );
  }
}
