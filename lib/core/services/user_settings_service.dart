import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/user_settings_model.dart';

/// Service for managing per-user application settings on the server.
///
/// Wraps [MyOffGridAIApiClient] and returns typed [UserSettingsModel] instances.
class UserSettingsService {
  final MyOffGridAIApiClient _client;

  /// Creates a [UserSettingsService] with the given API [client].
  UserSettingsService({required MyOffGridAIApiClient client}) : _client = client;

  /// Fetches the current user's settings from the server.
  Future<UserSettingsModel> getSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.userSettingsPath,
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserSettingsModel.fromJson(data);
  }

  /// Updates the current user's settings on the server.
  Future<UserSettingsModel> updateSettings(
      UpdateUserSettingsRequest request) async {
    final response = await _client.put<Map<String, dynamic>>(
      AppConstants.userSettingsPath,
      data: request.toJson(),
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserSettingsModel.fromJson(data);
  }
}

/// Riverpod provider for [UserSettingsService].
final userSettingsServiceProvider = Provider<UserSettingsService>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserSettingsService(client: client);
});

/// Provider for the current user's settings.
final userSettingsProvider =
    FutureProvider.autoDispose<UserSettingsModel>((ref) async {
  final service = ref.watch(userSettingsServiceProvider);
  return service.getSettings();
});
