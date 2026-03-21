import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/books_screen.dart';
import 'package:myoffgridai_client/features/books/kiwix_catalog_card.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays Kiwix catalog entries for a specific category in a vertical grid.
///
/// Takes a [categoryName] parameter and fetches matching entries from the
/// Kiwix catalog API. Includes a language filter dropdown in the AppBar.
class KiwixCategoryContentScreen extends ConsumerStatefulWidget {
  /// The Kiwix category to browse.
  final String categoryName;

  /// Creates a [KiwixCategoryContentScreen].
  const KiwixCategoryContentScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<KiwixCategoryContentScreen> createState() =>
      _KiwixCategoryContentScreenState();
}

/// State for [KiwixCategoryContentScreen] managing the language filter.
class _KiwixCategoryContentScreenState
    extends ConsumerState<KiwixCategoryContentScreen> {
  String? _selectedLang;

  /// Converts a category key like 'stack_exchange' to 'Stack Exchange'.
  String _displayName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;
    final isOwnerOrAdmin =
        user?.role == 'ROLE_OWNER' || user?.role == 'ROLE_ADMIN';

    final resultAsync = ref.watch(
      kiwixCatalogBrowseByCategoryProvider((
        category: widget.categoryName,
        lang: _selectedLang,
        count: 50,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName(widget.categoryName)),
        actions: [
          DropdownButton<String?>(
            value: _selectedLang,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.translate, size: 20),
            style: Theme.of(context).textTheme.bodySmall,
            items: kiwixLanguageOptions
                .map((entry) => DropdownMenuItem<String?>(
                      value: entry.$1,
                      child: Text(entry.$2),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedLang = value),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: resultAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          title: 'Load Failed',
          message: e.toString(),
          onRetry: () => ref.invalidate(kiwixCatalogBrowseByCategoryProvider),
        ),
        data: (result) {
          if (result.entries.isEmpty) {
            return EmptyStateView(
              icon: Icons.language,
              title: 'No entries found',
              subtitle:
                  'No content found for "${_displayName(widget.categoryName)}"',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: result.entries.length,
            itemBuilder: (context, index) => KiwixCatalogCard(
              entry: result.entries[index],
              isOwnerOrAdmin: isOwnerOrAdmin,
            ),
          );
        },
      ),
    );
  }
}
