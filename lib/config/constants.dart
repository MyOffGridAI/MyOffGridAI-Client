import 'package:flutter/foundation.dart';

/// All application-wide constants for MyOffGridAI-Client.
///
/// No magic strings or numbers anywhere else in the codebase.
/// Every URL, timeout, route name, storage key, and UI constant lives here.
class AppConstants {
  AppConstants._();

  // Server connection
  // Web runs in the browser on the dev machine — use localhost.
  // Native apps (iOS/Android) connect over the network to the appliance.
  static const String defaultServerUrl =
      kIsWeb ? 'http://localhost:8080' : 'http://offgrid.local:8080';
  static const String devServerUrl = 'http://localhost:8080';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration sseTimeout = Duration(minutes: 5);

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String serverUrlKey = 'server_url';
  static const String themeKey = 'theme_preference';

  // API paths (must match server)
  static const String authBasePath = '/api/auth';
  static const String usersBasePath = '/api/users';
  static const String chatBasePath = '/api/chat';
  static const String modelsBasePath = '/api/models';
  static const String memoryBasePath = '/api/memory';
  static const String knowledgeBasePath = '/api/knowledge';
  static const String skillsBasePath = '/api/skills';
  static const String inventoryBasePath = '/api/skills/inventory';
  static const String sensorsBasePath = '/api/sensors';
  static const String eventsBasePath = '/api/events';
  static const String insightsBasePath = '/api/insights';
  static const String notificationsBasePath = '/api/notifications';
  static const String devicesBasePath = '/api/notifications/devices';
  static const String privacyBasePath = '/api/privacy';
  static const String systemBasePath = '/api/system';
  static const String enrichmentBasePath = '/api/enrichment';
  static const String externalApiSettingsPath = '/api/settings/external-apis';
  static const String userSettingsPath = '/api/users/me/settings';
  static const String judgeBasePath = '/api/ai/judge';
  static const String libraryBasePath = '/api/library';

  // AI Judge defaults
  static const double defaultJudgeScoreThreshold = 7.0;

  // Frontier providers
  static const List<String> frontierProviders = ['CLAUDE', 'GROK', 'OPENAI'];

  // Route names
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/';
  static const String routeChat = '/chat';
  static const String routeChatConversation = '/chat/:conversationId';
  static const String routeMemory = '/memory';
  static const String routeKnowledge = '/knowledge';
  static const String routeSkills = '/skills';
  static const String routeInventory = '/inventory';
  static const String routeSensors = '/sensors';
  static const String routeEvents = '/events';
  static const String routeInsights = '/insights';
  static const String routeNotifications = '/notifications';
  static const String routePrivacy = '/privacy';
  static const String routeSystem = '/system';
  static const String routeUsers = '/users';
  static const String routeKnowledgeDetail = '/knowledge/:documentId';
  static const String routeKnowledgeNew = '/knowledge/new';
  static const String routeKnowledgeEdit = '/knowledge/:documentId/edit';
  static const String routeSensorDetail = '/sensors/:sensorId';
  static const String routeSensorAdd = '/sensors/add';
  static const String routeSettings = '/settings';
  static const String routeSearch = '/search';
  static const String routeBooks = '/books';
  static const String routeBookReader = '/books/reader';
  static const String routeDeviceNotSetup = '/device-not-setup';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // UI
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  // Navigation panel
  static const double navPanelExpandedWidth = 280.0;
  static const double navPanelCollapsedWidth = 72.0;
  // Legacy aliases
  static const double sidebarExpandedWidth = navPanelExpandedWidth;
  static const double sidebarCollapsedWidth = navPanelCollapsedWidth;

  // Polling intervals
  static const Duration connectionPollInterval = Duration(seconds: 10);
  static const Duration modelHealthPollInterval = Duration(seconds: 60);
  static const Duration notificationPollInterval = Duration(seconds: 30);

  // MQTT
  static const String mqttClientIdPrefix = 'myoffgridai-flutter-';
  static const int mqttPort = 1883;
  static const int mqttKeepAliveSeconds = 60;
  static const Duration mqttReconnectDelay = Duration(seconds: 5);
  static const String mqttTopicPrefix = '/myoffgridai/';
  static const String mqttBroadcastTopic = '/myoffgridai/broadcast';

  // Notification channels
  static const String notificationChannelId = 'myoffgridai_alerts';
  static const String notificationChannelName = 'MyOffGridAI Alerts';
  static const String notificationChannelDescription =
      'Push notifications from your off-grid AI';
  static const String foregroundServiceChannelId = 'myoffgridai_service';
  static const String foregroundServiceChannelName = 'MyOffGridAI Service';
  static const String foregroundServiceNotificationTitle = 'MyOffGridAI';
  static const String foregroundServiceNotificationBody =
      'AI assistant connected';

  // Secure storage keys (device)
  static const String deviceIdKey = 'device_id';

  // Library
  static const int kiwixPort = 8888;
  static const int ebooksPageSize = 20;
  static const Duration ebookDownloadTimeout = Duration(seconds: 60);

  // Validation
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 50;
  static const int passwordMinLength = 4;
  static const int displayNameMinLength = 1;
  static const int displayNameMaxLength = 100;
}
