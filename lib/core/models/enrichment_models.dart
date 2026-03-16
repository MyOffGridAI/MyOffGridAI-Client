/// Models for the web enrichment feature (External APIs, Fetch, Search).
///
/// These models mirror the server-side DTOs in the enrichment and settings
/// packages. [ExternalApiSettingsModel] maps to ExternalApiSettingsDto,
/// [SearchResultModel] maps to SearchResultDto, and [EnrichmentStatusModel]
/// maps to EnrichmentStatusDto.
library;

/// Represents the external API integration settings.
///
/// Mirrors the server's ExternalApiSettingsDto. Boolean flags indicate
/// whether API keys are configured — actual key values are never sent
/// to the client.
class ExternalApiSettingsModel {
  final bool anthropicEnabled;
  final String anthropicModel;
  final bool anthropicKeyConfigured;
  final bool braveEnabled;
  final bool braveKeyConfigured;
  final int maxWebFetchSizeKb;
  final int searchResultLimit;

  const ExternalApiSettingsModel({
    required this.anthropicEnabled,
    required this.anthropicModel,
    required this.anthropicKeyConfigured,
    required this.braveEnabled,
    required this.braveKeyConfigured,
    required this.maxWebFetchSizeKb,
    required this.searchResultLimit,
  });

  /// Creates an [ExternalApiSettingsModel] from a JSON map.
  factory ExternalApiSettingsModel.fromJson(Map<String, dynamic> json) {
    return ExternalApiSettingsModel(
      anthropicEnabled: json['anthropicEnabled'] as bool? ?? false,
      anthropicModel:
          json['anthropicModel'] as String? ?? 'claude-sonnet-4-20250514',
      anthropicKeyConfigured:
          json['anthropicKeyConfigured'] as bool? ?? false,
      braveEnabled: json['braveEnabled'] as bool? ?? false,
      braveKeyConfigured: json['braveKeyConfigured'] as bool? ?? false,
      maxWebFetchSizeKb: json['maxWebFetchSizeKb'] as int? ?? 512,
      searchResultLimit: json['searchResultLimit'] as int? ?? 5,
    );
  }
}

/// Request payload for updating external API settings.
///
/// Mirrors the server's UpdateExternalApiSettingsRequest. When a key
/// field is null, the server preserves the existing value. An empty
/// string clears the key.
class UpdateExternalApiSettingsRequest {
  final String? anthropicApiKey;
  final String anthropicModel;
  final bool anthropicEnabled;
  final String? braveApiKey;
  final bool braveEnabled;
  final int maxWebFetchSizeKb;
  final int searchResultLimit;

  const UpdateExternalApiSettingsRequest({
    this.anthropicApiKey,
    required this.anthropicModel,
    required this.anthropicEnabled,
    this.braveApiKey,
    required this.braveEnabled,
    required this.maxWebFetchSizeKb,
    required this.searchResultLimit,
  });

  /// Serializes this request to a JSON map for the API.
  Map<String, dynamic> toJson() {
    return {
      if (anthropicApiKey != null) 'anthropicApiKey': anthropicApiKey,
      'anthropicModel': anthropicModel,
      'anthropicEnabled': anthropicEnabled,
      if (braveApiKey != null) 'braveApiKey': braveApiKey,
      'braveEnabled': braveEnabled,
      'maxWebFetchSizeKb': maxWebFetchSizeKb,
      'searchResultLimit': searchResultLimit,
    };
  }
}

/// A single web search result.
///
/// Mirrors the server's SearchResultDto. Returned as part of
/// the search enrichment response.
class SearchResultModel {
  final String title;
  final String url;
  final String description;
  final String? publishedDate;

  const SearchResultModel({
    required this.title,
    required this.url,
    required this.description,
    this.publishedDate,
  });

  /// Creates a [SearchResultModel] from a JSON map.
  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      publishedDate: json['publishedDate'] as String?,
    );
  }
}

/// Current availability status of enrichment services.
///
/// Mirrors the server's EnrichmentStatusDto. Used to determine
/// which enrichment features are available in the UI.
class EnrichmentStatusModel {
  final bool claudeAvailable;
  final bool braveAvailable;
  final int maxWebFetchSizeKb;
  final int searchResultLimit;

  const EnrichmentStatusModel({
    required this.claudeAvailable,
    required this.braveAvailable,
    required this.maxWebFetchSizeKb,
    required this.searchResultLimit,
  });

  /// Creates an [EnrichmentStatusModel] from a JSON map.
  factory EnrichmentStatusModel.fromJson(Map<String, dynamic> json) {
    return EnrichmentStatusModel(
      claudeAvailable: json['claudeAvailable'] as bool? ?? false,
      braveAvailable: json['braveAvailable'] as bool? ?? false,
      maxWebFetchSizeKb: json['maxWebFetchSizeKb'] as int? ?? 512,
      searchResultLimit: json['searchResultLimit'] as int? ?? 5,
    );
  }
}
