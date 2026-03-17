import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/utils/download_trigger_stub.dart';

void main() {
  group('triggerDownload (stub)', () {
    test('is callable without errors', () {
      expect(
        () => triggerDownload('data:text/plain;base64,SGVsbG8=', 'test.txt'),
        returnsNormally,
      );
    });

    test('handles empty URI and filename', () {
      expect(
        () => triggerDownload('', ''),
        returnsNormally,
      );
    });
  });
}
