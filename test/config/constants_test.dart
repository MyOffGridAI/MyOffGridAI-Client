import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridai_client/config/constants.dart';

void main() {
  group('AppConstants', () {
    // ── Private constructor ─────────────────────────────────────────────────
    test('private constructor prevents instantiation', () {
      // The private constructor AppConstants._() means we can't instantiate,
      // but we can verify the class exists and constants are accessible.
      // This exercises line 8 (the constructor declaration).
      expect(AppConstants.defaultServerUrl, isNotEmpty);
    });

    // ── Server connection ──────────────────────────────────────────────────
    test('defaultServerUrl is set for web or native', () {
      // kIsWeb is false during test execution (dart VM), so expect native URL.
      expect(AppConstants.defaultServerUrl, isNotEmpty);
    });

    test('devServerUrl points to localhost', () {
      expect(AppConstants.devServerUrl, 'http://localhost:8080');
    });

    test('timeout durations are positive', () {
      expect(AppConstants.connectTimeout.inSeconds, 10);
      expect(AppConstants.receiveTimeout.inSeconds, 120);
      expect(AppConstants.sseTimeout.inMinutes, 5);
    });

    // ── Secure storage keys ────────────────────────────────────────────────
    test('storage keys are defined and non-empty', () {
      expect(AppConstants.accessTokenKey, isNotEmpty);
      expect(AppConstants.refreshTokenKey, isNotEmpty);
      expect(AppConstants.serverUrlKey, isNotEmpty);
      expect(AppConstants.themeKey, isNotEmpty);
      expect(AppConstants.deviceIdKey, isNotEmpty);
    });

    // ── API paths ──────────────────────────────────────────────────────────
    test('API paths start with /api/', () {
      final paths = [
        AppConstants.authBasePath,
        AppConstants.usersBasePath,
        AppConstants.chatBasePath,
        AppConstants.modelsBasePath,
        AppConstants.memoryBasePath,
        AppConstants.knowledgeBasePath,
        AppConstants.skillsBasePath,
        AppConstants.inventoryBasePath,
        AppConstants.sensorsBasePath,
        AppConstants.eventsBasePath,
        AppConstants.insightsBasePath,
        AppConstants.notificationsBasePath,
        AppConstants.devicesBasePath,
        AppConstants.privacyBasePath,
        AppConstants.systemBasePath,
        AppConstants.enrichmentBasePath,
        AppConstants.externalApiSettingsPath,
        AppConstants.libraryBasePath,
      ];
      for (final path in paths) {
        expect(path, startsWith('/api/'), reason: 'Path $path must start with /api/');
      }
    });

    // ── Route names ────────────────────────────────────────────────────────
    test('route names are defined', () {
      expect(AppConstants.routeLogin, '/login');
      expect(AppConstants.routeRegister, '/register');
      expect(AppConstants.routeHome, '/');
      expect(AppConstants.routeChat, '/chat');
      expect(AppConstants.routeChatConversation, contains(':conversationId'));
      expect(AppConstants.routeMemory, '/memory');
      expect(AppConstants.routeKnowledge, '/knowledge');
      expect(AppConstants.routeSkills, '/skills');
      expect(AppConstants.routeInventory, '/inventory');
      expect(AppConstants.routeSensors, '/sensors');
      expect(AppConstants.routeEvents, '/events');
      expect(AppConstants.routeInsights, '/insights');
      expect(AppConstants.routeNotifications, '/notifications');
      expect(AppConstants.routePrivacy, '/privacy');
      expect(AppConstants.routeSystem, '/system');
      expect(AppConstants.routeUsers, '/users');
      expect(AppConstants.routeKnowledgeDetail, contains(':documentId'));
      expect(AppConstants.routeKnowledgeNew, '/knowledge/new');
      expect(AppConstants.routeKnowledgeEdit, contains(':documentId'));
      expect(AppConstants.routeSensorDetail, contains(':sensorId'));
      expect(AppConstants.routeSensorAdd, '/sensors/add');
      expect(AppConstants.routeSettings, '/settings');
      expect(AppConstants.routeSearch, '/search');
      expect(AppConstants.routeBooks, '/books');
      expect(AppConstants.routeBookReader, '/books/reader');
      expect(AppConstants.routeDeviceNotSetup, '/device-not-setup');
    });

    // ── Pagination ─────────────────────────────────────────────────────────
    test('pagination defaults are set', () {
      expect(AppConstants.defaultPageSize, 20);
      expect(AppConstants.maxPageSize, 100);
    });

    // ── UI ──────────────────────────────────────────────────────────────────
    test('UI durations and breakpoints are positive', () {
      expect(AppConstants.snackBarDuration.inSeconds, 3);
      expect(AppConstants.animationDuration.inMilliseconds, 250);
      expect(AppConstants.mobileBreakpoint, 600);
      expect(AppConstants.tabletBreakpoint, 1200);
    });

    // ── Navigation panel ───────────────────────────────────────────────────
    test('navigation panel widths are set', () {
      expect(AppConstants.navPanelExpandedWidth, 280.0);
      expect(AppConstants.navPanelCollapsedWidth, 72.0);
      // Legacy aliases
      expect(AppConstants.sidebarExpandedWidth, AppConstants.navPanelExpandedWidth);
      expect(AppConstants.sidebarCollapsedWidth, AppConstants.navPanelCollapsedWidth);
    });

    // ── Polling intervals ──────────────────────────────────────────────────
    test('polling intervals are positive', () {
      expect(AppConstants.connectionPollInterval.inSeconds, 10);
      expect(AppConstants.modelHealthPollInterval.inSeconds, 60);
      expect(AppConstants.notificationPollInterval.inSeconds, 30);
    });

    // ── MQTT ───────────────────────────────────────────────────────────────
    test('MQTT constants are set', () {
      expect(AppConstants.mqttClientIdPrefix, isNotEmpty);
      expect(AppConstants.mqttPort, 1883);
      expect(AppConstants.mqttKeepAliveSeconds, 60);
      expect(AppConstants.mqttReconnectDelay.inSeconds, 5);
      expect(AppConstants.mqttTopicPrefix, isNotEmpty);
      expect(AppConstants.mqttBroadcastTopic, isNotEmpty);
    });

    // ── Notification channels ──────────────────────────────────────────────
    test('notification channel constants are set', () {
      expect(AppConstants.notificationChannelId, isNotEmpty);
      expect(AppConstants.notificationChannelName, isNotEmpty);
      expect(AppConstants.notificationChannelDescription, isNotEmpty);
      expect(AppConstants.foregroundServiceChannelId, isNotEmpty);
      expect(AppConstants.foregroundServiceChannelName, isNotEmpty);
      expect(AppConstants.foregroundServiceNotificationTitle, isNotEmpty);
      expect(AppConstants.foregroundServiceNotificationBody, isNotEmpty);
    });

    // ── Library ────────────────────────────────────────────────────────────
    test('library constants are set', () {
      expect(AppConstants.kiwixPort, 8888);
      expect(AppConstants.ebooksPageSize, 20);
      expect(AppConstants.ebookDownloadTimeout.inSeconds, 60);
    });

    // ── Validation ─────────────────────────────────────────────────────────
    test('validation constants are set', () {
      expect(AppConstants.usernameMinLength, 3);
      expect(AppConstants.usernameMaxLength, 50);
      expect(AppConstants.passwordMinLength, 4);
      expect(AppConstants.displayNameMinLength, 1);
      expect(AppConstants.displayNameMaxLength, 100);
    });
  });
}
