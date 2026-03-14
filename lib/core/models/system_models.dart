/// Extended system status model with full server fields.
///
/// Mirrors the server's SystemStatusDto with all fields.
class SystemStatusModel {
  final bool initialized;
  final String? instanceName;
  final bool fortressEnabled;
  final bool wifiConfigured;
  final String? serverVersion;
  final String? timestamp;

  const SystemStatusModel({
    required this.initialized,
    this.instanceName,
    required this.fortressEnabled,
    required this.wifiConfigured,
    this.serverVersion,
    this.timestamp,
  });

  /// Creates a [SystemStatusModel] from a JSON map.
  factory SystemStatusModel.fromJson(Map<String, dynamic> json) {
    return SystemStatusModel(
      initialized: json['initialized'] as bool? ?? false,
      instanceName: json['instanceName'] as String?,
      fortressEnabled: json['fortressEnabled'] as bool? ?? false,
      wifiConfigured: json['wifiConfigured'] as bool? ?? false,
      serverVersion: json['serverVersion'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Information about an Ollama model.
///
/// Mirrors the server's OllamaModelInfo.
class OllamaModelInfoModel {
  final String name;
  final int size;
  final String? modifiedAt;

  const OllamaModelInfoModel({
    required this.name,
    required this.size,
    this.modifiedAt,
  });

  /// Creates an [OllamaModelInfoModel] from a JSON map.
  factory OllamaModelInfoModel.fromJson(Map<String, dynamic> json) {
    return OllamaModelInfoModel(
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      modifiedAt: json['modifiedAt'] as String?,
    );
  }
}

/// Active model information.
///
/// Mirrors the server's ActiveModelDto.
class ActiveModelInfo {
  final String? modelName;
  final String? embedModelName;

  const ActiveModelInfo({
    this.modelName,
    this.embedModelName,
  });

  /// Creates an [ActiveModelInfo] from a JSON map.
  factory ActiveModelInfo.fromJson(Map<String, dynamic> json) {
    return ActiveModelInfo(
      modelName: json['modelName'] as String?,
      embedModelName: json['embedModelName'] as String?,
    );
  }
}
