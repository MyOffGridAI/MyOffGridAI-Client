import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/event_model.dart';

/// Service for scheduled event CRUD operations.
///
/// Wraps [MyOffGridAIApiClient] and returns typed [ScheduledEventModel]s.
class EventService {
  final MyOffGridAIApiClient _client;

  /// Creates an [EventService] with the given API [client].
  EventService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists all events for the current user.
  Future<List<ScheduledEventModel>> listEvents(
      {int page = 0, int size = 100}) async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.eventsBasePath,
      queryParams: {'page': page, 'size': size},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => ScheduledEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a single event by [eventId].
  Future<ScheduledEventModel> getEvent(String eventId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.eventsBasePath}/$eventId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return ScheduledEventModel.fromJson(data);
  }

  /// Creates a new event.
  Future<ScheduledEventModel> createEvent(Map<String, dynamic> body) async {
    final response = await _client.post<Map<String, dynamic>>(
      AppConstants.eventsBasePath,
      data: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ScheduledEventModel.fromJson(data);
  }

  /// Updates an existing event.
  Future<ScheduledEventModel> updateEvent(
      String eventId, Map<String, dynamic> body) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.eventsBasePath}/$eventId',
      data: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ScheduledEventModel.fromJson(data);
  }

  /// Deletes an event by [eventId].
  Future<void> deleteEvent(String eventId) async {
    await _client.delete('${AppConstants.eventsBasePath}/$eventId');
  }

  /// Toggles the enabled/disabled state of an event.
  Future<ScheduledEventModel> toggleEvent(String eventId) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.eventsBasePath}/$eventId/toggle',
    );
    final data = response['data'] as Map<String, dynamic>;
    return ScheduledEventModel.fromJson(data);
  }
}

/// Riverpod provider for [EventService].
final eventServiceProvider = Provider<EventService>((ref) {
  final client = ref.watch(apiClientProvider);
  return EventService(client: client);
});

/// Provider for the events list (used by EventsScreen).
final eventsListProvider =
    FutureProvider.autoDispose<List<ScheduledEventModel>>((ref) async {
  final service = ref.watch(eventServiceProvider);
  return service.listEvents();
});
