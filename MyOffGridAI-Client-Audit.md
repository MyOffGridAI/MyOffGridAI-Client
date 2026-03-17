# MyOffGridAI-Client — Codebase Audit

**Audit Date:** 2026-03-17T12:29:55Z
**Branch:** main
**Commit:** f209898ce82cf8e3abe6e4e706ebe64be7d7f38c P13-Client: Complete all outstanding items (C1-C8)
**Auditor:** Claude Code (Automated)
**Purpose:** Zero-context reference for AI-assisted development
**Audit File:** MyOffGridAI-Client-Audit.md
**Scorecard:** MyOffGridAI-Client-Scorecard.md
**OpenAPI Spec:** MyOffGridAI-Client-OpenAPI.yaml (generated separately)

> This audit is the source of truth for the MyOffGridAI-Client codebase structure, entities, services, and configuration.
> The OpenAPI spec (MyOffGridAI-Client-OpenAPI.yaml) is the source of truth for all endpoints, DTOs, and API contracts.
> An AI reading this audit + the OpenAPI spec should be able to generate accurate code
> changes, new features, tests, and fixes without filesystem access.

---

## 1. Project Identity

```
Project Name:          MyOffGridAI-Client
Repository URL:        https://github.com/adamallard/MyOffGridAI-Client (inferred)
Primary Language:      Dart / Flutter
Dart SDK Version:      ^3.11.0
Build Tool:            Flutter CLI + pub
Current Branch:        main
Latest Commit Hash:    f209898ce82cf8e3abe6e4e706ebe64be7d7f38c
Latest Commit Message: P13-Client: Complete all outstanding items (C1-C8)
Audit Timestamp:       2026-03-17T12:29:55Z
```

---

## 2. Directory Structure

```
lib/                           (95 Dart files, ~19,226 lines)
├── main.dart                  ← App entry point
├── config/
│   ├── constants.dart         ← All app-wide constants (URLs, keys, routes, UI)
│   ├── router.dart            ← GoRouter with auth guards
│   └── theme.dart             ← Light/dark themes, brand colors, ThemeNotifier
├── core/
│   ├── api/
│   │   ├── api_exception.dart ← Typed HTTP exception
│   │   ├── api_response.dart  ← Server envelope wrapper
│   │   ├── myoffgridai_api_client.dart ← Dio HTTP client with JWT interceptor
│   │   └── providers.dart     ← System status, model health, connection polling
│   ├── auth/
│   │   ├── auth_service.dart  ← Login/register/logout/refresh
│   │   ├── auth_state.dart    ← AuthNotifier (JWT decode, token lifecycle)
│   │   └── secure_storage_service.dart ← FlutterSecureStorage wrapper with cache
│   ├── models/                (19 files, 42 classes, 1 enum, 10 static-const enum-equivalents)
│   └── services/              (20 files, 22 classes, 113 public methods, 40 Riverpod providers)
├── features/
│   ├── auth/                  (4 screens: login, register, users, device-not-setup)
│   ├── books/                 (2 screens: list, reader)
│   ├── chat/                  (2 screens + 5 widgets: list, conversation, message bubble, etc.)
│   ├── events/                (2 files: screen + dialog)
│   ├── insights/              (1 screen: combined insights + notifications tabs)
│   ├── inventory/             (1 screen)
│   ├── knowledge/             (3 screens: list, detail, editor)
│   ├── memory/                (1 screen)
│   ├── notifications/         (1 screen)
│   ├── privacy/               (1 screen: fortress + sovereignty + audit tabs)
│   ├── search/                (1 screen: unified cross-domain search)
│   ├── sensors/               (3 screens: list, detail, add)
│   ├── settings/              (1 screen: 6-tab mega settings)
│   ├── skills/                (1 screen)
│   └── system/                (1 screen)
├── shared/
│   ├── utils/                 (6 files: date, download, platform, size formatters)
│   └── widgets/               (9 files: app shell, nav panel, dialogs, status widgets)

test/                          (93 Dart files, ~33,172 lines, 1,737 test cases)
```

Single-module Flutter project. Source in `lib/`, tests mirror source structure in `test/`. No code generation (no build_runner output, no `.g.dart`/`.freezed.dart` files). Architecture: feature-first with shared core layer (API client, auth, models, services).

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
| flutter_secure_storage | ^9.2.4 | Encrypted storage (tokens, prefs) |
| fl_chart | ^0.70.2 | Charts (sensor history) |
| file_picker | ^8.3.7 | Native file picker (uploads) |
| desktop_drop | ^0.4.4 | Drag-and-drop file support |
| cross_file | ^0.3.5+2 | Cross-platform file abstraction |
| intl | ^0.20.2 | Date/number formatting |
| flutter_quill | ^11.4.0 | Rich text editor (knowledge docs) |
| mqtt_client | ^10.2.1 | MQTT for push notifications |
| flutter_local_notifications | ^17.2.3 | Local push notification display |
| flutter_foreground_task | ^8.13.0 | Android foreground service |
| permission_handler | ^11.3.1 | Runtime permissions |
| webview_flutter | ^4.10.0 | WebView (Kiwix browser) |
| webview_flutter_android | ^4.3.0 | Android WebView impl |
| webview_flutter_wkwebview | ^3.18.0 | iOS WebView impl |
| epub_view | ^3.2.0 | EPUB reader |
| pdfx | ^2.9.0 | PDF reader |
| path_provider | ^2.1.5 | Platform file paths |
| open_filex | ^4.6.0 | Open files in OS viewer |
| cached_network_image | ^3.4.1 | Image caching |
| flutter_markdown | ^0.7.4+3 | Markdown rendering (chat) |
| markdown | ^7.3.0 | Markdown parsing |
| flutter_highlight | ^0.7.0 | Syntax highlighting (code blocks) |
| highlight | ^0.7.0 | Syntax highlighting engine |

**Dev Dependencies:**

| Dependency | Version | Purpose |
|---|---|---|
| flutter_test | SDK | Testing framework |
| flutter_lints | ^6.0.0 | Lint rules |
| build_runner | ^2.4.15 | Code generation runner |
| riverpod_generator | ^2.6.3 | Riverpod codegen |
| mockito | ^5.4.6 | Mock framework |
| mocktail | ^1.0.4 | Lightweight mock framework |

**Build commands:**
```
Build:   flutter build <platform>
Test:    flutter test
Run:     flutter run
Analyze: flutter analyze
```

---

## 4. Configuration & Infrastructure Summary

**Configuration is centralized in `lib/config/constants.dart`** — no YAML/properties files. All server URLs, timeouts, API paths, route names, storage keys, UI constants, MQTT settings, and notification channel IDs are defined as static constants in `AppConstants`.

**Key facts:**
- Default server URL: `http://localhost:8080` (web) / `http://offgrid.local:8080` (native)
- Connect timeout: 10s, Receive timeout: 120s, SSE timeout: 5min
- MQTT port: 1883, Kiwix port: 8888
- Pagination defaults: page size 20, max 100
- Responsive breakpoints: mobile < 600px, tablet < 1200px
- Theme persistence: FlutterSecureStorage (in-memory cache fallback for web)

**Analysis options:** `analysis_options.yaml` — minimal, includes `package:flutter_lints/flutter.yaml`, disables `unnecessary_underscores`.

**Connection map:**
```
Database:       None (client-only; server manages persistence)
Cache:          In-memory token/pref cache in SecureStorageService
Message Broker: MQTT (mosquitto on server, mqtt_client in Flutter)
External APIs:  MyOffGridAI-Server (REST + SSE), Kiwix serve (WebView), Gutenberg/Gutendex (via server proxy)
Cloud Services: None (offline-first architecture)
```

**CI/CD:** None detected.

---

## 5. Startup & Runtime Behavior

**Entry point:** `lib/main.dart` → `Future<void> main()`

**Startup sequence:**
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `SecureStorageService()` created
3. Server URL resolved from secure storage (default: `http://localhost:8080` on web)
4. `LocalNotificationService.initialize()` — plugin init + Android channel creation
5. `ProviderScope` created with overrides for `secureStorageProvider`, `localNotificationServiceProvider`, `apiClientProvider`
6. `MyOffGridAIApp` widget launched — `MaterialApp.router` with `GoRouter`, light/dark themes

**Post-login initialization (non-blocking):**
1. Device registration with server (MQTT topic assignment)
2. Android foreground service start (no-op on iOS/web)
3. MQTT connection to Mosquitto broker

**Scheduled/polling tasks:**
- Connection status: polls `/api/system/status` every 10 seconds
- Model health: polls `/api/models/health` every 60 seconds
- Notification count: polls `/api/notifications/unread-count` every 30 seconds

**Health check:** No dedicated health endpoint on client; relies on `connectionStatusProvider` polling server's `/api/system/status`.

---

## 6. Entity / Data Model Layer

This is a Flutter client — no database entities. All models are DTOs that mirror server-side entities.

### Model Inventory (42 classes across 19 files)

**lib/core/models/conversation_model.dart:**
- `ConversationModel` — id, title?, isArchived, messageCount, createdAt?, updatedAt?
- `ConversationSummaryModel` — id, title?, isArchived, messageCount, updatedAt?, lastMessagePreview?

**lib/core/models/device_registration_model.dart:**
- `DeviceRegistrationModel` — id, deviceId, deviceName, platform, mqttClientId, lastSeenAt?

**lib/core/models/enrichment_models.dart:**
- `ExternalApiSettingsModel` — anthropicEnabled, anthropicModel, anthropicKeyConfigured, braveEnabled, braveKeyConfigured, huggingFaceEnabled, huggingFaceKeyConfigured, maxWebFetchSizeKb, searchResultLimit
- `UpdateExternalApiSettingsRequest` — API key fields (nullable), boolean toggles, limits; has `toJson()`
- `SearchResultModel` — title, url, description, publishedDate?
- `EnrichmentStatusModel` — claudeAvailable, braveAvailable, maxWebFetchSizeKb, searchResultLimit

**lib/core/models/event_model.dart:**
- `ScheduledEventModel` — 17 fields (id, userId?, name, description?, eventType, isEnabled, cronExpression?, recurringIntervalMinutes?, sensorId?, thresholdOperator?, thresholdValue?, actionType, actionPayload, lastTriggeredAt?, nextFireAt?, createdAt?, updatedAt?); has `toJson()`
- `EventType` — SCHEDULED, SENSOR_THRESHOLD, RECURRING (static constants)
- `ActionType` — PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY (static constants)
- `ThresholdOperator` — ABOVE, BELOW, EQUALS (static constants)

**lib/core/models/inference_stream_event.dart:**
- `InferenceEventType` (enum) — thinking, content, done, error
- `InferenceMetadata` — tokensGenerated, tokensPerSecond, inferenceTimeSeconds, stopReason?, thinkingTokenCount?
- `InferenceStreamEvent` — type, content?, metadata?, messageId?

**lib/core/models/insight_model.dart:**
- `InsightModel` — id, content, category, isRead, isDismissed, generatedAt?, readAt?
- `InsightCategory` — SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING

**lib/core/models/inventory_item_model.dart:**
- `InventoryItemModel` — id, name, category, quantity, unit?, notes?, lowStockThreshold?, createdAt?, updatedAt?; getter `isLowStock`
- `InventoryCategory` — FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER

**lib/core/models/knowledge_document_model.dart:**
- `KnowledgeDocumentModel` — id, filename, displayName?, mimeType?, fileSizeBytes, status, errorMessage?, chunkCount, uploadedAt?, processedAt?, hasContent, editable; getters: isProcessing, isIndexed, isFailed
- `DocumentContentModel` — documentId, title, content?, mimeType?, editable
- `KnowledgeSearchResultModel` — chunkId, documentId, documentName, content, pageNumber?, chunkIndex, similarityScore

**lib/core/models/library_models.dart:**
- `ZimFileModel` — id, filename, displayName?, description?, language?, category?, fileSizeBytes, articleCount, mediaCount, createdDate?, kiwixBookId?, uploadedAt?, uploadedBy?
- `EbookModel` — id, title, author?, description?, isbn?, publisher?, publishedYear?, language?, format, fileSizeBytes, gutenbergId?, downloadCount, hasCoverImage, uploadedAt?, uploadedBy?; getter `isFromGutenberg`
- `KiwixStatusModel` — available, url?, bookCount
- `GutenbergBookModel` — id, title, authors, subjects, languages, downloadCount, formats; getter `hasEpub`
- `GutenbergSearchResultModel` — count, next?, previous?, results (List<GutenbergBookModel>)

**lib/core/models/memory_model.dart:**
- `MemoryModel` — id, content, importance, tags?, sourceConversationId?, createdAt?, updatedAt?, lastAccessedAt?, accessCount; getter `tagList`
- `MemorySearchResultModel` — memory (MemoryModel), similarityScore

**lib/core/models/message_model.dart:**
- `MessageModel` — id, role, content, tokenCount?, hasRagContext, thinkingContent?, tokensPerSecond?, inferenceTimeSeconds?, stopReason?, thinkingTokenCount?, createdAt?; getters: isUser, isAssistant; `copyWith()`

**lib/core/models/model_catalog_models.dart:**
- `HfModelModel` — id, author, modelId, downloads, likes, tags, isGated, lastModified?, files; getters: hasGguf, hasMlx, ggufFiles
- `HfModelFileModel` — filename, sizeBytes?; getters: quantLabel, formattedSize
- `DownloadProgressModel` — downloadId, repoId, filename, status, bytesDownloaded, totalBytes, percentComplete, speedBytesPerSecond, estimatedSecondsRemaining, errorMessage?; getters: isActive, isComplete, isFailed, isCancelled
- `LocalModelFileModel` — filename, repoId?, format, sizeBytes, lastModified?, isCurrentlyLoaded

**lib/core/models/notification_model.dart:**
- `NotificationModel` — id, title, body, type, severity, isRead, createdAt?, readAt?, metadata?
- `NotificationType` — SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL
- `NotificationSeverity` — INFO, WARNING, CRITICAL

**lib/core/models/page_response.dart:**
- `PageResponse<T>` — content, totalElements, totalPages, number, size, first, last, empty

**lib/core/models/privacy_models.dart:**
- `FortressStatusModel` — enabled, enabledAt?, enabledByUsername?, verified
- `DataInventoryModel` — conversationCount, messageCount, memoryCount, knowledgeDocumentCount, sensorCount, insightCount
- `AuditSummaryModel` — successCount, failureCount, deniedCount, windowStart?, windowEnd?
- `SovereigntyReportModel` — generatedAt?, fortressStatus?, outboundTrafficVerification?, dataInventory?, auditSummary?, encryptionStatus?, telemetryStatus?, lastVerifiedAt?
- `AuditLogModel` — id, userId?, username?, action, resourceType?, resourceId?, httpMethod?, requestPath?, outcome, responseStatus?, durationMs?, timestamp?
- `WipeResultModel` — targetUserId?, stepsCompleted, completedAt?, success
- `AuditOutcome` — SUCCESS, FAILURE, DENIED

**lib/core/models/sensor_model.dart:**
- `SensorModel` — id, name, type, portPath?, baudRate, dataFormat?, valueField?, unit?, isActive, pollIntervalSeconds, lowThreshold?, highThreshold?, createdAt?, updatedAt?
- `SensorReadingModel` — id, sensorId, value, rawData?, recordedAt?
- `SensorTestResultModel` — success, portPath, baudRate, sampleData?, message
- `SensorType` — TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION
- `DataFormat` — CSV_LINE, JSON_LINE, RAW_TEXT

**lib/core/models/skill_model.dart:**
- `SkillModel` — id, name, displayName, description?, version?, author?, category?, isEnabled, isBuiltIn, parametersSchema?, createdAt?, updatedAt?
- `SkillExecutionModel` — id, skillId, skillName, userId?, status, inputParams?, outputResult?, errorMessage?, startedAt?, completedAt?, durationMs?; getters: isRunning, isSuccess, isFailed

**lib/core/models/system_models.dart:**
- `SystemStatusModel` — initialized, instanceName?, fortressEnabled, wifiConfigured, serverVersion?, timestamp?
- `OllamaModelInfoModel` — name, size, modifiedAt?
- `AiSettingsModel` — modelName, temperature, similarityThreshold, memoryTopK, ragMaxContextTokens, contextSize, contextMessageLimit; `toJson()`
- `StorageSettingsModel` — knowledgeStoragePath, totalSpaceMb, usedSpaceMb, freeSpaceMb, maxUploadSizeMb; `toJson()`
- `ActiveModelInfo` — modelName?, embedModelName?

**lib/core/models/user_model.dart:**
- `UserModel` — id, username, displayName, role, isActive; `toJson()`

**Patterns:** All models use `const` constructors, `final` fields (immutable), hand-written `fromJson`/`toJson`. No code generation.

---

## 7. Enum Inventory

| Enum/Constants Class | Values | Used In |
|---|---|---|
| `InferenceEventType` (Dart enum) | thinking, content, done, error | InferenceStreamEvent, ChatMessagesNotifier |
| `EventType` (static constants) | SCHEDULED, SENSOR_THRESHOLD, RECURRING | ScheduledEventModel, EventDialog |
| `ActionType` (static constants) | PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY | ScheduledEventModel, EventDialog |
| `ThresholdOperator` (static constants) | ABOVE, BELOW, EQUALS | ScheduledEventModel, EventDialog |
| `InsightCategory` (static constants) | SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING | InsightModel, InsightsScreen |
| `InventoryCategory` (static constants) | FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER | InventoryItemModel, InventoryScreen |
| `NotificationType` (static constants) | SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL | NotificationModel |
| `NotificationSeverity` (static constants) | INFO, WARNING, CRITICAL | NotificationModel, LocalNotificationService |
| `SensorType` (static constants) | TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION | SensorModel, SensorsScreen |
| `DataFormat` (static constants) | CSV_LINE, JSON_LINE, RAW_TEXT | SensorModel, AddSensorScreen |
| `AuditOutcome` (static constants) | SUCCESS, FAILURE, DENIED | AuditLogModel, PrivacyScreen |
| `MqttConnectionStatus` (Dart enum) | disconnected, connecting, connected, error | MqttServiceNotifier |
| `LoadingSize` (Dart enum) | small(16), medium(24), large(40) | LoadingIndicator |

---

## 8. Repository Layer

N/A — Flutter client. No local database or repository pattern. All data fetched via REST from server.

---

## 9. Service Layer — Full Method Signatures

### MyOffGridAIApiClient (lib/core/api/myoffgridai_api_client.dart)
Injects: Dio, SecureStorageService, Ref
```
- get<T>(String path, {Map<String,dynamic>? queryParams, T Function(dynamic)? fromJson}): Future<T>
- post<T>(String path, {dynamic data, T Function(dynamic)? fromJson}): Future<T>
- put<T>(String path, {dynamic data, T Function(dynamic)? fromJson}): Future<T>
- patch<T>(String path, {dynamic data, T Function(dynamic)? fromJson}): Future<T>
- delete(String path): Future<void>
- getBytes(String path): Future<List<int>>
- getStream(String path, {Map<String,dynamic>? queryParams, Duration? receiveTimeout}): Future<ResponseBody?>
- postStream(String path, {dynamic data, Duration? receiveTimeout}): Future<ResponseBody?>
- postMultipart<T>(String path, FormData formData, {T Function(dynamic)? fromJson}): Future<T>
- updateBaseUrl(String newBaseUrl): void
- refreshToken(): Future<bool>
```

### AuthService (lib/core/auth/auth_service.dart)
Injects: MyOffGridAIApiClient, SecureStorageService
```
- login(String username, String password): Future<AuthResponse>
- register({required String username, required String displayName, required String password, String? email, String role}): Future<AuthResponse>
- logout(): Future<void>
- refresh(): Future<AuthResponse>
- getCurrentUser(String userId): Future<UserModel>
```

### ChatService (lib/core/services/chat_service.dart)
Injects: MyOffGridAIApiClient
```
- listConversations({int page, int size, bool archived}): Future<List<ConversationSummaryModel>>
- createConversation({String? title}): Future<ConversationModel>
- getConversation(String conversationId): Future<ConversationModel>
- deleteConversation(String conversationId): Future<void>
- archiveConversation(String conversationId): Future<void>
- renameConversation(String conversationId, String title): Future<ConversationModel>
- searchConversations(String query): Future<List<ConversationSummaryModel>>
- listMessages(String conversationId, {int page, int size}): Future<List<MessageModel>>
- sendMessage(String conversationId, String content, {bool stream}): Future<MessageModel>
- sendMessageStream(String conversationId, String content): Stream<InferenceStreamEvent>
- editMessage(String conversationId, String messageId, String newContent): Future<MessageModel>
- deleteMessage(String conversationId, String messageId): Future<void>
- branchConversation(String conversationId, String messageId, {String? title}): Future<ConversationModel>
- regenerateMessage(String conversationId, String messageId): Stream<InferenceStreamEvent>
```

### ChatMessagesNotifier (lib/core/services/chat_messages_notifier.dart)
Injects: ChatService (via ref), aiThinkingProvider, conversationsProvider
```
- build(String conversationId): Future<List<MessageModel>>
- sendMessage(String content): Future<void>
- editMessage(String messageId, String newContent): Future<void>
- deleteMessage(String messageId): Future<void>
- regenerateMessage(String messageId): Future<void>
```

### DeviceRegistrationService (lib/core/services/device_registration_service.dart)
Injects: MyOffGridAIApiClient, SecureStorageService
```
- registerDevice(): Future<void>
- getRegisteredDevices(): Future<List<DeviceRegistrationModel>>
- unregisterDevice(String deviceId): Future<void>
```

### EnrichmentService (lib/core/services/enrichment_service.dart)
Injects: MyOffGridAIApiClient
```
- getExternalApiSettings(): Future<ExternalApiSettingsModel>
- updateExternalApiSettings(UpdateExternalApiSettingsRequest request): Future<ExternalApiSettingsModel>
- fetchUrl({required String url, bool summarizeWithClaude}): Future<KnowledgeDocumentModel>
- search({required String query, int storeTopN, bool summarizeWithClaude}): Future<record>
- getStatus(): Future<EnrichmentStatusModel>
```

### EventService (lib/core/services/event_service.dart)
Injects: MyOffGridAIApiClient
```
- listEvents({int page, int size}): Future<List<ScheduledEventModel>>
- getEvent(String eventId): Future<ScheduledEventModel>
- createEvent(Map<String,dynamic> body): Future<ScheduledEventModel>
- updateEvent(String eventId, Map<String,dynamic> body): Future<ScheduledEventModel>
- deleteEvent(String eventId): Future<void>
- toggleEvent(String eventId): Future<ScheduledEventModel>
```

### ForegroundServiceManager (lib/core/services/foreground_service_manager.dart)
Injects: none
```
- startService(): Future<void>
- stopService(): Future<void>
- isRunning: bool (getter)
```

### InsightService (lib/core/services/insight_service.dart)
Injects: MyOffGridAIApiClient
```
- listInsights({int page, int size, String? category}): Future<List<InsightModel>>
- generateInsights(): Future<List<InsightModel>>
- markAsRead(String insightId): Future<InsightModel>
- dismiss(String insightId): Future<InsightModel>
- getUnreadCount(): Future<int>
```

### InventoryService (lib/core/services/inventory_service.dart)
Injects: MyOffGridAIApiClient
```
- listItems({String? category}): Future<List<InventoryItemModel>>
- createItem({required String name, required String category, required double quantity, String? unit, String? notes, double? lowStockThreshold}): Future<InventoryItemModel>
- updateItem(String itemId, Map<String,dynamic> updates): Future<InventoryItemModel>
- deleteItem(String itemId): Future<void>
```

### KnowledgeService (lib/core/services/knowledge_service.dart)
Injects: MyOffGridAIApiClient
```
- listDocuments({int page, int size}): Future<List<KnowledgeDocumentModel>>
- getDocument(String documentId): Future<KnowledgeDocumentModel>
- uploadDocument(String filename, List<int> bytes): Future<KnowledgeDocumentModel>
- updateDisplayName(String documentId, String displayName): Future<KnowledgeDocumentModel>
- deleteDocument(String documentId): Future<void>
- retryProcessing(String documentId): Future<KnowledgeDocumentModel>
- search(String query, {int topK}): Future<List<KnowledgeSearchResultModel>>
- getDocumentContent(String documentId): Future<DocumentContentModel>
- downloadDocument(String documentId): Future<List<int>>
- createDocument({required String title, required String content}): Future<KnowledgeDocumentModel>
- updateDocumentContent(String documentId, String content): Future<KnowledgeDocumentModel>
```

### LibraryService (lib/core/services/library_service.dart)
Injects: MyOffGridAIApiClient
```
- listZimFiles(): Future<List<ZimFileModel>>
- uploadZimFile({required String filename, required List<int> bytes, required String displayName, String? category}): Future<ZimFileModel>
- deleteZimFile(String id): Future<void>
- getKiwixStatus(): Future<KiwixStatusModel>
- getKiwixUrl(): Future<String>
- listEbooks({String? search, String? format, int page, int size}): Future<List<EbookModel>>
- getEbook(String id): Future<EbookModel>
- uploadEbook({required String filename, required List<int> bytes, required String title, String? author}): Future<EbookModel>
- deleteEbook(String id): Future<void>
- downloadEbookContent(String id): Future<List<int>>
- searchGutenberg(String query, {int limit}): Future<GutenbergSearchResultModel>
- getGutenbergBook(int id): Future<GutenbergBookModel>
- importGutenbergBook(int gutenbergId): Future<EbookModel>
```

### LocalNotificationService (lib/core/services/local_notification_service.dart)
Injects: FlutterLocalNotificationsPlugin (optional)
```
- initialize(): Future<void>
- requestPermission(): Future<bool>
- showNotification({required int id, required String title, required String body, String? payload}): Future<void>
- showAlertNotification(NotificationModel notification): Future<void>
- isInitialized: bool (getter)
```

### MemoryService (lib/core/services/memory_service.dart)
Injects: MyOffGridAIApiClient
```
- listMemories({int page, int size, String? importance, String? tag}): Future<List<MemoryModel>>
- getMemory(String id): Future<MemoryModel>
- deleteMemory(String id): Future<void>
- updateTags(String id, String tags): Future<MemoryModel>
- updateImportance(String id, String importance): Future<MemoryModel>
- search(String query, {int topK}): Future<List<MemorySearchResultModel>>
- exportMemories(): Future<List<MemoryModel>>
```

### ModelCatalogService (lib/core/services/model_catalog_service.dart)
Injects: MyOffGridAIApiClient
```
- searchCatalog({required String query, String format, int limit}): Future<List<HfModelModel>>
- getModelDetails(String author, String modelId): Future<HfModelModel>
- getModelFiles(String author, String modelId): Future<List<HfModelFileModel>>
- startDownload({required String repoId, required String filename}): Future<Map<String,dynamic>>
- getAllDownloads(): Future<List<DownloadProgressModel>>
- streamDownloadProgress(String downloadId): Stream<DownloadProgressModel>
- cancelDownload(String downloadId): Future<void>
- listLocalModels(): Future<List<LocalModelFileModel>>
- deleteLocalModel(String filename): Future<void>
```

### MqttServiceNotifier (lib/core/services/mqtt_service.dart)
Injects: Ref (for SecureStorageService, LocalNotificationService, notificationsProvider)
```
- connect(String userId): Future<void>
- disconnect(): void
```

### NotificationService (lib/core/services/notification_service.dart)
Injects: MyOffGridAIApiClient
```
- listNotifications({bool unreadOnly, int page, int size}): Future<List<NotificationModel>>
- markAsRead(String notificationId): Future<NotificationModel>
- markAllAsRead(): Future<void>
- deleteNotification(String notificationId): Future<void>
- getUnreadCount(): Future<int>
```

### PrivacyService (lib/core/services/privacy_service.dart)
Injects: MyOffGridAIApiClient
```
- getFortressStatus(): Future<FortressStatusModel>
- enableFortress(): Future<void>
- disableFortress(): Future<void>
- getSovereigntyReport(): Future<SovereigntyReportModel>
- getAuditLogs({String? outcome, int page, int size}): Future<List<AuditLogModel>>
- wipeSelfData(): Future<WipeResultModel>
```

### SensorService (lib/core/services/sensor_service.dart)
Injects: MyOffGridAIApiClient
```
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
```

### SkillsService (lib/core/services/skills_service.dart)
Injects: MyOffGridAIApiClient
```
- listSkills(): Future<List<SkillModel>>
- getSkill(String skillId): Future<SkillModel>
- toggleSkill(String skillId, bool enabled): Future<SkillModel>
- executeSkill(String skillId, {Map<String,dynamic>? params}): Future<SkillExecutionModel>
- listExecutions({int page, int size}): Future<List<SkillExecutionModel>>
```

### SystemService (lib/core/services/system_service.dart)
Injects: MyOffGridAIApiClient
```
- getSystemStatus(): Future<SystemStatusModel>
- listModels(): Future<List<OllamaModelInfoModel>>
- getActiveModel(): Future<ActiveModelInfo>
- getAiSettings(): Future<AiSettingsModel>
- getStorageSettings(): Future<StorageSettingsModel>
- updateStorageSettings(StorageSettingsModel settings): Future<StorageSettingsModel>
- updateAiSettings(AiSettingsModel settings): Future<AiSettingsModel>
```

### UserService (lib/core/services/user_service.dart)
Injects: MyOffGridAIApiClient
```
- listUsers({int page, int size}): Future<List<UserModel>>
- getUser(String userId): Future<UserDetailModel>
- updateUser(String userId, {String? displayName, String? email, String? role}): Future<UserDetailModel>
- deactivateUser(String userId): Future<void>
- deleteUser(String userId): Future<void>
```

---

## 10. Controller / API Layer — Method Signatures Only

N/A — Flutter client. No controllers. All API calls are in service classes (Section 9). Feature screens consume services via Riverpod providers.

---

## 11. Security Configuration

```
Authentication:    JWT Bearer token (access + refresh)
Token issuer:      MyOffGridAI-Server (external)
Token storage:     FlutterSecureStorage (iOS Keychain, Android EncryptedSharedPreferences)
                   + in-memory cache fallback for web

Token lifecycle:
  - Login/Register → server returns accessToken + refreshToken
  - Stored via SecureStorageService.saveTokens()
  - Attached to requests by _AuthInterceptor (Dio interceptor)
  - On 401: single refresh attempt via /api/auth/refresh
  - On refresh failure: clearTokens() + user returned to login

Route protection:
  - GoRouter redirect: unauthenticated users → /login
  - /users route: ROLE_OWNER or ROLE_ADMIN only
  - Logged-in users redirected from /login and /register to /

CORS: N/A (client-side)
CSRF: N/A (client-side)
Rate limiting: N/A (server-side concern)
```

---

## 12. Custom Security Components

### _AuthInterceptor (lib/core/api/myoffgridai_api_client.dart)
- Extends: `Interceptor` (Dio)
- Attaches `Authorization: Bearer <token>` to all requests
- Skips auth for requests with `_skipAuth: true` header
- On 401: attempts single token refresh, retries original request
- Never retries `/auth/refresh` or `/auth/login` paths
- On refresh failure: clears tokens

### _LoggingInterceptor (lib/core/api/myoffgridai_api_client.dart)
- Debug-only (kDebugMode)
- Logs HTTP method + path (request) and status code (response)
- Never logs Authorization headers or request bodies

### AuthNotifier (lib/core/auth/auth_state.dart)
- Decodes JWT payload locally (no network call) on startup
- Checks token expiry; attempts refresh if expired
- Extracts userId, username, displayName, role from JWT claims

---

## 13. Exception Handling & Error Responses

### ApiException (lib/core/api/api_exception.dart)
```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
}
```

**Error handling pattern:**
- DioException with response → extracts `message` and `errors` from response body
- Connection/receive timeout → statusCode 408, "Connection timed out"
- No response → statusCode 0, "Cannot reach MyOffGrid AI server"

**No global exception handler on client.** Each screen catches ApiException and displays via SnackBar.

---

## 14. Mappers / DTOs

No mapper framework (MapStruct, etc.). All mapping is manual via `fromJson` factory constructors and `toJson` methods. See Section 6 for complete field mappings.

---

## 15. Utility Classes & Shared Components

### DateFormatter (lib/shared/utils/date_formatter.dart)
```
- formatRelative(DateTime): String → "just now", "X minutes ago", "Yesterday", "Mar 14"
- formatFull(DateTime): String → "March 14, 2026 at 3:45 PM"
- formatDate(DateTime): String → "Mar 14, 2026"
```
Used by: NavigationPanel, MemoryScreen, NotificationsScreen, various detail screens

### SizeFormatter (lib/shared/utils/size_formatter.dart)
```
- formatBytes(int bytes): String → "1.2 MB", "340 KB"
```
Used by: HfModelFileModel, KnowledgeScreen, SystemScreen

### PlatformUtils (lib/shared/utils/platform_utils.dart)
```
- isWeb: bool
- isMobile: bool
- isTablet(BuildContext): bool (600-1200px)
- isMobileWidth(BuildContext): bool (<600px)
- isDesktopWidth(BuildContext): bool (>=1200px)
```
Used by: AppShell (adaptive navigation), various responsive layouts

### DownloadUtils (lib/shared/utils/download_utils.dart)
```
- downloadBytes(List<int> bytes, String filename): void → web-only browser download via data URI
```
Uses conditional import: download_trigger_stub.dart (native no-op) / download_trigger_web.dart (dart:html anchor)

### Shared Widgets

| Widget | Type | Purpose |
|---|---|---|
| AppShell | ConsumerStatefulWidget | Top-level scaffold with adaptive nav (BottomNavigationBar mobile, NavigationPanel desktop) |
| NavigationPanel | ConsumerStatefulWidget | Claude-style collapsible sidebar with nav items, conversation list, search, settings |
| ConnectionLostBanner | ConsumerWidget | Amber banner when server unreachable |
| SystemStatusBar | ConsumerWidget | Persistent bar with model health, model switcher, notification count |
| ConfirmationDialog | StatelessWidget | Reusable confirm/cancel dialog with destructive mode |
| EmptyStateView | StatelessWidget | Empty list placeholder with icon, title, subtitle |
| ErrorView | StatelessWidget | Error display with retry button |
| LoadingIndicator | StatelessWidget | Configurable spinner (small/medium/large) with label |
| NotificationBadge | StatelessWidget | Red circle badge overlay with count |

---

## 16. Database Schema (Live)

N/A — Flutter client. No local database. Server manages all persistence.

---

## 17. Message Broker Configuration

```
Broker:    MQTT (Mosquitto on server)
Library:   mqtt_client ^10.2.1
Port:      1883 (configurable via server URL host)
Client ID: myoffgridai-flutter-<deviceId>
Keep Alive: 60 seconds
Reconnect: Auto with 5-second delay

Topics:
  - /myoffgridai/<userId>/notifications → User-specific notifications
  - /myoffgridai/broadcast → System-wide broadcasts

Consumer: MqttServiceNotifier (lib/core/services/mqtt_service.dart)
  - Deserializes JSON messages to NotificationModel
  - Dispatches to LocalNotificationService.showAlertNotification()
  - Invalidates notificationsProvider for UI refresh
```

---

## 18. Cache Layer

No Redis or dedicated caching layer. In-memory cache in `SecureStorageService` for tokens and preferences. Riverpod `autoDispose` providers serve as the de facto data cache, refetching when watched screens mount.

---

## 19. Environment Variable Inventory

N/A — Flutter client. No environment variables. Configuration is compile-time constants in `lib/config/constants.dart`. Server URL is user-configurable at runtime via the login screen.

---

## 20. Service Dependency Map

```
MyOffGridAI-Client → MyOffGridAI-Server
  REST API: http(s)://<server>:8080/api/**
  SSE Streaming: POST /api/chat/conversations/{id}/messages/stream
  SSE Streaming: GET /api/models/downloads/{id}/progress
  MQTT: tcp://<server>:1883

MyOffGridAI-Client → Kiwix Serve (via server)
  WebView: http://<server>:8888

Downstream Consumers: None (end-user client)
```

---

## 21. Known Technical Debt & Issues

### TODO/PLACEHOLDER/STUB Scan

**PASS — 0 actual TODOs, FIXMEs, or stubs found.** Grep hits were false positives (string constants containing "TEMPERATURE", "stub" in conditional import filename).

### Issues

| Issue | Location | Severity | Notes |
|---|---|---|---|
| Deprecated dart:html import | lib/shared/utils/download_trigger_web.dart:2 | Medium | Should migrate to package:web + dart:js_interop |
| Deprecated Flutter Quill `.value` property | lib/features/settings/settings_screen.dart:2001 | Low | Use `initialValue` instead (deprecated after v3.33.0) |
| use_build_context_synchronously | lib/features/knowledge/knowledge_screen.dart:226 | Low | BuildContext used across async gap with unrelated mounted check |
| 13 use_null_aware_elements hints | Various service files | Low | Could use null-aware `?` marker in collection literals |
| 1 unnecessary_import in test | test/core/api/myoffgridai_api_client_test.dart:7 | Low | Unused mocktail import |
| Test coverage at 85.1% | Project-wide | Medium | Below 100% mandatory threshold — BLOCKING |
| No CI/CD pipeline | Project root | Medium | No GitHub Actions, Jenkins, or GitLab CI detected |

---

## 22. Security Vulnerability Scan (Snyk)

```
Scan Date: 2026-03-17
Snyk CLI Version: 1.1303.0

### Dependency Vulnerabilities (Open Source)
SKIPPED — Snyk does not support Flutter/Dart dependency scanning.
Snyk returned: "No supported files found (SNYK-CLI-0008)"

### Code Vulnerabilities (SAST)
SKIPPED — Snyk Code not enabled for the organization.
Snyk returned: "Snyk Code is not enabled (SNYK-CODE-0005)"

### Flutter Static Analysis (flutter analyze)
Errors: 0
Warnings: 1 (unused import in test file)
Info: 20 (deprecated APIs, null-aware element suggestions, async context usage)
```

---

## Riverpod Provider Registry

| Provider | Type | Source File |
|---|---|---|
| `secureStorageProvider` | Provider<SecureStorageService> | secure_storage_service.dart |
| `apiClientProvider` | Provider<MyOffGridAIApiClient> | myoffgridai_api_client.dart |
| `localNotificationServiceProvider` | Provider<LocalNotificationService> | local_notification_service.dart |
| `routerProvider` | Provider<GoRouter> | router.dart |
| `themeProvider` | StateNotifierProvider<ThemeNotifier, ThemeMode> | theme.dart |
| `authServiceProvider` | Provider<AuthService> | auth_service.dart |
| `authStateProvider` | AsyncNotifierProvider<AuthNotifier, UserModel?> | auth_state.dart |
| `systemStatusProvider` | FutureProvider.autoDispose<SystemStatusDto> | providers.dart |
| `modelHealthProvider` | FutureProvider.autoDispose<OllamaHealthDto> | providers.dart |
| `unreadCountProvider` | FutureProvider.autoDispose<int> | providers.dart |
| `connectionStatusProvider` | StreamProvider.autoDispose<bool> | providers.dart |
| `serverUrlProvider` | FutureProvider<String> | providers.dart |
| `chatServiceProvider` | Provider<ChatService> | chat_service.dart |
| `conversationsProvider` | FutureProvider.autoDispose<List<ConversationSummaryModel>> | chat_service.dart |
| `messagesProvider` | FutureProvider.autoDispose.family<List<MessageModel>, String> | chat_service.dart |
| `aiThinkingProvider` | StateProvider.autoDispose.family<bool, String> | chat_service.dart |
| `sidebarCollapsedProvider` | StateProvider<bool> | chat_service.dart |
| `chatMessagesNotifierProvider` | AsyncNotifierProvider.family<..., List<MessageModel>, String> | chat_messages_notifier.dart |
| `deviceRegistrationServiceProvider` | Provider<DeviceRegistrationService> | device_registration_service.dart |
| `enrichmentServiceProvider` | Provider<EnrichmentService> | enrichment_service.dart |
| `enrichmentStatusProvider` | FutureProvider.autoDispose<EnrichmentStatusModel> | enrichment_service.dart |
| `externalApiSettingsProvider` | FutureProvider.autoDispose<ExternalApiSettingsModel> | enrichment_service.dart |
| `eventServiceProvider` | Provider<EventService> | event_service.dart |
| `eventsListProvider` | FutureProvider.autoDispose<List<ScheduledEventModel>> | event_service.dart |
| `foregroundServiceManagerProvider` | Provider<ForegroundServiceManager> | foreground_service_manager.dart |
| `insightServiceProvider` | Provider<InsightService> | insight_service.dart |
| `insightsProvider` | FutureProvider.autoDispose<List<InsightModel>> | insight_service.dart |
| `inventoryServiceProvider` | Provider<InventoryService> | inventory_service.dart |
| `inventoryProvider` | FutureProvider.autoDispose<List<InventoryItemModel>> | inventory_service.dart |
| `knowledgeServiceProvider` | Provider<KnowledgeService> | knowledge_service.dart |
| `knowledgeDocumentsProvider` | FutureProvider.autoDispose<List<KnowledgeDocumentModel>> | knowledge_service.dart |
| `documentContentProvider` | FutureProvider.autoDispose.family<DocumentContentModel, String> | knowledge_service.dart |
| `libraryServiceProvider` | Provider<LibraryService> | library_service.dart |
| `zimFilesProvider` | FutureProvider.autoDispose<List<ZimFileModel>> | library_service.dart |
| `ebooksProvider` | FutureProvider.autoDispose.family<List<EbookModel>, record> | library_service.dart |
| `kiwixStatusProvider` | FutureProvider.autoDispose<KiwixStatusModel> | library_service.dart |
| `kiwixUrlProvider` | FutureProvider.autoDispose<String> | library_service.dart |
| `memoryServiceProvider` | Provider<MemoryService> | memory_service.dart |
| `memoriesProvider` | FutureProvider.autoDispose<List<MemoryModel>> | memory_service.dart |
| `modelCatalogServiceProvider` | Provider<ModelCatalogService> | model_catalog_service.dart |
| `localModelsProvider` | FutureProvider.autoDispose<List<LocalModelFileModel>> | model_catalog_service.dart |
| `activeDownloadsProvider` | FutureProvider.autoDispose<List<DownloadProgressModel>> | model_catalog_service.dart |
| `mqttServiceProvider` | StateNotifierProvider<MqttServiceNotifier, MqttState> | mqtt_service.dart |
| `notificationServiceProvider` | Provider<NotificationService> | notification_service.dart |
| `notificationsProvider` | FutureProvider.autoDispose<List<NotificationModel>> | notification_service.dart |
| `notificationsUnreadCountProvider` | StreamProvider.autoDispose<int> | notification_service.dart |
| `privacyServiceProvider` | Provider<PrivacyService> | privacy_service.dart |
| `fortressStatusProvider` | FutureProvider.autoDispose<FortressStatusModel> | privacy_service.dart |
| `sensorServiceProvider` | Provider<SensorService> | sensor_service.dart |
| `sensorsProvider` | FutureProvider.autoDispose<List<SensorModel>> | sensor_service.dart |
| `skillsServiceProvider` | Provider<SkillsService> | skills_service.dart |
| `skillsProvider` | FutureProvider.autoDispose<List<SkillModel>> | skills_service.dart |
| `systemServiceProvider` | Provider<SystemService> | system_service.dart |
| `systemStatusDetailProvider` | FutureProvider.autoDispose<SystemStatusModel> | system_service.dart |
| `ollamaModelsProvider` | FutureProvider.autoDispose<List<OllamaModelInfoModel>> | system_service.dart |
| `aiSettingsProvider` | FutureProvider.autoDispose<AiSettingsModel> | system_service.dart |
| `storageSettingsProvider` | FutureProvider.autoDispose<StorageSettingsModel> | system_service.dart |
| `userServiceProvider` | Provider<UserService> | user_service.dart |
| `usersListProvider` | FutureProvider.autoDispose<List<UserModel>> | user_service.dart |
