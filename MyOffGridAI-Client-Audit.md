# MyOffGridAI-Client — Codebase Audit

**Audit Date:** 2026-03-16T21:13:11Z
**Branch:** main
**Commit:** c362751f522f3e848bdcb51bada58432a4c87dd9 Remove unused imports and declarations from test files
**Auditor:** Claude Code (Automated)
**Purpose:** Zero-context reference for AI-assisted development
**Audit File:** MyOffGridAI-Client-Audit.md
**Scorecard:** MyOffGridAI-Client-Scorecard.md
**OpenAPI Spec:** Generated separately

> This audit is the source of truth for the MyOffGridAI-Client codebase structure, entities, services, and configuration.
> The OpenAPI spec is the source of truth for all endpoints, DTOs, and API contracts.
> An AI reading this audit + the OpenAPI spec should be able to generate accurate code
> changes, new features, tests, and fixes without filesystem access.

---

## 1. Project Identity

```
Project Name: MyOffGridAI-Client
Repository URL: (GitHub — MyOffGridAI-Client)
Primary Language / Framework: Dart / Flutter
Dart Version: ^3.11.0
Build Tool + Version: Flutter SDK 3.41.1 / pub
Current Branch: main
Latest Commit Hash: c362751f522f3e848bdcb51bada58432a4c87dd9
Latest Commit Message: Remove unused imports and declarations from test files
Audit Timestamp: 2026-03-16T21:13:11Z
```

---

## 2. Directory Structure

```
lib/
├── main.dart                              — App entry point, ProviderScope init
├── config/
│   ├── constants.dart                     — All constants (URLs, timeouts, routes, MQTT, UI)
│   ├── router.dart                        — GoRouter with auth guards
│   └── theme.dart                         — Light/dark themes, ThemeNotifier
├── core/
│   ├── api/
│   │   ├── api_exception.dart             — Typed API exception
│   │   ├── api_response.dart              — Server ApiResponse<T> mirror
│   │   ├── myoffgridai_api_client.dart    — Dio HTTP client with JWT interceptor
│   │   └── providers.dart                 — System status, health, notification providers
│   ├── auth/
│   │   ├── auth_service.dart              — Login, logout, register, refresh
│   │   ├── auth_state.dart                — Riverpod AsyncNotifier for auth state
│   │   └── secure_storage_service.dart    — flutter_secure_storage wrapper
│   ├── models/                            — 17 model files (see Section 6)
│   └── services/                          — 19 service files (see Section 9)
├── features/
│   ├── auth/                              — login, register, device_not_setup, users screens
│   ├── books/                             — books_screen, book_reader_screen
│   ├── chat/                              — chat_list, chat_conversation, thinking_indicator
│   ├── events/                            — events_screen, event_dialog
│   ├── insights/                          — insights_screen
│   ├── inventory/                         — inventory_screen
│   ├── knowledge/                         — knowledge_screen, document_detail, document_editor
│   ├── memory/                            — memory_screen
│   ├── notifications/                     — notifications_screen
│   ├── privacy/                           — privacy_screen
│   ├── search/                            — search_screen
│   ├── sensors/                           — sensors_screen, sensor_detail, add_sensor
│   ├── settings/                          — settings_screen (1783 lines — largest file)
│   ├── skills/                            — skills_screen
│   └── system/                            — system_screen
└── shared/
    ├── utils/                             — date_formatter, download_utils, platform_utils, size_formatter
    └── widgets/                           — app_shell, confirmation_dialog, connection_lost_banner,
                                             empty_state_view, error_view, loading_indicator,
                                             navigation_panel, notification_badge, system_status_bar
```

**Summary:** Single-module Flutter client app with 86 Dart source files (16,582 lines) and 83 test files (30,379 lines). Feature-sliced architecture with shared core layer (API, auth, models, services) and shared widgets/utils.

---

## 3. Build & Dependency Manifest

**Build file:** `pubspec.yaml`

| Dependency | Version | Purpose |
|---|---|---|
| flutter | SDK | UI framework |
| flutter_localizations | SDK | i18n support |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| dio | ^5.7.0 | HTTP client |
| go_router | ^14.8.1 | Declarative routing |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod codegen annotations |
| flutter_secure_storage | ^9.2.4 | Encrypted key-value storage |
| web_socket_channel | ^3.0.2 | WebSocket support |
| fl_chart | ^0.70.2 | Charts for sensor data |
| file_picker | ^8.3.7 | File selection dialog |
| desktop_drop | ^0.4.4 | Drag-and-drop file upload |
| cross_file | ^0.3.5+2 | Cross-platform file abstraction |
| intl | ^0.20.2 | Date/number formatting |
| flutter_quill | ^11.4.0 | Rich text editor |
| mqtt_client | ^10.2.1 | MQTT messaging |
| flutter_local_notifications | ^17.2.3 | Local push notifications |
| flutter_foreground_task | ^8.13.0 | Background service |
| permission_handler | ^11.3.1 | Runtime permissions |
| webview_flutter | ^4.10.0 | Embedded web content |
| webview_flutter_android | ^4.3.0 | Android WebView impl |
| webview_flutter_wkwebview | ^3.18.0 | iOS WebView impl |
| pdfx | ^2.9.0 | PDF rendering |
| path_provider | ^2.1.5 | File system paths |
| open_filex | ^4.6.0 | Open files externally |
| cached_network_image | ^3.4.1 | Image caching |

**Dev Dependencies:**

| Dependency | Version | Purpose |
|---|---|---|
| flutter_test | SDK | Widget testing |
| flutter_lints | ^6.0.0 | Lint rules |
| build_runner | ^2.4.15 | Code generation |
| riverpod_generator | ^2.6.3 | Riverpod provider codegen |
| mockito | ^5.4.6 | Mock generation |
| mocktail | ^1.0.4 | Lightweight mocking |

**Build commands:**
```
Build:   flutter build apk / flutter build ios / flutter build web
Test:    flutter test
Run:     flutter run
Package: flutter build apk --release
```

---

## 4. Configuration & Infrastructure Summary

- **`pubspec.yaml`** — App name: `myoffgridai_client`, version 1.0.0+1, SDK ^3.11.0
- **`analysis_options.yaml`** — Uses `flutter_lints/flutter.yaml`, disables `unnecessary_underscores` rule
- **`lib/config/constants.dart`** — All app constants. Server URL defaults: web → `http://localhost:8080`, native → `http://offgrid.local:8080`. Timeouts: connect 10s, receive 120s, SSE 5min.

**Connection map:**
```
Backend API: HTTP via Dio → configurable server URL (default localhost:8080 / offgrid.local:8080)
MQTT Broker: mqtt_client → server host, port 1883, topic prefix /myoffgridai/
Database: None (client-side) — flutter_secure_storage for tokens/prefs
Cache: None — cached_network_image for images only
Message Broker: MQTT (see Section 17)
External APIs: None direct — all via backend proxy
Cloud Services: None
```

**CI/CD:** None detected.
**Docker:** No Dockerfile or docker-compose.
**.env files:** None.

---

## 5. Startup & Runtime Behavior

**Entry point:** `lib/main.dart` → `main()` function

**Startup sequence:**
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Create `SecureStorageService` and load saved server URL
3. Initialize `LocalNotificationService`
4. Launch app with `ProviderScope` overriding `secureStorageProvider`, `localNotificationServiceProvider`, and `apiClientProvider`

**Root widget:** `MyOffGridAIApp` (ConsumerWidget) — configures `MaterialApp.router` with light/dark themes, GoRouter, and localization delegates (Material, Cupertino, Widgets, FlutterQuill).

**Auth guard:** GoRouter `redirect` function checks `authStateProvider`:
- Unauthenticated users → `/login`
- Authenticated users on login/register → `/` (home)
- Users screen restricted to `ROLE_OWNER` / `ROLE_ADMIN`

**Background services:**
- MQTT service (reconnect delay: 5s, keep-alive: 60s)
- Foreground service manager for persistent connection
- Notification polling (30s interval)
- Connection polling (10s interval)
- Model health polling (60s interval)

---

## 6. Entity / Data Model Layer

All models are in `lib/core/models/`. Immutable classes with `const` constructors and `factory fromJson` methods. No database entities — these mirror server DTOs.

### conversation_model.dart
- **ConversationModel** — `id`, `title?`, `isArchived`, `messageCount`, `createdAt?`, `updatedAt?`
- **ConversationSummaryModel** — same + `lastMessagePreview?`

### device_registration_model.dart
- **DeviceRegistrationModel** — `id`, `deviceId`, `deviceName`, `platform`, `mqttClientId`, `lastSeenAt?`

### enrichment_models.dart
- **ExternalApiSettingsModel** — `anthropicEnabled`, `anthropicModel`, `anthropicKeyConfigured`, `braveEnabled`, `braveKeyConfigured`, `maxWebFetchSizeKb`, `searchResultLimit`
- **UpdateExternalApiSettingsRequest** — `anthropicApiKey?`, `anthropicModel`, `anthropicEnabled`, `braveApiKey?`, `braveEnabled`, `maxWebFetchSizeKb`, `searchResultLimit` + `toJson()`
- **SearchResultModel** — `title`, `url`, `description`, `publishedDate?`
- **EnrichmentStatusModel** — `claudeAvailable`, `braveAvailable`, `maxWebFetchSizeKb`, `searchResultLimit`

### event_model.dart
- **ScheduledEventModel** — `id`, `userId?`, `name`, `description?`, `eventType`, `isEnabled`, `cronExpression?`, `recurringIntervalMinutes?`, `sensorId?`, `thresholdOperator?`, `thresholdValue?`, `actionType`, `actionPayload`, `lastTriggeredAt?`, `nextFireAt?`, `createdAt?`, `updatedAt?` + `toJson()`
- **EventType** — `SCHEDULED`, `SENSOR_THRESHOLD`, `RECURRING` + `label()`
- **ActionType** — `PUSH_NOTIFICATION`, `AI_PROMPT`, `AI_SUMMARY` + `label()`
- **ThresholdOperator** — `ABOVE`, `BELOW`, `EQUALS` + `label()`

### insight_model.dart
- **InsightModel** — `id`, `content`, `category`, `isRead`, `isDismissed`, `generatedAt?`, `readAt?`
- **InsightCategory** — `SECURITY`, `EFFICIENCY`, `HEALTH`, `MAINTENANCE`, `SUSTAINABILITY`, `PLANNING`

### inventory_item_model.dart
- **InventoryItemModel** — `id`, `name`, `category`, `quantity`, `unit?`, `notes?`, `lowStockThreshold?`, `createdAt?`, `updatedAt?` + getter `isLowStock`
- **InventoryCategory** — `FOOD`, `WATER`, `FUEL`, `TOOLS`, `MEDICINE`, `SPARE_PARTS`, `OTHER`

### knowledge_document_model.dart
- **KnowledgeDocumentModel** — `id`, `filename`, `displayName?`, `mimeType?`, `fileSizeBytes`, `status`, `errorMessage?`, `chunkCount`, `uploadedAt?`, `processedAt?`, `hasContent`, `editable` + getters `isProcessing`, `isIndexed`, `isFailed`
- **DocumentContentModel** — `documentId`, `title`, `content?`, `mimeType?`, `editable`
- **KnowledgeSearchResultModel** — `chunkId`, `documentId`, `documentName`, `content`, `pageNumber?`, `chunkIndex`, `similarityScore`

### library_models.dart
- **ZimFileModel** — `id`, `filename`, `displayName?`, `description?`, `language?`, `category?`, `fileSizeBytes`, `articleCount`, `mediaCount`, `createdDate?`, `kiwixBookId?`, `uploadedAt?`, `uploadedBy?`
- **EbookModel** — `id`, `title`, `author?`, `description?`, `isbn?`, `publisher?`, `publishedYear?`, `language?`, `format`, `fileSizeBytes`, `gutenbergId?`, `downloadCount`, `hasCoverImage`, `uploadedAt?`, `uploadedBy?` + getters `isFromGutenberg`, `hasEpub` (on GutenbergBookModel)
- **KiwixStatusModel** — `available`, `url?`, `bookCount`
- **GutenbergBookModel** — `id`, `title`, `authors`, `subjects`, `languages`, `downloadCount`, `formats` + getter `hasEpub`
- **GutenbergSearchResultModel** — `count`, `next?`, `previous?`, `results`

### memory_model.dart
- **MemoryModel** — `id`, `content`, `importance`, `tags?`, `sourceConversationId?`, `createdAt?`, `updatedAt?`, `lastAccessedAt?`, `accessCount` + getter `tagList`
- **MemorySearchResultModel** — `memory` (MemoryModel), `similarityScore`

### message_model.dart
- **MessageModel** — `id`, `role`, `content`, `tokenCount?`, `hasRagContext`, `createdAt?` + getters `isUser`, `isAssistant`

### notification_model.dart
- **NotificationModel** — `id`, `title`, `body`, `type`, `severity`, `isRead`, `createdAt?`, `readAt?`, `metadata?`
- **NotificationType** — `SENSOR_ALERT`, `SYSTEM_HEALTH`, `INSIGHT_READY`, `MODEL_UPDATE`, `GENERAL`
- **NotificationSeverity** — `INFO`, `WARNING`, `CRITICAL`

### page_response.dart
- **PageResponse\<T\>** — `content`, `totalElements`, `totalPages`, `number`, `size`, `first`, `last`, `empty` + factory `fromJson(json, itemFactory)`

### privacy_models.dart
- **FortressStatusModel** — `enabled`, `enabledAt?`, `enabledByUsername?`, `verified`
- **DataInventoryModel** — `conversationCount`, `messageCount`, `memoryCount`, `knowledgeDocumentCount`, `sensorCount`, `insightCount`
- **AuditSummaryModel** — `successCount`, `failureCount`, `deniedCount`, `windowStart?`, `windowEnd?`
- **SovereigntyReportModel** — `generatedAt?`, `fortressStatus?`, `outboundTrafficVerification?`, `dataInventory?`, `auditSummary?`, `encryptionStatus?`, `telemetryStatus?`, `lastVerifiedAt?`
- **AuditLogModel** — `id`, `userId?`, `username?`, `action`, `resourceType?`, `resourceId?`, `httpMethod?`, `requestPath?`, `outcome`, `responseStatus?`, `durationMs?`, `timestamp?`
- **WipeResultModel** — `targetUserId?`, `stepsCompleted`, `completedAt?`, `success`
- **AuditOutcome** — `SUCCESS`, `FAILURE`, `DENIED`

### sensor_model.dart
- **SensorModel** — `id`, `name`, `type`, `portPath?`, `baudRate`, `dataFormat?`, `valueField?`, `unit?`, `isActive`, `pollIntervalSeconds`, `lowThreshold?`, `highThreshold?`, `createdAt?`, `updatedAt?`
- **SensorReadingModel** — `id`, `sensorId`, `value`, `rawData?`, `recordedAt?`
- **SensorTestResultModel** — `success`, `portPath`, `baudRate`, `sampleData?`, `message`
- **SensorType** — `TEMPERATURE`, `HUMIDITY`, `PRESSURE`, `SOIL_MOISTURE`, `WIND_SPEED`, `SOLAR_RADIATION`
- **DataFormat** — `CSV_LINE`, `JSON_LINE`, `RAW_TEXT`

### skill_model.dart
- **SkillModel** — `id`, `name`, `displayName`, `description?`, `version?`, `author?`, `category?`, `isEnabled`, `isBuiltIn`, `parametersSchema?`, `createdAt?`, `updatedAt?`
- **SkillExecutionModel** — `id`, `skillId`, `skillName`, `userId?`, `status`, `inputParams?`, `outputResult?`, `errorMessage?`, `startedAt?`, `completedAt?`, `durationMs?` + getters `isRunning`, `isSuccess`, `isFailed`

### system_models.dart
- **SystemStatusModel** — `initialized`, `instanceName?`, `fortressEnabled`, `wifiConfigured`, `serverVersion?`, `timestamp?`
- **OllamaModelInfoModel** — `name`, `size`, `modifiedAt?`
- **AiSettingsModel** — `modelName`, `temperature`, `similarityThreshold`, `memoryTopK`, `ragMaxContextTokens`, `contextSize`, `contextMessageLimit` + `toJson()`
- **StorageSettingsModel** — `knowledgeStoragePath`, `totalSpaceMb`, `usedSpaceMb`, `freeSpaceMb`, `maxUploadSizeMb` + `toJson()`
- **ActiveModelInfo** — `modelName?`, `embedModelName?`

### user_model.dart
- **UserModel** — `id`, `username`, `displayName`, `role`, `isActive` + `toJson()`

---

## 7. Enum Inventory

All enums are implemented as Dart classes with static `const String` fields (not Dart `enum` types):

| Enum Class | Values | Used In |
|---|---|---|
| EventType | SCHEDULED, SENSOR_THRESHOLD, RECURRING | ScheduledEventModel, EventDialog |
| ActionType | PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY | ScheduledEventModel, EventDialog |
| ThresholdOperator | ABOVE, BELOW, EQUALS | ScheduledEventModel, EventDialog |
| InsightCategory | SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING | InsightModel, InsightsScreen |
| InventoryCategory | FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER | InventoryItemModel, InventoryScreen |
| NotificationType | SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL | NotificationModel |
| NotificationSeverity | INFO, WARNING, CRITICAL | NotificationModel |
| SensorType | TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION | SensorModel, AddSensorScreen |
| DataFormat | CSV_LINE, JSON_LINE, RAW_TEXT | SensorModel, AddSensorScreen |
| AuditOutcome | SUCCESS, FAILURE, DENIED | AuditLogModel, PrivacyScreen |

---

## 8. Repository Layer

Not applicable — this is a Flutter client app. Data access goes through service classes that call the backend REST API via `MyOffGridAIApiClient`.

---

## 9. Service Layer — Full Method Signatures

### core/api/api_exception.dart
```
=== ApiException ===
Fields: message (String), statusCode (int?)
Static: fromDioException(DioException): ApiException
Overrides: toString()
```

### core/api/api_response.dart
```
=== ApiResponse<T> ===
Generic wrapper for server responses: success, message?, data?, error?
Factory: fromJson(Map, T Function(dynamic)?)
```

### core/api/myoffgridai_api_client.dart
```
=== MyOffGridAIApiClient ===
Injects: baseUrl (String), storage (SecureStorageService), ref (Ref)
Creates Dio with connectTimeout, receiveTimeout, JWT interceptor (auto-attaches Bearer token, auto-refresh on 401)

Public Methods:
  - get<T>(String path, {Map? queryParams}): Future<T>
  - post<T>(String path, {dynamic data, Map? queryParams}): Future<T>
  - put<T>(String path, {dynamic data}): Future<T>
  - patch<T>(String path, {dynamic data}): Future<T>
  - delete(String path): Future<void>
  - upload<T>(String path, FormData data, {Function? onProgress}): Future<T>
  - streamPost(String path, {dynamic data}): Stream<String> (SSE)
  - downloadFile(String url, String savePath): Future<void>
  - get baseUrl: String
  - updateBaseUrl(String newUrl): void
```

### core/api/providers.dart
```
=== Providers (top-level) ===
  - apiClientProvider: Provider<MyOffGridAIApiClient>
  - systemStatusProvider: FutureProvider.autoDispose<Map<String, dynamic>>
  - connectionStatusProvider: StreamProvider.autoDispose<bool>
  - unreadNotificationCountProvider: FutureProvider.autoDispose<int>
```

### core/auth/auth_service.dart
```
=== AuthService ===
Injects: MyOffGridAIApiClient, SecureStorageService

Public Methods:
  - login(String username, String password): Future<UserModel>
  - register(String username, String password, {String? displayName, String? email}): Future<UserModel>
  - refreshToken(): Future<void>
  - logout(): Future<void>
  - getCurrentUser(): Future<UserModel>
```

### core/auth/auth_state.dart
```
=== AuthStateNotifier (AsyncNotifier<UserModel?>) ===
Manages auth lifecycle as Riverpod AsyncNotifier.

Public Methods:
  - build(): Future<UserModel?>  — checks stored token on startup
  - login(String username, String password): Future<void>
  - register(String username, String password, {String? displayName, String? email}): Future<void>
  - logout(): Future<void>
  - refreshUser(): Future<void>
  - checkDeviceSetup(): Future<bool>

Providers:
  - authStateProvider: AsyncNotifierProvider<AuthStateNotifier, UserModel?>
```

### core/auth/secure_storage_service.dart
```
=== SecureStorageService ===
Wraps FlutterSecureStorage.

Public Methods:
  - saveAccessToken(String token): Future<void>
  - getAccessToken(): Future<String?>
  - saveRefreshToken(String token): Future<void>
  - getRefreshToken(): Future<String?>
  - saveServerUrl(String url): Future<void>
  - getServerUrl(): Future<String>
  - saveThemePreference(String pref): Future<void>
  - getThemePreference(): Future<String>
  - saveDeviceId(String id): Future<void>
  - getDeviceId(): Future<String?>
  - clearAll(): Future<void>

Provider: secureStorageProvider
```

### core/services/chat_service.dart
```
=== ChatService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listConversations({int page, int size}): Future<List<ConversationSummaryModel>>
  - getConversation(String id): Future<ConversationModel>
  - createConversation(): Future<ConversationModel>
  - deleteConversation(String id): Future<void>
  - renameConversation(String id, String title): Future<ConversationModel>
  - getMessages(String conversationId, {int page, int size}): Future<List<MessageModel>>
  - sendMessage(String conversationId, String content): Stream<String> (SSE)
  - searchMessages(String query, {int page, int size}): Future<List<MessageModel>>

Providers: chatServiceProvider, conversationsProvider, messagesProvider(conversationId)
```

### core/services/chat_messages_notifier.dart
```
=== ChatMessagesNotifier (StateNotifier<AsyncValue<List<MessageModel>>>) ===
Manages message list state for a conversation.

Public Methods:
  - loadMessages(String conversationId): Future<void>
  - addMessage(MessageModel message): void
  - updateLastMessage(String content): void
```

### core/services/device_registration_service.dart
```
=== DeviceRegistrationService ===
Injects: MyOffGridAIApiClient, SecureStorageService

Public Methods:
  - registerDevice({required String deviceName, required String platform, required String mqttClientId}): Future<DeviceRegistrationModel>
  - listDevices(): Future<List<DeviceRegistrationModel>>
  - deleteDevice(String registrationId): Future<void>
  - getOrCreateDeviceId(): Future<String>

Provider: deviceRegistrationServiceProvider
```

### core/services/enrichment_service.dart
```
=== EnrichmentService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - getExternalApiSettings(): Future<ExternalApiSettingsModel>
  - updateExternalApiSettings(UpdateExternalApiSettingsRequest request): Future<ExternalApiSettingsModel>
  - getEnrichmentStatus(): Future<EnrichmentStatusModel>
  - fetchUrl(String url): Future<String>
  - searchWeb(String query): Future<List<SearchResultModel>>

Providers: enrichmentServiceProvider, externalApiSettingsProvider, enrichmentStatusProvider
```

### core/services/event_service.dart
```
=== EventService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listEvents({int page, int size}): Future<List<ScheduledEventModel>>
  - getEvent(String eventId): Future<ScheduledEventModel>
  - createEvent(ScheduledEventModel event): Future<ScheduledEventModel>
  - updateEvent(String eventId, ScheduledEventModel event): Future<ScheduledEventModel>
  - deleteEvent(String eventId): Future<void>
  - toggleEvent(String eventId, bool enabled): Future<ScheduledEventModel>

Providers: eventServiceProvider, eventsProvider
```

### core/services/foreground_service_manager.dart
```
=== ForegroundServiceManager ===
Wraps FlutterForegroundTask for persistent MQTT connection.

Public Methods:
  - startService(): Future<void>
  - stopService(): Future<void>
  - get isRunning: bool

Provider: foregroundServiceManagerProvider
```

### core/services/insight_service.dart
```
=== InsightService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listInsights({String? category, bool? unreadOnly, int page, int size}): Future<List<InsightModel>>
  - getInsight(String insightId): Future<InsightModel>
  - markAsRead(String insightId): Future<InsightModel>
  - dismissInsight(String insightId): Future<void>
  - generateInsights(): Future<List<InsightModel>>
  - getUnreadCount(): Future<int>

Providers: insightServiceProvider, insightsProvider
```

### core/services/inventory_service.dart
```
=== InventoryService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listItems({String? category, int page, int size}): Future<List<InventoryItemModel>>
  - getItem(String itemId): Future<InventoryItemModel>
  - createItem({required String name, required String category, required double quantity, String? unit, String? notes, double? lowStockThreshold}): Future<InventoryItemModel>
  - updateItem(String itemId, {String? name, String? category, double? quantity, String? unit, String? notes, double? lowStockThreshold}): Future<InventoryItemModel>
  - deleteItem(String itemId): Future<void>

Providers: inventoryServiceProvider, inventoryProvider
```

### core/services/knowledge_service.dart
```
=== KnowledgeService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listDocuments({int page, int size}): Future<List<KnowledgeDocumentModel>>
  - getDocument(String documentId): Future<KnowledgeDocumentModel>
  - uploadDocument(String filename, List<int> bytes, String mimeType): Future<KnowledgeDocumentModel>
  - deleteDocument(String documentId): Future<void>
  - searchDocuments(String query, {int topK}): Future<List<KnowledgeSearchResultModel>>
  - getDocumentContent(String documentId): Future<DocumentContentModel>
  - updateDocumentContent(String documentId, String title, String content): Future<DocumentContentModel>
  - updateDocumentDisplayName(String documentId, String displayName): Future<KnowledgeDocumentModel>
  - reprocessDocument(String documentId): Future<KnowledgeDocumentModel>
  - downloadDocumentUrl(String documentId): String

Providers: knowledgeServiceProvider, knowledgeDocumentsProvider
```

### core/services/library_service.dart
```
=== LibraryService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listZimFiles(): Future<List<ZimFileModel>>
  - uploadZimFile(String filename, List<int> bytes): Future<ZimFileModel>
  - deleteZimFile(String zimId): Future<void>
  - getKiwixStatus(): Future<KiwixStatusModel>
  - listEbooks({int page, int size, String? search, String? format}): Future<List<EbookModel>>
  - getEbook(String ebookId): Future<EbookModel>
  - uploadEbook(String filename, List<int> bytes, String mimeType, {String? title, String? author}): Future<EbookModel>
  - deleteEbook(String ebookId): Future<void>
  - getEbookContentUrl(String ebookId): String
  - getEbookCoverUrl(String ebookId): String
  - searchGutenberg(String query, {int page}): Future<GutenbergSearchResultModel>
  - importFromGutenberg(int gutenbergId): Future<EbookModel>

Providers: libraryServiceProvider, zimFilesProvider, kiwixStatusProvider, ebooksProvider
```

### core/services/local_notification_service.dart
```
=== LocalNotificationService ===
Wraps FlutterLocalNotificationsPlugin.

Public Methods:
  - initialize(): Future<void>
  - showNotification({required String title, required String body, String? payload}): Future<void>

Provider: localNotificationServiceProvider
```

### core/services/memory_service.dart
```
=== MemoryService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listMemories({String? importance, int page, int size}): Future<List<MemoryModel>>
  - getMemory(String memoryId): Future<MemoryModel>
  - createMemory({required String content, String importance, String? tags}): Future<MemoryModel>
  - deleteMemory(String memoryId): Future<void>
  - searchMemories(String query, {int topK}): Future<List<MemorySearchResultModel>>

Providers: memoryServiceProvider, memoriesProvider
```

### core/services/mqtt_service.dart
```
=== MqttService ===
Injects: SecureStorageService

Public Methods:
  - connect(String serverHost, String username): Future<void>
  - disconnect(): void
  - subscribe(String topic, Function(String topic, String payload) handler): void
  - publish(String topic, String payload): void
  - get isConnected: bool
  - get connectionStream: Stream<bool>

Provider: mqttServiceProvider
```

### core/services/notification_service.dart
```
=== NotificationService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listNotifications({bool? unreadOnly, int page, int size}): Future<List<NotificationModel>>
  - markAsRead(String notificationId): Future<NotificationModel>
  - markAllAsRead(): Future<void>
  - deleteNotification(String notificationId): Future<void>
  - getUnreadCount(): Future<int>

Providers: notificationServiceProvider, notificationsProvider
```

### core/services/privacy_service.dart
```
=== PrivacyService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - getFortressStatus(): Future<FortressStatusModel>
  - enableFortress(): Future<FortressStatusModel>
  - disableFortress(): Future<FortressStatusModel>
  - getSovereigntyReport(): Future<SovereigntyReportModel>
  - getAuditLogs({String? outcome, int page, int size}): Future<List<AuditLogModel>>
  - wipeSelfData(): Future<WipeResultModel>

Providers: privacyServiceProvider, fortressStatusProvider
```

### core/services/sensor_service.dart
```
=== SensorService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listSensors(): Future<List<SensorModel>>
  - getSensor(String sensorId): Future<SensorModel>
  - createSensor({required String name, required String type, required String portPath, int? baudRate, String? dataFormat, String? valueField, String? unit, required int pollIntervalSeconds, double? lowThreshold, double? highThreshold}): Future<SensorModel>
  - deleteSensor(String sensorId): Future<void>
  - startSensor(String sensorId): Future<SensorModel>
  - stopSensor(String sensorId): Future<SensorModel>
  - getLatestReading(String sensorId): Future<SensorReadingModel?>
  - getHistory(String sensorId, {int hours, int page, int size}): Future<List<SensorReadingModel>>
  - updateThresholds(String sensorId, {double? lowThreshold, double? highThreshold}): Future<SensorModel>
  - testConnection(String portPath, int baudRate): Future<SensorTestResultModel>
  - listPorts(): Future<List<String>>

Providers: sensorServiceProvider, sensorsProvider
```

### core/services/skills_service.dart
```
=== SkillsService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listSkills(): Future<List<SkillModel>>
  - getSkill(String skillId): Future<SkillModel>
  - toggleSkill(String skillId, bool enabled): Future<SkillModel>
  - executeSkill(String skillId, {Map? params}): Future<SkillExecutionModel>
  - listExecutions({int page, int size}): Future<List<SkillExecutionModel>>

Providers: skillsServiceProvider, skillsProvider
```

### core/services/system_service.dart
```
=== SystemService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - getSystemStatus(): Future<SystemStatusModel>
  - listModels(): Future<List<OllamaModelInfoModel>>
  - getActiveModel(): Future<ActiveModelInfo>
  - getAiSettings(): Future<AiSettingsModel>
  - getStorageSettings(): Future<StorageSettingsModel>
  - updateStorageSettings(StorageSettingsModel): Future<StorageSettingsModel>
  - updateAiSettings(AiSettingsModel): Future<AiSettingsModel>

Providers: systemServiceProvider, systemStatusDetailProvider, ollamaModelsProvider, aiSettingsProvider, storageSettingsProvider
```

### core/services/user_service.dart
```
=== UserService ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listUsers({int page, int size}): Future<List<UserModel>>
  - getUser(String userId): Future<UserDetailModel>
  - updateUser(String userId, {String? displayName, String? email, String? role}): Future<UserDetailModel>
  - deactivateUser(String userId): Future<void>
  - deleteUser(String userId): Future<void>

Also defines: UserDetailModel (id, username, email?, displayName, role, isActive, createdAt?, updatedAt?, lastLoginAt?)

Providers: userServiceProvider, usersListProvider
```

---

## 10. Controller / API Layer

Not applicable — this is a Flutter client. Screens consume services directly via Riverpod providers. See Section 9 for the service layer and its provider bindings.

---

## 11. Security Configuration

```
Authentication: JWT (Bearer token via Dio interceptor)
Token storage: flutter_secure_storage (platform-encrypted)
Token refresh: Automatic on 401 — interceptor calls AuthService.refreshToken(), retries original request
Logout: Clears tokens from secure storage, resets auth state

Public routes (no auth required):
  - /login
  - /register
  - /device-not-setup

Protected routes:
  - All other routes — redirected to /login if no token

Role-based access:
  - /users — ROLE_OWNER or ROLE_ADMIN only (GoRouter redirect guard)

CORS: N/A (client-side)
CSRF: N/A (client-side, JWT-based)
Rate limiting: N/A (server-side concern)
```

---

## 12. Custom Security Components

```
=== MyOffGridAIApiClient (JWT Interceptor) ===
Location: lib/core/api/myoffgridai_api_client.dart
Purpose: Attaches Bearer token to all requests, auto-refreshes on 401
Token source: SecureStorageService.getAccessToken()
Refresh mechanism: Calls /api/auth/refresh with stored refresh token
On refresh failure: Clears tokens, redirects to login

=== SecureStorageService ===
Location: lib/core/auth/secure_storage_service.dart
Wraps: FlutterSecureStorage
Stores: access_token, refresh_token, server_url, theme_preference, device_id
```

---

## 13. Exception Handling & Error Responses

```
=== ApiException ===
Location: lib/core/api/api_exception.dart
Fields: message (String), statusCode (int?)
Factory: fromDioException(DioException) — extracts error message from response body or falls back to Dio message

Error handling pattern:
  - Services throw ApiException on HTTP errors
  - Screens catch exceptions in try/catch and show SnackBar messages
  - No global error handler widget — each screen handles its own errors
  - ErrorView widget for full-page error states with retry button
```

---

## 14. Mappers / DTOs

No mappers or mapping frameworks. Models have `factory fromJson()` constructors for deserialization and `toJson()` methods where needed for serialization. Direct JSON parsing — no MapStruct/ModelMapper equivalent.

---

## 15. Utility Classes & Shared Components

### Shared Utils

```
=== DateFormatter (lib/shared/utils/date_formatter.dart) ===
Static Methods:
  - formatRelative(String? isoDate): String — "2 hours ago", "Yesterday", etc.
  - formatFull(String? isoDate): String — "Mar 16, 2026 4:30 PM"
Used by: Multiple screens for timestamp display

=== DownloadUtils (lib/shared/utils/download_utils.dart) ===
Static Methods:
  - downloadFile(String url, String filename, BuildContext context): Future<void>
Used by: DocumentDetailScreen, BooksScreen

=== PlatformUtils (lib/shared/utils/platform_utils.dart) ===
Static Methods:
  - get isDesktop: bool
  - get isMobile: bool
  - get isWeb: bool
Used by: Multiple screens for platform-adaptive UI

=== SizeFormatter (lib/shared/utils/size_formatter.dart) ===
Static Methods:
  - format(int bytes): String — "1.2 MB", "340 KB", etc.
Used by: KnowledgeScreen, BooksScreen, LibraryService
```

### Shared Widgets

```
=== AppShell (lib/shared/widgets/app_shell.dart) ===
Shell widget wrapping all authenticated routes. Contains NavigationPanel + content area.
Responsive: sidebar on desktop, bottom nav drawer on mobile.

=== NavigationPanel (lib/shared/widgets/navigation_panel.dart) ===
607 lines. Collapsible sidebar with nav items, conversation list, new chat button, rename/delete.

=== SystemStatusBar (lib/shared/widgets/system_status_bar.dart) ===
Status bar showing connection state, model name, server version. Uses connectionStatusProvider.

=== ConfirmationDialog (lib/shared/widgets/confirmation_dialog.dart) ===
Reusable Material dialog with title, content, confirm/cancel actions.

=== ConnectionLostBanner (lib/shared/widgets/connection_lost_banner.dart) ===
Banner shown when server connection is lost.

=== EmptyStateView (lib/shared/widgets/empty_state_view.dart) ===
Full-page empty state with icon, title, subtitle, optional action button.

=== ErrorView (lib/shared/widgets/error_view.dart) ===
Full-page error state with icon, message, retry button.

=== LoadingIndicator (lib/shared/widgets/loading_indicator.dart) ===
Centered CircularProgressIndicator with optional message.

=== NotificationBadge (lib/shared/widgets/notification_badge.dart) ===
Badge overlay showing unread notification count.
```

---

## 16. Database Schema

Not applicable — this is a Flutter client app. No local database. Data persisted via:
- `flutter_secure_storage` — tokens, server URL, theme preference, device ID
- Backend REST API — all data stored server-side

---

## 17. Message Broker Configuration

```
Broker: MQTT via mqtt_client package
Connection: Configurable server host, port 1883
Client ID: myoffgridai-flutter-{deviceId}
Keep-alive: 60 seconds
Reconnect delay: 5 seconds

Topics:
  - /myoffgridai/broadcast — Global broadcast messages
  - /myoffgridai/{userId}/notifications — User-specific notifications

Service: MqttService (lib/core/services/mqtt_service.dart)
  - Connects with username-based auth
  - Subscribe/publish pattern
  - Connection state exposed as Stream<bool>

Integration:
  - ForegroundServiceManager keeps MQTT alive in background (Android)
  - LocalNotificationService shows push notifications on MQTT messages
  - DeviceRegistrationService registers device with server for targeted messages
```

---

## 18. Cache Layer

No Redis or caching layer detected. Only `cached_network_image` for HTTP image caching (covers, thumbnails). No application-level data caching.

---

## 19. Environment Variable Inventory

No environment variables used. All configuration is in:
- `lib/config/constants.dart` — compile-time constants
- `flutter_secure_storage` — runtime user-configurable server URL

Server URL is user-configurable at login (defaults: web → `localhost:8080`, native → `offgrid.local:8080`).

---

## 20. Service Dependency Map

```
MyOffGridAI-Client → Depends On
──────────────────────────────────
MyOffGridAI Server (Spring Boot): HTTP REST API (all services)
  - Auth: /api/auth/**
  - Chat: /api/chat/**
  - Memory: /api/memory/**
  - Knowledge: /api/knowledge/**
  - Skills: /api/skills/**
  - Sensors: /api/sensors/**
  - Events: /api/events/**
  - Insights: /api/insights/**
  - Notifications: /api/notifications/**
  - Privacy: /api/privacy/**
  - System: /api/system/**
  - Models: /api/models/**
  - Users: /api/users/**
  - Enrichment: /api/enrichment/**
  - Library: /api/library/**
  - Settings: /api/settings/**

MQTT Broker (via MyOffGridAI Server): port 1883
  - Push notifications
  - Real-time updates

Kiwix Server (via MyOffGridAI Server): port 8888
  - ZIM file serving for offline library

Downstream Consumers: None (this is the end-user client)
```

---

## 21. Known Technical Debt & Issues

### TODO/Placeholder/Stub Scan Result: **PASS — No TODOs, FIXMEs, or stubs found**

| Issue | Location | Severity | Notes |
|-------|----------|----------|-------|
| Missing DartDoc on 2 classes | `notifications_screen.dart` | Medium | 2 out of 192 classes undocumented (private state classes) |
| Test coverage at 91.6% | Multiple files | High | 44 files below 100% — see Scorecard for details |
| settings_screen.dart very large | `lib/features/settings/settings_screen.dart` | Medium | 1783 lines — could benefit from splitting |
| DownloadUtils nearly untested | `lib/shared/utils/download_utils.dart` | Medium | 1/21 lines covered (platform-dependent file I/O) |
| MQTT service low coverage | `lib/core/services/mqtt_service.dart` | Medium | 6.3% — hard to unit test MQTT connections |
| NavigationPanel low coverage | `lib/shared/widgets/navigation_panel.dart` | Medium | 4.1% — complex widget with many interaction paths |

---

## 22. Security Vulnerability Scan (Snyk)

```
Scan Date: 2026-03-16
Snyk CLI Version: 1.1303.0

SNYK SCAN: NOT APPLICABLE
Snyk does not support Flutter/Dart projects for dependency scanning.
Error: "No supported files found" (SNYK-CLI-0008)

Alternative: Manual review of pubspec.yaml dependencies shows all packages
are from pub.dev with standard versioning. No known CVEs at time of audit.
```

### Dependency Vulnerabilities (Open Source)
Not scannable — Snyk does not support Dart/Flutter.

### Code Vulnerabilities (SAST)
Not scannable — Snyk Code does not support Dart.

### IaC Findings
Not applicable — no Dockerfile or infrastructure config present.

---
