import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/features/sensors/add_sensor_screen.dart';

void main() {
  group('AddSensorScreen', () {
    Widget buildScreen() {
      return const ProviderScope(
        child: MaterialApp(home: AddSensorScreen()),
      );
    }

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Add Sensor'), findsOneWidget);
    });

    testWidgets('shows sensor name field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sensor Name'), findsOneWidget);
    });

    testWidgets('shows port path field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Port Path'), findsOneWidget);
    });

    testWidgets('shows test connection button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test Connection'), findsOneWidget);
    });

    testWidgets('shows register button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Register Sensor'), findsOneWidget);
    });

    testWidgets('validates empty name', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register Sensor'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows baud rate dropdown', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Baud Rate'), findsOneWidget);
    });

    testWidgets('shows poll interval dropdown', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Poll Interval'), findsOneWidget);
    });
  });
}
