import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/sensor_model.dart';

/// Service for sensor management and reading operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class SensorService {
  final MyOffGridAIApiClient _client;

  /// Creates a [SensorService] with the given API [client].
  SensorService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists all sensors.
  Future<List<SensorModel>> listSensors() async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.sensorsBasePath,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => SensorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a single sensor by [sensorId].
  Future<SensorModel> getSensor(String sensorId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/$sensorId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return SensorModel.fromJson(data);
  }

  /// Registers a new sensor.
  Future<SensorModel> createSensor({
    required String name,
    required String type,
    required String portPath,
    int? baudRate,
    String? dataFormat,
    String? valueField,
    String? unit,
    required int pollIntervalSeconds,
    double? lowThreshold,
    double? highThreshold,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppConstants.sensorsBasePath,
      data: {
        'name': name,
        'type': type,
        'portPath': portPath,
        if (baudRate != null) 'baudRate': baudRate,
        if (dataFormat != null) 'dataFormat': dataFormat,
        if (valueField != null) 'valueField': valueField,
        if (unit != null) 'unit': unit,
        'pollIntervalSeconds': pollIntervalSeconds,
        if (lowThreshold != null) 'lowThreshold': lowThreshold,
        if (highThreshold != null) 'highThreshold': highThreshold,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return SensorModel.fromJson(data);
  }

  /// Deletes a sensor by [sensorId].
  Future<void> deleteSensor(String sensorId) async {
    await _client.delete('${AppConstants.sensorsBasePath}/$sensorId');
  }

  /// Starts a sensor.
  Future<SensorModel> startSensor(String sensorId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/$sensorId/start',
    );
    final data = response['data'] as Map<String, dynamic>;
    return SensorModel.fromJson(data);
  }

  /// Stops a sensor.
  Future<SensorModel> stopSensor(String sensorId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/$sensorId/stop',
    );
    final data = response['data'] as Map<String, dynamic>;
    return SensorModel.fromJson(data);
  }

  /// Gets the latest reading for a sensor.
  Future<SensorReadingModel?> getLatestReading(String sensorId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/$sensorId/latest',
    );
    final data = response['data'];
    if (data == null) return null;
    return SensorReadingModel.fromJson(data as Map<String, dynamic>);
  }

  /// Gets reading history for a sensor.
  Future<List<SensorReadingModel>> getHistory(
    String sensorId, {
    int hours = 24,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/$sensorId/history',
      queryParams: {'hours': hours, 'page': page, 'size': size},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => SensorReadingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates threshold values for a sensor.
  Future<SensorModel> updateThresholds(
    String sensorId, {
    double? lowThreshold,
    double? highThreshold,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/$sensorId/thresholds',
      data: {
        'lowThreshold': lowThreshold,
        'highThreshold': highThreshold,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return SensorModel.fromJson(data);
  }

  /// Tests a sensor connection.
  Future<SensorTestResultModel> testConnection(
    String portPath,
    int baudRate,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/test',
      data: {'portPath': portPath, 'baudRate': baudRate},
    );
    final data = response['data'] as Map<String, dynamic>;
    return SensorTestResultModel.fromJson(data);
  }

  /// Lists available serial ports.
  Future<List<String>> listPorts() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.sensorsBasePath}/ports',
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((e) => e as String).toList();
  }
}

/// Riverpod provider for [SensorService].
final sensorServiceProvider = Provider<SensorService>((ref) {
  final client = ref.watch(apiClientProvider);
  return SensorService(client: client);
});

/// Provider for the sensor list.
final sensorsProvider =
    FutureProvider.autoDispose<List<SensorModel>>((ref) async {
  final service = ref.watch(sensorServiceProvider);
  return service.listSensors();
});
