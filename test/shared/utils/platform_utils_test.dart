import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/utils/platform_utils.dart';

void main() {
  group('PlatformUtils', () {
    test('isMobile returns true in non-web test environment', () {
      expect(PlatformUtils.isMobile, isTrue);
    });

    test('isWeb returns false in non-web test environment', () {
      expect(PlatformUtils.isWeb, isFalse);
    });

    testWidgets('isMobileWidth returns true for narrow screens',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isMobileWidth(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isMobileWidth returns false for wide screens',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isMobileWidth(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for tablet width (600-1199)',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isTablet(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns false for mobile width (<600)',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isTablet(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns false for desktop width (>=1200)',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isTablet(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktopWidth returns true for wide screens (>=1200)',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isDesktopWidth(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktopWidth returns false for narrow screens (<1200)',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 600)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isDesktopWidth(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('boundary: 600px is tablet, not mobile', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isMobileWidth(context), isFalse);
              expect(PlatformUtils.isTablet(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('boundary: 1200px is desktop, not tablet', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 900)),
          child: Builder(
            builder: (context) {
              expect(PlatformUtils.isTablet(context), isFalse);
              expect(PlatformUtils.isDesktopWidth(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
