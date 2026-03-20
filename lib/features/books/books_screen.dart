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
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
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
                itemBuilder: (context, index) => _EbookTile(
                  ebook: ebooks[index],
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

/// Renders a single eBook entry with format icon, metadata, Gutenberg badge,
/// and an optional delete action for owners/admins.
class _EbookTile extends ConsumerStatefulWidget {
  final EbookModel ebook;
  final bool isOwnerOrAdmin;

  const _EbookTile({required this.ebook, required this.isOwnerOrAdmin});

  @override
  ConsumerState<_EbookTile> createState() => _EbookTileState();
}

/// State for [_EbookTile] managing the delete-in-progress indicator.
class _EbookTileState extends ConsumerState<_EbookTile> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final ebook = widget.ebook;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ebook.isFromGutenberg)
            Tooltip(
              message: 'From Project Gutenberg',
              child: Icon(Icons.public,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            ),
          if (widget.isOwnerOrAdmin)
            PopupMenuButton<String>(
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_vert),
              enabled: !_deleting,
              onSelected: (value) {
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      onTap: () => context.go(
        AppConstants.routeBookReader,
        extra: ebook,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete eBook',
      message: 'Are you sure you want to delete "${widget.ebook.title}"? '
          'This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final service = ref.read(libraryServiceProvider);
      await service.deleteEbook(widget.ebook.id);
      ref.invalidate(ebooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.ebook.title}" deleted'),
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
      if (mounted) setState(() => _deleting = false);
    }
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

// ── Kiwix Tab ────────────────────────────────────────────────────────────

/// Renders the Kiwix tab with status bar, local ZIM files, active downloads,
/// catalog browse, and search.
class _KiwixTab extends ConsumerStatefulWidget {
  const _KiwixTab();

  @override
  ConsumerState<_KiwixTab> createState() => _KiwixTabState();
}

/// State for [_KiwixTab] managing catalog search, language filter, and download polling.
class _KiwixTabState extends ConsumerState<_KiwixTab> {
  final _searchController = TextEditingController();
  String _catalogQuery = '';
  String? _selectedLanguage;
  Timer? _downloadPollTimer;

  @override
  void initState() {
    super.initState();
    _startDownloadPolling();
  }

  @override
  void dispose() {
    _downloadPollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startDownloadPolling() {
    _downloadPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) ref.invalidate(kiwixDownloadsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isOwnerOrAdmin =
        user?.role == 'ROLE_OWNER' || user?.role == 'ROLE_ADMIN';

    return ListView(
      children: [
        _KiwixStatusBar(isOwnerOrAdmin: isOwnerOrAdmin),
        _MyZimFilesSection(isOwnerOrAdmin: isOwnerOrAdmin),
        _ActiveDownloadsSection(),
        const SizedBox(height: 8),
        _KiwixCatalogBrowseSection(
          searchController: _searchController,
          query: _catalogQuery,
          selectedLanguage: _selectedLanguage,
          isOwnerOrAdmin: isOwnerOrAdmin,
          onSearchChanged: (value) {
            setState(() => _catalogQuery = value.trim());
          },
          onLanguageChanged: (lang) {
            setState(() => _selectedLanguage = lang);
          },
        ),
      ],
    );
  }
}

/// Status bar showing kiwix-serve state with installation status,
/// start/stop toggle, and "Open Kiwix" button.
class _KiwixStatusBar extends ConsumerStatefulWidget {
  final bool isOwnerOrAdmin;

  const _KiwixStatusBar({required this.isOwnerOrAdmin});

  @override
  ConsumerState<_KiwixStatusBar> createState() => _KiwixStatusBarState();
}

/// State for [_KiwixStatusBar] managing the start/stop and install loading indicators.
class _KiwixStatusBarState extends ConsumerState<_KiwixStatusBar> {
  bool _toggling = false;
  bool _installing = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(kiwixStatusProvider);
    final theme = Theme.of(context);

    return statusAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: ErrorView(
          title: 'Status Check Failed',
          message: e.toString(),
          onRetry: () => ref.invalidate(kiwixStatusProvider),
        ),
      ),
      data: (status) {
        // Installation in progress
        if (status.isInstalling || _installing) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Installing Kiwix...',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Installation failed
        if (status.isInstallFailed) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Kiwix Install Failed',
                            style: theme.textTheme.titleSmall),
                        if (status.installationError != null)
                          Text(
                            status.installationError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (widget.isOwnerOrAdmin)
                    FilledButton.tonal(
                      onPressed: _retryInstall,
                      child: const Text('Retry Install'),
                    ),
                ],
              ),
            ),
          );
        }

        // Not installed (auto-install disabled)
        if (status.isNotInstalled) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kiwix not installed',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (widget.isOwnerOrAdmin)
                    FilledButton.tonal(
                      onPressed: _retryInstall,
                      child: const Text('Install'),
                    ),
                ],
              ),
            ),
          );
        }

        // Installed — show running/stopped state
        final isRunning = status.available;

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isRunning ? Icons.check_circle : Icons.cancel,
                  color: isRunning ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRunning ? 'Kiwix Running' : 'Kiwix Stopped',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (isRunning && status.url != null)
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _KiwixWebViewPage(url: status.url!),
                      ),
                    ),
                    child: const Text('Open Kiwix'),
                  ),
                if (widget.isOwnerOrAdmin && status.processManaged) ...[
                  const SizedBox(width: 8),
                  _toggling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                          tooltip: isRunning ? 'Stop Kiwix' : 'Start Kiwix',
                          onPressed: () => _toggleKiwix(isRunning),
                        ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleKiwix(bool isRunning) async {
    setState(() => _toggling = true);
    try {
      final service = ref.read(libraryServiceProvider);
      if (isRunning) {
        await service.stopKiwix();
      } else {
        await service.startKiwix();
      }
      ref.invalidate(kiwixStatusProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _retryInstall() async {
    setState(() => _installing = true);
    try {
      final service = ref.read(libraryServiceProvider);
      await service.installKiwix();
      ref.invalidate(kiwixStatusProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }
}

/// Section showing local ZIM files with delete for OWNER/ADMIN.
class _MyZimFilesSection extends ConsumerWidget {
  final bool isOwnerOrAdmin;

  const _MyZimFilesSection({required this.isOwnerOrAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zimAsync = ref.watch(zimFilesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'My ZIM Files',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        zimAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingIndicator(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(zimFilesProvider),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (files) {
            if (files.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No ZIM files yet. Browse the catalog below.'),
                ),
              );
            }
            return Column(
              children: files
                  .map((zf) => _ZimFileTile(
                        zimFile: zf,
                        isOwnerOrAdmin: isOwnerOrAdmin,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Single ZIM file entry with metadata and delete action.
class _ZimFileTile extends ConsumerStatefulWidget {
  final ZimFileModel zimFile;
  final bool isOwnerOrAdmin;

  const _ZimFileTile({required this.zimFile, required this.isOwnerOrAdmin});

  @override
  ConsumerState<_ZimFileTile> createState() => _ZimFileTileState();
}

/// State for [_ZimFileTile] managing the delete-in-progress indicator.
class _ZimFileTileState extends ConsumerState<_ZimFileTile> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final zf = widget.zimFile;
    final kiwixStatus = ref.watch(kiwixStatusProvider).valueOrNull;
    final isKiwixRunning = kiwixStatus?.available == true && kiwixStatus?.url != null;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(
        zf.displayName ?? zf.filename,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (zf.category != null) zf.category!,
          if (zf.language != null) zf.language!,
          _formatSize(zf.fileSizeBytes),
        ].join(' \u2022 '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isKiwixRunning)
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          if (widget.isOwnerOrAdmin)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleting ? null : _confirmDelete,
            ),
        ],
      ),
      onTap: isKiwixRunning
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _KiwixWebViewPage(url: kiwixStatus!.url!),
                ),
              )
          : null,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete ZIM File',
      message:
          'Are you sure you want to delete "${widget.zimFile.displayName ?? widget.zimFile.filename}"? '
          'This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final service = ref.read(libraryServiceProvider);
      await service.deleteZimFile(widget.zimFile.id);
      ref.invalidate(zimFilesProvider);
      ref.invalidate(kiwixStatusProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Section showing active downloads with progress indicators.
class _ActiveDownloadsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(kiwixDownloadsProvider);
    final theme = Theme.of(context);

    return downloadsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (downloads) {
        final active = downloads.where((d) => d.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Active Downloads',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...active.map((dl) => ListTile(
                  leading: const Icon(Icons.downloading),
                  title: Text(dl.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: LinearProgressIndicator(
                    value: dl.percentComplete / 100,
                  ),
                  trailing: Text(
                    '${dl.percentComplete.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                )),
          ],
        );
      },
    );
  }
}

/// Common language options for the Kiwix catalog filter dropdown.
const _kiwixLanguageOptions = <(String?, String)>[
  (null, 'All Languages'),
  ('eng', 'English'),
  ('fra', 'French'),
  ('deu', 'German'),
  ('spa', 'Spanish'),
  ('por', 'Portuguese'),
  ('rus', 'Russian'),
  ('zho', 'Chinese'),
  ('jpn', 'Japanese'),
  ('ara', 'Arabic'),
  ('hin', 'Hindi'),
  ('ita', 'Italian'),
  ('kor', 'Korean'),
  ('nld', 'Dutch'),
  ('pol', 'Polish'),
  ('tur', 'Turkish'),
  ('vie', 'Vietnamese'),
  ('ukr', 'Ukrainian'),
  ('swa', 'Swahili'),
];

/// Catalog browse section with language filter, search bar, and horizontal cards.
class _KiwixCatalogBrowseSection extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final String query;
  final String? selectedLanguage;
  final bool isOwnerOrAdmin;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onLanguageChanged;

  const _KiwixCatalogBrowseSection({
    required this.searchController,
    required this.query,
    required this.selectedLanguage,
    required this.isOwnerOrAdmin,
    required this.onSearchChanged,
    required this.onLanguageChanged,
  });

  @override
  ConsumerState<_KiwixCatalogBrowseSection> createState() =>
      _KiwixCatalogBrowseSectionState();
}

/// State for [_KiwixCatalogBrowseSection] managing the scroll controller.
class _KiwixCatalogBrowseSectionState
    extends ConsumerState<_KiwixCatalogBrowseSection> {
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(value);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Browse Catalog',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownButton<String?>(
                value: widget.selectedLanguage,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.translate, size: 20),
                style: theme.textTheme.bodySmall,
                items: _kiwixLanguageOptions
                    .map((entry) => DropdownMenuItem<String?>(
                          value: entry.$1,
                          child: Text(entry.$2),
                        ))
                    .toList(),
                onChanged: widget.onLanguageChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Search Kiwix catalog...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
            onSubmitted: widget.onSearchChanged,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.query.isEmpty)
          _KiwixBrowseCards(
            isOwnerOrAdmin: widget.isOwnerOrAdmin,
            selectedLanguage: widget.selectedLanguage,
            scrollController: _scrollController,
          )
        else
          _KiwixSearchResults(
            query: widget.query,
            selectedLanguage: widget.selectedLanguage,
            isOwnerOrAdmin: widget.isOwnerOrAdmin,
          ),
      ],
    );
  }
}

/// Horizontal scroll cards for Kiwix catalog browse.
class _KiwixBrowseCards extends ConsumerWidget {
  final bool isOwnerOrAdmin;
  final String? selectedLanguage;
  final ScrollController scrollController;

  const _KiwixBrowseCards({
    required this.isOwnerOrAdmin,
    required this.selectedLanguage,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(kiwixCatalogBrowseProvider(selectedLanguage));

    return SizedBox(
      height: 240,
      child: asyncValue.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load catalog',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => ref.invalidate(kiwixCatalogBrowseProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (result) {
          if (result.entries.isEmpty) {
            return const Center(child: Text('No catalog entries available'));
          }
          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: result.entries.length,
              itemBuilder: (context, index) => _KiwixCatalogCard(
                entry: result.entries[index],
                isOwnerOrAdmin: isOwnerOrAdmin,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact card for a Kiwix catalog entry with download button.
class _KiwixCatalogCard extends ConsumerStatefulWidget {
  final KiwixCatalogEntryModel entry;
  final bool isOwnerOrAdmin;

  const _KiwixCatalogCard({
    required this.entry,
    required this.isOwnerOrAdmin,
  });

  @override
  ConsumerState<_KiwixCatalogCard> createState() => _KiwixCatalogCardState();
}

/// State for [_KiwixCatalogCard] managing the download-in-progress indicator.
class _KiwixCatalogCardState extends ConsumerState<_KiwixCatalogCard> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);

    return SizedBox(
      width: 200,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.language,
                  size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                entry.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.description != null &&
                  entry.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                [
                  if (entry.language != null) entry.language!,
                  _formatSize(entry.sizeBytes),
                ].join(' \u2022 '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (widget.isOwnerOrAdmin && entry.downloadUrl != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: _downloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          tooltip: 'Download ZIM',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _startDownload,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() => _downloading = true);
    try {
      final entry = widget.entry;
      final service = ref.read(libraryServiceProvider);
      await service.downloadFromCatalog(
        downloadUrl: entry.downloadUrl!,
        filename: entry.name != null ? '${entry.name}.zim' : 'download.zim',
        displayName: entry.title,
        category: entry.category,
        language: entry.language,
        sizeBytes: entry.sizeBytes,
      );
      ref.invalidate(kiwixDownloadsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading "${entry.title}"...')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Search results list for the Kiwix catalog.
class _KiwixSearchResults extends ConsumerWidget {
  final String query;
  final String? selectedLanguage;
  final bool isOwnerOrAdmin;

  const _KiwixSearchResults({
    required this.query,
    required this.selectedLanguage,
    required this.isOwnerOrAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(
        kiwixCatalogSearchProvider((query: query, lang: selectedLanguage)));

    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: LoadingIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('Search failed: ${e.toString()}')),
      ),
      data: (result) {
        if (result.entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No results found')),
          );
        }
        return Column(
          children: result.entries
              .map((entry) => _KiwixSearchResultTile(
                    entry: entry,
                    isOwnerOrAdmin: isOwnerOrAdmin,
                  ))
              .toList(),
        );
      },
    );
  }
}

/// Single search result tile with download button.
class _KiwixSearchResultTile extends ConsumerStatefulWidget {
  final KiwixCatalogEntryModel entry;
  final bool isOwnerOrAdmin;

  const _KiwixSearchResultTile({
    required this.entry,
    required this.isOwnerOrAdmin,
  });

  @override
  ConsumerState<_KiwixSearchResultTile> createState() =>
      _KiwixSearchResultTileState();
}

/// State for [_KiwixSearchResultTile] managing the download-in-progress indicator.
class _KiwixSearchResultTileState
    extends ConsumerState<_KiwixSearchResultTile> {
  bool _downloading = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (entry.language != null) entry.language!,
          if (entry.category != null) entry.category!,
          _formatSize(entry.sizeBytes),
        ].join(' \u2022 '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: widget.isOwnerOrAdmin && entry.downloadUrl != null
          ? IconButton(
              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Download ZIM',
              onPressed: _downloading ? null : _startDownload,
            )
          : null,
    );
  }

  Future<void> _startDownload() async {
    setState(() => _downloading = true);
    try {
      final entry = widget.entry;
      final service = ref.read(libraryServiceProvider);
      await service.downloadFromCatalog(
        downloadUrl: entry.downloadUrl!,
        filename: entry.name != null ? '${entry.name}.zim' : 'download.zim',
        displayName: entry.title,
        category: entry.category,
        language: entry.language,
        sizeBytes: entry.sizeBytes,
      );
      ref.invalidate(kiwixDownloadsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading "${entry.title}"...')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

/// Full-screen page showing Kiwix WebView content.
class _KiwixWebViewPage extends StatefulWidget {
  final String url;

  const _KiwixWebViewPage({required this.url});

  @override
  State<_KiwixWebViewPage> createState() => _KiwixWebViewPageState();
}

/// State for [_KiwixWebViewPage] managing the WebView controller.
class _KiwixWebViewPageState extends State<_KiwixWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiwix Content')),
      body: WebViewWidget(controller: _controller),
    );
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
class _GutenbergBrowseSection extends ConsumerStatefulWidget {
  final String title;
  final AutoDisposeFutureProvider<GutenbergSearchResultModel> provider;
  final bool isOwnerOrAdmin;

  const _GutenbergBrowseSection({
    required this.title,
    required this.provider,
    required this.isOwnerOrAdmin,
  });

  @override
  ConsumerState<_GutenbergBrowseSection> createState() =>
      _GutenbergBrowseSectionState();
}

/// State for [_GutenbergBrowseSection] managing the scroll controller
/// for the visible scrollbar on horizontal book lists.
class _GutenbergBrowseSectionState
    extends ConsumerState<_GutenbergBrowseSection> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(widget.provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.title,
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
                      onPressed: () => ref.invalidate(widget.provider),
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
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: result.results.length,
                  itemBuilder: (context, index) => _GutenbergBookCard(
                    book: result.results[index],
                    isOwnerOrAdmin: widget.isOwnerOrAdmin,
                  ),
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
