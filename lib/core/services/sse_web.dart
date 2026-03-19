import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-platform SSE POST stream using XHR with text responseType.
///
/// Dio's web adapter uses `XMLHttpRequest` with `responseType = 'arraybuffer'`,
/// which buffers the **entire** response before delivering it — completely
/// breaking SSE streaming. This implementation uses text mode instead, where
/// [html.HttpRequest.responseText] grows incrementally and `onProgress` fires
/// as chunks arrive from the server.
///
/// Returns a [Stream] of text fragments as they arrive. Each fragment may
/// contain partial SSE lines; the caller is responsible for line-buffering.
Stream<String> platformSsePost({
  required String url,
  required String body,
  required Map<String, String> headers,
}) {
  late final StreamController<String> controller;
  final xhr = html.HttpRequest();
  int lastIndex = 0;

  void flush() {
    final text = xhr.responseText ?? '';
    if (text.length > lastIndex) {
      controller.add(text.substring(lastIndex));
      lastIndex = text.length;
    }
  }

  controller = StreamController<String>(
    onCancel: () => xhr.abort(),
  );

  xhr.open('POST', url);
  for (final entry in headers.entries) {
    xhr.setRequestHeader(entry.key, entry.value);
  }

  // onProgress fires periodically during LOADING — responseText contains
  // all data received so far, so we emit only the new portion each time.
  xhr.onProgress.listen((_) => flush());

  xhr.onLoad.listen((_) {
    flush();
    if (xhr.status != null && (xhr.status! < 200 || xhr.status! >= 300)) {
      controller.addError(
        Exception('SSE request failed: ${xhr.status} ${xhr.statusText}'),
      );
    }
    controller.close();
  });

  xhr.onError.listen((_) {
    controller.addError(
      Exception('SSE network error: ${xhr.status} ${xhr.statusText}'),
    );
    controller.close();
  });

  xhr.send(body);
  return controller.stream;
}
