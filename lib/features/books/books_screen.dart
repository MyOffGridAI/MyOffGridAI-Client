import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Displays the offline library with three tabs: Library (eBooks),
/// Kiwix (ZIM content via WebView), and Gutenberg (search & import).
///
/// Owners/admins can upload eBooks, manage ZIM files, and import
/// books from Project Gutenberg. All authenticated users can browse
/// and read content.
class BooksScreen extends ConsumerStatefulWidget {
  /// Creates a [BooksScreen].
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _gutenbergQuery = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isOwnerOrAdmin =
        user?.role == 'ROLE_OWNER' || user?.role == 'ROLE_ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Library'),
            Tab(icon: Icon(Icons.language), text: 'Kiwix'),
            Tab(icon: Icon(Icons.auto_stories), text: 'Gutenberg'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LibraryTab(
            isOwnerOrAdmin: isOwnerOrAdmin,
            isUploading: _isUploading,
            onUpload: _uploadEbook,
          ),
          const _KiwixTab(),
          _GutenbergTab(
            searchController: _searchController,
            query: _gutenbergQuery,
            isOwnerOrAdmin: isOwnerOrAdmin,
            onSearch: (query) => setState(() => _gutenbergQuery = query),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadEbook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf', 'mobi', 'azw', 'txt', 'html', 'htm'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final title = await _showTitleDialog(file.name);
    if (title == null || title.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final service = ref.read(libraryServiceProvider);
      await service.uploadEbook(
        filename: file.name,
        bytes: file.bytes!,
        title: title,
      );
      ref.invalidate(ebooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('eBook uploaded successfully')),
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

  Future<String?> _showTitleDialog(String defaultTitle) {
    final nameWithoutExt = defaultTitle.contains('.')
        ? defaultTitle.substring(0, defaultTitle.lastIndexOf('.'))
        : defaultTitle;
    final controller = TextEditingController(text: nameWithoutExt);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter book title',
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}

// ── Library Tab (eBooks) ──────────────────────────────────────────────────

class _LibraryTab extends ConsumerWidget {
  final bool isOwnerOrAdmin;
  final bool isUploading;
  final VoidCallback onUpload;

  const _LibraryTab({
    required this.isOwnerOrAdmin,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ebooksAsync =
        ref.watch(ebooksProvider((search: null, format: null)));

    return Column(
      children: [
        if (isOwnerOrAdmin)
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isUploading ? null : onUpload,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isUploading ? 'Uploading...' : 'Upload eBook'),
              ),
            ),
          ),
        Expanded(
          child: ebooksAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              title: 'Load Failed',
              message: e.toString(),
              onRetry: () => ref.invalidate(ebooksProvider),
            ),
            data: (ebooks) {
              if (ebooks.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.menu_book,
                  title: 'No eBooks yet',
                  subtitle: 'Upload an eBook or import from Gutenberg',
                );
              }
              return ListView.builder(
                itemCount: ebooks.length,
                itemBuilder: (context, index) =>
                    _EbookTile(ebook: ebooks[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EbookTile extends StatelessWidget {
  final EbookModel ebook;

  const _EbookTile({required this.ebook});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_formatIcon(ebook.format)),
      title: Text(ebook.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (ebook.author != null) ebook.author!,
          ebook.format,
          _formatSize(ebook.fileSizeBytes),
        ].join(' \u2022 '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ebook.isFromGutenberg
          ? Tooltip(
              message: 'From Project Gutenberg',
              child: Icon(Icons.public,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            )
          : null,
      onTap: () => context.go(
        AppConstants.routeBookReader,
        extra: ebook,
      ),
    );
  }

  IconData _formatIcon(String format) {
    return switch (format.toUpperCase()) {
      'PDF' => Icons.picture_as_pdf,
      'EPUB' => Icons.auto_stories,
      'TXT' => Icons.article,
      'HTML' => Icons.code,
      _ => Icons.book,
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Kiwix Tab (WebView) ──────────────────────────────────────────────────

class _KiwixTab extends ConsumerWidget {
  const _KiwixTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(kiwixStatusProvider);

    return statusAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(
        title: 'Load Failed',
        message: e.toString(),
        onRetry: () => ref.invalidate(kiwixStatusProvider),
      ),
      data: (status) {
        if (!status.available || status.url == null) {
          return const EmptyStateView(
            icon: Icons.language,
            title: 'Kiwix Unavailable',
            subtitle: 'The Kiwix server is not reachable. '
                'Check that the Kiwix container is running.',
          );
        }
        return _KiwixWebView(url: status.url!);
      },
    );
  }
}

class _KiwixWebView extends StatefulWidget {
  final String url;

  const _KiwixWebView({required this.url});

  @override
  State<_KiwixWebView> createState() => _KiwixWebViewState();
}

class _KiwixWebViewState extends State<_KiwixWebView>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WebViewWidget(controller: _controller);
  }
}

// ── Gutenberg Tab (Search & Import) ──────────────────────────────────────

class _GutenbergTab extends ConsumerWidget {
  final TextEditingController searchController;
  final String query;
  final bool isOwnerOrAdmin;
  final ValueChanged<String> onSearch;

  const _GutenbergTab({
    required this.searchController,
    required this.query,
    required this.isOwnerOrAdmin,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search Project Gutenberg...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                      },
                    )
                  : null,
            ),
            onSubmitted: onSearch,
          ),
        ),
        Expanded(
          child: query.isEmpty
              ? const EmptyStateView(
                  icon: Icons.auto_stories,
                  title: 'Search Gutenberg',
                  subtitle:
                      'Search 70,000+ free public domain books from Project Gutenberg',
                )
              : _GutenbergResults(
                  query: query,
                  isOwnerOrAdmin: isOwnerOrAdmin,
                ),
        ),
      ],
    );
  }
}

/// Provider for Gutenberg search results keyed by query string.
final gutenbergSearchProvider = FutureProvider.autoDispose
    .family<GutenbergSearchResultModel, String>((ref, query) async {
  final service = ref.watch(libraryServiceProvider);
  return service.searchGutenberg(query);
});

class _GutenbergResults extends ConsumerWidget {
  final String query;
  final bool isOwnerOrAdmin;

  const _GutenbergResults({
    required this.query,
    required this.isOwnerOrAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(gutenbergSearchProvider(query));

    return resultsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(
        title: 'Search Failed',
        message: 'Search unavailable. The server may be offline.',
        onRetry: () => ref.invalidate(gutenbergSearchProvider(query)),
      ),
      data: (result) {
        if (result.results.isEmpty) {
          return const EmptyStateView(
            icon: Icons.search_off,
            title: 'No results',
            subtitle: 'Try a different search term',
          );
        }
        return ListView.builder(
          itemCount: result.results.length,
          itemBuilder: (context, index) => _GutenbergBookTile(
            book: result.results[index],
            isOwnerOrAdmin: isOwnerOrAdmin,
          ),
        );
      },
    );
  }
}

class _GutenbergBookTile extends ConsumerStatefulWidget {
  final GutenbergBookModel book;
  final bool isOwnerOrAdmin;

  const _GutenbergBookTile({
    required this.book,
    required this.isOwnerOrAdmin,
  });

  @override
  ConsumerState<_GutenbergBookTile> createState() =>
      _GutenbergBookTileState();
}

class _GutenbergBookTileState extends ConsumerState<_GutenbergBookTile> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return ListTile(
      leading: const Icon(Icons.auto_stories),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (book.authors.isNotEmpty) book.authors.first,
          if (book.languages.isNotEmpty) book.languages.first.toUpperCase(),
          '${book.downloadCount} downloads',
        ].join(' \u2022 '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: widget.isOwnerOrAdmin
          ? IconButton(
              icon: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Import to library',
              onPressed: _importing ? null : _importBook,
            )
          : null,
    );
  }

  Future<void> _importBook() async {
    setState(() => _importing = true);
    try {
      final service = ref.read(libraryServiceProvider);
      await service.importGutenbergBook(widget.book.id);
      ref.invalidate(ebooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.book.title}" imported successfully'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}
