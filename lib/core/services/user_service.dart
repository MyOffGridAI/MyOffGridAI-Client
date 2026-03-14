import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myoffgridai_client/config/constants.dart';
import 'package:myoffgridai_client/core/api/myoffgridai_api_client.dart';
import 'package:myoffgridai_client/core/models/user_model.dart';

/// Extended user detail model with additional fields.
class UserDetailModel {
  final String id;
  final String username;
  final String? email;
  final String displayName;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? lastLoginAt;

  const UserDetailModel({
    required this.id,
    required this.username,
    this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  /// Creates a [UserDetailModel] from a JSON map.
  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    return UserDetailModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'ROLE_MEMBER',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      lastLoginAt: json['lastLoginAt'] as String?,
    );
  }
}

/// Service for user management operations (OWNER/ADMIN).
///
/// Wraps [MyOffGridAIApiClient] and returns typed models.
class UserService {
  final MyOffGridAIApiClient _client;

  /// Creates a [UserService] with the given API [client].
  UserService({required MyOffGridAIApiClient client}) : _client = client;

  /// Lists all users.
  Future<List<UserModel>> listUsers({int page = 0, int size = 100}) async {
    final response = await _client.get<Map<String, dynamic>>(
      AppConstants.usersBasePath,
      queryParams: {'page': page, 'size': size},
    );
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets a user's detailed profile by [userId].
  Future<UserDetailModel> getUser(String userId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${AppConstants.usersBasePath}/$userId',
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserDetailModel.fromJson(data);
  }

  /// Updates a user's profile.
  Future<UserDetailModel> updateUser(
    String userId, {
    String? displayName,
    String? email,
    String? role,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${AppConstants.usersBasePath}/$userId',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        if (role != null) 'role': role,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return UserDetailModel.fromJson(data);
  }

  /// Deactivates a user by [userId].
  Future<void> deactivateUser(String userId) async {
    await _client.put<Map<String, dynamic>>(
      '${AppConstants.usersBasePath}/$userId/deactivate',
    );
  }

  /// Deletes a user by [userId].
  Future<void> deleteUser(String userId) async {
    await _client.delete('${AppConstants.usersBasePath}/$userId');
  }
}

/// Riverpod provider for [UserService].
final userServiceProvider = Provider<UserService>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserService(client: client);
});

/// Provider for the user list (used by UsersScreen).
final usersListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.listUsers();
});
