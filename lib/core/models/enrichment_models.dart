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
/// to the client. Includes frontier provider settings (Grok, OpenAI)
/// and AI judge configuration.
class ExternalApiSettingsModel {
  final bool anthropicEnabled;
  final String anthropicModel;
  final bool anthropicKeyConfigured;
  final bool braveEnabled;
  final bool braveKeyConfigured;
  final bool huggingFaceEnabled;
  final bool huggingFaceKeyConfigured;
  final int maxWebFetchSizeKb;
  final int searchResultLimit;
  final bool grokEnabled;
  final bool grokKeyConfigured;
  final bool openAiEnabled;
  final bool openAiKeyConfigured;
  final String? preferredFrontierProvider;
  final bool judgeEnabled;
  final String? judgeModelFilename;
  final double judgeScoreThreshold;

  const ExternalApiSettingsModel({
    required this.anthropicEnabled,
    required this.anthropicModel,
    required this.anthropicKeyConfigured,
    required this.braveEnabled,
    required this.braveKeyConfigured,
    required this.huggingFaceEnabled,
    required this.huggingFaceKeyConfigured,
    required this.maxWebFetchSizeKb,
    required this.searchResultLimit,
    required this.grokEnabled,
    required this.grokKeyConfigured,
    required this.openAiEnabled,
    required this.openAiKeyConfigured,
    this.preferredFrontierProvider,
    required this.judgeEnabled,
    this.judgeModelFilename,
    required this.judgeScoreThreshold,
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
      huggingFaceEnabled: json['huggingFaceEnabled'] as bool? ?? false,
      huggingFaceKeyConfigured:
          json['huggingFaceKeyConfigured'] as bool? ?? false,
      maxWebFetchSizeKb: json['maxWebFetchSizeKb'] as int? ?? 512,
      searchResultLimit: json['searchResultLimit'] as int? ?? 5,
      grokEnabled: json['grokEnabled'] as bool? ?? false,
      grokKeyConfigured: json['grokKeyConfigured'] as bool? ?? false,
      openAiEnabled: json['openAiEnabled'] as bool? ?? false,
      openAiKeyConfigured: json['openAiKeyConfigured'] as bool? ?? false,
      preferredFrontierProvider:
          json['preferredFrontierProvider'] as String?,
      judgeEnabled: json['judgeEnabled'] as bool? ?? false,
      judgeModelFilename: json['judgeModelFilename'] as String?,
      judgeScoreThreshold:
          (json['judgeScoreThreshold'] as num?)?.toDouble() ?? 7.0,
    );
  }
}

/// Request payload for updating external API settings.
///
/// Mirrors the server's UpdateExternalApiSettingsRequest. When a key
/// field is null, the server preserves the existing value. An empty
/// string clears the key. Includes frontier provider and judge settings.
class UpdateExternalApiSettingsRequest {
  final String? anthropicApiKey;
  final String anthropicModel;
  final bool anthropicEnabled;
  final String? braveApiKey;
  final bool braveEnabled;
  final String? huggingFaceToken;
  final bool huggingFaceEnabled;
  final int maxWebFetchSizeKb;
  final int searchResultLimit;
  final String? grokApiKey;
  final bool? grokEnabled;
  final String? openAiApiKey;
  final bool? openAiEnabled;
  final String? preferredFrontierProvider;
  final bool? judgeEnabled;
  final String? judgeModelFilename;
  final double? judgeScoreThreshold;

  const UpdateExternalApiSettingsRequest({
    this.anthropicApiKey,
    required this.anthropicModel,
    required this.anthropicEnabled,
    this.braveApiKey,
    required this.braveEnabled,
    this.huggingFaceToken,
    required this.huggingFaceEnabled,
    required this.maxWebFetchSizeKb,
    required this.searchResultLimit,
    this.grokApiKey,
    this.grokEnabled,
    this.openAiApiKey,
    this.openAiEnabled,
    this.preferredFrontierProvider,
    this.judgeEnabled,
    this.judgeModelFilename,
    this.judgeScoreThreshold,
  });

  /// Serializes this request to a JSON map for the API.
  Map<String, dynamic> toJson() {
    return {
      if (anthropicApiKey != null) 'anthropicApiKey': anthropicApiKey,
      'anthropicModel': anthropicModel,
      'anthropicEnabled': anthropicEnabled,
      if (braveApiKey != null) 'braveApiKey': braveApiKey,
      'braveEnabled': braveEnabled,
      if (huggingFaceToken != null) 'huggingFaceToken': huggingFaceToken,
      'huggingFaceEnabled': huggingFaceEnabled,
      'maxWebFetchSizeKb': maxWebFetchSizeKb,
      'searchResultLimit': searchResultLimit,
      if (grokApiKey != null) 'grokApiKey': grokApiKey,
      if (grokEnabled != null) 'grokEnabled': grokEnabled,
      if (openAiApiKey != null) 'openAiApiKey': openAiApiKey,
      if (openAiEnabled != null) 'openAiEnabled': openAiEnabled,
      if (preferredFrontierProvider != null)
        'preferredFrontierProvider': preferredFrontierProvider,
      if (judgeEnabled != null) 'judgeEnabled': judgeEnabled,
      if (judgeModelFilename != null)
        'judgeModelFilename': judgeModelFilename,
      if (judgeScoreThreshold != null)
        'judgeScoreThreshold': judgeScoreThreshold,
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
