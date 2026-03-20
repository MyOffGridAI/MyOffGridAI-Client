// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool _registered = false;

/// Registers the Gutenberg iframe platform view factory for Flutter web.
void registerGutenbergIframe() {
  if (_registered) return;
  _registered = true;
  ui_web.platformViewRegistry.registerViewFactory(
    'gutenberg-iframe',
    (int viewId) {
      return html.IFrameElement()
        ..src = 'https://www.gutenberg.org'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    },
  );
}
