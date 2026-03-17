import 'package:flutter/material.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';

/// Scrollable list of HuggingFace model search results.
///
/// Each model is displayed as an expandable card showing repository metadata
/// and available GGUF files. Selecting a file triggers [onFileSelected] to
/// show the file's details in the [ModelDetailPanel].
class DiscoverModelList extends StatelessWidget {
  /// The search results to display.
  final List<HfModelModel> results;

  /// Called when a user taps a GGUF file row in a model card.
  final void Function(HfModelModel model, HfModelFileModel file)? onFileSelected;

  /// Creates a [DiscoverModelList].
  const DiscoverModelList({
    super.key,
    required this.results,
    this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for GGUF models on HuggingFace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _DiscoverModelCard(
          model: results[index],
          onFileSelected: onFileSelected,
        );
      },
    );
  }
}

/// Expandable card showing a HuggingFace model repository with GGUF files.
class _DiscoverModelCard extends StatefulWidget {
  final HfModelModel model;
  final void Function(HfModelModel model, HfModelFileModel file)? onFileSelected;

  const _DiscoverModelCard({required this.model, this.onFileSelected});

  @override
  State<_DiscoverModelCard> createState() => _DiscoverModelCardState();
}

class _DiscoverModelCardState extends State<_DiscoverModelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final ggufFiles = model.ggufFiles;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              Icons.hub,
              color: colorScheme.primary,
            ),
            title: Text(
              model.id,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                '${ggufFiles.length} GGUF files',
                '${model.downloads} downloads',
                '${model.likes} likes',
                if (model.isGated) 'Gated',
              ].join(' · '),
            ),
            trailing: ggufFiles.isNotEmpty
                ? IconButton(
                    icon: Icon(_expanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                    onPressed: () =>
                        setState(() => _expanded = !_expanded),
                  )
                : null,
            onTap: ggufFiles.isNotEmpty
                ? () => setState(() => _expanded = !_expanded)
                : null,
          ),
          if (_expanded && ggufFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 12),
              child: Column(
                children: ggufFiles.map((file) {
                  return _FileRow(
                    file: file,
                    onTap: widget.onFileSelected != null
                        ? () =>
                            widget.onFileSelected!(model, file)
                        : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single GGUF file row within an expanded model card.
class _FileRow extends StatelessWidget {
  final HfModelFileModel file;
  final VoidCallback? onTap;

  const _FileRow({required this.file, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            if (file.isRecommended)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.star, size: 16, color: Colors.amber),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.filename,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: file.isRecommended
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.qualityLabel != null)
                    Text(
                      file.qualityLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (file.quantLabel.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  file.quantLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              file.formattedSize,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
