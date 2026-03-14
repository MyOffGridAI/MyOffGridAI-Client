import 'package:flutter/material.dart';

/// A reusable confirmation dialog with confirm and cancel actions.
///
/// Use the static [show] method to display the dialog and receive
/// a boolean result indicating the user's choice.
class ConfirmationDialog extends StatelessWidget {
  /// The dialog title.
  final String title;

  /// The dialog message body.
  final String message;

  /// Text for the confirm button.
  final String confirmText;

  /// Text for the cancel button.
  final String cancelText;

  /// Whether the confirm action is destructive (renders button in red).
  final bool isDestructive;

  /// Creates a [ConfirmationDialog].
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
  });

  /// Shows a [ConfirmationDialog] and returns true if confirmed, false if cancelled.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
