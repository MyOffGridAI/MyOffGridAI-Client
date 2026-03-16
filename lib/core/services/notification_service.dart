import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/notification_model.dart';

/// Service for notification operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class NotificationService {
  final MyOffGridAIApiClient _client;

  /// Creates a [NotificationService] with the given API [client].
  NotificationService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists notifications with optional unread filter.
  Future<List<NotificationModel>> listNotifications({
    bool unreadOnly = false,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.notificationsBasePath,
      queryParams: {'unreadOnly': unreadOnly, 'page': page, 'size': size},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marks a notification as read.
  Future<NotificationModel> markAsRead(String notificationId) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.notificationsBasePath}/$notificationId/read',
    );
    final data = response['data'] as Map<String, dynamic>;
    return NotificationModel.fromJson(data);
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    await _client.put<Map<String, dynamic>>(
      '${AppConstants.notificationsBasePath}/read-all',
    );
  }

  /// Deletes a notification by [notificationId].
  Future<void> deleteNotification(String notificationId) async {
    await _client
        .delete('${AppConstants.notificationsBasePath}/$notificationId');
  }

  /// Gets the count of unread notifications.
  Future<int> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.notificationsBasePath}/unread-count',
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['unreadCount'] as int? ?? 0;
    }
    if (data is int) return data;
    return 0;
  }
}

/// Riverpod provider for [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationService(client: client);
});

/// Provider for the notification list.
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.listNotifications();
});

/// Provider for the unread notification count, polled every 30 seconds.
final notificationsUnreadCountProvider =
    StreamProvider.autoDispose<int>((ref) async* {
  final service = ref.watch(notificationServiceProvider);
  while (true) {
    try {
      yield await service.getUnreadCount();
    } catch (_) {
      yield 0;
    }
    await Future.delayed(AppConstants.notificationPollInterval);
  }
});
