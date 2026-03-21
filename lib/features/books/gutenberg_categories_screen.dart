import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/config/constants.dart';

/// Data class for a category group header and its sub-categories.
class _CategoryGroup {
  final String title;
  final IconData icon;
  final List<_Category> categories;

  const _CategoryGroup({
    required this.title,
    required this.icon,
    required this.categories,
  });
}

/// Data class for a single Gutenberg bookshelf category.
class _Category {
  final String name;
  final IconData icon;

  const _Category({required this.name, required this.icon});
}

/// Hardcoded category groups matching Gutenberg's bookshelf structure.
const _categoryGroups = <_CategoryGroup>[
  _CategoryGroup(
    title: 'Literature',
    icon: Icons.auto_stories,
    categories: [
      _Category(name: 'Adventure', icon: Icons.explore),
      _Category(name: 'American Literature', icon: Icons.flag),
      _Category(name: 'British Literature', icon: Icons.castle),
      _Category(name: "Children's Literature", icon: Icons.child_care),
      _Category(name: 'Classics', icon: Icons.star),
      _Category(name: 'Crime/Mystery', icon: Icons.search),
      _Category(name: 'Drama', icon: Icons.theater_comedy),
      _Category(name: 'Fantasy', icon: Icons.auto_fix_high),
      _Category(name: 'Fiction', icon: Icons.menu_book),
      _Category(name: 'Historical Fiction', icon: Icons.history_edu),
      _Category(name: 'Horror', icon: Icons.nights_stay),
      _Category(name: 'Humor', icon: Icons.sentiment_very_satisfied),
      _Category(name: 'Poetry', icon: Icons.format_quote),
      _Category(name: 'Romance', icon: Icons.favorite),
      _Category(name: 'Science Fiction', icon: Icons.rocket_launch),
      _Category(name: 'Short Stories', icon: Icons.short_text),
    ],
  ),
  _CategoryGroup(
    title: 'History',
    icon: Icons.history,
    categories: [
      _Category(name: 'Ancient History', icon: Icons.account_balance),
      _Category(name: 'Medieval History', icon: Icons.shield),
      _Category(name: 'Modern History', icon: Icons.public),
      _Category(name: 'American History', icon: Icons.flag),
      _Category(name: 'European History', icon: Icons.language),
      _Category(name: 'Military History', icon: Icons.military_tech),
      _Category(name: 'Biography', icon: Icons.person),
    ],
  ),
  _CategoryGroup(
    title: 'Science & Technology',
    icon: Icons.science,
    categories: [
      _Category(name: 'Astronomy', icon: Icons.nightlight_round),
      _Category(name: 'Biology', icon: Icons.biotech),
      _Category(name: 'Chemistry', icon: Icons.science),
      _Category(name: 'Engineering', icon: Icons.engineering),
      _Category(name: 'Mathematics', icon: Icons.calculate),
      _Category(name: 'Medicine', icon: Icons.local_hospital),
      _Category(name: 'Physics', icon: Icons.bolt),
      _Category(name: 'Technology', icon: Icons.computer),
    ],
  ),
  _CategoryGroup(
    title: 'Arts & Culture',
    icon: Icons.palette,
    categories: [
      _Category(name: 'Architecture', icon: Icons.domain),
      _Category(name: 'Art', icon: Icons.brush),
      _Category(name: 'Fashion', icon: Icons.checkroom),
      _Category(name: 'Music', icon: Icons.music_note),
      _Category(name: 'Photography', icon: Icons.camera_alt),
    ],
  ),
  _CategoryGroup(
    title: 'Social Sciences',
    icon: Icons.groups,
    categories: [
      _Category(name: 'Economics', icon: Icons.trending_up),
      _Category(name: 'Law', icon: Icons.gavel),
      _Category(name: 'Philosophy', icon: Icons.psychology),
      _Category(name: 'Politics', icon: Icons.how_to_vote),
      _Category(name: 'Psychology', icon: Icons.psychology_alt),
      _Category(name: 'Sociology', icon: Icons.diversity_3),
    ],
  ),
  _CategoryGroup(
    title: 'Religion & Spirituality',
    icon: Icons.auto_awesome,
    categories: [
      _Category(name: 'Christianity', icon: Icons.church),
      _Category(name: 'Islam', icon: Icons.mosque),
      _Category(name: 'Judaism', icon: Icons.synagogue),
      _Category(name: 'Mythology', icon: Icons.auto_fix_high),
      _Category(name: 'Spirituality', icon: Icons.self_improvement),
    ],
  ),
  _CategoryGroup(
    title: 'Lifestyle',
    icon: Icons.spa,
    categories: [
      _Category(name: 'Cooking', icon: Icons.restaurant),
      _Category(name: 'Gardening', icon: Icons.yard),
      _Category(name: 'Sports', icon: Icons.sports),
      _Category(name: 'Travel', icon: Icons.flight),
      _Category(name: 'Nature', icon: Icons.park),
    ],
  ),
  _CategoryGroup(
    title: 'Education & Reference',
    icon: Icons.school,
    categories: [
      _Category(name: 'Education', icon: Icons.school),
      _Category(name: 'Language', icon: Icons.translate),
      _Category(name: 'Reference', icon: Icons.library_books),
    ],
  ),
];

/// Displays Gutenberg book categories organized into groups.
///
/// Each group has a header and a grid of category cards. Tapping a category
/// navigates to [GutenbergCategoryBooksScreen] to show books in that category.
class GutenbergCategoriesScreen extends StatelessWidget {
  /// Creates a [GutenbergCategoriesScreen].
  const GutenbergCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gutenberg Categories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _categoryGroups.length,
        itemBuilder: (context, groupIndex) {
          final group = _categoryGroups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    Icon(group.icon,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      group.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: group.categories.length,
                itemBuilder: (context, catIndex) {
                  final category = group.categories[catIndex];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push(
                        AppConstants.routeGutenbergCategoryBooks,
                        extra: category.name,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(category.icon,
                                size: 20,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.name,
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (groupIndex < _categoryGroups.length - 1)
                const Divider(height: 24),
            ],
          );
        },
      ),
    );
  }
}
