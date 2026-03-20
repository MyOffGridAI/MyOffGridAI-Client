import 'dart:async';

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

/// State for [BooksScreen] managing the three-tab layout, Gutenberg search, and eBook uploads.
class _BooksScreenState extends ConsumerState<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _gutenbergQuery = '';
  bool _isUploading = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _gutenbergQuery = value.trim());
    });
    // Update suffix icon reactively
    setState(() {});
  }

  void _onSearchSubmitted(String value) {
    _searchDebounce?.cancel();
    setState(() => _gutenbergQuery = value.trim());
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
            onSearch: _onSearchSubmitted,
            onSearchChanged: _onSearchChanged,
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

/// Renders the Library tab listing uploaded eBooks with an optional upload button.
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

/// Renders a single eBook entry with format icon, metadata, and Gutenberg badge.
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

/// Renders the Kiwix tab showing ZIM content via WebView when available.
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

/// Embeds the Kiwix server content in a WebView with keep-alive support.
class _KiwixWebView extends StatefulWidget {
  final String url;

  const _KiwixWebView({required this.url});

  @override
  State<_KiwixWebView> createState() => _KiwixWebViewState();
}

/// State for [_KiwixWebView] managing the WebView controller and keep-alive lifecycle.
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

/// Renders the Gutenberg tab with search input, curated browse sections,
/// and import-capable result list.
class _GutenbergTab extends ConsumerWidget {
  final TextEditingController searchController;
  final String query;
  final bool isOwnerOrAdmin;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSearchChanged;

  const _GutenbergTab({
    required this.searchController,
    required this.query,
    required this.isOwnerOrAdmin,
    required this.onSearch,
    required this.onSearchChanged,
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
            onChanged: onSearchChanged,
            onSubmitted: onSearch,
          ),
        ),
        Expanded(
          child: query.isEmpty
              ? _GutenbergBrowseView(isOwnerOrAdmin: isOwnerOrAdmin)
              : _GutenbergResults(
                  query: query,
                  isOwnerOrAdmin: isOwnerOrAdmin,
                ),
        ),
      ],
    );
  }
}

/// Curated browse view showing Popular Books and Newest Releases sections.
class _GutenbergBrowseView extends ConsumerWidget {
  final bool isOwnerOrAdmin;

  const _GutenbergBrowseView({required this.isOwnerOrAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        _GutenbergBrowseSection(
          title: 'Popular Books',
          provider: gutenbergPopularProvider,
          isOwnerOrAdmin: isOwnerOrAdmin,
        ),
        const SizedBox(height: 8),
        _GutenbergBrowseSection(
          title: 'Newest Releases',
          provider: gutenbergRecentProvider,
          isOwnerOrAdmin: isOwnerOrAdmin,
        ),
      ],
    );
  }
}

/// A single browse section with a title and horizontal scrolling book cards.
class _GutenbergBrowseSection extends ConsumerWidget {
  final String title;
  final AutoDisposeFutureProvider<GutenbergSearchResultModel> provider;
  final bool isOwnerOrAdmin;

  const _GutenbergBrowseSection({
    required this.title,
    required this.provider,
    required this.isOwnerOrAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 180,
          child: asyncValue.when(
            loading: () => const Center(child: LoadingIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Load Failed',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => ref.invalidate(provider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (result) {
              if (result.results.isEmpty) {
                return const Center(
                  child: Text('No books available'),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: result.results.length,
                itemBuilder: (context, index) => _GutenbergBookCard(
                  book: result.results[index],
                  isOwnerOrAdmin: isOwnerOrAdmin,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact book card for horizontal scroll lists in browse sections.
class _GutenbergBookCard extends ConsumerStatefulWidget {
  final GutenbergBookModel book;
  final bool isOwnerOrAdmin;

  const _GutenbergBookCard({
    required this.book,
    required this.isOwnerOrAdmin,
  });

  @override
  ConsumerState<_GutenbergBookCard> createState() =>
      _GutenbergBookCardState();
}

/// State for [_GutenbergBookCard] managing the import-in-progress indicator.
class _GutenbergBookCardState extends ConsumerState<_GutenbergBookCard> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);

    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          onTap: widget.isOwnerOrAdmin && !_importing ? _importBook : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_stories,
                    size: 28, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (book.authors.isNotEmpty)
                  Text(
                    book.authors.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.download,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${book.downloadCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_importing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

/// Provider for Gutenberg search results keyed by query string.
final gutenbergSearchProvider = FutureProvider.autoDispose
    .family<GutenbergSearchResultModel, String>((ref, query) async {
  final service = ref.watch(libraryServiceProvider);
  return service.searchGutenberg(query);
});

/// Renders the Gutenberg search results list with import buttons for authorized users.
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
        message: e.toString(),
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

/// Renders a single Gutenberg book with metadata and an import button for authorized users.
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

/// State for [_GutenbergBookTile] managing the import-in-progress indicator.
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
