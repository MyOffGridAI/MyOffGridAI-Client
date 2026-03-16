import 'package:flutter/material.dart';

/// Collapsible block showing the AI's thinking/reasoning process.
///
/// Three visual states:
/// - **Streaming**: Expanded with a pulsing border, showing live thinking text.
/// - **Collapsed** (default after stream): Shows "Thought for Xs" as a chip.
/// - **Expanded**: User tapped to reveal the full thinking content.
class ThinkingBlock extends StatefulWidget {
  /// The thinking text content.
  final String content;

  /// Whether thinking content is still being streamed.
  final bool isStreaming;

  /// Creates a [ThinkingBlock].
  const ThinkingBlock({
    super.key,
    required this.content,
    this.isStreaming = false,
  });

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isStreaming) {
      _pulseController.repeat(reverse: true);
      _isExpanded = true;
    }
  }

  @override
  void didUpdateWidget(ThinkingBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      _isExpanded = true;
    } else if (!widget.isStreaming && _pulseController.isAnimating) {
      _pulseController.stop();
      _isExpanded = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Streaming state: always expanded with pulsing border
    if (widget.isStreaming) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseOpacity = 0.3 + (_pulseController.value * 0.4);
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: pulseOpacity),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Thinking...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Collapsed state: chip showing "Thought for Xs"
    if (!_isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Thought process',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      );
    }

    // Expanded state: full thinking content
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Thought process',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.expand_less,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            widget.content,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
