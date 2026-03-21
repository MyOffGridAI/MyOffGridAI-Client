import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/library_models.dart';
import 'package:myoffgridai_client/core/services/library_service.dart';

/// Compact card for a Kiwix catalog entry with download button.
///
/// Displays the entry's illustration (or a fallback icon), title, description,
/// language, category, size metadata, and a download button for owners/admins.
/// Manages its own download-in-progress state internally.
class KiwixCatalogCard extends ConsumerStatefulWidget {
  /// The Kiwix catalog entry to display.
  final KiwixCatalogEntryModel entry;

  /// Whether the current user is an owner or admin (controls download button visibility).
  final bool isOwnerOrAdmin;

  /// Creates a [KiwixCatalogCard].
  const KiwixCatalogCard({
    super.key,
    required this.entry,
    required this.isOwnerOrAdmin,
  });

  @override
  ConsumerState<KiwixCatalogCard> createState() => _KiwixCatalogCardState();
}

/// State for [KiwixCatalogCard] managing the download-in-progress indicator.
class _KiwixCatalogCardState extends ConsumerState<KiwixCatalogCard> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration or fallback icon
            if (entry.illustrationUrl != null &&
                entry.illustrationUrl!.isNotEmpty)
              SizedBox(
                height: 48,
                width: 48,
                child: CachedNetworkImage(
                  imageUrl: entry.illustrationUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Icon(Icons.language,
                      size: 28, color: theme.colorScheme.primary),
                  errorWidget: (_, __, ___) => Icon(Icons.language,
                      size: 28, color: theme.colorScheme.primary),
                ),
              )
            else
              Icon(Icons.language,
                  size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            // Title
            Text(
              entry.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Description
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
            // Metadata: language, category, size
            const SizedBox(height: 4),
            Text(
              [
                if (entry.language != null) entry.language!,
                if (entry.category != null) entry.category!,
                _formatSize(entry.sizeBytes),
              ].join(' \u2022 '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Download button (owner/admin only)
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
    );
  }

  /// Initiates a ZIM download from the Kiwix catalog.
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

  /// Formats byte count to human-readable size string.
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
