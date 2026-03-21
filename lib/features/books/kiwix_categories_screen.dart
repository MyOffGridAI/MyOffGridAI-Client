import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';

/// Data class for a Kiwix content category.
class _KiwixCategory {
  final String name;
  final IconData icon;
  final String description;

  const _KiwixCategory({
    required this.name,
    required this.icon,
    required this.description,
  });
}

/// Hardcoded Kiwix categories matching the Kiwix Library website.
const _kiwixCategories = <_KiwixCategory>[
  _KiwixCategory(
      name: 'gutenberg',
      icon: Icons.auto_stories,
      description: 'Project Gutenberg books'),
  _KiwixCategory(
      name: 'ifixit',
      icon: Icons.build,
      description: 'Repair guides'),
  _KiwixCategory(
      name: 'mooc',
      icon: Icons.school,
      description: 'Online courses'),
  _KiwixCategory(
      name: 'other',
      icon: Icons.category,
      description: 'Miscellaneous content'),
  _KiwixCategory(
      name: 'phet',
      icon: Icons.science,
      description: 'Physics simulations'),
  _KiwixCategory(
      name: 'psiram',
      icon: Icons.fact_check,
      description: 'Fact-checking wiki'),
  _KiwixCategory(
      name: 'stack_exchange',
      icon: Icons.forum,
      description: 'Q&A communities'),
  _KiwixCategory(
      name: 'ted',
      icon: Icons.record_voice_over,
      description: 'TED talks'),
  _KiwixCategory(
      name: 'vikidia',
      icon: Icons.child_care,
      description: "Children's encyclopedia"),
  _KiwixCategory(
      name: 'wikibooks',
      icon: Icons.menu_book,
      description: 'Open textbooks'),
  _KiwixCategory(
      name: 'wikinews',
      icon: Icons.newspaper,
      description: 'Free news'),
  _KiwixCategory(
      name: 'wikipedia',
      icon: Icons.language,
      description: 'Encyclopedia'),
  _KiwixCategory(
      name: 'wikiquote',
      icon: Icons.format_quote,
      description: 'Quotations'),
  _KiwixCategory(
      name: 'wikisource',
      icon: Icons.source,
      description: 'Source texts'),
  _KiwixCategory(
      name: 'wikiversity',
      icon: Icons.school,
      description: 'Learning resources'),
  _KiwixCategory(
      name: 'wikivoyage',
      icon: Icons.flight,
      description: 'Travel guides'),
  _KiwixCategory(
      name: 'wiktionary',
      icon: Icons.translate,
      description: 'Dictionary'),
];

/// Displays Kiwix content categories in a grid layout.
///
/// Each category card shows an icon, display name, and description.
/// Tapping a card navigates to [KiwixCategoryContentScreen] to browse
/// entries for that category.
class KiwixCategoriesScreen extends StatelessWidget {
  /// Creates a [KiwixCategoriesScreen].
  const KiwixCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kiwix Categories')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _kiwixCategories.length,
        itemBuilder: (context, index) {
          final category = _kiwixCategories[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(
                AppConstants.routeKiwixCategoryContent,
                extra: category.name,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(category.icon,
                        size: 32, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      _displayName(category.name),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Converts a category key like 'stack_exchange' to 'Stack Exchange'.
  String _displayName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
