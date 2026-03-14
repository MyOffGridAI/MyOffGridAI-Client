import 'package:intl/intl.dart';

/// Utility class for formatting dates consistently throughout the app.
class DateFormatter {
  DateFormatter._();

  /// Formats [dt] as a relative time string.
  ///
  /// Returns "just now" for < 1 minute, "X minutes ago", "X hours ago",
  /// "Yesterday", or a short date like "Mar 14".
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(dt);
  }

  /// Formats [dt] as a full date-time string like "March 14, 2026 at 3:45 PM".
  static String formatFull(DateTime dt) {
    return DateFormat("MMMM d, y 'at' h:mm a").format(dt);
  }

  /// Formats [dt] as a short date string like "Mar 14, 2026".
  static String formatDate(DateTime dt) {
    return DateFormat('MMM d, y').format(dt);
  }
}
