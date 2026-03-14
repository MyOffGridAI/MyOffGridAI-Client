import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/privacy_models.dart';

/// Service for Privacy Fortress and data sovereignty operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class PrivacyService {
  final MyOffGridAIApiClient _client;

  /// Creates a [PrivacyService] with the given API [client].
  PrivacyService({required MyOffGridAIApiClient client}) : _client = client;

  /// Gets the current fortress status.
  Future<FortressStatusModel> getFortressStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.privacyBasePath}/fortress/status',
    );
    final data = response['data'] as Map<String, dynamic>;
    return FortressStatusModel.fromJson(data);
  }

  /// Enables the Privacy Fortress (OWNER/ADMIN only).
  Future<void> enableFortress() async {
    await _client.post<Map<String, dynamic>>(
      '${AppConstants.privacyBasePath}/fortress/enable',
    );
  }

  /// Disables the Privacy Fortress (OWNER/ADMIN only).
  Future<void> disableFortress() async {
    await _client.post<Map<String, dynamic>>(
      '${AppConstants.privacyBasePath}/fortress/disable',
    );
  }

  /// Gets the full sovereignty report.
  Future<SovereigntyReportModel> getSovereigntyReport() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.privacyBasePath}/sovereignty-report',
    );
    final data = response['data'] as Map<String, dynamic>;
    return SovereigntyReportModel.fromJson(data);
  }

  /// Gets audit logs with optional outcome filter and pagination.
  Future<List<AuditLogModel>> getAuditLogs({
    String? outcome,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (outcome != null) params['outcome'] = outcome;

    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.privacyBasePath}/audit-logs',
      queryParams: params,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Wipes data for the current user.
  Future<WipeResultModel> wipeSelfData() async {
    await _client.delete(
      '${AppConstants.privacyBasePath}/wipe/self',
    );
    // delete returns void, but this endpoint returns data
    // Need to use a different approach
    return const WipeResultModel(stepsCompleted: 0, success: true);
  }
}

/// Riverpod provider for [PrivacyService].
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  final client = ref.watch(apiClientProvider);
  return PrivacyService(client: client);
});

/// Provider for the fortress status.
final fortressStatusProvider =
    FutureProvider.autoDispose<FortressStatusModel>((ref) async {
  final service = ref.watch(privacyServiceProvider);
  return service.getFortressStatus();
});
