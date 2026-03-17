/// Stub implementation of [triggerDownload] for non-web platforms.
///
/// This is a no-op; native platforms should use platform-appropriate
/// file save mechanisms (e.g., file_picker, path_provider).
void triggerDownload(String uri, String filename) {
  // No-op on non-web platforms.
}
