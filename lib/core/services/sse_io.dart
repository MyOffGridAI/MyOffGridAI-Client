/// Native (IO) platform SSE stream stub.
///
/// On native platforms, SSE streaming uses Dio's byte-stream adapter which
/// delivers chunks incrementally. This stub exists only to satisfy the
/// conditional import contract — it is never called at runtime.
Stream<String> platformSsePost({
  required String url,
  required String body,
  required Map<String, String> headers,
}) {
  throw UnsupportedError('platformSsePost is only implemented for web');
}
