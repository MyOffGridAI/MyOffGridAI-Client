import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';

/// Bottom sheet showing full metadata for a Gutenberg book.
///
/// Reusable across the main Gutenberg tab, Top 100 screen, and category
/// books screen.
class GutenbergDetailSheet extends StatelessWidget {
  /// The Gutenberg book whose details are displayed.
  final GutenbergBookModel book;

  /// Whether the current user is an owner or admin (controls import visibility).
  final bool isOwnerOrAdmin;

  /// Whether an import is currently in progress for this book.
  final bool isImporting;

  /// Called when the user taps the import button.
  final VoidCallback onImport;

  /// Creates a [GutenbergDetailSheet].
  const GutenbergDetailSheet({
    super.key,
    required this.book,
    required this.isOwnerOrAdmin,
    required this.isImporting,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = book.formats['image/jpeg'];

    // Collect format labels from MIME types
    final formatLabels = book.formats.keys
        .where((k) => k != 'image/jpeg')
        .map((mime) => switch (mime) {
              'application/epub+zip' => 'EPUB',
              'application/x-mobipocket-ebook' => 'MOBI',
              'text/plain' || 'text/plain; charset=us-ascii' ||
              'text/plain; charset=utf-8' =>
                'TXT',
              'text/html' => 'HTML',
              'application/pdf' => 'PDF',
              'application/rdf+xml' => 'RDF',
              _ => mime.split('/').last.toUpperCase(),
            })
        .toSet()
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Cover + title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 120,
                          height: 160,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.auto_stories, size: 40),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_stories, size: 40),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (book.authors.isNotEmpty)
                          Text(
                            book.authors.join(', '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.download,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${SizeFormatter.formatCount(book.downloadCount)} downloads',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Subjects
              if (book.subjects.isNotEmpty) ...[
                Text('Subjects', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: book.subjects
                      .map((s) => Chip(
                            label: Text(s),
                            labelStyle: theme.textTheme.bodySmall,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Formats
              if (formatLabels.isNotEmpty) ...[
                Text('Available Formats', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: formatLabels
                      .map((f) => Chip(
                            label: Text(f),
                            labelStyle: theme.textTheme.bodySmall,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Import button
              if (isOwnerOrAdmin)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isImporting ? null : onImport,
                    icon: isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label:
                        Text(isImporting ? 'Importing...' : 'Import to Library'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
