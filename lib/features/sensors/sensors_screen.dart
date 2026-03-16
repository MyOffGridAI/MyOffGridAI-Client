import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/shared/widgets/confirmation_dialog.dart';
import 'package:myoffgridai_client/shared/widgets/empty_state_view.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Dashboard displaying all registered sensors.
///
/// Shows sensors as cards with their type, status, and latest reading.
/// Provides navigation to sensor detail and add sensor screens.
class SensorsScreen extends ConsumerWidget {
  /// Creates a [SensorsScreen].
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorsAsync = ref.watch(sensorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sensors')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/sensors/add'),
        child: const Icon(Icons.add),
      ),
      body: sensorsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load sensors',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(sensorsProvider),
        ),
        data: (sensors) {
          if (sensors.isEmpty) {
            return const EmptyStateView(
              icon: Icons.sensors,
              title: 'No sensors registered',
              subtitle: 'Tap + to add a sensor',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: sensors.length,
            itemBuilder: (context, index) => _SensorCard(
              sensor: sensors[index],
              onTap: () => context.go('/sensors/${sensors[index].id}'),
              onToggle: () => _toggleSensor(context, ref, sensors[index]),
              onDelete: () =>
                  _deleteSensor(context, ref, sensors[index].id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleSensor(
    BuildContext context,
    WidgetRef ref,
    SensorModel sensor,
  ) async {
    try {
      final service = ref.read(sensorServiceProvider);
      if (sensor.isActive) {
        await service.stopSensor(sensor.id);
      } else {
        await service.startSensor(sensor.id);
      }
      ref.invalidate(sensorsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deleteSensor(
    BuildContext context,
    WidgetRef ref,
    String sensorId,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Sensor',
      message: 'This sensor and all its readings will be deleted.',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(sensorServiceProvider);
      await service.deleteSensor(sensorId);
      ref.invalidate(sensorsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}

/// Renders a sensor as a card in the grid with status icon, name, and toggle switch.
///
/// Tapping navigates to sensor detail; long-pressing triggers delete confirmation.
class _SensorCard extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SensorCard({
    required this.sensor,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _sensorIcon(sensor.type),
                    color: sensor.isActive ? Colors.green : Colors.grey,
                  ),
                  const Spacer(),
                  Switch(
                    value: sensor.isActive,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sensor.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sensor.type,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Row(
                children: [
                  if (sensor.unit != null)
                    Text(sensor.unit!,
                        style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    '${sensor.pollIntervalSeconds}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _sensorIcon(String type) {
    switch (type) {
      case 'TEMPERATURE':
        return Icons.thermostat;
      case 'HUMIDITY':
        return Icons.water_drop;
      case 'PRESSURE':
        return Icons.compress;
      case 'SOIL_MOISTURE':
        return Icons.grass;
      case 'WIND_SPEED':
        return Icons.air;
      case 'SOLAR_RADIATION':
        return Icons.wb_sunny;
      default:
        return Icons.sensors;
    }
  }
}
