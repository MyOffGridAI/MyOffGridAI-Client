import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';
import 'package:pdfx/pdfx.dart';

/// Displays an eBook for reading based on its format.
///
/// Supports:
/// - **PDF** — rendered natively via [PdfView]
/// - **TXT** — displayed as selectable scrollable text
/// - **EPUB / MOBI / AZW / HTML** — shows a download prompt since native
///   rendering requires platform-specific viewers
///
/// The [ebook] is passed via GoRouter `extra` parameter.
class BookReaderScreen extends ConsumerStatefulWidget {
  /// The eBook to display.
  final EbookModel ebook;

  /// Creates a [BookReaderScreen] for the given [ebook].
  const BookReaderScreen({super.key, required this.ebook});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  Uint8List? _contentBytes;
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
      final service = ref.read(libraryServiceProvider);
      final bytes = await service.downloadEbookContent(widget.ebook.id);
      if (mounted) {
        setState(() {
          _contentBytes = Uint8List.fromList(bytes);
          _loading = false;
        });
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
          _error = 'Failed to load book content';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ebook.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.ebook.author != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  widget.ebook.author!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorView(
        title: 'Load Failed',
        message: _error!,
        onRetry: _loadContent,
      );
    }
    if (_contentBytes == null || _contentBytes!.isEmpty) {
      return const ErrorView(
        title: 'Empty Content',
        message: 'No content available for this book',
      );
    }

    final format = widget.ebook.format.toUpperCase();
    return switch (format) {
      'PDF' => _PdfReaderView(bytes: _contentBytes!),
      'TXT' => _TextReaderView(bytes: _contentBytes!),
      _ => _UnsupportedFormatView(
          format: widget.ebook.format,
          title: widget.ebook.title,
        ),
    };
  }
}

// ── PDF Reader ────────────────────────────────────────────────────────────

class _PdfReaderView extends StatefulWidget {
  final Uint8List bytes;

  const _PdfReaderView({required this.bytes});

  @override
  State<_PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<_PdfReaderView> {
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

// ── Text Reader ───────────────────────────────────────────────────────────

class _TextReaderView extends StatelessWidget {
  final Uint8List bytes;

  const _TextReaderView({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final text = String.fromCharCodes(bytes);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              fontFamily: 'serif',
            ),
      ),
    );
  }
}

// ── Unsupported Format ────────────────────────────────────────────────────

class _UnsupportedFormatView extends StatelessWidget {
  final String format;
  final String title;

  const _UnsupportedFormatView({
    required this.format,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'In-app reading for $format files is not yet supported.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The file has been downloaded to your device library. '
              'Use an external reader app to open it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
