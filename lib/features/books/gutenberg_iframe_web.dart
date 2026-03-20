// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool _registered = false;
html.IFrameElement? _activeIframe;

/// Registers the Gutenberg iframe platform view factory for Flutter web.
void registerGutenbergIframe() {
  if (_registered) return;
  _registered = true;
  ui_web.platformViewRegistry.registerViewFactory(
    'gutenberg-iframe',
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'https://www.gutenberg.org'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      _activeIframe = iframe;
      return iframe;
    },
  );
}

/// Resets the Gutenberg iframe back to the home page.
void resetGutenbergIframe() {
  _activeIframe?.src = 'https://www.gutenberg.org';
}
