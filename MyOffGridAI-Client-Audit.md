# MyOffGridAI-Client — Codebase Audit

**Audit Date:** 2026-03-16T23:25:12Z
**Branch:** main
**Commit:** d6733fa1d4e9a0f79757d46146e8477a57066fc4 P12-Client: Add HuggingFace model catalog, download manager, and Models tab
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
Project Name: MyOffGridAI-Client
Repository URL: (local — ~/Documents/Github/MyOffGridAI-Client)
Primary Language / Framework: Dart / Flutter
Dart Version: 3.11.0
Flutter Version: 3.41.1 (stable)
Build Tool: Flutter CLI + pub
Current Branch: main
Latest Commit Hash: d6733fa1d4e9a0f79757d46146e8477a57066fc4
Latest Commit Message: P12-Client: Add HuggingFace model catalog, download manager, and Models tab
Audit Timestamp: 2026-03-16T23:25:12Z
```

---

## 2. Directory Structure

```
lib/
├── main.dart                          ← App entry point
├── config/
│   ├── constants.dart                 ← All app-wide constants (URLs, keys, routes, UI)
│   ├── router.dart                    ← GoRouter with auth guards
│   └── theme.dart                     ← Light/dark themes with brand colors
├── core/
│   ├── api/
│   │   ├── api_exception.dart         ← Typed HTTP error exception
│   │   ├── api_response.dart          ← Server ApiResponse<T> envelope
│   │   ├── myoffgridai_api_client.dart ← Dio-based HTTP client with JWT interceptors
│   │   └── providers.dart             ← System status, model health, connection polling providers
│   ├── auth/
│   │   ├── auth_service.dart          ← Login, register, logout, token refresh
│   │   ├── auth_state.dart            ← AsyncNotifier managing auth state + JWT decode
│   │   └── secure_storage_service.dart ← FlutterSecureStorage wrapper with in-memory cache
│   ├── models/                        ← 19 model files (DTOs mirroring server)
│   │   ├── conversation_model.dart
│   │   ├── device_registration_model.dart
│   │   ├── enrichment_models.dart
│   │   ├── event_model.dart
│   │   ├── inference_stream_event.dart
│   │   ├── insight_model.dart
│   │   ├── inventory_item_model.dart
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
│   └── services/                      ← 20 service files (API wrappers + Riverpod providers)
│       ├── chat_messages_notifier.dart
│       ├── chat_service.dart
│       ├── device_registration_service.dart
│       ├── enrichment_service.dart
│       ├── event_service.dart
│       ├── foreground_service_manager.dart
│       ├── insight_service.dart
│       ├── inventory_service.dart
│       ├── knowledge_service.dart
│       ├── library_service.dart
│       ├── local_notification_service.dart
│       ├── memory_service.dart
│       ├── model_catalog_service.dart
│       ├── mqtt_service.dart
│       ├── notification_service.dart
│       ├── privacy_service.dart
│       ├── sensor_service.dart
│       ├── skills_service.dart
│       ├── system_service.dart
│       └── user_service.dart
├── features/                          ← Feature-based screen organization
│   ├── auth/                          ← Login, Register, Users, DeviceNotSetup
│   ├── books/                         ← BooksScreen, BookReaderScreen
│   ├── chat/                          ← ChatListScreen, ChatConversationScreen, widgets/
│   ├── events/                        ← EventsScreen, EventDialog
│   ├── insights/                      ← InsightsScreen
│   ├── inventory/                     ← InventoryScreen
│   ├── knowledge/                     ← KnowledgeScreen, DocumentDetail, DocumentEditor
│   ├── memory/                        ← MemoryScreen
│   ├── notifications/                 ← NotificationsScreen
│   ├── privacy/                       ← PrivacyScreen
│   ├── search/                        ← SearchScreen
│   ├── sensors/                       ← SensorsScreen, SensorDetail, AddSensor
│   ├── settings/                      ← SettingsScreen (6-tab)
│   ├── skills/                        ← SkillsScreen
│   └── system/                        ← SystemScreen
└── shared/
    ├── utils/                         ← DateFormatter, DownloadUtils, PlatformUtils, SizeFormatter
    └── widgets/                       ← AppShell, NavigationPanel, ConfirmationDialog, etc.
```

Single-module Flutter project. Source in `lib/`, tests mirror in `test/`. 93 source files, 89 test files.

---

## 3. Build & Dependency Manifest

**Build file:** `pubspec.yaml`

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter | SDK | UI framework |
| flutter_localizations | SDK | i18n support |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| dio | ^5.7.0 | HTTP client (REST API calls) |
| go_router | ^14.8.1 | Declarative routing with auth guards |
| flutter_riverpod | ^2.6.1 | State management / dependency injection |
| riverpod_annotation | ^2.6.1 | Riverpod code generation annotations |
| flutter_secure_storage | ^9.2.4 | Encrypted token/preference storage |
| web_socket_channel | ^3.0.2 | WebSocket support (unused currently) |
| fl_chart | ^0.70.2 | Chart rendering (sensor history) |
| file_picker | ^8.3.7 | File upload dialogs |
| desktop_drop | ^0.4.4 | Drag-and-drop file import |
| cross_file | ^0.3.5+2 | Cross-platform file abstraction |
| intl | ^0.20.2 | Date formatting |
| flutter_quill | ^11.4.0 | Rich text editor (knowledge documents) |
| mqtt_client | ^10.2.1 | MQTT push notifications |
| flutter_local_notifications | ^17.2.3 | Local push notification display |
| flutter_foreground_task | ^8.13.0 | Android foreground service (MQTT keepalive) |
| permission_handler | ^11.3.1 | Runtime permission requests |
| webview_flutter | ^4.10.0 | WebView (Kiwix browser) |
| webview_flutter_android | ^4.3.0 | Android WebView implementation |
| webview_flutter_wkwebview | ^3.18.0 | iOS WebView implementation |
| pdfx | ^2.9.0 | PDF rendering (eBook reader) |
| path_provider | ^2.1.5 | Platform file paths |
| open_filex | ^4.6.0 | Open files with native apps |
| cached_network_image | ^3.4.1 | Cached image loading |
| flutter_markdown | ^0.7.4+3 | Markdown rendering (chat messages) |
| markdown | ^7.3.0 | Markdown parsing |
| flutter_highlight | ^0.7.0 | Syntax highlighting (code blocks in chat) |
| highlight | ^0.7.0 | Language detection for highlighting |

### Dev Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter_test | SDK | Widget/unit testing |
| flutter_lints | ^6.0.0 | Lint rules |
| build_runner | ^2.4.15 | Code generation |
| riverpod_generator | ^2.6.3 | Riverpod provider generation |
| mockito | ^5.4.6 | Mock generation |
| mocktail | ^1.0.4 | Lightweight mocking |

### Build Commands

```
Build: flutter build apk / flutter build ios / flutter build web
Test: flutter test
Test + Coverage: flutter test --coverage
Run: flutter run
```

---

## 4. Configuration & Infrastructure Summary

**`pubspec.yaml`** — Project metadata, dependencies, SDK constraints. Path: `./pubspec.yaml`

**`analysis_options.yaml`** — Uses `package:flutter_lints/flutter.yaml` with `unnecessary_underscores: false`. Path: `./analysis_options.yaml`

**`lib/config/constants.dart`** — All app-wide constants. Key values:
- Default server: `http://offgrid.local:8080` (native), `http://localhost:8080` (web)
- Connect timeout: 10s, Receive timeout: 120s, SSE timeout: 5min
- MQTT port: 1883, keepalive: 60s
- Password min length: 4 (dev mode)
- Mobile breakpoint: 600px, Tablet breakpoint: 1200px
- All API paths defined as constants (`/api/auth`, `/api/chat`, `/api/models`, etc.)
- All route paths defined as constants

**Connection map:**
```
Database: None (client-side only — server handles persistence)
Cache: In-memory cache in SecureStorageService
Message Broker: MQTT (Mosquitto) via offgrid.local:1883
External APIs: MyOffGridAI-Server REST API (all endpoints)
Cloud Services: None (fully offline-capable)
```

**CI/CD:** None detected.

---

## 5. Startup & Runtime Behavior

**Entry point:** `lib/main.dart` → `main()` function

**Startup sequence:**
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Create `SecureStorageService`, read stored server URL
3. Initialize `LocalNotificationService`
4. Create `ProviderScope` with overrides for storage, notifications, API client
5. Launch `MyOffGridAIApp` (MaterialApp.router with GoRouter)

**Auth flow on startup:**
- `AuthNotifier.build()` checks for stored JWT in secure storage
- If token exists, decodes JWT payload to extract user info (no network call)
- If token expired, attempts refresh via `/api/auth/refresh`
- If no token or refresh fails, user sees LoginScreen

**Post-login services (non-blocking):**
- Device registration via `/api/notifications/devices`
- Foreground service start (Android only)
- MQTT connection to Mosquitto broker

**Background services:**
- Connection polling every 10 seconds (`connectionStatusProvider`)
- Notification polling every 30 seconds (`notificationsUnreadCountProvider`)
- Model health polling on each access (`modelHealthProvider`)

---

## 6. Entity / Data Model Layer

This is a Flutter client — no database entities. Models are DTOs mirroring the server. Key models:

### ConversationModel / ConversationSummaryModel
Fields: id, title, isArchived, messageCount, createdAt, updatedAt, lastMessagePreview (summary only)

### MessageModel
Fields: id, role (USER/ASSISTANT/SYSTEM), content, tokenCount, hasRagContext, thinkingContent, tokensPerSecond, inferenceTimeSeconds, stopReason, thinkingTokenCount, createdAt
Custom: `isUser`, `isAssistant`, `copyWith()`

### UserModel
Fields: id, username, displayName, role, isActive

### MemoryModel / MemorySearchResultModel
Fields: id, content, importance (LOW/MEDIUM/HIGH/CRITICAL), tags, sourceConversationId, accessCount, timestamps
Custom: `tagList` getter splits comma-separated tags

### KnowledgeDocumentModel / DocumentContentModel / KnowledgeSearchResultModel
Fields: id, filename, displayName, mimeType, fileSizeBytes, status (PENDING/PROCESSING/INDEXED/FAILED), chunkCount, timestamps
Custom: `isProcessing`, `isIndexed`, `isFailed` getters

### SensorModel / SensorReadingModel / SensorTestResultModel
Fields: id, name, type, portPath, baudRate, dataFormat, valueField, unit, isActive, pollIntervalSeconds, thresholds

### ScheduledEventModel
Fields: id, name, eventType (SCHEDULED/SENSOR_THRESHOLD/RECURRING), cronExpression, sensorId, thresholdOperator/Value, actionType (PUSH_NOTIFICATION/AI_PROMPT/AI_SUMMARY), actionPayload

### NotificationModel
Fields: id, title, body, type (SENSOR_ALERT/SYSTEM_HEALTH/INSIGHT_READY/MODEL_UPDATE/GENERAL), severity (INFO/WARNING/CRITICAL), isRead

### InsightModel
Fields: id, content, category (SECURITY/EFFICIENCY/HEALTH/MAINTENANCE/SUSTAINABILITY/PLANNING), isRead, isDismissed

### InventoryItemModel
Fields: id, name, category (FOOD/WATER/FUEL/TOOLS/MEDICINE/SPARE_PARTS/OTHER), quantity, unit, lowStockThreshold
Custom: `isLowStock` getter

### SkillModel / SkillExecutionModel
Fields: id, name, displayName, description, category, isEnabled, isBuiltIn, parametersSchema

### InferenceStreamEvent / InferenceMetadata
Fields: type (thinking/content/done/error), content, metadata (tokensGenerated, tokensPerSecond, inferenceTimeSeconds, stopReason), messageId

### HfModelModel / HfModelFileModel / DownloadProgressModel / LocalModelFileModel
HuggingFace catalog models with download tracking (downloadId, status, percentComplete, speedBytesPerSecond, estimatedSecondsRemaining)

### Privacy Models
FortressStatusModel, SovereigntyReportModel (with DataInventory, AuditSummary), AuditLogModel, WipeResultModel

### Library Models
ZimFileModel, EbookModel, KiwixStatusModel, GutenbergBookModel, GutenbergSearchResultModel

### System Models
SystemStatusModel, OllamaModelInfoModel, AiSettingsModel (temperature, similarityThreshold, memoryTopK, ragMaxContextTokens, contextSize, contextMessageLimit), StorageSettingsModel, ActiveModelInfo

### Enrichment Models
ExternalApiSettingsModel (anthropic/brave/huggingFace enabled flags), UpdateExternalApiSettingsRequest, SearchResultModel, EnrichmentStatusModel

### Other Models
DeviceRegistrationModel, PageResponse<T>, ApiResponse<T>, ApiException

---

## 7. Enum Inventory

All enums are implemented as Dart classes with static const strings (matching server enum values):

| Enum Class | Values | Used In |
|---|---|---|
| InferenceEventType | thinking, content, done, error | InferenceStreamEvent |
| EventType | SCHEDULED, SENSOR_THRESHOLD, RECURRING | ScheduledEventModel |
| ActionType | PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY | ScheduledEventModel |
| ThresholdOperator | ABOVE, BELOW, EQUALS | ScheduledEventModel |
| InsightCategory | SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING | InsightModel |
| InventoryCategory | FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER | InventoryItemModel |
| SensorType | TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION | SensorModel |
| DataFormat | CSV_LINE, JSON_LINE, RAW_TEXT | SensorModel |
| NotificationType | SENSOR_ALERT, SYSTEM_HEALTH, INSIGHT_READY, MODEL_UPDATE, GENERAL | NotificationModel |
| NotificationSeverity | INFO, WARNING, CRITICAL | NotificationModel |
| AuditOutcome | SUCCESS, FAILURE, DENIED | AuditLogModel |
| MqttConnectionStatus | disconnected, connecting, connected, error | MqttState |
| LoadingSize | small(16), medium(24), large(40) | LoadingIndicator |

---

## 8. Repository Layer

N/A — Flutter client. No local database or repository pattern. All data access goes through service classes that call the REST API.

---

## 9. Service Layer — Full Method Signatures

### AuthService
Injects: MyOffGridAIApiClient, SecureStorageService
- `login(String username, String password): Future<AuthResponse>`
- `register({username, displayName, password, email?, role}): Future<AuthResponse>`
- `logout(): Future<void>`
- `refresh(): Future<AuthResponse>`
- `getCurrentUser(String userId): Future<UserModel>`

### ChatService
Injects: MyOffGridAIApiClient
- `listConversations({page, size, archived}): Future<List<ConversationSummaryModel>>`
- `createConversation({title?}): Future<ConversationModel>`
- `getConversation(String id): Future<ConversationModel>`
- `deleteConversation(String id): Future<void>`
- `archiveConversation(String id): Future<void>`
- `renameConversation(String id, String title): Future<ConversationModel>`
- `searchConversations(String query): Future<List<ConversationSummaryModel>>`
- `listMessages(String convId, {page, size}): Future<List<MessageModel>>`
- `sendMessage(String convId, String content, {stream}): Future<MessageModel>`
- `sendMessageStream(String convId, String content): Stream<InferenceStreamEvent>` — SSE
- `editMessage(String convId, String msgId, String content): Future<MessageModel>`
- `deleteMessage(String convId, String msgId): Future<void>`
- `branchConversation(String convId, String msgId, {title?}): Future<ConversationModel>`
- `regenerateMessage(String convId, String msgId): Stream<InferenceStreamEvent>` — SSE

### ChatMessagesNotifier (AutoDisposeFamilyAsyncNotifier)
- `sendMessage(String content): Future<void>` — optimistic UI + SSE streaming
- `editMessage(String messageId, String newContent): Future<void>`
- `deleteMessage(String messageId): Future<void>`
- `regenerateMessage(String messageId): Future<void>` — SSE streaming

### MemoryService
Injects: MyOffGridAIApiClient
- `listMemories({page, size, importance?, tag?}): Future<List<MemoryModel>>`
- `getMemory(String id): Future<MemoryModel>`
- `deleteMemory(String id): Future<void>`
- `updateTags(String id, String tags): Future<MemoryModel>`
- `updateImportance(String id, String importance): Future<MemoryModel>`
- `search(String query, {topK}): Future<List<MemorySearchResultModel>>`
- `exportMemories(): Future<List<MemoryModel>>`

### KnowledgeService
Injects: MyOffGridAIApiClient
- `listDocuments({page, size}): Future<List<KnowledgeDocumentModel>>`
- `getDocument(String id): Future<KnowledgeDocumentModel>`
- `uploadDocument(String filename, List<int> bytes): Future<KnowledgeDocumentModel>`
- `updateDisplayName(String id, String name): Future<KnowledgeDocumentModel>`
- `deleteDocument(String id): Future<void>`
- `retryProcessing(String id): Future<KnowledgeDocumentModel>`
- `search(String query, {topK}): Future<List<KnowledgeSearchResultModel>>`
- `getDocumentContent(String id): Future<DocumentContentModel>`
- `downloadDocument(String id): Future<List<int>>`
- `createDocument({title, content}): Future<KnowledgeDocumentModel>`
- `updateDocumentContent(String id, String content): Future<KnowledgeDocumentModel>`

### SensorService
Injects: MyOffGridAIApiClient
- `listSensors(): Future<List<SensorModel>>`
- `getSensor(String id): Future<SensorModel>`
- `createSensor({name, type, portPath, baudRate?, ...}): Future<SensorModel>`
- `deleteSensor(String id): Future<void>`
- `startSensor(String id): Future<SensorModel>`
- `stopSensor(String id): Future<SensorModel>`
- `getLatestReading(String id): Future<SensorReadingModel?>`
- `getHistory(String id, {hours, page, size}): Future<List<SensorReadingModel>>`
- `updateThresholds(String id, {low?, high?}): Future<SensorModel>`
- `testConnection(String port, int baud): Future<SensorTestResultModel>`
- `listPorts(): Future<List<String>>`

### EventService
Injects: MyOffGridAIApiClient
- `listEvents({page, size}): Future<List<ScheduledEventModel>>`
- `getEvent(String id): Future<ScheduledEventModel>`
- `createEvent(Map body): Future<ScheduledEventModel>`
- `updateEvent(String id, Map body): Future<ScheduledEventModel>`
- `deleteEvent(String id): Future<void>`
- `toggleEvent(String id): Future<ScheduledEventModel>`

### InsightService
Injects: MyOffGridAIApiClient
- `listInsights({page, size, category?}): Future<List<InsightModel>>`
- `generateInsights(): Future<List<InsightModel>>`
- `markAsRead(String id): Future<InsightModel>`
- `dismiss(String id): Future<InsightModel>`
- `getUnreadCount(): Future<int>`

### NotificationService
Injects: MyOffGridAIApiClient
- `listNotifications({unreadOnly, page, size}): Future<List<NotificationModel>>`
- `markAsRead(String id): Future<NotificationModel>`
- `markAllAsRead(): Future<void>`
- `deleteNotification(String id): Future<void>`
- `getUnreadCount(): Future<int>`

### InventoryService
Injects: MyOffGridAIApiClient
- `listItems({category?}): Future<List<InventoryItemModel>>`
- `createItem({name, category, quantity, unit?, notes?, lowStockThreshold?}): Future<InventoryItemModel>`
- `updateItem(String id, Map updates): Future<InventoryItemModel>`
- `deleteItem(String id): Future<void>`

### SkillsService
Injects: MyOffGridAIApiClient
- `listSkills(): Future<List<SkillModel>>`
- `getSkill(String id): Future<SkillModel>`
- `toggleSkill(String id, bool enabled): Future<SkillModel>`
- `executeSkill(String id, {params?}): Future<SkillExecutionModel>`
- `listExecutions({page, size}): Future<List<SkillExecutionModel>>`

### PrivacyService
Injects: MyOffGridAIApiClient
- `getFortressStatus(): Future<FortressStatusModel>`
- `enableFortress(): Future<void>`
- `disableFortress(): Future<void>`
- `getSovereigntyReport(): Future<SovereigntyReportModel>`
- `getAuditLogs({outcome?, page, size}): Future<List<AuditLogModel>>`
- `wipeSelfData(): Future<WipeResultModel>`

### SystemService
Injects: MyOffGridAIApiClient
- `getSystemStatus(): Future<SystemStatusModel>`
- `listModels(): Future<List<OllamaModelInfoModel>>`
- `getActiveModel(): Future<ActiveModelInfo>`
- `getAiSettings(): Future<AiSettingsModel>`
- `getStorageSettings(): Future<StorageSettingsModel>`
- `updateStorageSettings(StorageSettingsModel): Future<StorageSettingsModel>`
- `updateAiSettings(AiSettingsModel): Future<AiSettingsModel>`

### UserService
Injects: MyOffGridAIApiClient
- `listUsers({page, size}): Future<List<UserModel>>`
- `getUser(String id): Future<UserDetailModel>`
- `updateUser(String id, {displayName?, email?, role?}): Future<UserDetailModel>`
- `deactivateUser(String id): Future<void>`
- `deleteUser(String id): Future<void>`

### EnrichmentService
Injects: MyOffGridAIApiClient
- `getExternalApiSettings(): Future<ExternalApiSettingsModel>`
- `updateExternalApiSettings(UpdateExternalApiSettingsRequest): Future<ExternalApiSettingsModel>`
- `fetchUrl({url, summarizeWithClaude}): Future<KnowledgeDocumentModel>`
- `search({query, storeTopN, summarizeWithClaude}): Future<(results, storedDocuments)>`
- `getStatus(): Future<EnrichmentStatusModel>`

### LibraryService
Injects: MyOffGridAIApiClient
- `listZimFiles(): Future<List<ZimFileModel>>`
- `uploadZimFile({filename, bytes, displayName, category?}): Future<ZimFileModel>`
- `deleteZimFile(String id): Future<void>`
- `getKiwixStatus(): Future<KiwixStatusModel>`
- `getKiwixUrl(): Future<String>`
- `listEbooks({search?, format?, page, size}): Future<List<EbookModel>>`
- `getEbook(String id): Future<EbookModel>`
- `uploadEbook({filename, bytes, title, author?}): Future<EbookModel>`
- `deleteEbook(String id): Future<void>`
- `downloadEbookContent(String id): Future<List<int>>`
- `searchGutenberg(String query, {limit}): Future<GutenbergSearchResultModel>`
- `getGutenbergBook(int id): Future<GutenbergBookModel>`
- `importGutenbergBook(int id): Future<EbookModel>`

### ModelCatalogService
Injects: MyOffGridAIApiClient
- `searchCatalog({query, format, limit}): Future<List<HfModelModel>>`
- `getModelDetails(String author, String modelId): Future<HfModelModel>`
- `getModelFiles(String author, String modelId): Future<List<HfModelFileModel>>`
- `startDownload({repoId, filename}): Future<Map<String, dynamic>>`
- `getAllDownloads(): Future<List<DownloadProgressModel>>`
- `streamDownloadProgress(String downloadId): Stream<DownloadProgressModel>` — SSE
- `cancelDownload(String downloadId): Future<void>`
- `listLocalModels(): Future<List<LocalModelFileModel>>`
- `deleteLocalModel(String filename): Future<void>`

### DeviceRegistrationService
Injects: MyOffGridAIApiClient, SecureStorageService
- `registerDevice(): Future<void>`
- `getRegisteredDevices(): Future<List<DeviceRegistrationModel>>`
- `unregisterDevice(String deviceId): Future<void>`

### MqttServiceNotifier (StateNotifier<MqttState>)
- `connect(String userId): Future<void>`
- `disconnect(): void`

### ForegroundServiceManager
- `startService(): Future<void>` — Android only
- `stopService(): Future<void>` — Android only

### LocalNotificationService
- `initialize(): Future<void>`
- `requestPermission(): Future<bool>`
- `showNotification({id, title, body, payload?}): Future<void>`
- `showAlertNotification(NotificationModel): Future<void>`

---

## 10. Controller / API Layer — Method Signatures Only

N/A — Flutter client uses screens (widgets) directly calling services via Riverpod, not controllers. See Section 9 for all service methods.

---

## 11. Security Configuration

```
Authentication: JWT Bearer tokens (access + refresh)
Token issuer/validator: MyOffGridAI-Server (external)
Password encoder: Server-side (client sends plaintext over HTTPS)

Public endpoints (no auth required):
  - /api/auth/login
  - /api/auth/register
  - /api/auth/refresh
  - /device-not-setup (client route)

Protected endpoints: All other /api/** endpoints require Bearer token

CORS: N/A (client-side)
CSRF: N/A (client-side, stateless JWT)
Rate limiting: Server-side
```

**Auth flow:**
1. Login → server returns `{accessToken, refreshToken, user}`
2. Tokens stored in FlutterSecureStorage with in-memory cache fallback
3. `_AuthInterceptor` attaches Bearer token to all requests (except `_skipAuth`)
4. On 401, interceptor attempts single token refresh, retries original request
5. On refresh failure, clears tokens → user redirected to LoginScreen via GoRouter guard

**Role-based access:** Users screen restricted to `ROLE_OWNER` and `ROLE_ADMIN` via router redirect.

---

## 12. Custom Security Components

### _AuthInterceptor (Dio Interceptor)
- Extends: `Interceptor`
- Purpose: Attaches JWT to outgoing requests, handles 401 with token refresh
- Skips auth for: requests with `_skipAuth` header, and never retries `/auth/refresh` or `/auth/login`

### _LoggingInterceptor (Dio Interceptor)
- Debug-only (kDebugMode guard)
- Logs method, path, status code via `debugPrint`
- Never logs Authorization headers or request bodies

### SecureStorageService
- Wraps FlutterSecureStorage with in-memory cache
- iOS: KeychainAccessibility.first_unlock
- Android: encryptedSharedPreferences enabled
- Best-effort persistent writes (cache always updated)

---

## 13. Exception Handling & Error Responses

### ApiException
- Fields: statusCode (int), message (String), errors (Map<String, dynamic>?)
- Created from DioException in `_handleDioException`:
  - Server response → extracts `message` and `errors` from response body
  - Connection/receive timeout → 408 with "Connection timed out" message
  - No response → status 0 with "Cannot reach MyOffGrid AI server"

Error handling is screen-level — each screen catches ApiException and shows SnackBar with `e.message`.

---

## 14. Mappers / DTOs

No separate mapper classes. All models have `factory fromJson(Map<String, dynamic>)` constructors and some have `toJson()` methods for request serialization. Mapping is inline in service methods.

---

## 15. Utility Classes & Shared Components

### DateFormatter
- `formatRelative(DateTime)`: "just now", "X minutes ago", "Mar 14"
- `formatFull(DateTime)`: "March 14, 2026 at 3:45 PM"
- `formatDate(DateTime)`: "Mar 14, 2026"
- Used by: NavigationPanel, NotificationsScreen, MemoryScreen

### SizeFormatter
- `formatBytes(int)`: "1.2 MB", "340 KB"
- Used by: SystemStatusBar, ModelCatalogModels, KnowledgeScreen

### PlatformUtils
- `isWeb`, `isMobile`, `isTablet(context)`, `isMobileWidth(context)`, `isDesktopWidth(context)`
- Used by: AppShell, various screens for responsive layout

### DownloadUtils
- `downloadBytes(List<int>, String filename)`: Web-only file download via base64 data URI
- Used by: DocumentDetailScreen

### Shared Widgets
- **AppShell**: Responsive scaffold (BottomNav on mobile, NavigationPanel on desktop) + ConnectionLostBanner + SystemStatusBar
- **NavigationPanel**: Claude-style sidebar with nav items, conversation list, search, settings. Supports collapse/expand
- **ConnectionLostBanner**: Amber banner when server unreachable (polls every 10s)
- **SystemStatusBar**: Compact bar showing Ollama status dot, model dropdown, unread notification count
- **ConfirmationDialog**: Reusable confirm/cancel dialog with destructive styling option
- **EmptyStateView**: Icon + title + subtitle for empty lists
- **ErrorView**: Error icon + title + message + optional retry button
- **LoadingIndicator**: Centered spinner with optional label, three sizes
- **NotificationBadge**: Red circle badge overlaid on child widget

---

## 16. Database Schema (Live)

N/A — Flutter client. No local database. All data persisted on MyOffGridAI-Server.

---

## 17. MESSAGE BROKER DETECTION

**MQTT broker detected.** Client connects to Mosquitto broker on the MyOffGridAI appliance.

```
Broker: Mosquitto (MQTT)
Connection: offgrid.local:1883 (derived from server URL host)
Client ID: myoffgridai-flutter-{deviceId}

Topics Subscribed:
  - /myoffgridai/{userId}/notifications — user-specific alerts
  - /myoffgridai/broadcast — server-wide broadcasts

Message Handling:
  - Incoming JSON parsed as NotificationModel
  - Displayed via LocalNotificationService
  - Notification list invalidated for refresh

Reconnection: Auto-reconnect with 5-second delay on disconnect
Android: Foreground service keeps connection alive in background
iOS/Web: Connection active only in foreground
```

---

## 18. CACHE DETECTION

No Redis or external caching layer detected.

**In-memory caching:**
- `SecureStorageService._cache`: Maps storage keys to values. Survives within session even if FlutterSecureStorage reads fail (web crypto API issue).
- Riverpod `autoDispose` providers: Auto-cache with automatic cleanup when no listeners.
- `cached_network_image` package: Disk-based image caching for network images.

---

## 19. ENVIRONMENT VARIABLE INVENTORY

N/A — Flutter client has no environment variable configuration. Server URL is stored in FlutterSecureStorage and editable via the login screen. All configuration is in `lib/config/constants.dart`.

---

## 20. SERVICE DEPENDENCY MAP

```
This Service → Depends On
--------------------------
MyOffGridAI-Client → MyOffGridAI-Server (REST API, all /api/** endpoints)
MyOffGridAI-Client → Mosquitto Broker (MQTT, port 1883, push notifications)
MyOffGridAI-Client → Kiwix Serve (HTTP, port 8888, offline wiki content via WebView)

External APIs (via server proxy):
- HuggingFace Hub (model catalog search)
- Project Gutenberg / Gutendex (book search and import)

Downstream Consumers: None (end-user client)
```

---

## 21. Known Technical Debt & Issues

### TODO/FIXME/Stub Scan Results

**PASS — No TODO, FIXME, XXX, HACK, placeholder, or stub patterns found in source code.**

### UnimplementedError Assessment

One `throw UnimplementedError` found at `lib/core/api/myoffgridai_api_client.dart:352`:
```dart
final apiClientProvider = Provider<MyOffGridAIApiClient>((ref) {
  throw UnimplementedError(
    'apiClientProvider must be overridden at startup after resolving server URL',
  );
});
```
**Assessment:** This is an **intentional Riverpod pattern** — the provider is always overridden in `main()` via `ProviderScope.overrides`. The throw only executes if someone incorrectly removes the override. **Not a code completeness issue.**

### Issues

| Issue | Location | Severity | Notes |
|-------|----------|----------|-------|
| Test coverage at 85.0% (not 100%) | Project-wide | CRITICAL | BLOCKING — 6160/7247 lines covered |
| 4 undocumented classes | message_action_bar.dart, thinking_block.dart, notifications_screen.dart | Medium | 216/220 classes documented (98.2%) |
| Snyk unsupported for Flutter | Project-wide | Low | Snyk CLI does not support pub/Flutter dependency scanning |
| `web_socket_channel` dependency unused | pubspec.yaml | Low | Package declared but no imports found in source |
| DownloadUtils._triggerDownload is no-op | shared/utils/download_utils.dart | Low | Web download via JS interop not implemented — method body empty |

---

## 22. Security Vulnerability Scan (Snyk)

```
Scan Date: 2026-03-16
Snyk CLI Version: 1.1303.0
Result: SKIPPED — Snyk CLI does not support Flutter/Dart projects (pubspec.yaml)
Error: "No supported files found (SNYK-CLI-0008)"
```

**Snyk does not support pub/Flutter dependency scanning.** Alternative tools (e.g., `dart pub audit`, `pana`) could be used for Dart-specific vulnerability checks.

### Dependency Vulnerabilities (Open Source)
SKIPPED — Snyk not supported for this project type.

### Code Vulnerabilities (SAST)
SKIPPED — Snyk Code does not support Dart.

### IaC Findings
N/A — No Dockerfile or infrastructure config present.
