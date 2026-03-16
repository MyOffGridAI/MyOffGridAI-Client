import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/utils/download_utils.dart';

void main() {
  group('DownloadUtils', () {
    // ── downloadBytes ──────────────────────────────────────────────────────
    // On non-web (test environment), downloadBytes is a no-op (returns early).
    test('downloadBytes is a no-op on non-web platforms', () {
      // This should not throw — it simply returns early due to !kIsWeb.
      expect(
        () => DownloadUtils.downloadBytes([0x50, 0x44, 0x46], 'test.pdf'),
        returnsNormally,
      );
    });

    test('downloadBytes handles empty bytes without error', () {
      expect(
        () => DownloadUtils.downloadBytes([], 'empty.txt'),
        returnsNormally,
      );
    });

    test('downloadBytes handles various filenames without error', () {
      expect(
        () => DownloadUtils.downloadBytes([0x00], 'report.xlsx'),
        returnsNormally,
      );
      expect(
        () => DownloadUtils.downloadBytes([0x00], 'doc.docx'),
        returnsNormally,
      );
      expect(
        () => DownloadUtils.downloadBytes([0x00], 'slides.pptx'),
        returnsNormally,
      );
    });
  });
}
