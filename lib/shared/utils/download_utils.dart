import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myoffgridai_client/shared/utils/download_trigger_stub.dart'
    if (dart.library.html) 'package:myoffgridai_client/shared/utils/download_trigger_web.dart'
    as trigger;

/// Utility for triggering file downloads.
///
/// On web, creates an anchor element to download bytes as a file.
/// On other platforms, this is a no-op (desktop file save dialogs
/// should be handled via file_picker or similar).
class DownloadUtils {
  DownloadUtils._();

  /// Triggers a file download with the given [bytes] and [filename].
  ///
  /// Only functional on Flutter Web. On native platforms, callers should
  /// use platform-appropriate file save mechanisms.
  static void downloadBytes(List<int> bytes, String filename) {
    if (!kIsWeb) return;
    final base64 = base64Encode(bytes);
    final mimeType = _guessMimeType(filename);
    final uri = 'data:$mimeType;base64,$base64';
    trigger.triggerDownload(uri, filename);
  }

  static String _guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'md' => 'text/markdown',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'rtf' => 'application/rtf',
      _ => 'application/octet-stream',
    };
  }
}
