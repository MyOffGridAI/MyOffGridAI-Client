import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/api/providers.dart';
import 'package:myoffgridai_client/shared/widgets/connection_lost_banner.dart';

void main() {
  group('ConnectionLostBanner', () {
    testWidgets('visible when connection lost', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionStatusProvider
                .overrideWith((ref) => Stream.value(false)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ConnectionLostBanner()),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Cannot reach MyOffGrid AI'),
        findsOneWidget,
      );
    });

    testWidgets('hidden when connection is active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionStatusProvider
                .overrideWith((ref) => Stream.value(true)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ConnectionLostBanner()),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Cannot reach MyOffGrid AI'),
        findsNothing,
      );
    });

    testWidgets('hidden during loading state', (tester) async {
      final controller = StreamController<bool>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionStatusProvider
                .overrideWith((ref) => controller.stream),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ConnectionLostBanner()),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Cannot reach MyOffGrid AI'),
        findsNothing,
      );
      controller.close();
    });
  });
}
