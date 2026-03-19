import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:myoffgridai_client/core/models/message_model.dart';
import 'package:myoffgridai_client/features/chat/widgets/thinking_block.dart';
import 'package:myoffgridai_client/features/chat/widgets/inference_metadata_row.dart';
import 'package:myoffgridai_client/features/chat/widgets/message_action_bar.dart';

/// Renders a single chat message bubble with markdown content, thinking block,
/// inference metadata, and action buttons.
///
/// User messages are right-aligned with the primary color. Assistant messages
/// are left-aligned with a surface container background and include markdown
/// rendering, optional thinking blocks, metadata, and action buttons.
class MessageBubble extends StatelessWidget {
  /// The message to display.
  final MessageModel message;

  /// Whether this bubble is currently streaming (content still arriving).
  final bool isStreaming;

  /// Whether the AI is actively in the thinking phase for this conversation.
  ///
  /// When true AND [isStreaming] is true, the [ThinkingBlock] displays in
  /// its live streaming state. Computed by the parent from [aiThinkingProvider].
  final bool isActivelyThinking;

  /// Called when the user taps "Edit" on their own message.
  final ValueChanged<MessageModel>? onEdit;

  /// Called when the user taps "Delete" on a message.
  final ValueChanged<MessageModel>? onDelete;

  /// Called when the user taps "Regenerate" on an assistant message.
  final ValueChanged<MessageModel>? onRegenerate;

  /// Called when the user taps "Branch" on a message.
  final ValueChanged<MessageModel>? onBranch;

  /// Creates a [MessageBubble].
  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.isActivelyThinking = false,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
    this.onBranch,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.80,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thinking block (assistant only)
                  // Show when: (a) there IS thinking content, OR
                  // (b) the model is actively thinking and this is the
                  //     streaming bubble (handles "waiting for first chunk")
                  if (!isUser &&
                      ((message.thinkingContent != null &&
                              message.thinkingContent!.isNotEmpty) ||
                          (isActivelyThinking && isStreaming)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ThinkingBlock(
                        content: message.thinkingContent ?? '',
                        isStreaming: isActivelyThinking && isStreaming,
                        thinkingTokenCount: message.thinkingTokenCount,
                      ),
                    ),

                  // Message content
                  if (isUser)
                    SelectableText(
                      message.content,
                      style: TextStyle(color: colorScheme.onPrimary),
                    )
                  else
                    _AssistantMarkdownContent(content: message.content),

                  // RAG context indicator
                  if (message.hasRagContext)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories,
                            size: 14,
                            color: isUser
                                ? colorScheme.onPrimary
                                    .withValues(alpha: 0.7)
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Knowledge-enhanced',
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser
                                  ? colorScheme.onPrimary
                                      .withValues(alpha: 0.7)
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Source tag and judge score badges (assistant only)
                  if (!isUser &&
                      (message.sourceTag != null || message.hasJudgeScore))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (message.sourceTag != null)
                            _SourceTagBadge(sourceTag: message.sourceTag!),
                          if (message.hasJudgeScore)
                            _JudgeScoreChip(
                              score: message.judgeScore!,
                              reason: message.judgeReason,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Inference metadata (assistant only, after stream completes)
            if (!isUser && !isStreaming && message.inferenceTimeSeconds != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: InferenceMetadataRow(
                  tokensPerSecond: message.tokensPerSecond,
                  inferenceTimeSeconds: message.inferenceTimeSeconds,
                  stopReason: message.stopReason,
                ),
              ),

            // Action bar (not during streaming)
            if (!isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: MessageActionBar(
                  message: message,
                  onCopy: () => _copyToClipboard(context, message.content),
                  onEdit: onEdit != null ? () => onEdit!(message) : null,
                  onDelete: onDelete != null ? () => onDelete!(message) : null,
                  onRegenerate:
                      onRegenerate != null ? () => onRegenerate!(message) : null,
                  onBranch: onBranch != null ? () => onBranch!(message) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Renders assistant message content as markdown with syntax highlighting.
class _AssistantMarkdownContent extends StatelessWidget {
  final String content;

  const _AssistantMarkdownContent({required this.content});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 15,
          height: 1.5,
        ),
        h1: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h2: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        h2Padding: const EdgeInsets.only(top: 6, bottom: 2),
        h3: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        blockSpacing: 12,
        listIndent: 20,
        code: TextStyle(
          color: colorScheme.onSurface,
          backgroundColor: colorScheme.surfaceContainerHigh,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF282C34),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
        blockquotePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        listBullet: TextStyle(color: colorScheme.onSurface),
      ),
      builders: {
        'code': _CodeBlockBuilder(),
      },
    );
  }
}

/// Badge showing whether a response was generated locally or enhanced by cloud.
class _SourceTagBadge extends StatelessWidget {
  /// The source tag value (e.g. "LOCAL", "ENHANCED").
  final String sourceTag;

  const _SourceTagBadge({required this.sourceTag});

  @override
  Widget build(BuildContext context) {
    final isEnhanced = sourceTag == 'ENHANCED';
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEnhanced
            ? colorScheme.tertiary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnhanced ? Icons.cloud : Icons.computer,
            size: 12,
            color: isEnhanced
                ? colorScheme.tertiary
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 3),
          Text(
            isEnhanced ? 'Cloud-enhanced' : 'Local',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isEnhanced
                  ? colorScheme.tertiary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip showing the AI judge quality score with a color indicator.
class _JudgeScoreChip extends StatelessWidget {
  /// The quality score from 1 to 10.
  final double score;

  /// Brief explanation of the score (shown on tap via tooltip).
  final String? reason;

  const _JudgeScoreChip({required this.score, this.reason});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoreColor = _scoreColor(score, colorScheme);

    return Tooltip(
      message: reason ?? 'Quality score: ${score.toStringAsFixed(1)}/10',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel, size: 12, color: scoreColor),
            const SizedBox(width: 3),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score, ColorScheme colorScheme) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return colorScheme.error;
  }
}

/// Custom markdown builder for fenced code blocks with syntax highlighting.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Only handle fenced code blocks (pre > code)
    if (element.tag != 'code') return null;

    final content = element.textContent;
    final language = element.attributes['class']?.replaceFirst('language-', '');

    if (language == null || language.isEmpty) {
      // Inline code — let default handler manage it
      return null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language label header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1E2127),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language,
                  style: const TextStyle(
                    color: Color(0xFF9DA5B4),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    size: 14,
                    color: Color(0xFF9DA5B4),
                  ),
                ),
              ],
            ),
          ),
          // Highlighted code
          HighlightView(
            content,
            language: language,
            theme: atomOneDarkTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
