import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/epub_bookmark_model.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/epub_bookmark_service.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';
import 'package:epub_view/epub_view.dart' as epub;
import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
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

/// State for [BookReaderScreen] managing content download and format-specific rendering.
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
      'EPUB' => _EpubReaderView(
          bytes: _contentBytes!,
          ebookId: widget.ebook.id,
          bookTitle: widget.ebook.title,
        ),
      'TXT' => _TextReaderView(bytes: _contentBytes!),
      _ => _UnsupportedFormatView(
          format: widget.ebook.format,
          title: widget.ebook.title,
        ),
    };
  }
}

// ── PDF Reader ────────────────────────────────────────────────────────────

/// Renders a PDF document using a pinch-to-zoom viewer.
class _PdfReaderView extends StatefulWidget {
  final Uint8List bytes;

  const _PdfReaderView({required this.bytes});

  @override
  State<_PdfReaderView> createState() => _PdfReaderViewState();
}

/// State for [_PdfReaderView] managing the PDF controller lifecycle.
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

// ── EPUB Reader ──────────────────────────────────────────────────────────

/// Renders an EPUB document with toolbar, progress bar, chapter navigation,
/// and bookmark support.
class _EpubReaderView extends ConsumerStatefulWidget {
  final Uint8List bytes;
  final String ebookId;
  final String bookTitle;

  const _EpubReaderView({
    required this.bytes,
    required this.ebookId,
    required this.bookTitle,
  });

  @override
  ConsumerState<_EpubReaderView> createState() => _EpubReaderViewState();
}

/// State for [_EpubReaderView] managing the EPUB controller lifecycle,
/// chapter navigation, progress tracking, and bookmark persistence.
class _EpubReaderViewState extends ConsumerState<_EpubReaderView> {
  epub.EpubController? _epubController;
  List<EpubViewChapter> _chapters = [];
  int _currentChapter = 1;
  int _totalChapters = 0;
  String? _currentChapterTitle;
  double _overallProgress = 0.0;
  double _chapterProgress = 0.0;
  bool _isBookmarkAtCurrentPosition = false;
  String? _currentCfi;
  Timer? _debounceTimer;
  bool _isInitialized = false;

  EpubBookmarkService get _bookmarkService =>
      ref.read(epubBookmarkServiceProvider);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  /// Loads saved reading state and creates the controller with resume CFI.
  Future<void> _initController() async {
    final state = await _bookmarkService.getReadingState(widget.ebookId);
    if (!mounted) return;

    _epubController = epub.EpubController(
      document: epub.EpubDocument.openData(widget.bytes),
      epubCfi: state.lastPositionCfi,
    );

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Fire-and-forget final position save
    if (_currentCfi != null) {
      _bookmarkService.saveLastPosition(widget.ebookId, _currentCfi!);
    }
    _epubController?.dispose();
    super.dispose();
  }

  /// Called when the EPUB document finishes loading.
  void _onDocumentLoaded(epub.EpubBook document) {
    final chapters = _epubController!.tableOfContents();
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _totalChapters = chapters.length;
      });
    }
  }

  /// Determines the current TOC chapter from the scroll position index.
  ///
  /// Finds the last chapter whose [startIndex] is <= the current position,
  /// which is more reliable than the library's internal chapter tracking
  /// for EPUBs with complex structure (e.g. Project Gutenberg).
  int _chapterIndexFromPosition(int positionIndex) {
    int chapterIdx = 0;
    for (int i = 0; i < _chapters.length; i++) {
      if (_chapters[i].startIndex <= positionIndex) {
        chapterIdx = i;
      } else {
        break;
      }
    }
    return chapterIdx;
  }

  /// Called when the visible chapter changes.
  void _onChapterChanged(EpubChapterViewValue? value) {
    if (value == null) return;

    _chapterProgress = value.progress.clamp(0.0, 100.0);

    // Compute chapter from scroll position against TOC startIndexes
    // rather than trusting the library's chapterNumber, which can be
    // wrong for EPUBs with complex structure (e.g. Project Gutenberg).
    final posIndex = value.position.index;
    final chapterIdx = _chapters.isNotEmpty
        ? _chapterIndexFromPosition(posIndex)
        : 0;
    final chapterNumber = chapterIdx + 1;
    final chapterTitle = _chapters.isNotEmpty
        ? _chapters[chapterIdx].title
        : value.chapter?.Title;

    final totalForProgress = _totalChapters > 0 ? _totalChapters : 1;
    final progress =
        ((chapterNumber - 1) + _chapterProgress / 100.0) / totalForProgress;

    setState(() {
      _currentChapter = chapterNumber;
      _currentChapterTitle = chapterTitle;
      _overallProgress = progress.clamp(0.0, 1.0);
    });

    // Generate CFI and check bookmark status
    final cfi = _epubController!.generateEpubCfi();
    if (cfi != null) {
      _currentCfi = cfi;
      _checkBookmarkStatus(cfi);
    }

    // Debounced auto-save of last position
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (_currentCfi != null) {
        _bookmarkService.saveLastPosition(widget.ebookId, _currentCfi!);
      }
    });
  }

  /// Checks whether the current CFI matches a saved bookmark.
  Future<void> _checkBookmarkStatus(String cfi) async {
    final has = await _bookmarkService.hasBookmarkAtCfi(widget.ebookId, cfi);
    if (mounted) {
      setState(() {
        _isBookmarkAtCurrentPosition = has;
      });
    }
  }

  /// Scrolls to the previous chapter.
  void _goToPreviousChapter() {
    if (_currentChapter <= 1 || _chapters.isEmpty) return;
    // Chapters list is 0-indexed; currentChapter is 1-based
    final targetIndex = _currentChapter - 2;
    if (targetIndex >= 0 && targetIndex < _chapters.length) {
      _epubController!.scrollTo(index: _chapters[targetIndex].startIndex);
    }
  }

  /// Scrolls to the next chapter.
  void _goToNextChapter() {
    if (_currentChapter >= _totalChapters || _chapters.isEmpty) return;
    final targetIndex = _currentChapter;
    if (targetIndex < _chapters.length) {
      _epubController!.scrollTo(index: _chapters[targetIndex].startIndex);
    }
  }

  /// Toggles a bookmark at the current reading position.
  Future<void> _toggleBookmark() async {
    final cfi = _epubController!.generateEpubCfi();
    if (cfi == null) return;

    if (_isBookmarkAtCurrentPosition) {
      await _bookmarkService.removeBookmark(widget.ebookId, cfi);
    } else {
      final bookmark = EpubBookmarkModel(
        cfi: cfi,
        chapterTitle: _currentChapterTitle,
        chapterNumber: _currentChapter,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      await _bookmarkService.addBookmark(widget.ebookId, bookmark);
    }

    if (mounted) {
      setState(() {
        _isBookmarkAtCurrentPosition = !_isBookmarkAtCurrentPosition;
      });
    }
  }

  /// Shows the Table of Contents as a bottom sheet.
  void _showTableOfContents() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Table of Contents',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final isSubChapter = chapter.type == 'subchapter';
                  final isCurrent = index == _currentChapter - 1;

                  return ListTile(
                    contentPadding: EdgeInsets.only(
                      left: isSubChapter ? 32.0 : 16.0,
                      right: 16.0,
                    ),
                    title: Text(
                      chapter.title ?? 'Chapter ${index + 1}',
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontSize: isSubChapter ? 13 : 14,
                      ),
                    ),
                    selected: isCurrent,
                    onTap: () {
                      Navigator.pop(context);
                      _epubController!
                          .scrollTo(index: chapter.startIndex);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the bookmarks list as a bottom sheet.
  void _showBookmarksList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.8,
        builder: (context, scrollController) => FutureBuilder<List<EpubBookmarkModel>>(
          future: _bookmarkService.getBookmarks(widget.ebookId),
          builder: (context, snapshot) {
            final bookmarks = snapshot.data ?? [];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bookmarks (${bookmarks.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                if (bookmarks.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No bookmarks yet'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = bookmarks[index];
                        final createdAt = DateTime.tryParse(bookmark.createdAt);
                        final timeLabel = createdAt != null
                            ? DateFormatter.formatRelative(createdAt)
                            : '';

                        return Dismissible(
                          key: ValueKey(bookmark.cfi),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Theme.of(context).colorScheme.error,
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                          onDismissed: (_) {
                            _bookmarkService.removeBookmark(
                              widget.ebookId,
                              bookmark.cfi,
                            );
                          },
                          child: ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(
                              bookmark.label ??
                                  bookmark.chapterTitle ??
                                  'Chapter ${bookmark.chapterNumber}',
                            ),
                            subtitle: Text(
                              'Chapter ${bookmark.chapterNumber}'
                              '${timeLabel.isNotEmpty ? ' \u2022 $timeLabel' : ''}',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _epubController!.gotoEpubCfi(bookmark.cfi);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _epubController == null) {
      return const LoadingIndicator();
    }

    final theme = Theme.of(context);
    final isFirstChapter = _currentChapter <= 1;
    final isLastChapter =
        _totalChapters > 0 && _currentChapter >= _totalChapters;

    return Column(
      children: [
        // ── Toolbar ──
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous chapter',
                  onPressed: isFirstChapter ? null : _goToPreviousChapter,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next chapter',
                  onPressed: isLastChapter ? null : _goToNextChapter,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.toc),
                  tooltip: 'Table of Contents',
                  onPressed:
                      _chapters.isNotEmpty ? _showTableOfContents : null,
                ),
                IconButton(
                  icon: Icon(
                    _isBookmarkAtCurrentPosition
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                  tooltip: _isBookmarkAtCurrentPosition
                      ? 'Remove bookmark'
                      : 'Add bookmark',
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.collections_bookmark),
                  tooltip: 'View bookmarks',
                  onPressed: _showBookmarksList,
                ),
              ],
            ),
          ),
        ),

        // ── Progress bar ──
        LinearProgressIndicator(
          value: _overallProgress,
          minHeight: 3,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),

        // ── Chapter info row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _currentChapterTitle ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_totalChapters > 0)
                Text(
                  'Chapter $_currentChapter of $_totalChapters',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),

        // ── EPUB content ──
        Expanded(
          child: epub.EpubView(
            controller: _epubController!,
            onChapterChanged: _onChapterChanged,
            onDocumentLoaded: _onDocumentLoaded,
            builders: epub.EpubViewBuilders<epub.DefaultBuilderOptions>(
              options: const epub.DefaultBuilderOptions(),
              loaderBuilder: (_) => const LoadingIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Text Reader ───────────────────────────────────────────────────────────

/// Renders a plain text eBook as selectable scrollable text with serif font.
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

/// Renders a fallback message for eBook formats that lack in-app rendering support.
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
