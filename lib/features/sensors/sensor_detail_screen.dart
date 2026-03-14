import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';
import 'package:myoffgridai_client/core/services/sensor_service.dart';
import 'package:myoffgridai_client/shared/widgets/error_view.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Provider for a single sensor by ID.
final _sensorProvider =
    FutureProvider.autoDispose.family<SensorModel, String>(
  (ref, sensorId) async {
    final service = ref.watch(sensorServiceProvider);
    return service.getSensor(sensorId);
  },
);

/// Provider for sensor reading history.
final _historyProvider =
    FutureProvider.autoDispose.family<List<SensorReadingModel>, String>(
  (ref, sensorId) async {
    final service = ref.watch(sensorServiceProvider);
    return service.getHistory(sensorId, hours: 24, size: 50);
  },
);

/// Detail view for a single sensor with historical chart.
///
/// Shows sensor metadata, latest reading, and a line chart of
/// historical readings using [fl_chart].
class SensorDetailScreen extends ConsumerWidget {
  /// The sensor ID to display.
  final String sensorId;

  /// Creates a [SensorDetailScreen] for the given [sensorId].
  const SensorDetailScreen({super.key, required this.sensorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(_sensorProvider(sensorId));
    final historyAsync = ref.watch(_historyProvider(sensorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Detail')),
      body: sensorAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          title: 'Failed to load sensor',
          message: error is ApiException
              ? error.message
              : 'An unexpected error occurred.',
          onRetry: () => ref.invalidate(_sensorProvider(sensorId)),
        ),
        data: (sensor) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSensorInfo(context, sensor),
              const SizedBox(height: 24),
              Text('History (24h)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: historyAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (_, __) => const Center(
                    child: Text('Failed to load history'),
                  ),
                  data: (readings) => _buildChart(context, readings, sensor),
                ),
              ),
              const SizedBox(height: 24),
              _buildReadingsList(context, ref, historyAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorInfo(BuildContext context, SensorModel sensor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sensor.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Icon(
                  Icons.circle,
                  size: 12,
                  color: sensor.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(sensor.isActive ? 'Active' : 'Inactive'),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('Type', sensor.type),
            if (sensor.portPath != null)
              _infoRow('Port', sensor.portPath!),
            _infoRow('Baud Rate', '${sensor.baudRate}'),
            _infoRow('Poll Interval', '${sensor.pollIntervalSeconds}s'),
            if (sensor.unit != null) _infoRow('Unit', sensor.unit!),
            if (sensor.lowThreshold != null)
              _infoRow('Low Threshold', '${sensor.lowThreshold}'),
            if (sensor.highThreshold != null)
              _infoRow('High Threshold', '${sensor.highThreshold}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<SensorReadingModel> readings,
    SensorModel sensor,
  ) {
    if (readings.isEmpty) {
      return const Center(child: Text('No readings yet'));
    }

    final spots = readings.reversed.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (sensor.lowThreshold != null)
              HorizontalLine(
                y: sensor.lowThreshold!,
                color: Colors.blue.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            if (sensor.highThreshold != null)
              HorizontalLine(
                y: sensor.highThreshold!,
                color: Colors.red.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SensorReadingModel>> historyAsync,
  ) {
    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (readings) {
        if (readings.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Readings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...readings.take(10).map((r) => ListTile(
                  dense: true,
                  title: Text('${r.value}'),
                  subtitle: r.recordedAt != null
                      ? Text(r.recordedAt!)
                      : null,
                )),
          ],
        );
      },
    );
  }
}
