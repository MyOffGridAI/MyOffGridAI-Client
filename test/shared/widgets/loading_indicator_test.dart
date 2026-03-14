import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('renders at small size without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(size: LoadingSize.small)),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox).first).width, 16);
    });

    testWidgets('renders at medium size (default) without overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox).first).width, 24);
    });

    testWidgets('renders at large size without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(size: LoadingSize.large)),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox).first).width, 40);
    });

    testWidgets('shows label text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator(label: 'Loading data...')),
        ),
      );
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('hides label text when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingIndicator()),
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });
}
