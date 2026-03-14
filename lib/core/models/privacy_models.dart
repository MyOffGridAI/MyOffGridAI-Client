/// Status of the Privacy Fortress.
///
/// Mirrors the server's FortressStatus.
class FortressStatusModel {
  final bool enabled;
  final String? enabledAt;
  final String? enabledByUsername;
  final bool verified;

  const FortressStatusModel({
    required this.enabled,
    this.enabledAt,
    this.enabledByUsername,
    required this.verified,
  });

  /// Creates a [FortressStatusModel] from a JSON map.
  factory FortressStatusModel.fromJson(Map<String, dynamic> json) {
    return FortressStatusModel(
      enabled: json['enabled'] as bool? ?? false,
      enabledAt: json['enabledAt'] as String?,
      enabledByUsername: json['enabledByUsername'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }
}

/// Data inventory section of the sovereignty report.
class DataInventoryModel {
  final int conversationCount;
  final int messageCount;
  final int memoryCount;
  final int knowledgeDocumentCount;
  final int sensorCount;
  final int insightCount;

  const DataInventoryModel({
    required this.conversationCount,
    required this.messageCount,
    required this.memoryCount,
    required this.knowledgeDocumentCount,
    required this.sensorCount,
    required this.insightCount,
  });

  /// Creates a [DataInventoryModel] from a JSON map.
  factory DataInventoryModel.fromJson(Map<String, dynamic> json) {
    return DataInventoryModel(
      conversationCount: json['conversationCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      memoryCount: json['memoryCount'] as int? ?? 0,
      knowledgeDocumentCount: json['knowledgeDocumentCount'] as int? ?? 0,
      sensorCount: json['sensorCount'] as int? ?? 0,
      insightCount: json['insightCount'] as int? ?? 0,
    );
  }
}

/// Audit summary section of the sovereignty report.
class AuditSummaryModel {
  final int successCount;
  final int failureCount;
  final int deniedCount;
  final String? windowStart;
  final String? windowEnd;

  const AuditSummaryModel({
    required this.successCount,
    required this.failureCount,
    required this.deniedCount,
    this.windowStart,
    this.windowEnd,
  });

  /// Creates an [AuditSummaryModel] from a JSON map.
  factory AuditSummaryModel.fromJson(Map<String, dynamic> json) {
    return AuditSummaryModel(
      successCount: json['successCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      deniedCount: json['deniedCount'] as int? ?? 0,
      windowStart: json['windowStart'] as String?,
      windowEnd: json['windowEnd'] as String?,
    );
  }
}

/// Full sovereignty report showing data residency status.
///
/// Mirrors the server's SovereigntyReport.
class SovereigntyReportModel {
  final String? generatedAt;
  final FortressStatusModel? fortressStatus;
  final String? outboundTrafficVerification;
  final DataInventoryModel? dataInventory;
  final AuditSummaryModel? auditSummary;
  final String? encryptionStatus;
  final String? telemetryStatus;
  final String? lastVerifiedAt;

  const SovereigntyReportModel({
    this.generatedAt,
    this.fortressStatus,
    this.outboundTrafficVerification,
    this.dataInventory,
    this.auditSummary,
    this.encryptionStatus,
    this.telemetryStatus,
    this.lastVerifiedAt,
  });

  /// Creates a [SovereigntyReportModel] from a JSON map.
  factory SovereigntyReportModel.fromJson(Map<String, dynamic> json) {
    return SovereigntyReportModel(
      generatedAt: json['generatedAt'] as String?,
      fortressStatus: json['fortressStatus'] != null
          ? FortressStatusModel.fromJson(
              json['fortressStatus'] as Map<String, dynamic>)
          : null,
      outboundTrafficVerification:
          json['outboundTrafficVerification'] as String?,
      dataInventory: json['dataInventory'] != null
          ? DataInventoryModel.fromJson(
              json['dataInventory'] as Map<String, dynamic>)
          : null,
      auditSummary: json['auditSummary'] != null
          ? AuditSummaryModel.fromJson(
              json['auditSummary'] as Map<String, dynamic>)
          : null,
      encryptionStatus: json['encryptionStatus'] as String?,
      telemetryStatus: json['telemetryStatus'] as String?,
      lastVerifiedAt: json['lastVerifiedAt'] as String?,
    );
  }
}

/// An entry in the privacy audit log.
///
/// Mirrors the server's AuditLogDto.
class AuditLogModel {
  final String id;
  final String? userId;
  final String? username;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? httpMethod;
  final String? requestPath;
  final String outcome;
  final int? responseStatus;
  final int? durationMs;
  final String? timestamp;

  const AuditLogModel({
    required this.id,
    this.userId,
    this.username,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.httpMethod,
    this.requestPath,
    required this.outcome,
    this.responseStatus,
    this.durationMs,
    this.timestamp,
  });

  /// Creates an [AuditLogModel] from a JSON map.
  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      action: json['action'] as String? ?? '',
      resourceType: json['resourceType'] as String?,
      resourceId: json['resourceId'] as String?,
      httpMethod: json['httpMethod'] as String?,
      requestPath: json['requestPath'] as String?,
      outcome: json['outcome'] as String? ?? 'SUCCESS',
      responseStatus: json['responseStatus'] as int?,
      durationMs: json['durationMs'] as int?,
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Result of a data wipe operation.
///
/// Mirrors the server's WipeResult.
class WipeResultModel {
  final String? targetUserId;
  final int stepsCompleted;
  final String? completedAt;
  final bool success;

  const WipeResultModel({
    this.targetUserId,
    required this.stepsCompleted,
    this.completedAt,
    required this.success,
  });

  /// Creates a [WipeResultModel] from a JSON map.
  factory WipeResultModel.fromJson(Map<String, dynamic> json) {
    return WipeResultModel(
      targetUserId: json['targetUserId'] as String?,
      stepsCompleted: json['stepsCompleted'] as int? ?? 0,
      completedAt: json['completedAt'] as String?,
      success: json['success'] as bool? ?? false,
    );
  }
}

/// Valid audit outcome values matching the server enum.
class AuditOutcome {
  AuditOutcome._();

  static const String success = 'SUCCESS';
  static const String failure = 'FAILURE';
  static const String denied = 'DENIED';

  static const List<String> all = [success, failure, denied];
}
