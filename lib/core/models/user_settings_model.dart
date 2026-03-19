/// Model representing a user's application settings.
class UserSettingsModel {
  /// The user's theme preference: "light", "dark", or "system".
  final String themePreference;

  /// Creates a [UserSettingsModel].
  const UserSettingsModel({
    this.themePreference = 'system',
  });

  /// Creates a [UserSettingsModel] from a JSON map.
  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      themePreference: json['themePreference'] as String? ?? 'system',
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() => {
        'themePreference': themePreference,
      };
}

/// Request model for updating user settings.
class UpdateUserSettingsRequest {
  /// The desired theme preference: "light", "dark", or "system".
  final String themePreference;

  /// Creates an [UpdateUserSettingsRequest].
  const UpdateUserSettingsRequest({
    required this.themePreference,
  });

  /// Converts this request to a JSON map.
  Map<String, dynamic> toJson() => {
        'themePreference': themePreference,
      };
}
