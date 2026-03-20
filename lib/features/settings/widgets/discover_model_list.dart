import 'package:flutter/material.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';
import 'package:myoffgridai_client/shared/utils/date_formatter.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';

/// Scrollable list of HuggingFace model search results.
///
/// Each model is displayed as an expandable card showing repository metadata
/// and available GGUF files. Selecting a file triggers [onFileSelected] to
/// show the file's details in the [ModelDetailPanel].
class DiscoverModelList extends StatelessWidget {
  /// The search results to display.
  final List<HfModelModel> results;

  /// Whether a search or initial load is in progress.
  final bool isLoading;

  /// Called when a user taps a GGUF file row in a model card.
  final void Function(HfModelModel model, HfModelFileModel file)? onFileSelected;

  /// Creates a [DiscoverModelList].
  const DiscoverModelList({
    super.key,
    required this.results,
    this.isLoading = false,
    this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading models...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ] else ...[
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
                'No models found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
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

/// Returns an icon based on the model's [pipelineTag].
IconData _pipelineIcon(String? pipelineTag) {
  switch (pipelineTag) {
    case 'text-generation':
      return Icons.chat;
    case 'image-to-text':
    case 'image-classification':
    case 'image-segmentation':
      return Icons.visibility;
    case 'text-to-image':
      return Icons.image;
    case 'code-generation':
      return Icons.code;
    case 'text2text-generation':
    case 'translation':
      return Icons.translate;
    case 'summarization':
      return Icons.summarize;
    default:
      return Icons.hub;
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
    final dimText = colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: ggufFiles.isNotEmpty
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pipeline icon
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 10),
                    child: Icon(
                      _pipelineIcon(model.pipelineTag),
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  // Model info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Model name
                        Text(
                          model.modelId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Author
                        Text(
                          model.author,
                          style: TextStyle(fontSize: 12, color: dimText),
                        ),
                        const SizedBox(height: 4),
                        // Stats line
                        Text(
                          [
                            '${SizeFormatter.formatCount(model.downloads)} downloads',
                            '${SizeFormatter.formatCount(model.likes)} likes',
                            '${ggufFiles.length} GGUF files',
                          ].join(' · '),
                          style: TextStyle(fontSize: 11, color: dimText),
                        ),
                        const SizedBox(height: 6),
                        // Tag chips + timestamp
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (model.pipelineTag != null)
                              _TagChip(
                                label: model.pipelineTag!,
                                color: colorScheme.primaryContainer,
                                textColor: colorScheme.onPrimaryContainer,
                              ),
                            _TagChip(
                              label: 'GGUF',
                              color: colorScheme.tertiaryContainer,
                              textColor: colorScheme.onTertiaryContainer,
                            ),
                            if (model.isGated)
                              _TagChip(
                                label: 'Gated',
                                color: colorScheme.errorContainer,
                                textColor: colorScheme.onErrorContainer,
                              ),
                            if (model.lastModified != null)
                              Text(
                                '· ${DateFormatter.formatRelative(model.lastModified!)}',
                                style: TextStyle(fontSize: 11, color: dimText),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand button
                  if (ggufFiles.isNotEmpty)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: dimText,
                    ),
                ],
              ),
            ),
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

/// A small styled chip for displaying tags.
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _TagChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
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
