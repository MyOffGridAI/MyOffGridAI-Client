import 'package:flutter/material.dart';

/// Animated typing indicator bubble shown while the AI is generating a response.
///
/// Displays three pulsing dots styled like an assistant message bubble
/// (left-aligned, surfaceContainerHighest background). Uses a single
/// [AnimationController] with staggered intervals for each dot.
class ThinkingIndicatorBubble extends StatefulWidget {
  /// Creates a [ThinkingIndicatorBubble].
  const ThinkingIndicatorBubble({super.key});

  @override
  State<ThinkingIndicatorBubble> createState() =>
      _ThinkingIndicatorBubbleState();
}

class _ThinkingIndicatorBubbleState extends State<ThinkingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final t = (_controller.value - delay) % 1.0;
                final opacity = (1.0 - (t - 0.5).abs() * 2).clamp(0.3, 1.0);
                final offset = -4.0 * (1.0 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
