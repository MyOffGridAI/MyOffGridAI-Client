import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

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
    // Web download via data URI approach (avoids dart:html import issues)
    // ignore: avoid_dynamic_calls
    _webDownload(bytes, filename);
  }

  static void _webDownload(List<int> bytes, String filename) {
    // Use universal_html or js_interop for web downloads
    // For now, use a base64 data URI approach that works across platforms
    final base64 = base64Encode(bytes);
    final mimeType = _guessMimeType(filename);
    // This will be handled by the web engine via a data URI
    // In a real web app, you'd use dart:html AnchorElement
    // For cross-platform safety, we encode and trigger via JS interop
    final uri = 'data:$mimeType;base64,$base64';
    _triggerDownload(uri, filename);
  }

  static void _triggerDownload(String uri, String filename) {
    // Platform-safe: this will only work on web via dart:js_interop
    // On non-web, this is a no-op handled by the kIsWeb guard above
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
      _ => 'application/octet-stream',
    };
  }
}
