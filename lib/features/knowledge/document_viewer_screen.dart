import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/knowledge_document_model.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/shared/utils/download_utils.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';
import 'package:pdfx/pdfx.dart';

/// Provider for a single knowledge document by ID (for the viewer).
final _viewerDocumentProvider =
    FutureProvider.autoDispose.family<KnowledgeDocumentModel, String>(
  (ref, documentId) async {
    final service = ref.watch(knowledgeServiceProvider);
    return service.getDocument(documentId);
  },
);

/// Full-screen document viewer that renders content based on MIME type.
///
/// Supports:
/// - **PDF** (`application/pdf`) — rendered with [PdfViewPinch]
/// - **Images** (`image/*`) — rendered with [InteractiveViewer] + [Image.memory]
/// - **Markdown** (`text/markdown`, `text/x-markdown`) — rendered with [Markdown]
/// - **Quill Delta** (`application/x-quill-delta`) — rendered with read-only [QuillEditor]
/// - **Text / other** — rendered with [SelectableText]
class DocumentViewerScreen extends ConsumerStatefulWidget {
  /// The document ID to display.
  final String documentId;

  /// Creates a [DocumentViewerScreen] for the given [documentId].
  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

/// State for [DocumentViewerScreen] managing content loading and format dispatch.
class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  bool _isDownloading = false;

  /// Whether the MIME type requires raw bytes (PDF, images).
  static bool _needsBytes(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType == 'application/pdf' || mimeType.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(_viewerDocumentProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/knowledge/${widget.documentId}'),
        ),
        title: docAsync.when(
          loading: () => const Text('Document'),
          error: (_, __) => const Text('Document'),
          data: (doc) => Text(
            doc.displayName ?? doc.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          docAsync.whenOrNull(
                data: (doc) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (doc.editable)
                      IconButton(
                        icon: const Icon(Icons.edit_document),
                        tooltip: 'Edit',
                        onPressed: () =>
                            context.go('/knowledge/${doc.id}/edit'),
                      ),
                    IconButton(
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed:
                          _isDownloading ? null : () => _downloadDocument(doc),
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
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
              ref.invalidate(_viewerDocumentProvider(widget.documentId)),
        ),
        data: (doc) => _DocumentContentLoader(
          documentId: widget.documentId,
          mimeType: doc.mimeType,
          needsBytes: _needsBytes(doc.mimeType),
        ),
      ),
    );
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
}

/// Loads content (bytes or text) and delegates to the appropriate viewer widget.
class _DocumentContentLoader extends ConsumerStatefulWidget {
  final String documentId;
  final String? mimeType;
  final bool needsBytes;

  const _DocumentContentLoader({
    required this.documentId,
    required this.mimeType,
    required this.needsBytes,
  });

  @override
  ConsumerState<_DocumentContentLoader> createState() =>
      _DocumentContentLoaderState();
}

/// State for [_DocumentContentLoader] managing async content fetching.
class _DocumentContentLoaderState
    extends ConsumerState<_DocumentContentLoader> {
  Uint8List? _bytes;
  String? _textContent;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(knowledgeServiceProvider);
      if (widget.needsBytes) {
        final bytes = await service.downloadDocument(widget.documentId);
        if (mounted) {
          setState(() {
            _bytes = Uint8List.fromList(bytes);
            _loading = false;
          });
        }
      } else {
        final content = await service.getDocumentContent(widget.documentId);
        if (mounted) {
          setState(() {
            _textContent = content.content;
            _loading = false;
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load document content.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();

    if (_error != null) {
      return ErrorView(
        title: 'Load Failed',
        message: _error!,
        onRetry: _loadContent,
      );
    }

    final mime = widget.mimeType ?? '';

    if (mime == 'application/pdf') {
      if (_bytes == null || _bytes!.isEmpty) {
        return const ErrorView(
          title: 'Empty Content',
          message: 'No content available for this document.',
        );
      }
      return _PdfDocumentView(bytes: _bytes!);
    }

    if (mime.startsWith('image/')) {
      if (_bytes == null || _bytes!.isEmpty) {
        return const ErrorView(
          title: 'Empty Content',
          message: 'No content available for this document.',
        );
      }
      return _ImageDocumentView(bytes: _bytes!);
    }

    final text = _textContent ?? '';
    if (text.isEmpty) {
      return const ErrorView(
        title: 'Empty Content',
        message: 'No content available for this document.',
      );
    }

    if (mime == 'text/markdown' || mime == 'text/x-markdown') {
      return _MarkdownDocumentView(content: text);
    }

    if (mime == 'application/x-quill-delta') {
      return _QuillDocumentView(content: text);
    }

    // text/plain and all other types — extract plain text from Quill Delta if possible
    return _TextDocumentView(content: text);
  }
}

// ── PDF Viewer ──────────────────────────────────────────────────────────────

/// Renders a PDF document using a pinch-to-zoom viewer.
class _PdfDocumentView extends StatefulWidget {
  final Uint8List bytes;

  const _PdfDocumentView({required this.bytes});

  @override
  State<_PdfDocumentView> createState() => _PdfDocumentViewState();
}

/// State for [_PdfDocumentView] managing the PDF controller lifecycle.
class _PdfDocumentViewState extends State<_PdfDocumentView> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _pdfController,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const LoadingIndicator(),
        pageLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (_, error) => ErrorView(
          title: 'PDF Error',
          message: 'Failed to render PDF: $error',
        ),
      ),
    );
  }
}

// ── Image Viewer ────────────────────────────────────────────────────────────

/// Renders an image with pinch-to-zoom and pan support.
class _ImageDocumentView extends StatelessWidget {
  final Uint8List bytes;

  const _ImageDocumentView({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, error, __) => ErrorView(
            title: 'Image Error',
            message: 'Failed to render image: $error',
          ),
        ),
      ),
    );
  }
}

// ── Markdown Viewer ─────────────────────────────────────────────────────────

/// Renders Markdown content with proper formatting.
class _MarkdownDocumentView extends StatelessWidget {
  final String content;

  const _MarkdownDocumentView({required this.content});

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: content,
      selectable: true,
      padding: const EdgeInsets.all(16),
    );
  }
}

// ── Quill Delta Viewer ──────────────────────────────────────────────────────

/// Renders Quill Delta JSON content in a read-only QuillEditor.
class _QuillDocumentView extends StatefulWidget {
  final String content;

  const _QuillDocumentView({required this.content});

  @override
  State<_QuillDocumentView> createState() => _QuillDocumentViewState();
}

/// State for [_QuillDocumentView] managing the Quill controller lifecycle.
class _QuillDocumentViewState extends State<_QuillDocumentView> {
  QuillController? _controller;
  String? _fallbackText;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      final deltaJson = jsonDecode(widget.content) as List<dynamic>;
      final doc = Document.fromJson(deltaJson);
      _controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (_) {
      _fallbackText = widget.content;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fallbackText != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _fallbackText!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: QuillEditor.basic(
        controller: _controller!,
        config: const QuillEditorConfig(
          showCursor: false,
        ),
      ),
    );
  }
}

// ── Text Viewer ─────────────────────────────────────────────────────────────

/// Renders plain text content as selectable scrollable text.
///
/// If the content appears to be Quill Delta JSON, extracts the plain text first.
class _TextDocumentView extends StatelessWidget {
  final String content;

  const _TextDocumentView({required this.content});

  @override
  Widget build(BuildContext context) {
    final displayText = _extractPlainText(content);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        displayText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
    );
  }

  /// Extracts plain text from Quill Delta JSON, or returns the raw string.
  static String _extractPlainText(String content) {
    try {
      final ops = jsonDecode(content) as List<dynamic>;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map<String, dynamic>) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      final extracted = buffer.toString().trim();
      return extracted.isNotEmpty ? extracted : content;
    } catch (_) {
      return content;
    }
  }
}
