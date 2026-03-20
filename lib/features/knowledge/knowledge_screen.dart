import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/enrichment_models.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/enrichment_service.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/core/services/system_service.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Maps a MIME type and filename to a short document type label.
///
/// Returns a human-readable abbreviation (e.g., "PDF", "DOCX") based on
/// [mimeType]. Falls back to the uppercase file extension from [filename]
/// when the MIME type is null or unrecognized.
@visibleForTesting
String docTypeLabel(String? mimeType, String filename) {
  const mimeLabels = {
    'application/pdf': 'PDF',
    'text/plain': 'TXT',
    'text/markdown': 'MD',
    'application/msword': 'DOC',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        'DOCX',
    'application/vnd.ms-excel': 'XLS',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'XLSX',
    'application/vnd.ms-powerpoint': 'PPT',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        'PPTX',
    'application/rtf': 'RTF',
    'text/html': 'HTML',
    'application/json': 'JSON',
  };

  if (mimeType != null && mimeLabels.containsKey(mimeType)) {
    return mimeLabels[mimeType]!;
  }

  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex != -1 && dotIndex < filename.length - 1) {
    return filename.substring(dotIndex + 1).toUpperCase();
  }
  return '';
}

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

/// State for [KnowledgeScreen] managing document upload, drag-and-drop, and enrichment sheets.
class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  static const _allowedExtensions = [
    'pdf', 'txt', 'md', 'doc', 'docx', 'rtf', 'xlsx', 'xls', 'pptx', 'ppt'
  ];

  bool _isUploading = false;
  bool _isDragging = false;
  String _sortField = 'name';
  bool _sortAscending = true;

  /// Sorts [docs] in place by the active sort field and direction.
  List<KnowledgeDocumentModel> _sortDocuments(
      List<KnowledgeDocumentModel> docs) {
    final sorted = List<KnowledgeDocumentModel>.from(docs);
    sorted.sort((a, b) {
      int cmp;
      if (_sortField == 'type') {
        final aLabel =
            docTypeLabel(a.mimeType, a.filename).toLowerCase();
        final bLabel =
            docTypeLabel(b.mimeType, b.filename).toLowerCase();
        cmp = aLabel.compareTo(bLabel);
      } else {
        final aName =
            (a.displayName ?? a.filename).toLowerCase();
        final bName =
            (b.displayName ?? b.filename).toLowerCase();
        cmp = aName.compareTo(bName);
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(knowledgeDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Fetch URL',
            onPressed: () => _showFetchUrlSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Web Search',
            onPressed: () => _showWebSearchSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Create new document',
            onPressed: () => context.go('/knowledge/new'),
          ),
        ],
      ),
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
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) {
          setState(() => _isDragging = false);
          _handleDroppedFiles(details.files);
        },
        child: Stack(
          children: [
            docsAsync.when(
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
                final sorted = _sortDocuments(docs);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          _SortButton(
                            label: 'Name',
                            isActive: _sortField == 'name',
                            ascending: _sortAscending,
                            onTap: () => setState(() {
                              if (_sortField == 'name') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortField = 'name';
                                _sortAscending = true;
                              }
                            }),
                          ),
                          const SizedBox(width: 8),
                          _SortButton(
                            label: 'Type',
                            isActive: _sortField == 'type',
                            ascending: _sortAscending,
                            onTap: () => setState(() {
                              if (_sortField == 'type') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortField = 'type';
                                _sortAscending = true;
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final doc = sorted[index];
                          return _DocumentTile(
                            document: doc,
                            onTap: () =>
                                context.go('/knowledge/${doc.id}'),
                            onDelete: () => _deleteDocument(doc.id),
                            onRetry: doc.isFailed
                                ? () => _retryProcessing(doc.id)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drop files here',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFetchUrlSheet(BuildContext context) {
    final urlController = TextEditingController();
    bool summarize = false;
    bool fetching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fetch URL',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link),
                  labelText: 'URL',
                  hintText: 'https://example.com/article',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Summarize with Claude'),
                subtitle: const Text('Uses Anthropic API if available'),
                value: summarize,
                onChanged: (v) =>
                    setSheetState(() => summarize = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: fetching
                      ? null
                      : () async {
                          final url = urlController.text.trim();
                          if (url.isEmpty) return;
                          setSheetState(() => fetching = true);
                          try {
                            final service =
                                ref.read(enrichmentServiceProvider);
                            await service.fetchUrl(
                              url: url,
                              summarizeWithClaude: summarize,
                            );
                            ref.invalidate(knowledgeDocumentsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'URL fetched and stored')),
                              );
                            }
                          } on ApiException catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setSheetState(() => fetching = false);
                            }
                          }
                        },
                  icon: fetching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download),
                  label: Text(fetching ? 'Fetching...' : 'Fetch'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => urlController.dispose());
  }

  void _showWebSearchSheet(BuildContext context) {
    final queryController = TextEditingController();
    int storeTopN = 0;
    bool summarize = false;
    bool searching = false;
    List<SearchResultModel>? searchResults;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Web Search',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: queryController,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search query',
                  hintText: 'solar panel maintenance',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Store top results: $storeTopN',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: Slider(
                      value: storeTopN.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      onChanged: (v) =>
                          setSheetState(() => storeTopN = v.round()),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('Summarize with Claude'),
                value: summarize,
                onChanged: (v) =>
                    setSheetState(() => summarize = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: searching
                      ? null
                      : () async {
                          final query = queryController.text.trim();
                          if (query.isEmpty) return;
                          setSheetState(() {
                            searching = true;
                            searchResults = null;
                          });
                          try {
                            final service =
                                ref.read(enrichmentServiceProvider);
                            final result = await service.search(
                              query: query,
                              storeTopN: storeTopN,
                              summarizeWithClaude: summarize,
                            );
                            setSheetState(
                                () => searchResults = result.results);
                            if (storeTopN > 0) {
                              ref.invalidate(
                                  knowledgeDocumentsProvider);
                            }
                          } on ApiException catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setSheetState(() => searching = false);
                            }
                          }
                        },
                  icon: searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(searching ? 'Searching...' : 'Search'),
                ),
              ),
              if (searchResults != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${searchResults!.length} result(s)',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults!.length,
                    itemBuilder: (_, i) {
                      final r = searchResults![i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          r.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).then((_) => queryController.dispose());
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    final validFiles = files.where((f) {
      final ext = f.name.split('.').last.toLowerCase();
      return _allowedExtensions.contains(ext);
    }).toList();

    if (validFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No supported files. Use PDF, TXT, MD, DOC, DOCX, XLSX, XLS, PPTX, or PPT.')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    int uploaded = 0;
    try {
      final storageSettings = await ref.read(storageSettingsProvider.future);
      final maxBytes = storageSettings.maxUploadSizeMb * 1024 * 1024;
      final service = ref.read(knowledgeServiceProvider);
      for (final file in validFiles) {
        final bytes = await file.readAsBytes();
        if (bytes.length > maxBytes) {
          final fileSizeMb = (bytes.length / (1024 * 1024)).ceil();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'File too large (${file.name}: $fileSizeMb MB). Maximum allowed: ${storageSettings.maxUploadSizeMb} MB')),
            );
          }
          continue;
        }
        await service.uploadDocument(file.name, bytes);
        uploaded++;
      }
      ref.invalidate(knowledgeDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$uploaded file(s) uploaded successfully')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  uploaded > 0
                      ? '$uploaded uploaded, then failed: ${e.message}'
                      : e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final storageSettings = await ref.read(storageSettingsProvider.future);
      final maxBytes = storageSettings.maxUploadSizeMb * 1024 * 1024;
      if (file.bytes!.length > maxBytes) {
        final fileSizeMb = (file.bytes!.length / (1024 * 1024)).ceil();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'File too large ($fileSizeMb MB). Maximum allowed: ${storageSettings.maxUploadSizeMb} MB')),
          );
        }
        return;
      }
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

/// Renders a single knowledge document row with status icon, metadata, and action buttons.
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
    return ListTile(
        leading: _statusIcon(document.status),
        title: Text(
          document.displayName ?? document.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(docTypeLabel(document.mimeType, document.filename)),
            const Text(' · '),
            Text(SizeFormatter.formatBytes(document.fileSizeBytes)),
            const Text(' · '),
            _statusChip(context, document.status),
            if (document.isIndexed) ...[
              const Text(' | '),
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
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Delete document',
            ),
          ],
        ),
        onTap: onTap,
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

/// A sort toggle button showing field name and directional arrow.
///
/// Displays an up arrow when [ascending] and active, down arrow when
/// descending and active, and no arrow when inactive.
class _SortButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool ascending;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.isActive,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = isActive ? (ascending ? ' \u2191' : ' \u2193') : '';
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text('$label$arrow'),
    );
  }
}
