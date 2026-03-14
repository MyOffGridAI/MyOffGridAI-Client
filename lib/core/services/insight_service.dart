import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/insight_model.dart';

/// Service for proactive insight operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class InsightService {
  final MyOffGridAIApiClient _client;

  /// Creates an [InsightService] with the given API [client].
  InsightService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists insights with pagination and optional category filter.
  Future<List<InsightModel>> listInsights({
    int page = 0,
    int size = 20,
    String? category,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (category != null) params['category'] = category;

    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.insightsBasePath,
      queryParams: params,
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generates new proactive insights.
  Future<List<InsightModel>> generateInsights() async {
    final response = await _client.post<Map<String, dynamic>>(
      '${AppConstants.insightsBasePath}/generate',
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marks an insight as read.
  Future<InsightModel> markAsRead(String insightId) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.insightsBasePath}/$insightId/read',
    );
    final data = response['data'] as Map<String, dynamic>;
    return InsightModel.fromJson(data);
  }

  /// Dismisses an insight.
  Future<InsightModel> dismiss(String insightId) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.insightsBasePath}/$insightId/dismiss',
    );
    final data = response['data'] as Map<String, dynamic>;
    return InsightModel.fromJson(data);
  }

  /// Gets the count of unread insights.
  Future<int> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.insightsBasePath}/unread-count',
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['unreadCount'] as int? ?? 0;
    }
    return 0;
  }
}

/// Riverpod provider for [InsightService].
final insightServiceProvider = Provider<InsightService>((ref) {
  final client = ref.watch(apiClientProvider);
  return InsightService(client: client);
});

/// Provider for the insights list.
final insightsProvider =
    FutureProvider.autoDispose<List<InsightModel>>((ref) async {
  final service = ref.watch(insightServiceProvider);
  return service.listInsights();
});
