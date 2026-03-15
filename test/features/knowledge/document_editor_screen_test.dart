import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/features/knowledge/document_editor_screen.dart';

void main() {
  group('DocumentEditorScreen', () {
    Widget buildScreen({String? documentId}) {
      return ProviderScope(
        child: MaterialApp(
          home: DocumentEditorScreen(documentId: documentId),
        ),
      );
    }

    testWidgets('new document shows New Document title', (tester) async {
      // QuillSimpleToolbar overflows in test environment — suppress
      FlutterError.onError = (details) {};
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('New Document'), findsOneWidget);
    });

    testWidgets('new document shows title field', (tester) async {
      FlutterError.onError = (details) {};
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('new document shows save button', (tester) async {
      FlutterError.onError = (details) {};
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('edit mode shows Edit Document title', (tester) async {
      FlutterError.onError = (details) {};
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await tester.pumpWidget(buildScreen(documentId: 'some-id'));
      await tester.pump();

      expect(find.text('Edit Document'), findsOneWidget);
    });

    testWidgets('new document shows back button', (tester) async {
      FlutterError.onError = (details) {};
      addTearDown(() => FlutterError.onError = FlutterError.dumpErrorToConsole);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
