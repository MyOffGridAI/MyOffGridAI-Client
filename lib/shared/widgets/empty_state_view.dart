import 'package:flutter/material.dart';

/// Empty list state widget with icon, title, and optional subtitle.
///
/// Used when a list has no items to display, providing a clear
/// visual indication and optional guidance text.
class EmptyStateView extends StatelessWidget {
  /// The icon displayed at the top.
  final IconData icon;

  /// The primary text describing the empty state.
  final String title;

  /// Optional secondary text with additional context.
  final String? subtitle;

  /// Creates an [EmptyStateView] with the given [icon], [title], and optional [subtitle].
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
