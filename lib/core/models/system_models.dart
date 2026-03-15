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

/// AI and memory configuration settings.
///
/// Mirrors the server's AiSettingsDto.
class AiSettingsModel {
  final String modelName;
  final double temperature;
  final double similarityThreshold;
  final int memoryTopK;
  final int ragMaxContextTokens;
  final int contextSize;
  final int contextMessageLimit;

  const AiSettingsModel({
    this.modelName = '',
    this.temperature = 0.7,
    this.similarityThreshold = 0.45,
    this.memoryTopK = 5,
    this.ragMaxContextTokens = 2048,
    this.contextSize = 4096,
    this.contextMessageLimit = 20,
  });

  /// Creates an [AiSettingsModel] from a JSON map.
  factory AiSettingsModel.fromJson(Map<String, dynamic> json) {
    return AiSettingsModel(
      modelName: json['modelName'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      similarityThreshold:
          (json['similarityThreshold'] as num?)?.toDouble() ?? 0.45,
      memoryTopK: json['memoryTopK'] as int? ?? 5,
      ragMaxContextTokens: json['ragMaxContextTokens'] as int? ?? 2048,
      contextSize: json['contextSize'] as int? ?? 4096,
      contextMessageLimit: json['contextMessageLimit'] as int? ?? 20,
    );
  }

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'temperature': temperature,
        'similarityThreshold': similarityThreshold,
        'memoryTopK': memoryTopK,
        'ragMaxContextTokens': ragMaxContextTokens,
        'contextSize': contextSize,
        'contextMessageLimit': contextMessageLimit,
      };
}

/// File storage settings and disk usage.
///
/// Mirrors the server's StorageSettingsDto.
class StorageSettingsModel {
  final String knowledgeStoragePath;
  final int totalSpaceMb;
  final int usedSpaceMb;
  final int freeSpaceMb;
  final int maxUploadSizeMb;

  const StorageSettingsModel({
    this.knowledgeStoragePath = '/var/myoffgridai/knowledge',
    this.totalSpaceMb = 0,
    this.usedSpaceMb = 0,
    this.freeSpaceMb = 0,
    this.maxUploadSizeMb = 25,
  });

  /// Creates a [StorageSettingsModel] from a JSON map.
  factory StorageSettingsModel.fromJson(Map<String, dynamic> json) {
    return StorageSettingsModel(
      knowledgeStoragePath:
          json['knowledgeStoragePath'] as String? ?? '/var/myoffgridai/knowledge',
      totalSpaceMb: json['totalSpaceMb'] as int? ?? 0,
      usedSpaceMb: json['usedSpaceMb'] as int? ?? 0,
      freeSpaceMb: json['freeSpaceMb'] as int? ?? 0,
      maxUploadSizeMb: json['maxUploadSizeMb'] as int? ?? 25,
    );
  }

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'knowledgeStoragePath': knowledgeStoragePath,
        'maxUploadSizeMb': maxUploadSizeMb,
      };
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
