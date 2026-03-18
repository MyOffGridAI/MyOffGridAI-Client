# MyOffGridAI-Client — Codebase Audit

**Audit Date:** 2026-03-18T18:20:09Z
**Branch:** main
**Commit:** a3cf2693bec00c2b6457df0fcde7779fcdee2de4 Add centralized file-based logging for client — replace all debugPrint with LogService
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
Project Name:       MyOffGridAI-Client
Description:        MyOffGrid AI — Your world, remembered.
Repository URL:     https://github.com/MyOffGridAI/MyOffGridAI-Client (inferred)
Primary Language:   Dart / Flutter
Dart SDK Version:   ^3.11.0 (actual: 3.11.0)
Flutter Version:    3.41.1 (stable channel)
Build Tool:         Flutter CLI / pub
Current Branch:     main
Latest Commit:      a3cf2693bec00c2b6457df0fcde7779fcdee2de4
Latest Message:     Add centralized file-based logging for client — replace all debugPrint with LogService
Audit Timestamp:    2026-03-18T18:20:14Z
```


## 2. Directory Structure

```
lib/
├── config/                   ← App configuration (constants, router, theme)
│   ├── constants.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── api/                  ← HTTP client, API response/exception models, DI providers
│   │   ├── api_exception.dart
│   │   ├── api_response.dart
│   │   ├── myoffgridai_api_client.dart
│   │   └── providers.dart
│   ├── auth/                 ← Authentication service, state, secure storage
│   │   ├── auth_service.dart
│   │   ├── auth_state.dart
│   │   └── secure_storage_service.dart
│   ├── models/               ← Data models (20 model files)
│   │   ├── conversation_model.dart
│   │   ├── device_registration_model.dart
│   │   ├── enrichment_models.dart
│   │   ├── event_model.dart
│   │   ├── inference_stream_event.dart
│   │   ├── insight_model.dart
│   │   ├── inventory_item_model.dart
│   │   ├── judge_models.dart
│   │   ├── knowledge_document_model.dart
│   │   ├── library_models.dart
│   │   ├── memory_model.dart
│   │   ├── message_model.dart
│   │   ├── model_catalog_models.dart
│   │   ├── notification_model.dart
│   │   ├── page_response.dart
│   │   ├── privacy_models.dart
│   │   ├── sensor_model.dart
│   │   ├── skill_model.dart
│   │   ├── system_models.dart
│   │   └── user_model.dart
│   └── services/             ← Business logic services (22 service files)
│       ├── chat_messages_notifier.dart
│       ├── chat_service.dart
│       ├── device_registration_service.dart
│       ├── enrichment_service.dart
│       ├── event_service.dart
│       ├── foreground_service_manager.dart
│       ├── insight_service.dart
│       ├── inventory_service.dart
│       ├── judge_service.dart
│       ├── knowledge_service.dart
│       ├── library_service.dart
│       ├── local_notification_service.dart
│       ├── log_service.dart
│       ├── memory_service.dart
│       ├── model_catalog_service.dart
│       ├── mqtt_service.dart
│       ├── notification_service.dart
│       ├── privacy_service.dart
│       ├── sensor_service.dart
│       ├── skills_service.dart
│       ├── system_service.dart
│       └── user_service.dart
├── features/                 ← Feature screens organized by domain
│   ├── auth/                 ← Login, Register, Users, Device Setup screens
│   ├── books/                ← Book reader (EPUB/PDF)
│   ├── chat/                 ← Chat UI (conversation, list, widgets)
│   ├── events/               ← Event management
│   ├── insights/             ← AI insights
│   ├── inventory/            ← Inventory management
│   ├── knowledge/            ← Knowledge base (docs, editor)
│   ├── memory/               ← Memory browser
│   ├── notifications/        ← Notifications
│   ├── privacy/              ← Privacy controls
│   ├── search/               ← Global search
│   ├── sensors/              ← IoT sensor management
│   ├── settings/             ← Settings & model catalog
│   ├── skills/               ← AI skills management
│   └── system/               ← System monitoring
├── shared/
│   ├── utils/                ← Date formatter, download utils, platform utils, size formatter
│   └── widgets/              ← Shared UI: AppShell, navigation, banners, dialogs, loading
└── main.dart                 ← App entry point

test/                         ← Mirrors lib/ structure exactly (1:1 test coverage)
web/                          ← Web target (index.html, manifest.json)
```

**Summary:** Single-module Flutter application. Source code under `lib/` follows a feature-first architecture with shared `core/` (API, auth, models, services) and `shared/` (utils, widgets) layers. Every `lib/` file has a corresponding `test/` file.


## 3. Build & Dependency Manifest

**Build file:** `pubspec.yaml`

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter (sdk) | 3.41.1 | UI framework |
| flutter_localizations (sdk) | 3.41.1 | i18n support |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| dio | ^5.7.0 | HTTP client |
| go_router | ^14.8.1 | Declarative routing |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod code generation annotations |
| flutter_secure_storage | ^9.2.4 | Encrypted key-value storage (tokens) |
| fl_chart | ^0.70.2 | Chart/graph widgets |
| file_picker | ^8.3.7 | Native file picker |
| desktop_drop | ^0.4.4 | Drag-and-drop file support |
| cross_file | ^0.3.5+2 | Cross-platform file abstraction |
| intl | ^0.20.2 | Date/number formatting, i18n |
| flutter_quill | ^11.4.0 | Rich text editor |
| mqtt_client | ^10.2.1 | MQTT protocol client (IoT/realtime) |
| flutter_local_notifications | ^17.2.3 | Local push notifications |
| flutter_foreground_task | ^8.13.0 | Background/foreground task management |
| permission_handler | ^11.3.1 | Runtime permission requests |
| webview_flutter | ^4.10.0 | WebView widget |
| webview_flutter_android | ^4.3.0 | Android WebView implementation |
| webview_flutter_wkwebview | ^3.18.0 | iOS WebView implementation |
| epub_view | ^3.2.0 | EPUB reader widget |
| pdfx | ^2.9.0 | PDF viewer widget |
| path_provider | ^2.1.5 | Platform file path resolution |
| open_filex | ^4.6.0 | Open files with system apps |
| cached_network_image | ^3.4.1 | Image caching from network |
| flutter_markdown | ^0.7.4+3 | Markdown rendering |
| markdown | ^7.3.0 | Markdown parsing |
| flutter_highlight | ^0.7.0 | Syntax highlighting for code blocks |
| highlight | ^0.7.0 | Syntax highlighting engine |

### Dev Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter_test (sdk) | — | Widget/unit testing framework |
| flutter_lints | ^6.0.0 | Lint rules |
| build_runner | ^2.4.15 | Code generation runner |
| riverpod_generator | ^2.6.3 | Riverpod provider code generation |
| mockito | ^5.4.6 | Mock generation for testing |
| mocktail | ^1.0.4 | Lightweight mocking for testing |

### Build Commands

```
Build:    flutter build apk / flutter build ios / flutter build web
Test:     flutter test
Run:      flutter run
Package:  flutter build apk --release
```


## 4. Configuration & Infrastructure Summary

### Configuration Files

- **`pubspec.yaml`** — Package manifest. Dart SDK ^3.11.0, Flutter stable. All dependencies listed in Section 3.
- **`analysis_options.yaml`** — Uses `package:flutter_lints/flutter.yaml`. Disables `unnecessary_underscores` rule.
- **`lib/config/constants.dart`** — Centralized constants. Server URL, API paths, timeouts, storage keys, MQTT config, pagination defaults, UI breakpoints, notification channels, validation rules.
- **`web/index.html`** — Web target entry point. Loads PDF.js CDN (v4.6.82) for PDF rendering. Flutter bootstrap script.
- **`web/manifest.json`** — PWA manifest.
- **`.vscode/launch.json`** — VS Code debug configuration.

### Key Configuration Facts

- **Server URL (Web):** `http://localhost:8080` — Web runs on dev machine via localhost
- **Server URL (Native):** `http://offgrid.local:8080` — Native apps connect over LAN to appliance
- **Connect Timeout:** 10 seconds
- **Receive Timeout:** 120 seconds
- **SSE Timeout:** 5 minutes
- **MQTT Port:** 1883 (standard, unencrypted)
- **MQTT Topic Prefix:** `/myoffgridai/`
- **Kiwix Port:** 8888 (offline library)
- **Pagination:** Default 20, max 100

### Connection Map

```
Server API:     HTTP REST — http://localhost:8080 (web) / http://offgrid.local:8080 (native)
MQTT Broker:    mqtt://offgrid.local:1883 (IoT sensors, broadcast events)
Kiwix Server:   http://<server>:8888 (offline Wikipedia/reference)
External APIs:  None directly from client — all proxied through server
Cloud Services: None — fully offline/local by design
```

### CI/CD

None detected. No `.github/workflows`, `Jenkinsfile`, or `.gitlab-ci.yml` present.


## 5. Startup & Runtime Behavior

### Entry Point

`lib/main.dart` → `main()` function

### Startup Sequence

1. `WidgetsFlutterBinding.ensureInitialized()` — Required for async init before `runApp`
2. `LogService().initialize()` — File-based centralized logging
3. `SecureStorageService()` — Encrypted key-value store (tokens, server URL)
4. `storage.getServerUrl()` — Resolves the server URL from secure storage
5. `LocalNotificationService().initialize()` — Local push notification setup
6. `ProviderScope` with overrides — Injects LogService, SecureStorage, LocalNotifications, and ApiClient into Riverpod DI
7. `MyOffGridAIApp` — Root widget with `MaterialApp.router`, GoRouter, light/dark theme

### Background Services

- **MQTT Service** — Persistent connection to MQTT broker for real-time sensor data and broadcasts
- **Foreground Service Manager** — Manages Android foreground service for persistent MQTT connection
- **Connection polling** — Periodic health checks (10s interval)
- **Notification polling** — Periodic notification fetch (30s interval)
- **Model health polling** — Periodic AI model status check (60s interval)

### Health Check

No dedicated health check endpoint on the client. Server health is checked via API connectivity.


## 6. Data Model Layer

All models are client-side DTOs mirroring server entities. No local database — all data persisted on server. All models use `factory fromJson()` constructors for JSON deserialization.

### conversation_model.dart
- **ConversationModel** — id(String), title(String?), isArchived(bool), messageCount(int), createdAt(String?), updatedAt(String?)
- **ConversationSummaryModel** — id, title, isArchived, messageCount, updatedAt, lastMessagePreview(String?)

### device_registration_model.dart
- **DeviceRegistrationModel** — id, deviceId, deviceName, platform, mqttClientId, lastSeenAt(String?)

### enrichment_models.dart
- **ExternalApiSettingsModel** — anthropicEnabled(bool), anthropicModel(String), anthropicKeyConfigured(bool), braveEnabled(bool), braveKeyConfigured(bool), huggingFaceEnabled(bool), huggingFaceKeyConfigured(bool), maxWebFetchSizeKb(int), searchResultLimit(int), grokEnabled(bool), grokKeyConfigured(bool), openAiEnabled(bool), openAiKeyConfigured(bool), preferredFrontierProvider(String?), judgeEnabled(bool), judgeModelFilename(String?), judgeScoreThreshold(double)
- **UpdateExternalApiSettingsRequest** — Has toJson(). Nullable key fields: anthropicApiKey, braveApiKey, huggingFaceToken, grokApiKey, openAiApiKey. Null = preserve existing, empty string = clear.
- **SearchResultModel** — title, url, description, publishedDate(String?)
- **EnrichmentStatusModel** — claudeAvailable(bool), braveAvailable(bool), maxWebFetchSizeKb(int), searchResultLimit(int)

### event_model.dart
- **ScheduledEventModel** — id, userId(String?), name, description(String?), eventType(String), isEnabled(bool), cronExpression(String?), recurringIntervalMinutes(int?), sensorId(String?), thresholdOperator(String?), thresholdValue(double?), actionType(String), actionPayload(String), lastTriggeredAt(String?), nextFireAt(String?), createdAt(String?), updatedAt(String?). Has toJson().
- **EventType** — SCHEDULED, SENSOR_THRESHOLD, RECURRING
- **ActionType** — PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY
- **ThresholdOperator** — ABOVE, BELOW, EQUALS

### inference_stream_event.dart
- **InferenceEventType** (enum) — thinking, content, done, error, judgeEvaluating, judgeResult, enhancedContent, enhancedDone
- **InferenceMetadata** — tokensGenerated(int), tokensPerSecond(double), inferenceTimeSeconds(double), stopReason(String?), thinkingTokenCount(int?)
- **InferenceStreamEvent** — type(InferenceEventType), content(String?), metadata(InferenceMetadata?), messageId(String?). Parses SSE JSON with snake_case type mapping.

### insight_model.dart
- **InsightModel** — id, content, category(String), isRead(bool), isDismissed(bool), generatedAt(String?), readAt(String?)
- **InsightCategory** — SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING

### inventory_item_model.dart
- **InventoryItemModel** — id, name, category(String), quantity(double), unit(String?), notes(String?), lowStockThreshold(double?), createdAt(String?), updatedAt(String?). Computed: isLowStock.
- **InventoryCategory** — FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER

### judge_models.dart
- **JudgeStatusModel** — enabled(bool), processRunning(bool), judgeModelFilename(String?), port(int), scoreThreshold(double)
- **JudgeTestResultModel** — score(double), reason(String?), needsCloud(bool), judgeAvailable(bool), error(String?)

### knowledge_document_model.dart
- **KnowledgeDocumentModel** — id, filename, displayName(String?), mimeType(String?), fileSizeBytes(int), status(String), errorMessage(String?), chunkCount(int), uploadedAt(String?), processedAt(String?), hasContent(bool), editable(bool). Computed: isProcessing, isIndexed, isFailed. Status enum: PENDING, PROCESSING, INDEXED, FAILED.
- **DocumentContentModel** — documentId, title, content(String?), mimeType(String?), editable(bool)
- **KnowledgeSearchResultModel** — chunkId, documentId, documentName, content, pageNumber(int?), chunkIndex(int), similarityScore(double)

### library_models.dart
- **ZimFileModel** — id, filename, displayName(String?), description(String?), language(String?), category(String?), fileSizeBytes(int), articleCount(int), mediaCount(int), createdDate(String?), kiwixBookId(String?), uploadedAt(String?), uploadedBy(String?)
- **EbookModel** — id, title, author(String?), description(String?), isbn(String?), publisher(String?), publishedYear(String?), language(String?), format(String), fileSizeBytes(int), gutenbergId(String?), downloadCount(int), hasCoverImage(bool), uploadedAt(String?), uploadedBy(String?). Computed: isFromGutenberg.
- **KiwixStatusModel** — available(bool), url(String?), bookCount(int)
- **GutenbergBookModel** — id(int), title, authors(List<String>), subjects(List<String>), languages(List<String>), downloadCount(int), formats(Map<String,String>). Computed: hasEpub.
- **GutenbergSearchResultModel** — count(int), next(String?), previous(String?), results(List<GutenbergBookModel>)

### memory_model.dart
- **MemoryModel** — id, content, importance(String), tags(String?), sourceConversationId(String?), createdAt(String?), updatedAt(String?), lastAccessedAt(String?), accessCount(int). Computed: tagList. Importance: LOW, MEDIUM, HIGH, CRITICAL.
- **MemorySearchResultModel** — memory(MemoryModel), similarityScore(double)

### message_model.dart
- **MessageModel** — id, role(String), content, tokenCount(int?), hasRagContext(bool), thinkingContent(String?), tokensPerSecond(double?), inferenceTimeSeconds(double?), stopReason(String?), thinkingTokenCount(int?), sourceTag(String?), judgeScore(double?), judgeReason(String?), createdAt(String?). Has copyWith(). Computed: isUser, isAssistant, isEnhanced, hasJudgeScore. Role: USER, ASSISTANT, SYSTEM.

### model_catalog_models.dart
- **HfModelModel** — id, author, modelId, downloads(int), likes(int), tags(List<String>), isGated(bool), lastModified(DateTime?), files(List<HfModelFileModel>). Computed: hasGguf, hasMlx, ggufFiles.
- **HfModelFileModel** — filename, sizeBytes(int?), isRecommended(bool), qualityLabel(String?), qualityRank(int?), estimatedRamBytes(int?), quantizationType(String?). Computed: quantLabel, formattedSize, estimatedRamMb, fitsInRam.
- **DownloadProgressModel** — downloadId, repoId, filename, status, bytesDownloaded(int), totalBytes(int), percentComplete(double), speedBytesPerSecond(double), estimatedSecondsRemaining(int), errorMessage(String?). Computed: isActive, isComplete, isFailed, isCancelled. Status: DOWNLOADING, QUEUED, COMPLETED, FAILED, CANCELLED.
- **LocalModelFileModel** — filename, repoId(String?), format, sizeBytes(int), lastModified(DateTime?), isCurrentlyLoaded(bool).

### notification_model.dart
- **NotificationModel** — id, title, body, type(String), severity(String), isRead(bool), createdAt(String?), readAt(String?), metadata(String?). Type: SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL. Severity: INFO, WARNING, CRITICAL.
- **NotificationType** — Constants class
- **NotificationSeverity** — Constants class

### page_response.dart
- **PageResponse\<T\>** — Generic paginated response. content(List<T>), totalElements(int), totalPages(int), number(int), size(int), first(bool), last(bool), empty(bool). Factory takes itemFactory function.

### privacy_models.dart
- **FortressStatusModel** — enabled(bool), enabledAt(String?), enabledByUsername(String?), verified(bool)
- **DataInventoryModel** — conversationCount, messageCount, memoryCount, knowledgeDocumentCount, sensorCount, insightCount (all int)
- **AuditSummaryModel** — successCount, failureCount, deniedCount (all int), windowStart(String?), windowEnd(String?)
- **SovereigntyReportModel** — generatedAt(String?), fortressStatus(FortressStatusModel?), outboundTrafficVerification(String?), dataInventory(DataInventoryModel?), auditSummary(AuditSummaryModel?), encryptionStatus(String?), telemetryStatus(String?), lastVerifiedAt(String?)
- **AuditLogModel** — id, userId(String?), username(String?), action, resourceType(String?), resourceId(String?), httpMethod(String?), requestPath(String?), outcome(String), responseStatus(int?), durationMs(int?), timestamp(String?)
- **WipeResultModel** — targetUserId(String?), stepsCompleted(int), completedAt(String?), success(bool)
- **AuditOutcome** — SUCCESS, FAILURE, DENIED

### sensor_model.dart
- **SensorModel** — id, name, type(String), portPath(String?), baudRate(int), dataFormat(String?), valueField(String?), unit(String?), isActive(bool), pollIntervalSeconds(int), lowThreshold(double?), highThreshold(double?), createdAt(String?), updatedAt(String?)
- **SensorReadingModel** — id, sensorId, value(double), rawData(String?), recordedAt(String?)
- **SensorTestResultModel** — success(bool), portPath, baudRate(int), sampleData(String?), message
- **SensorType** — TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION
- **DataFormat** — CSV_LINE, JSON_LINE, RAW_TEXT

### skill_model.dart
- **SkillModel** — id, name, displayName, description(String?), version(String?), author(String?), category(String?), isEnabled(bool), isBuiltIn(bool), parametersSchema(String?), createdAt(String?), updatedAt(String?)
- **SkillExecutionModel** — id, skillId, skillName, userId(String?), status(String), inputParams(String?), outputResult(String?), errorMessage(String?), startedAt(String?), completedAt(String?), durationMs(int?). Computed: isRunning, isSuccess, isFailed. Status: RUNNING, SUCCESS, FAILED, PENDING.

### system_models.dart
- **SystemStatusModel** — initialized(bool), instanceName(String?), fortressEnabled(bool), wifiConfigured(bool), serverVersion(String?), timestamp(String?)
- **OllamaModelInfoModel** — name, size(int), modifiedAt(String?)
- **AiSettingsModel** — modelName, temperature(double=0.7), similarityThreshold(double=0.45), memoryTopK(int=5), ragMaxContextTokens(int=2048), contextSize(int=4096), contextMessageLimit(int=20). Has toJson().
- **StorageSettingsModel** — knowledgeStoragePath, totalSpaceMb, usedSpaceMb, freeSpaceMb, maxUploadSizeMb(int=25). Has toJson().
- **ActiveModelInfo** — modelName(String?), embedModelName(String?)

### user_model.dart
- **UserModel** — id, username, displayName, role(String), isActive(bool). Has toJson(). Role: ROLE_MEMBER, ROLE_ADMIN.


## 7. Enum Inventory

Dart enums and enum-like constant classes are co-located with their models. Summary:

| Enum/Constants Class | Values | Used In |
|---|---|---|
| InferenceEventType (enum) | thinking, content, done, error, judgeEvaluating, judgeResult, enhancedContent, enhancedDone | InferenceStreamEvent |
| EventType | SCHEDULED, SENSOR_THRESHOLD, RECURRING | ScheduledEventModel.eventType |
| ActionType | PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY | ScheduledEventModel.actionType |
| ThresholdOperator | ABOVE, BELOW, EQUALS | ScheduledEventModel.thresholdOperator |
| InsightCategory | SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING | InsightModel.category |
| InventoryCategory | FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER | InventoryItemModel.category |
| SensorType | TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION | SensorModel.type |
| DataFormat | CSV_LINE, JSON_LINE, RAW_TEXT | SensorModel.dataFormat |
| NotificationType | SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL | NotificationModel.type |
| NotificationSeverity | INFO, WARNING, CRITICAL | NotificationModel.severity |
| AuditOutcome | SUCCESS, FAILURE, DENIED | AuditLogModel.outcome |

All enum-like classes have `label()` methods for UI display where applicable.


## 8. Repository / API Client Layer

Flutter client has no local database or JPA repositories. The data access layer is the centralized HTTP API client.

### myoffgridai_api_client.dart
**MyOffGridAIApiClient** — Dio-based HTTP client with JWT authentication.
- Constructor: baseUrl(String), storage(SecureStorageService), ref(Ref)
- Interceptors: _AuthInterceptor (JWT Bearer, auto-refresh on 401), _LoggingInterceptor
- Methods:
  - `get<T>(path, {queryParams, fromJson})` → T
  - `post<T>(path, {data, fromJson})` → T
  - `put<T>(path, {data, fromJson})` → T
  - `patch<T>(path, {data, fromJson})` → T
  - `delete(path)` → void
  - `getBytes(path)` → List<int> (file downloads)
  - `getStream(path, {queryParams, receiveTimeout})` → ResponseBody? (SSE streaming GET)
  - `postStream(path, {data, receiveTimeout})` → ResponseBody? (SSE streaming POST)
  - `postMultipart<T>(path, formData, {fromJson})` → T (file uploads)
  - `updateBaseUrl(newBaseUrl)` → void
  - `refreshToken()` → Future<bool>

### api_exception.dart
**ApiException** — statusCode(int), message(String), errors(Map<String,dynamic>?). Implements Exception.

### api_response.dart
**ApiResponse\<T\>** — Server envelope. success(bool), message(String?), data(T?), timestamp(String?), requestId(String?), totalElements(int?), page(int?), size(int?).

### providers.dart
Riverpod providers for cross-cutting concerns:
- **systemStatusProvider** — FutureProvider<SystemStatusDto>. Polls GET `/api/system/status`.
- **modelHealthProvider** — FutureProvider<OllamaHealthDto>. Polls GET `/api/models/health`.
- **unreadCountProvider** — FutureProvider<int>. GET `/api/notifications/unread-count`.
- **connectionStatusProvider** — StreamProvider<bool>. Pings `/api/system/status` every 10s.
- **serverUrlProvider** — FutureProvider<String>. Reads server URL from secure storage.
- **OllamaHealthDto** — available(bool), activeModel(String?), embedModelName(String?), responseTimeMs(int?)
- **SystemStatusDto** — initialized(bool)


## 9. Service Layer — Full Method Signatures

### auth_service.dart
**AuthService** — Injects: MyOffGridAIApiClient, SecureStorageService
- `login(String username, String password)`: Future<AuthResponse> — Authenticates user, persists tokens
- `register({required String username, required String displayName, required String password, String? email, String role})`: Future<AuthResponse> — Registers new user, persists tokens
- `logout()`: Future<void> — Clears tokens, calls server logout (best-effort)
- `refresh()`: Future<AuthResponse> — Refreshes access token via refresh token
- `getCurrentUser(String userId)`: Future<UserModel> — Gets user profile by ID
Provider: `authServiceProvider`

**AuthResponse** — accessToken, refreshToken, tokenType, expiresIn(int), user(UserModel)

### auth_state.dart
**AuthNotifier** (extends AsyncNotifier<UserModel?>) — Reads: secureStorageProvider, authServiceProvider, deviceRegistrationServiceProvider, foregroundServiceManagerProvider, mqttServiceProvider
- `build()`: Future<UserModel?> — Checks stored JWT, validates expiry, optionally refreshes
- `login(String username, String password)`: Future<void> — Login + start notification services
- `register({required String username, required String displayName, required String password, String? email})`: Future<void> — Register + start notification services
- `logout()`: Future<void> — Stop notification services, clear auth state
Provider: `authStateProvider`

### secure_storage_service.dart
**SecureStorageService** — Injects: FlutterSecureStorage? (optional override). In-memory cache for resilience.
- `saveTokens({required String accessToken, required String refreshToken})`: Future<void>
- `getAccessToken()`: Future<String?> — Cache-first
- `getRefreshToken()`: Future<String?> — Cache-first
- `clearTokens()`: Future<void>
- `saveServerUrl(String url)`: Future<void>
- `getServerUrl()`: Future<String> — Returns default if unset
- `saveThemePreference(String theme)`: Future<void>
- `getThemePreference()`: Future<String> — Defaults to 'system'
- `saveDeviceId(String deviceId)`: Future<void>
- `getDeviceId()`: Future<String?>
Provider: `secureStorageProvider`

### chat_service.dart
**ChatService** — Injects: MyOffGridAIApiClient
- `listConversations({int page, int size, bool archived})`: Future<List<ConversationSummaryModel>>
- `createConversation({String? title})`: Future<ConversationModel>
- `getConversation(String conversationId)`: Future<ConversationModel>
- `deleteConversation(String conversationId)`: Future<void>
- `archiveConversation(String conversationId)`: Future<void>
- `renameConversation(String conversationId, String title)`: Future<ConversationModel>
- `searchConversations(String query)`: Future<List<ConversationSummaryModel>>
- `listMessages(String conversationId, {int page, int size})`: Future<List<MessageModel>>
- `sendMessage(String conversationId, String content, {bool stream})`: Future<MessageModel>
- `sendMessageStream(String conversationId, String content)`: Stream<InferenceStreamEvent> — SSE streaming
- `editMessage(String conversationId, String messageId, String newContent)`: Future<MessageModel>
- `deleteMessage(String conversationId, String messageId)`: Future<void>
- `branchConversation(String conversationId, String messageId, {String? title})`: Future<ConversationModel>
- `regenerateMessage(String conversationId, String messageId)`: Stream<InferenceStreamEvent>
Providers: `chatServiceProvider`, `conversationsProvider`, `messagesProvider`, `aiThinkingProvider`, `judgeEvaluatingProvider`, `sidebarCollapsedProvider`

### chat_messages_notifier.dart
**ChatMessagesNotifier** (extends AutoDisposeFamilyAsyncNotifier<List<MessageModel>, String>)
- `build(String arg)`: Future<List<MessageModel>> — Fetches messages for conversation
- `sendMessage(String content)`: Future<void> — SSE streaming with optimistic UI, handles all inference event types
- `editMessage(String messageId, String newContent)`: Future<void>
- `deleteMessage(String messageId)`: Future<void>
- `regenerateMessage(String messageId)`: Future<void> — SSE streaming regeneration
Provider: `chatMessagesNotifierProvider` (family, keyed by conversationId)

### device_registration_service.dart
**DeviceRegistrationService** — Injects: MyOffGridAIApiClient, SecureStorageService
- `registerDevice()`: Future<void> — Registers device for push notifications
- `getRegisteredDevices()`: Future<List<DeviceRegistrationModel>>
- `unregisterDevice(String deviceId)`: Future<void>
Provider: `deviceRegistrationServiceProvider`

### enrichment_service.dart
**EnrichmentService** — Injects: MyOffGridAIApiClient
- `getExternalApiSettings()`: Future<ExternalApiSettingsModel>
- `updateExternalApiSettings(UpdateExternalApiSettingsRequest request)`: Future<ExternalApiSettingsModel>
- `fetchUrl({required String url, bool summarizeWithClaude})`: Future<KnowledgeDocumentModel>
- `search({required String query, int storeTopN, bool summarizeWithClaude})`: Future<({List<SearchResultModel> results, List<KnowledgeDocumentModel> storedDocuments})>
- `getStatus()`: Future<EnrichmentStatusModel>
Providers: `enrichmentServiceProvider`, `enrichmentStatusProvider`, `externalApiSettingsProvider`

### event_service.dart
**EventService** — Injects: MyOffGridAIApiClient
- `listEvents({int page, int size})`: Future<List<ScheduledEventModel>>
- `getEvent(String eventId)`: Future<ScheduledEventModel>
- `createEvent(Map<String, dynamic> body)`: Future<ScheduledEventModel>
- `updateEvent(String eventId, Map<String, dynamic> body)`: Future<ScheduledEventModel>
- `deleteEvent(String eventId)`: Future<void>
- `toggleEvent(String eventId)`: Future<ScheduledEventModel>
Providers: `eventServiceProvider`, `eventsListProvider`

### foreground_service_manager.dart
**ForegroundServiceManager** — No dependencies. Uses FlutterForegroundTask static API.
- `bool get isRunning`
- `startService()`: Future<void> — Android only, no-op on iOS/web
- `stopService()`: Future<void>
Provider: `foregroundServiceManagerProvider`

### insight_service.dart
**InsightService** — Injects: MyOffGridAIApiClient
- `listInsights({int page, int size, String? category})`: Future<List<InsightModel>>
- `generateInsights()`: Future<List<InsightModel>>
- `markAsRead(String insightId)`: Future<InsightModel>
- `dismiss(String insightId)`: Future<InsightModel>
- `getUnreadCount()`: Future<int>
Providers: `insightServiceProvider`, `insightsProvider`

### inventory_service.dart
**InventoryService** — Injects: MyOffGridAIApiClient
- `listItems({String? category})`: Future<List<InventoryItemModel>>
- `createItem({required String name, required String category, required double quantity, String? unit, String? notes, double? lowStockThreshold})`: Future<InventoryItemModel>
- `updateItem(String itemId, Map<String, dynamic> updates)`: Future<InventoryItemModel>
- `deleteItem(String itemId)`: Future<void>
Providers: `inventoryServiceProvider`, `inventoryProvider`

### judge_service.dart
**JudgeService** — Injects: MyOffGridAIApiClient
- `getStatus()`: Future<JudgeStatusModel>
- `start()`: Future<JudgeStatusModel>
- `stop()`: Future<JudgeStatusModel>
- `test({required String query, required String response})`: Future<JudgeTestResultModel>
Providers: `judgeServiceProvider`, `judgeStatusProvider`

### knowledge_service.dart
**KnowledgeService** — Injects: MyOffGridAIApiClient
- `listDocuments({int page, int size})`: Future<List<KnowledgeDocumentModel>>
- `getDocument(String documentId)`: Future<KnowledgeDocumentModel>
- `uploadDocument(String filename, List<int> bytes)`: Future<KnowledgeDocumentModel>
- `updateDisplayName(String documentId, String displayName)`: Future<KnowledgeDocumentModel>
- `deleteDocument(String documentId)`: Future<void>
- `retryProcessing(String documentId)`: Future<KnowledgeDocumentModel>
- `search(String query, {int topK})`: Future<List<KnowledgeSearchResultModel>>
- `getDocumentContent(String documentId)`: Future<DocumentContentModel>
- `downloadDocument(String documentId)`: Future<List<int>>
- `createDocument({required String title, required String content})`: Future<KnowledgeDocumentModel>
- `updateDocumentContent(String documentId, String content)`: Future<KnowledgeDocumentModel>
Providers: `knowledgeServiceProvider`, `knowledgeDocumentsProvider`, `documentContentProvider`

### library_service.dart
**LibraryService** — Injects: MyOffGridAIApiClient
- ZIM: `listZimFiles()`, `uploadZimFile({filename, bytes, displayName, category?})`, `deleteZimFile(id)`
- Kiwix: `getKiwixStatus()`, `getKiwixUrl()`
- eBooks: `listEbooks({search?, format?, page, size})`, `getEbook(id)`, `uploadEbook({filename, bytes, title, author?})`, `deleteEbook(id)`, `downloadEbookContent(id)`
- Gutenberg: `searchGutenberg(query, {limit})`, `getGutenbergBook(int id)`, `importGutenbergBook(int gutenbergId)`
Providers: `libraryServiceProvider`, `zimFilesProvider`, `ebooksProvider`, `kiwixStatusProvider`, `kiwixUrlProvider`

### local_notification_service.dart
**LocalNotificationService** — Injects: FlutterLocalNotificationsPlugin? (optional)
- `bool get isInitialized`
- `initialize()`: Future<void> — Must be called once at app startup
- `requestPermission()`: Future<bool>
- `showNotification({required int id, required String title, required String body, String? payload})`: Future<void>
- `showAlertNotification(NotificationModel notification)`: Future<void>
Provider: `localNotificationServiceProvider`

### log_service.dart
**LogService** — Singleton. Rotating file-based logging (10MB max, 5 rotated files).
- `static LogService get instance`
- `initialize()`: Future<void> — Opens log file
- `initializeWithPath(String dirPath)`: Future<void> — For testing
- `log(LogLevel level, String tag, String message, [Object? error, StackTrace?])`: void
- `debug(String tag, String message)`: void
- `info(String tag, String message)`: void
- `warn(String tag, String message)`: void
- `error(String tag, String message, [Object? error, StackTrace?])`: void
- `dispose()`: Future<void>
Provider: `logServiceProvider` (must be overridden at startup)

### memory_service.dart
**MemoryService** — Injects: MyOffGridAIApiClient
- `listMemories({int page, int size, String? importance, String? tag})`: Future<List<MemoryModel>>
- `getMemory(String id)`: Future<MemoryModel>
- `deleteMemory(String id)`: Future<void>
- `updateTags(String id, String tags)`: Future<MemoryModel>
- `updateImportance(String id, String importance)`: Future<MemoryModel>
- `search(String query, {int topK})`: Future<List<MemorySearchResultModel>>
- `exportMemories()`: Future<List<MemoryModel>>
Providers: `memoryServiceProvider`, `memoriesProvider`

### model_catalog_service.dart
**ModelCatalogService** — Injects: MyOffGridAIApiClient
- `searchCatalog({required String query, String format, int limit})`: Future<List<HfModelModel>>
- `getModelDetails(String author, String modelId)`: Future<HfModelModel>
- `getModelFiles(String author, String modelId)`: Future<List<HfModelFileModel>>
- `startDownload({required String repoId, required String filename})`: Future<Map<String, dynamic>>
- `getAllDownloads()`: Future<List<DownloadProgressModel>>
- `streamDownloadProgress(String downloadId)`: Stream<DownloadProgressModel> — SSE
- `cancelDownload(String downloadId)`: Future<void>
- `listLocalModels()`: Future<List<LocalModelFileModel>>
- `deleteLocalModel(String filename)`: Future<void>
Providers: `modelCatalogServiceProvider`, `localModelsProvider`, `activeDownloadsProvider`

### mqtt_service.dart
**MqttServiceNotifier** (extends StateNotifier<MqttState>) — Injects: Ref
- `connect(String userId)`: Future<void> — Connects to MQTT broker, subscribes to user + broadcast topics
- `disconnect()`: void — Disconnects, cancels reconnect timers
- `dispose()`: void
State: MqttState — connectionState(MqttConnectionStatus), errorMessage(String?), connectedAt(DateTime?), messagesReceived(int)
Provider: `mqttServiceProvider`

### notification_service.dart
**NotificationService** — Injects: MyOffGridAIApiClient
- `listNotifications({bool unreadOnly, int page, int size})`: Future<List<NotificationModel>>
- `markAsRead(String notificationId)`: Future<NotificationModel>
- `markAllAsRead()`: Future<void>
- `deleteNotification(String notificationId)`: Future<void>
- `getUnreadCount()`: Future<int>
Providers: `notificationServiceProvider`, `notificationsProvider`, `notificationsUnreadCountProvider` (polls every 30s)

### privacy_service.dart
**PrivacyService** — Injects: MyOffGridAIApiClient
- `getFortressStatus()`: Future<FortressStatusModel>
- `enableFortress()`: Future<void>
- `disableFortress()`: Future<void>
- `getSovereigntyReport()`: Future<SovereigntyReportModel>
- `getAuditLogs({String? outcome, int page, int size})`: Future<List<AuditLogModel>>
- `wipeSelfData()`: Future<WipeResultModel>
Providers: `privacyServiceProvider`, `fortressStatusProvider`

### sensor_service.dart
**SensorService** — Injects: MyOffGridAIApiClient
- `listSensors()`: Future<List<SensorModel>>
- `getSensor(String sensorId)`: Future<SensorModel>
- `createSensor({name, type, portPath, baudRate?, dataFormat?, valueField?, unit?, pollIntervalSeconds, lowThreshold?, highThreshold?})`: Future<SensorModel>
- `deleteSensor(String sensorId)`: Future<void>
- `startSensor(String sensorId)`: Future<SensorModel>
- `stopSensor(String sensorId)`: Future<SensorModel>
- `getLatestReading(String sensorId)`: Future<SensorReadingModel?>
- `getHistory(String sensorId, {int hours, int page, int size})`: Future<List<SensorReadingModel>>
- `updateThresholds(String sensorId, {double? lowThreshold, double? highThreshold})`: Future<SensorModel>
- `testConnection(String portPath, int baudRate)`: Future<SensorTestResultModel>
- `listPorts()`: Future<List<String>>
Providers: `sensorServiceProvider`, `sensorsProvider`

### skills_service.dart
**SkillsService** — Injects: MyOffGridAIApiClient
- `listSkills()`: Future<List<SkillModel>>
- `getSkill(String skillId)`: Future<SkillModel>
- `toggleSkill(String skillId, bool enabled)`: Future<SkillModel>
- `executeSkill(String skillId, {Map<String, dynamic>? params})`: Future<SkillExecutionModel>
- `listExecutions({int page, int size})`: Future<List<SkillExecutionModel>>
Providers: `skillsServiceProvider`, `skillsProvider`

### system_service.dart
**SystemService** — Injects: MyOffGridAIApiClient
- `getSystemStatus()`: Future<SystemStatusModel>
- `listModels()`: Future<List<OllamaModelInfoModel>>
- `getActiveModel()`: Future<ActiveModelInfo>
- `getAiSettings()`: Future<AiSettingsModel>
- `getStorageSettings()`: Future<StorageSettingsModel>
- `updateStorageSettings(StorageSettingsModel settings)`: Future<StorageSettingsModel>
- `updateAiSettings(AiSettingsModel settings)`: Future<AiSettingsModel>
Providers: `systemServiceProvider`, `systemStatusDetailProvider`, `ollamaModelsProvider`, `aiSettingsProvider`, `storageSettingsProvider`

### user_service.dart
**UserService** — Injects: MyOffGridAIApiClient
- `listUsers({int page, int size})`: Future<List<UserModel>>
- `getUser(String userId)`: Future<UserDetailModel>
- `updateUser(String userId, {String? displayName, String? email, String? role})`: Future<UserDetailModel>
- `deactivateUser(String userId)`: Future<void>
- `deleteUser(String userId)`: Future<void>
**UserDetailModel** — id, username, email(String?), displayName, role, isActive(bool), createdAt(String?), updatedAt(String?), lastLoginAt(String?)
Providers: `userServiceProvider`, `usersListProvider`

**Total: 25 files, 22 service classes, 147 public methods, 53 Riverpod providers.**


## 10. Controller / Route Layer

Flutter client uses GoRouter (declarative routing) instead of controllers. All routes defined in `lib/config/router.dart`.

### Route Table

| Route | Screen | Auth Required | Notes |
|---|---|---|---|
| `/login` | LoginScreen | No | Redirect to `/` if logged in |
| `/register` | RegisterScreen | No | Redirect to `/` if logged in |
| `/device-not-setup` | DeviceNotSetupScreen | No | |
| `/` (home) | ChatListScreen | Yes | Inside AppShell |
| `/chat` | ChatListScreen | Yes | |
| `/chat/:conversationId` | ChatConversationScreen | Yes | Accepts `extra` String for initial message |
| `/settings` | SettingsScreen | Yes | |
| `/search` | SearchScreen | Yes | |
| `/books` | BooksScreen | Yes | |
| `/books/reader` | BookReaderScreen | Yes | Accepts `extra` EbookModel |
| `/memory` | MemoryScreen | Yes | |
| `/knowledge` | KnowledgeScreen | Yes | |
| `/knowledge/new` | DocumentEditorScreen | Yes | |
| `/knowledge/:documentId/edit` | DocumentEditorScreen | Yes | |
| `/knowledge/:documentId` | DocumentDetailScreen | Yes | |
| `/skills` | SkillsScreen | Yes | |
| `/inventory` | InventoryScreen | Yes | |
| `/sensors` | SensorsScreen | Yes | |
| `/sensors/add` | AddSensorScreen | Yes | |
| `/sensors/:sensorId` | SensorDetailScreen | Yes | |
| `/events` | EventsScreen | Yes | |
| `/insights` | InsightsScreen | Yes | |
| `/notifications` | NotificationsScreen | Yes | |
| `/privacy` | PrivacyScreen | Yes | |
| `/system` | SystemScreen | Yes | |
| `/users` | UsersScreen | Yes | OWNER/ADMIN only |

### Auth Guards
- Unauthenticated → redirect to `/login`
- Authenticated + on login/register → redirect to `/`
- `/users` → requires `ROLE_OWNER` or `ROLE_ADMIN`

### Shell
All authenticated routes wrapped in `ShellRoute` → `AppShell` (provides NavigationPanel sidebar).

Providers: `routerProvider`

## 11. Security Configuration

```
Authentication: JWT Bearer tokens via Dio interceptor
Token storage: FlutterSecureStorage (iOS Keychain, Android EncryptedSharedPreferences)
Token refresh: Automatic on 401 via _AuthInterceptor (single retry, then clear tokens)
Token refresh path: POST /api/auth/refresh

Public endpoints (no auth required):
  - /login
  - /register
  - /device-not-setup

Protected endpoints:
  - All routes inside ShellRoute → require authenticated user
  - /users → ROLE_OWNER or ROLE_ADMIN only

CORS: Not applicable (client-side)
CSRF: Not applicable (client-side, uses Bearer tokens)
Rate limiting: Server-side only

Password requirements (dev mode): minimum 4 characters
Username requirements: 3-50 characters
```

## 12. Custom Security Components

### _AuthInterceptor (in myoffgridai_api_client.dart)
- Extends: Dio Interceptor
- Attaches JWT Bearer token from SecureStorageService to every request
- On 401: attempts single token refresh via POST `/api/auth/refresh`
- If refresh succeeds: retries original request with new token
- If refresh fails: clears tokens (triggers logout flow)
- Skips auth for requests marked with `_skipAuth` header
- Never retries `/auth/refresh` or `/auth/login` paths

### _LoggingInterceptor (in myoffgridai_api_client.dart)
- Logs HTTP method + path on request
- Logs status code + path on response
- Logs ERROR + status code on error
- Never logs Authorization headers or request bodies

### SecureStorageService
- In-memory cache (`_cache`) as fallback for platform storage read failures
- Uses platform-specific options: iOS Keychain (kSecAttrAccessibleFirstUnlock), Android EncryptedSharedPreferences

## 13. Exception Handling & Error Responses

### ApiException
Standard error type for all API errors. Fields: statusCode(int), message(String), errors(Map?).

### Error Handling Flow
1. Dio request throws `DioException`
2. `_handleDioException()` in MyOffGridAIApiClient maps it to `ApiException`:
   - Response present → extracts `message` and `errors` from JSON body
   - Connection/receive timeout → `ApiException(408, "Connection timed out...")`
   - No response → `ApiException(0, "Cannot reach MyOffGrid AI server.")`
3. UI screens catch `ApiException` and display `SnackBar` with error message

### ApiResponse<T> Envelope
All server responses wrapped in: `{success: bool, message: String?, data: T?, timestamp: String?, requestId: String?, totalElements: int?, page: int?, size: int?}`


## 14. Mappers / DTOs

**No separate mapper layer.** All models use `factory fromJson()` constructors for JSON deserialization and `toJson()` methods where needed for serialization. The `ApiResponse<T>` envelope uses a `fromJsonT` factory function parameter for generic deserialization.

Models with `toJson()`: UpdateExternalApiSettingsRequest, ScheduledEventModel, AiSettingsModel, StorageSettingsModel, UserModel.
Models with `copyWith()`: MessageModel, MqttState.

## 15. Utility Classes & Shared Components

### DateFormatter (`lib/shared/utils/date_formatter.dart`)
- `formatRelative(DateTime)`: String — "just now", "X minutes ago", "Yesterday", "Mar 14"
- `formatFull(DateTime)`: String — "March 14, 2026 at 3:45 PM"
- `formatDate(DateTime)`: String — "Mar 14, 2026"
Used by: Feature screens for timestamp display

### SizeFormatter (`lib/shared/utils/size_formatter.dart`)
- `formatBytes(int bytes)`: String — "1.2 MB", "340 KB"
Used by: HfModelFileModel.formattedSize, knowledge document display, library screens

### PlatformUtils (`lib/shared/utils/platform_utils.dart`)
- `isWeb`: bool — True on Flutter Web
- `isMobile`: bool — True on iOS/Android
- `isTablet(BuildContext)`: bool — 600-1200px width
- `isMobileWidth(BuildContext)`: bool — <600px
- `isDesktopWidth(BuildContext)`: bool — >=1200px
Used by: Responsive layouts throughout the app

### DownloadUtils (`lib/shared/utils/download_utils.dart`)
- `downloadBytes(List<int> bytes, String filename)`: void — Web-only file download via base64 data URI
- Conditional import: `download_trigger_web.dart` (web) / `download_trigger_stub.dart` (native no-op)
Used by: Knowledge document downloads, eBook downloads

### AppColors (`lib/config/theme.dart`)
Brand color palette: primary (forest green #2D5016), secondary (amber-brown #8B5E1A), earth-toned backgrounds.

### ThemeNotifier (`lib/config/theme.dart`)
- StateNotifier<ThemeMode> — persists light/dark/system preference to SecureStorageService
- `setThemeMode(ThemeMode mode)`: Future<void>
Provider: `themeProvider`

### Shared Widgets (`lib/shared/widgets/`)
- **AppShell** — Main scaffold with NavigationPanel sidebar + content area
- **NavigationPanel** — Expandable/collapsible sidebar navigation
- **ConnectionLostBanner** — Shows when server unreachable
- **SystemStatusBar** — Displays model health, connection status
- **ConfirmationDialog** — Reusable Yes/No dialog
- **EmptyStateView** — Placeholder for empty lists
- **ErrorView** — Standardized error display
- **LoadingIndicator** — Centered loading spinner
- **NotificationBadge** — Unread count badge


## 16. Database Schema

**No local database.** This is a Flutter client application. All data persisted on the MyOffGridAI-Server via REST API. Local storage is limited to:
- **FlutterSecureStorage** — JWT tokens, server URL, theme preference, device ID
- **LogService** — Rotating log files in app documents directory (up to 50MB total)

## 17. Message Broker Configuration

**MQTT Client** (mqtt_client ^10.2.1)

```
Broker: MQTT (server at offgrid.local:1883 or configured server host)
Port: 1883 (unencrypted)
Client ID Prefix: myoffgridai-flutter-
Keep Alive: 60 seconds
Reconnect Delay: 5 seconds (auto-reconnect on disconnect)
QoS: 1 (at-least-once)

Subscribed Topics:
  - /myoffgridai/{userId}/notifications — Per-user notifications
  - /myoffgridai/broadcast — Global broadcast messages

Consumer: MqttServiceNotifier
  - Parses JSON notification payloads
  - Triggers LocalNotificationService.showAlertNotification()
  - Invalidates notificationsProvider to refresh UI
```

## 18. Cache Layer

No Redis or external caching layer. Client-side caching:
- **SecureStorageService._cache** — In-memory token cache for resilience
- **Riverpod autoDispose** — FutureProvider.autoDispose handles data freshness
- **cached_network_image** — Disk/memory image caching for network images

## 19. Environment Variable Inventory

No environment variables in the Flutter client. All configuration is:
- **Compile-time** — `kIsWeb` platform detection
- **Runtime storage** — Server URL stored in FlutterSecureStorage (user-configurable via login screen)
- **Constants** — Hardcoded in `lib/config/constants.dart`

| Setting | Location | Default | Configurable |
|---|---|---|---|
| Server URL | SecureStorage | localhost:8080 (web) / offgrid.local:8080 (native) | Yes (login screen) |
| Theme | SecureStorage | system | Yes (settings) |
| Device ID | SecureStorage | Auto-generated UUID | No |

## 20. Service Dependency Map

```
MyOffGridAI-Client → Depends On:
  - MyOffGridAI-Server: REST API at :8080 (all data operations)
  - MQTT Broker: mqtt://host:1883 (push notifications, real-time events)
  - Kiwix Server: http://host:8888 (offline library, ZIM file serving)
  - CDN (web only): cdn.jsdelivr.net (PDF.js library for web PDF rendering)

Downstream Consumers: None (end-user client)
```


## 21. Known Technical Debt & Issues

### TODO/Placeholder/Stub Scan Results

**PASS — No TODO, FIXME, placeholder, or stub patterns found.**

Scan notes:
- `throw UnimplementedError` in `apiClientProvider` and `logServiceProvider` are intentional — Riverpod providers that MUST be overridden at app startup. Not stubs.
- `download_trigger_stub.dart` is a legitimate conditional import pattern for platform-specific web downloads.

### Issues Discovered During Audit

| Issue | Location | Severity | Notes |
|---|---|---|---|
| MQTT unencrypted | constants.dart:106 | Medium | Port 1883 — no TLS/SSL. Acceptable for LAN-only but not for internet-facing |
| No certificate pinning | myoffgridai_api_client.dart | Low | Dio HTTP client has no cert pinning. Acceptable for local network appliance. |
| CDN dependency on web | web/index.html:17 | Low | PDF.js loaded from cdn.jsdelivr.net — breaks offline web use. Could be bundled. |
| No CI/CD pipeline | Project root | Medium | No GitHub Actions, Jenkins, or GitLab CI configuration |
| Legacy sidebar aliases | constants.dart:95-96 | Low | `sidebarExpandedWidth` / `sidebarCollapsedWidth` aliases — can be removed |


## 22. Security Vulnerability Scan (Snyk)

Scan Date: 2026-03-18T18:30:37Z
Snyk CLI Version: 1.1303.0

### Dependency Vulnerabilities (Open Source)
Critical: 0
High: 0
Medium: 0
Low: 0

**PASS — No known vulnerabilities in dependencies.**

### Code Vulnerabilities (SAST)
Errors: 0
Warnings: 0

**PASS — No code vulnerabilities detected.**

### IaC Findings
Not applicable — no Dockerfile, docker-compose, or Kubernetes configuration in client project.

