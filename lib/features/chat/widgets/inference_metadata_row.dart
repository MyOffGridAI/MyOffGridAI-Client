import 'package:flutter/material.dart';

/// Displays inference performance metadata beneath an assistant message bubble.
///
/// Shows tokens per second, inference time, and stop reason as a compact
/// row of dimmed text chips.
class InferenceMetadataRow extends StatelessWidget {
  /// Tokens generated per second during inference.
  final double? tokensPerSecond;

  /// Total inference time in seconds.
  final double? inferenceTimeSeconds;

  /// The reason inference stopped (e.g., "stop", "length").
  final String? stopReason;

  /// Creates an [InferenceMetadataRow].
  const InferenceMetadataRow({
    super.key,
    this.tokensPerSecond,
    this.inferenceTimeSeconds,
    this.stopReason,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = colorScheme.onSurface.withValues(alpha: 0.4);
    final metaStyle = TextStyle(fontSize: 10, color: metaColor);

    final parts = <String>[];

    if (inferenceTimeSeconds != null) {
      parts.add('${inferenceTimeSeconds!.toStringAsFixed(1)}s');
    }
    if (tokensPerSecond != null) {
      parts.add('${tokensPerSecond!.toStringAsFixed(1)} tok/s');
    }
    if (stopReason != null && stopReason!.isNotEmpty) {
      parts.add(stopReason!);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.speed, size: 10, color: metaColor),
        const SizedBox(width: 4),
        Text(parts.join(' · '), style: metaStyle),
      ],
    );
  }
}
