import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/features/sensors/sensors_screen.dart';

void main() {
  group('SensorsScreen', () {
    Widget buildScreen({List<SensorModel> sensors = const []}) {
      return ProviderScope(
        overrides: [
          sensorsProvider.overrideWith((ref) => sensors),
        ],
        child: const MaterialApp(home: SensorsScreen()),
      );
    }

    testWidgets('shows empty state when no sensors', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('No sensors registered'), findsOneWidget);
    });

    testWidgets('displays sensor cards', (tester) async {
      final sensors = [
        SensorModel.fromJson({
          'id': '1',
          'name': 'Greenhouse Temp',
          'type': 'TEMPERATURE',
          'baudRate': 9600,
          'isActive': true,
          'pollIntervalSeconds': 30,
        }),
        SensorModel.fromJson({
          'id': '2',
          'name': 'Soil Moisture',
          'type': 'SOIL_MOISTURE',
          'baudRate': 9600,
          'isActive': false,
          'pollIntervalSeconds': 60,
        }),
      ];

      await tester.pumpWidget(buildScreen(sensors: sensors));
      await tester.pumpAndSettle();

      expect(find.text('Greenhouse Temp'), findsOneWidget);
      expect(find.text('Soil Moisture'), findsOneWidget);
    });

    testWidgets('shows add FAB', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows toggle switch on sensor cards', (tester) async {
      final sensors = [
        SensorModel.fromJson({
          'id': '1',
          'name': 'Temp',
          'type': 'TEMPERATURE',
          'baudRate': 9600,
          'isActive': true,
          'pollIntervalSeconds': 60,
        }),
      ];

      await tester.pumpWidget(buildScreen(sensors: sensors));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sensors'), findsOneWidget);
    });
  });
}
