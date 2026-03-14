/// Utility class for formatting byte sizes into human-readable strings.
class SizeFormatter {
  SizeFormatter._();

  /// Formats [bytes] into a human-readable string like "1.2 MB" or "340 KB".
  static String formatBytes(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';

    const units = ['KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int unitIndex = -1;

    do {
      value /= 1024;
      unitIndex++;
    } while (value >= 1024 && unitIndex < units.length - 1);

    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
}
