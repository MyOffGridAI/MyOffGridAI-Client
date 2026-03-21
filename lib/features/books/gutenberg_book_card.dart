import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';

/// A card displaying a Gutenberg book with cover image, title, author,
/// download count, and an import button.
///
/// Reusable across the main Gutenberg tab, Top 100 screen, and category
/// books screen.
class GutenbergBookCard extends StatelessWidget {
  /// The Gutenberg book to display.
  final GutenbergBookModel book;

  /// Whether the current user is an owner or admin (controls import visibility).
  final bool isOwnerOrAdmin;

  /// Whether an import is currently in progress for this book.
  final bool isImporting;

  /// Called when the user taps the import button.
  final VoidCallback onImport;

  /// Called when the user taps the card.
  final VoidCallback onTap;

  /// Creates a [GutenbergBookCard].
  const GutenbergBookCard({
    super.key,
    required this.book,
    required this.isOwnerOrAdmin,
    required this.isImporting,
    required this.onImport,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = book.formats['image/jpeg'];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            AspectRatio(
              aspectRatio: 3 / 4,
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.auto_stories, size: 40),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.auto_stories, size: 40),
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.auto_stories, size: 40),
                      ),
                    ),
            ),
            // Metadata
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.authors.isNotEmpty)
                      Text(
                        book.authors.first,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.download,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          SizeFormatter.formatCount(book.downloadCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isOwnerOrAdmin)
                      SizedBox(
                        width: double.infinity,
                        child: isImporting
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : FilledButton.tonal(
                                onPressed: onImport,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  minimumSize: const Size(0, 30),
                                  textStyle: theme.textTheme.labelSmall,
                                ),
                                child: const Text('Import'),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
