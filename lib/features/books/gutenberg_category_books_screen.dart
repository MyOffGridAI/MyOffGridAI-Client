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

/// Displays books from a specific Gutenberg category in a multi-column grid.
///
/// Takes a [categoryName] parameter and searches the Gutenberg catalog
/// for matching books. Tapping a book card opens [GutenbergDetailSheet].
class GutenbergCategoryBooksScreen extends ConsumerStatefulWidget {
  /// The name of the category to search for.
  final String categoryName;

  /// Creates a [GutenbergCategoryBooksScreen].
  const GutenbergCategoryBooksScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<GutenbergCategoryBooksScreen> createState() =>
      _GutenbergCategoryBooksScreenState();
}

/// State for [GutenbergCategoryBooksScreen] managing import tracking.
class _GutenbergCategoryBooksScreenState
    extends ConsumerState<GutenbergCategoryBooksScreen> {
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

  void _showDetailSheet(GutenbergBookModel book, bool isOwnerOrAdmin) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => GutenbergDetailSheet(
        book: book,
        isOwnerOrAdmin: isOwnerOrAdmin,
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
      gutenbergSearchProvider(
          (query: widget.categoryName, limit: 50)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: resultAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          title: 'Load Failed',
          message: e.toString(),
          onRetry: () => ref.invalidate(gutenbergSearchProvider),
        ),
        data: (result) {
          final books = result.results
              .where((b) => !_importedIds.contains(b.id))
              .toList();
          if (books.isEmpty) {
            return EmptyStateView(
              icon: Icons.auto_stories,
              title: 'No books found',
              subtitle:
                  'No books found for "${widget.categoryName}"',
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
              return GutenbergBookCard(
                book: book,
                isOwnerOrAdmin: isOwnerOrAdmin,
                isImporting: _isImporting[book.id] ?? false,
                onImport: () => _importBook(book.id),
                onTap: () => _showDetailSheet(book, isOwnerOrAdmin),
              );
            },
          );
        },
      ),
    );
  }
}
