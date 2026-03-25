import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/gutenberg_book_card.dart';
import 'package:myoffgridai_client/features/books/gutenberg_detail_sheet.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays the top 100 most popular books from Project Gutenberg in a
/// multi-column grid.
///
/// Tapping a book card opens [GutenbergDetailSheet] where the user can
/// view metadata and import the book into the local library.
class GutenbergTop100Screen extends ConsumerStatefulWidget {
  /// Creates a [GutenbergTop100Screen].
  const GutenbergTop100Screen({super.key});

  @override
  ConsumerState<GutenbergTop100Screen> createState() =>
      _GutenbergTop100ScreenState();
}

/// State for [GutenbergTop100Screen] managing import tracking.
class _GutenbergTop100ScreenState
    extends ConsumerState<GutenbergTop100Screen> {
  final Map<int, bool> _isImporting = {};
  final Set<int> _importedIds = {};

  bool _checkOwnerOrAdmin() {
    final user = ref.read(authStateProvider).valueOrNull;
    return user?.role == 'ROLE_OWNER' || user?.role == 'ROLE_ADMIN';
  }

  Future<void> _importBook(int gutenbergId) async {
    if (!_checkOwnerOrAdmin()) return;

    setState(() => _isImporting[gutenbergId] = true);
    try {
      final service = ref.read(libraryServiceProvider);
      final ebook = await service.importGutenbergBook(gutenbergId);
      ref.invalidate(ebooksProvider);
      if (mounted) {
        _importedIds.add(gutenbergId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${ebook.title}" imported successfully'),
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
      if (mounted) setState(() => _isImporting.remove(gutenbergId));
    }
  }

  void _showDetailSheet(
      GutenbergBookModel book, bool isOwnerOrAdmin, bool isImported) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => GutenbergDetailSheet(
        book: book,
        isOwnerOrAdmin: isOwnerOrAdmin,
        isImported: isImported,
        isImporting: _isImporting[book.id] ?? false,
        onImport: () async {
          await _importBook(book.id);
          if (_importedIds.contains(book.id) && sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;
    final isOwnerOrAdmin =
        user?.role == 'ROLE_OWNER' || user?.role == 'ROLE_ADMIN';

    final resultAsync = ref.watch(
      gutenbergBrowseProvider((sort: 'popular', limit: 100)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top 100 Gutenberg Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(gutenbergBrowseProvider),
          ),
        ],
      ),
      body: resultAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          title: 'Load Failed',
          message: e.toString(),
          onRetry: () => ref.invalidate(gutenbergBrowseProvider),
        ),
        data: (result) {
          final books = result.results;
          final importedIds = result.importedGutenbergIds;
          if (books.isEmpty) {
            return const EmptyStateView(
              icon: Icons.auto_stories,
              title: 'No books available',
              subtitle: 'Check your server connection',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.47,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isImported = importedIds.contains(book.id) ||
                  _importedIds.contains(book.id);
              return GutenbergBookCard(
                book: book,
                isOwnerOrAdmin: isOwnerOrAdmin,
                isImported: isImported,
                isImporting: _isImporting[book.id] ?? false,
                onImport: () => _importBook(book.id),
                onTap: () =>
                    _showDetailSheet(book, isOwnerOrAdmin, isImported),
              );
            },
          );
        },
      ),
    );
  }
}
