import 'package:flutter/material.dart';

/// Size options for the [LoadingIndicator].
enum LoadingSize {
  /// 16px indicator.
  small(16),

  /// 24px indicator (default).
  medium(24),

  /// 40px indicator.
  large(40);

  final double dimension;
  const LoadingSize(this.dimension);
}

/// A centered circular progress indicator with optional label text.
///
/// Provides three size variants ([LoadingSize]) and an optional
/// descriptive [label] displayed below the spinner.
class LoadingIndicator extends StatelessWidget {
  /// Optional label displayed below the spinner.
  final String? label;

  /// The size of the spinner.
  final LoadingSize size;

  /// Creates a [LoadingIndicator] with optional [label] and [size].
  const LoadingIndicator({
    super.key,
    this.label,
    this.size = LoadingSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.dimension,
            height: size.dimension,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
