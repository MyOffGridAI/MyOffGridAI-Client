import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Utility class for platform and screen-size detection.
///
/// Provides simple boolean checks for mobile, web, and tablet
/// to drive responsive layout decisions throughout the app.
class PlatformUtils {
  PlatformUtils._();

  /// True when running as Flutter Web.
  static bool get isWeb => kIsWeb;

  /// True when running on iOS or Android (non-web).
  static bool get isMobile => !kIsWeb;

  /// Returns true if the screen width is between 600 and 1200 logical pixels.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1200;
  }

  /// Returns true if the screen width is less than 600 logical pixels.
  static bool isMobileWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  /// Returns true if the screen width is 1200 or more logical pixels.
  static bool isDesktopWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1200;
  }
}
