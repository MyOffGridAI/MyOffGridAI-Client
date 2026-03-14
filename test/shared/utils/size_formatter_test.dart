import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/utils/size_formatter.dart';

void main() {
  group('SizeFormatter', () {
    test('formats bytes', () {
      expect(SizeFormatter.formatBytes(500), '500 B');
    });

    test('formats KB', () {
      expect(SizeFormatter.formatBytes(1024), '1.0 KB');
      expect(SizeFormatter.formatBytes(340 * 1024), '340 KB');
    });

    test('formats MB', () {
      expect(SizeFormatter.formatBytes(1024 * 1024), '1.0 MB');
      final bytes = (1.2 * 1024 * 1024).round();
      expect(SizeFormatter.formatBytes(bytes), '1.2 MB');
    });

    test('formats GB', () {
      final bytes = (2.1 * 1024 * 1024 * 1024).round();
      expect(SizeFormatter.formatBytes(bytes), '2.1 GB');
    });

    test('handles zero bytes', () {
      expect(SizeFormatter.formatBytes(0), '0 B');
    });

    test('handles negative bytes', () {
      expect(SizeFormatter.formatBytes(-100), '0 B');
    });
  });
}
