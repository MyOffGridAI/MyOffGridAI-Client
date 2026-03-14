/// Represents a user in the MyOffGridAI system.
///
/// Mirrors the server's UserSummaryDto with the fields needed
/// for client-side auth state and UI display.
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  /// Creates a [UserModel] from a JSON map matching UserSummaryDto.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'ROLE_MEMBER',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'role': role,
      'isActive': isActive,
    };
  }
}
