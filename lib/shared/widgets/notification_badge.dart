import 'package:flutter/material.dart';

/// A small red circle badge overlaid on a child widget showing a count.
///
/// Hides itself when [count] is 0.
class NotificationBadge extends StatelessWidget {
  /// The number to display in the badge.
  final int count;

  /// The widget to overlay the badge on.
  final Widget child;

  /// Creates a [NotificationBadge] with the given [count] and [child].
  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
