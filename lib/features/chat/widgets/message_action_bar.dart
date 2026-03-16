import 'package:flutter/material.dart';
import 'package:myoffgridai_client/core/models/message_model.dart';

/// Row of action buttons shown beneath a message bubble.
///
/// Assistant messages show: Copy, Regenerate, Branch, Delete.
/// User messages show: Edit, Delete.
/// Buttons are compact icon-only with tooltips and appear on hover/tap.
class MessageActionBar extends StatefulWidget {
  /// The message these actions apply to.
  final MessageModel message;

  /// Called when the user taps "Copy".
  final VoidCallback? onCopy;

  /// Called when the user taps "Edit" (user messages only).
  final VoidCallback? onEdit;

  /// Called when the user taps "Delete".
  final VoidCallback? onDelete;

  /// Called when the user taps "Regenerate" (assistant messages only).
  final VoidCallback? onRegenerate;

  /// Called when the user taps "Branch".
  final VoidCallback? onBranch;

  /// Creates a [MessageActionBar].
  const MessageActionBar({
    super.key,
    required this.message,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
    this.onBranch,
  });

  @override
  State<MessageActionBar> createState() => _MessageActionBarState();
}

class _MessageActionBarState extends State<MessageActionBar> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface.withValues(alpha: 0.4);
    const iconSize = 16.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => setState(() => _isHovering = !_isHovering),
        child: AnimatedOpacity(
          opacity: _isHovering ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Copy (both roles)
              if (widget.onCopy != null)
                _ActionButton(
                  icon: Icons.copy,
                  tooltip: 'Copy',
                  onTap: widget.onCopy!,
                  iconColor: iconColor,
                  iconSize: iconSize,
                ),

              // Edit (user only)
              if (widget.message.isUser && widget.onEdit != null)
                _ActionButton(
                  icon: Icons.edit,
                  tooltip: 'Edit',
                  onTap: widget.onEdit!,
                  iconColor: iconColor,
                  iconSize: iconSize,
                ),

              // Regenerate (assistant only)
              if (widget.message.isAssistant && widget.onRegenerate != null)
                _ActionButton(
                  icon: Icons.refresh,
                  tooltip: 'Regenerate',
                  onTap: widget.onRegenerate!,
                  iconColor: iconColor,
                  iconSize: iconSize,
                ),

              // Branch (both roles)
              if (widget.onBranch != null)
                _ActionButton(
                  icon: Icons.call_split,
                  tooltip: 'Branch',
                  onTap: widget.onBranch!,
                  iconColor: iconColor,
                  iconSize: iconSize,
                ),

              // Delete (both roles)
              if (widget.onDelete != null)
                _ActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  onTap: widget.onDelete!,
                  iconColor: colorScheme.error.withValues(alpha: 0.6),
                  iconSize: iconSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact icon button with a tooltip used in [MessageActionBar].
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;
  final double iconSize;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.iconColor,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}
