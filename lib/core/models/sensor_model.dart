/// Represents a hardware sensor.
///
/// Mirrors the server's SensorDto.
class SensorModel {
  final String id;
  final String name;
  final String type;
  final String? portPath;
  final int baudRate;
  final String? dataFormat;
  final String? valueField;
  final String? unit;
  final bool isActive;
  final int pollIntervalSeconds;
  final double? lowThreshold;
  final double? highThreshold;
  final String? createdAt;
  final String? updatedAt;

  const SensorModel({
    required this.id,
    required this.name,
    required this.type,
    this.portPath,
    required this.baudRate,
    this.dataFormat,
    this.valueField,
    this.unit,
    required this.isActive,
    required this.pollIntervalSeconds,
    this.lowThreshold,
    this.highThreshold,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [SensorModel] from a JSON map.
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'TEMPERATURE',
      portPath: json['portPath'] as String?,
      baudRate: json['baudRate'] as int? ?? 9600,
      dataFormat: json['dataFormat'] as String?,
      valueField: json['valueField'] as String?,
      unit: json['unit'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      pollIntervalSeconds: json['pollIntervalSeconds'] as int? ?? 60,
      lowThreshold: (json['lowThreshold'] as num?)?.toDouble(),
      highThreshold: (json['highThreshold'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

/// Represents a single sensor reading.
///
/// Mirrors the server's SensorReadingDto.
class SensorReadingModel {
  final String id;
  final String sensorId;
  final double value;
  final String? rawData;
  final String? recordedAt;

  const SensorReadingModel({
    required this.id,
    required this.sensorId,
    required this.value,
    this.rawData,
    this.recordedAt,
  });

  /// Creates a [SensorReadingModel] from a JSON map.
  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      id: json['id'] as String? ?? '',
      sensorId: json['sensorId'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      rawData: json['rawData'] as String?,
      recordedAt: json['recordedAt'] as String?,
    );
  }
}

/// Result of testing a sensor connection.
///
/// Mirrors the server's SensorTestResult.
class SensorTestResultModel {
  final bool success;
  final String portPath;
  final int baudRate;
  final String? sampleData;
  final String message;

  const SensorTestResultModel({
    required this.success,
    required this.portPath,
    required this.baudRate,
    this.sampleData,
    required this.message,
  });

  /// Creates a [SensorTestResultModel] from a JSON map.
  factory SensorTestResultModel.fromJson(Map<String, dynamic> json) {
    return SensorTestResultModel(
      success: json['success'] as bool? ?? false,
      portPath: json['portPath'] as String? ?? '',
      baudRate: json['baudRate'] as int? ?? 9600,
      sampleData: json['sampleData'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Valid sensor types matching the server enum.
class SensorType {
  SensorType._();

  static const String temperature = 'TEMPERATURE';
  static const String humidity = 'HUMIDITY';
  static const String pressure = 'PRESSURE';
  static const String soilMoisture = 'SOIL_MOISTURE';
  static const String windSpeed = 'WIND_SPEED';
  static const String solarRadiation = 'SOLAR_RADIATION';

  static const List<String> all = [
    temperature, humidity, pressure, soilMoisture, windSpeed, solarRadiation,
  ];
}

/// Valid data format types matching the server enum.
class DataFormat {
  DataFormat._();

  static const String csvLine = 'CSV_LINE';
  static const String jsonLine = 'JSON_LINE';
  static const String rawText = 'RAW_TEXT';

  static const List<String> all = [csvLine, jsonLine, rawText];
}
