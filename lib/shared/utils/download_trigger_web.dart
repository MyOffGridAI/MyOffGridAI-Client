// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of [triggerDownload] using an [html.AnchorElement].
///
/// Creates a hidden anchor element with the given data [uri] and
/// [filename], triggers a click to start the download, then removes
/// the element from the DOM.
void triggerDownload(String uri, String filename) {
  final anchor = html.AnchorElement(href: uri)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
