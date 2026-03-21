import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/auth/auth_state.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';
import 'package:myoffgridai_client/features/books/books_screen.dart';
import 'package:myoffgridai_client/features/books/kiwix_catalog_card.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Displays all Kiwix catalog entries in a full-screen vertical grid.
///
/// Includes a language filter dropdown in the AppBar. Uses
/// [KiwixCatalogCard] for each entry and supports download for
/// owners/admins.
class KiwixBrowseAllScreen extends ConsumerStatefulWidget {
  /// Creates a [KiwixBrowseAllScreen].
  const KiwixBrowseAllScreen({super.key});

  @override
  ConsumerState<KiwixBrowseAllScreen> createState() =>
      _KiwixBrowseAllScreenState();
}

/// State for [KiwixBrowseAllScreen] managing the language filter.
class _KiwixBrowseAllScreenState extends ConsumerState<KiwixBrowseAllScreen> {
  String? _selectedLang;

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;
    final isOwnerOrAdmin =
        user?.role == 'ROLE_OWNER' || user?.role == 'ROLE_ADMIN';

    final resultAsync = ref.watch(
      kiwixCatalogBrowseByCategoryProvider(
          (category: null, lang: _selectedLang, count: 50)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Kiwix Catalog'),
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
            return const EmptyStateView(
              icon: Icons.language,
              title: 'No catalog entries',
              subtitle: 'Try a different language filter',
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
