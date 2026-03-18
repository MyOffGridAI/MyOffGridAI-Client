import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Collapsible block showing the AI's thinking/reasoning process.
///
/// Three visual states:
/// - **Streaming**: Expanded with a pulsing border, showing live thinking text
///   inside a scroll-constrained view (max 200 px).
/// - **Collapsed** (default after stream): Shows a compact chip with token count.
/// - **Expanded**: User tapped to reveal the full thinking content.
class ThinkingBlock extends StatefulWidget {
  /// The thinking text content.
  final String content;

  /// Whether thinking content is still being streamed.
  final bool isStreaming;

  /// Estimated token count for the thinking block, if available.
  final int? thinkingTokenCount;

  /// Creates a [ThinkingBlock].
  const ThinkingBlock({
    super.key,
    required this.content,
    this.isStreaming = false,
    this.thinkingTokenCount,
  });

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      // Streaming just started
      _pulseController.repeat(reverse: true);
      _isExpanded = true;
    } else if (!widget.isStreaming && oldWidget.isStreaming) {
      // Streaming just stopped — delay collapse by 500ms
      _pulseController.stop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isExpanded = false);
        }
      });
    }

    // Auto-scroll to bottom when content changes during streaming
    if (widget.isStreaming && widget.content != oldWidget.content) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          final pulseOpacity = 0.4 + (_pulseController.value * 0.6);
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
                    const Text(
                      '\u{1F4AD}',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Thinking...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Text(
                      widget.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Collapsed state: chip
    if (!_isExpanded) {
      final label = widget.thinkingTokenCount != null
          ? 'Thought process \u00b7 ${widget.thinkingTokenCount} tokens \u25be'
          : 'Thought process \u25be';
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
              const Text(
                '\u{1F4AD}',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Expanded state: full thinking content
    final headerLabel = widget.thinkingTokenCount != null
        ? '\u{1F4AD} Thought process \u00b7 ${widget.thinkingTokenCount} tokens \u25b4'
        : '\u{1F4AD} Thought process \u25b4';
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
            child: Text(
              headerLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
