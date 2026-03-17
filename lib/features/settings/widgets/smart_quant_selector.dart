import 'package:flutter/material.dart';
import 'package:myoffgridai_client/core/models/model_catalog_models.dart';

/// Horizontal selector showing available quantizations sorted by quality rank.
///
/// Highlights the recommended variant and shows quality labels. Used in the
/// [ModelDetailPanel] to let users pick a quantization variant before downloading.
class SmartQuantSelector extends StatelessWidget {
  /// The available GGUF file variants.
  final List<HfModelFileModel> files;

  /// The currently selected file.
  final HfModelFileModel selected;

  /// Called when the user selects a different variant.
  final ValueChanged<HfModelFileModel> onSelected;

  /// Creates a [SmartQuantSelector].
  const SmartQuantSelector({
    super.key,
    required this.files,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by quality rank (highest first), falling back to filename
    final sorted = List<HfModelFileModel>.from(files)
      ..sort((a, b) {
        final rankA = a.qualityRank ?? 0;
        final rankB = b.qualityRank ?? 0;
        if (rankA != rankB) return rankB.compareTo(rankA);
        return a.filename.compareTo(b.filename);
      });

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = sorted[index];
          final isSelected = file.filename == selected.filename;

          return _QuantChip(
            file: file,
            isSelected: isSelected,
            onTap: () => onSelected(file),
          );
        },
      ),
    );
  }
}

/// Individual quantization option chip with label and size.
class _QuantChip extends StatelessWidget {
  final HfModelFileModel file;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuantChip({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected
        ? colorScheme.primary
        : file.isRecommended
            ? Colors.amber
            : colorScheme.outline.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (file.isRecommended)
              Icon(Icons.star, size: 12, color: Colors.amber),
            Text(
              file.quantLabel.isNotEmpty ? file.quantLabel : 'Unknown',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              file.formattedSize,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
