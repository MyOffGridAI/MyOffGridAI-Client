# MyOffGridAI-Client — Codebase Audit

**Audit Date:** 2026-03-16T01:05:49Z
**Branch:** main
**Commit:** d086e86177cf8acea678b13a10df9b5378ba8b12 Add RTF to allowed upload extensions and MIME type mapping
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
Repository URL: https://github.com/aallard/MyOffGridAI-Client.git
Primary Language / Framework: Dart / Flutter
Dart Version: 3.11.0
Flutter Version: 3.41.1
Build Tool: Flutter SDK + pub
Current Branch: main
Latest Commit Hash: d086e86177cf8acea678b13a10df9b5378ba8b12
Latest Commit Message: Add RTF to allowed upload extensions and MIME type mapping
Audit Timestamp: 2026-03-16T01:05:49Z
```

---

## 2. Directory Structure

```
lib/
├── main.dart
├── config/
│   ├── constants.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── api/
│   │   ├── myoffgridai_api_client.dart
│   │   ├── api_exception.dart
│   │   ├── api_response.dart
│   │   └── providers.dart
│   ├── auth/
│   │   ├── auth_service.dart
│   │   ├── auth_state.dart
│   │   └── secure_storage_service.dart
│   ├── models/
│   │   ├── conversation_model.dart
│   │   ├── event_model.dart
│   │   ├── insight_model.dart
│   │   ├── inventory_item_model.dart
│   │   ├── knowledge_document_model.dart
│   │   ├── memory_model.dart
│   │   ├── message_model.dart
│   │   ├── notification_model.dart
│   │   ├── page_response.dart
│   │   ├── privacy_models.dart
│   │   ├── sensor_model.dart
│   │   ├── skill_model.dart
│   │   ├── system_models.dart
│   │   └── user_model.dart
│   └── services/
│       ├── chat_messages_notifier.dart
│       ├── chat_service.dart
│       ├── event_service.dart
│       ├── insight_service.dart
│       ├── inventory_service.dart
│       ├── knowledge_service.dart
│       ├── memory_service.dart
│       ├── notification_service.dart
│       ├── privacy_service.dart
│       ├── sensor_service.dart
│       ├── skills_service.dart
│       ├── system_service.dart
│       └── user_service.dart
├── features/
│   ├── auth/
│   │   ├── device_not_setup_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── users_screen.dart
│   ├── chat/
│   │   ├── chat_conversation_screen.dart
│   │   ├── chat_list_screen.dart
│   │   └── widgets/thinking_indicator.dart
│   ├── events/
│   │   ├── event_dialog.dart
│   │   └── events_screen.dart
│   ├── insights/
│   │   └── insights_screen.dart
│   ├── inventory/
│   │   └── inventory_screen.dart
│   ├── knowledge/
│   │   ├── document_detail_screen.dart
│   │   ├── document_editor_screen.dart
│   │   └── knowledge_screen.dart
│   ├── memory/
│   │   └── memory_screen.dart
│   ├── privacy/
│   │   └── privacy_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── sensors/
│   │   ├── add_sensor_screen.dart
│   │   ├── sensor_detail_screen.dart
│   │   └── sensors_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   ├── skills/
│   │   └── skills_screen.dart
│   └── system/
│       └── system_screen.dart
└── shared/
    ├── utils/
    │   ├── date_formatter.dart
    │   ├── download_utils.dart
    │   ├── platform_utils.dart
    │   └── size_formatter.dart
    └── widgets/
        ├── app_shell.dart
        ├── confirmation_dialog.dart
        ├── connection_lost_banner.dart
        ├── empty_state_view.dart
        ├── error_view.dart
        ├── loading_indicator.dart
        ├── navigation_panel.dart
        ├── notification_badge.dart
        └── system_status_bar.dart
```

**Summary:** Single-module Flutter application. Source in `lib/` follows feature-based organization with `config/`, `core/` (API, auth, models, services), `features/` (screens), and `shared/` (reusable widgets/utils). 74 Dart files, ~12,861 lines. 42 test files with ~3,642 lines.

---

## 3. Build & Dependency Manifest

**Build file:** `pubspec.yaml`

| Dependency | Version | Purpose |
|---|---|---|
| flutter | SDK | UI framework |
| flutter_localizations | SDK | Localization support (FlutterQuill) |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| dio | ^5.7.0 | HTTP client with interceptors |
| go_router | ^14.8.1 | Declarative routing with auth guards |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod code generation annotations |
| flutter_secure_storage | ^9.2.4 | Encrypted token/preference storage |
| web_socket_channel | ^3.0.2 | WebSocket support (declared, not yet used) |
| fl_chart | ^0.70.2 | Charts (sensor history) |
| file_picker | ^8.3.7 | File selection for uploads |
| desktop_drop | ^0.4.4 | Drag-and-drop file upload |
| cross_file | ^0.3.5+2 | Cross-platform file abstraction |
| intl | ^0.20.2 | Date/number formatting |
| flutter_quill | ^11.4.0 | Rich text editor (knowledge documents) |

**Dev Dependencies:**

| Dependency | Version | Purpose |
|---|---|---|
| flutter_test | SDK | Widget/unit testing |
| flutter_lints | ^6.0.0 | Lint rules |
| build_runner | ^2.4.15 | Code generation |
| riverpod_generator | ^2.6.3 | Riverpod code generation |
| mockito | ^5.4.6 | Mock generation |
| mocktail | ^1.0.4 | Lightweight mocking |

**Build Commands:**
```
Build: flutter build web / flutter build ios / flutter build apk
Test: flutter test
Run (web): flutter run -d chrome
Run (device): flutter run
Coverage: flutter test --coverage
```

---

## 4. Configuration & Infrastructure Summary

**This is a Flutter client application — no server-side configuration files, no Docker, no database.**

- **`lib/config/constants.dart`** — All app constants. Server URLs (`http://localhost:8080` for web, `http://offgrid.local:8080` for native), API base paths, route names, timeouts, polling intervals, UI breakpoints, validation constraints. Path: `lib/config/constants.dart`
- **`lib/config/theme.dart`** — Material 3 light/dark themes with earth-toned brand colors (primary: `#2D5016` forest green). `ThemeNotifier` persists preference via `SecureStorageService`. Path: `lib/config/theme.dart`
- **`lib/config/router.dart`** — GoRouter with auth redirect guard. Unauthenticated → `/login`. `/users` requires OWNER/ADMIN role. Path: `lib/config/router.dart`
- **`analysis_options.yaml`** — Uses `flutter_lints/flutter.yaml`. Disables `unnecessary_underscores`. Path: `analysis_options.yaml`

**Connection map:**
```
Database: None (client-side app)
Cache: None (client-side app)
Message Broker: None
External APIs: MyOffGridAI-Server (configurable URL, default http://localhost:8080)
Cloud Services: None
```

**CI/CD:** None detected.

---

## 5. Startup & Runtime Behavior

**Entry point:** `lib/main.dart` → `main()` function.

**Startup sequence:**
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `SecureStorageService()` — instantiate secure storage
3. `storage.getServerUrl()` — resolve server URL from storage or default
4. `ProviderScope` with overrides for `secureStorageProvider` and `apiClientProvider`
5. `runApp(MyOffGridAIApp)` — MaterialApp.router with GoRouter

**On boot, GoRouter redirect:**
- Reads `authStateProvider` → decodes stored JWT, checks expiry
- If expired → attempts token refresh
- If unauthenticated → redirect to `/login`
- If authenticated on `/login` or `/register` → redirect to `/`

**Background polling (auto-dispose):**
- `connectionStatusProvider` — pings `/api/system/status` every 10s
- `modelHealthProvider` — polls `/api/models/health` every 60s
- `unreadCountProvider` — polls `/api/notifications/unread-count` every 30s

**Health check:** No dedicated health endpoint — monitors server connectivity via `connectionStatusProvider`.

---

## 6. Entity / Data Model Layer

All models are immutable Dart classes mirroring server DTOs. No ORM — this is a client-side app.

```
=== UserModel (lib/core/models/user_model.dart) ===
Fields:
  - id: String (required)
  - username: String (required)
  - displayName: String (required)
  - role: String (required, values: ROLE_OWNER, ROLE_ADMIN, ROLE_MEMBER)
  - isActive: bool (required)
  - email: String? (nullable)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== ConversationModel (lib/core/models/conversation_model.dart) ===
Fields:
  - id: String (required)
  - title: String? (nullable)
  - messageCount: int (required)
  - archived: bool (default: false)
  - createdAt: String? (nullable)
  - updatedAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== ConversationSummaryModel ===
Fields:
  - id: String (required)
  - title: String? (nullable)
  - lastMessagePreview: String? (nullable)
  - messageCount: int (default: 0)
  - updatedAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== MessageModel (lib/core/models/message_model.dart) ===
Fields:
  - id: String (required)
  - role: String (required, values: USER, ASSISTANT, SYSTEM)
  - content: String (required)
  - hasRagContext: bool (required)
  - ragSources: List<String>? (nullable)
  - createdAt: String? (nullable)
  - responseTimeMs: int? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== MemoryModel (lib/core/models/memory_model.dart) ===
Fields:
  - id: String (required)
  - content: String (required)
  - importance: String (required, values: LOW, MEDIUM, HIGH, CRITICAL)
  - tags: List<String> (default: [])
  - sourceConversationId: String? (nullable)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== MemorySearchResultModel ===
Fields:
  - memory: MemoryModel (required)
  - similarityScore: double (required)
Factory: fromJson(Map<String, dynamic>)

=== KnowledgeDocumentModel (lib/core/models/knowledge_document_model.dart) ===
Fields:
  - id: String (required)
  - originalFilename: String (required)
  - displayName: String? (nullable)
  - contentType: String? (nullable)
  - fileSize: int (default: 0)
  - status: String (required, values: PENDING, PROCESSING, INDEXED, FAILED)
  - chunkCount: int (default: 0)
  - failureReason: String? (nullable)
  - uploadedAt: String? (nullable)
  - processedAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== DocumentContentModel ===
Fields:
  - documentId: String (required)
  - content: String (required)
  - contentType: String (required)
Factory: fromJson(Map<String, dynamic>)

=== KnowledgeSearchResultModel ===
Fields:
  - documentId: String (required)
  - documentName: String (required)
  - chunkContent: String (required)
  - similarityScore: double (required)
Factory: fromJson(Map<String, dynamic>)

=== SkillModel (lib/core/models/skill_model.dart) ===
Fields:
  - id: String (required)
  - name: String (required)
  - description: String? (nullable)
  - category: String? (nullable)
  - enabled: bool (default: true)
  - parameters: Map<String, dynamic>? (nullable)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== SkillExecutionModel ===
Fields:
  - id: String (required)
  - skillId: String (required)
  - skillName: String (required)
  - status: String (required, values: PENDING, RUNNING, SUCCESS, FAILED)
  - result: String? (nullable)
  - error: String? (nullable)
  - executedAt: String? (nullable)
  - durationMs: int? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== InventoryItemModel (lib/core/models/inventory_item_model.dart) ===
Fields:
  - id: String (required)
  - name: String (required)
  - category: String (required, values: FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER)
  - quantity: double (required)
  - unit: String (required)
  - minimumQuantity: double? (nullable)
  - location: String? (nullable)
  - notes: String? (nullable)
  - lastUpdated: String? (nullable)
Custom: isLowStock → bool (quantity < minimumQuantity)
Factory: fromJson(Map<String, dynamic>)

=== SensorModel (lib/core/models/sensor_model.dart) ===
Fields:
  - id: String (required)
  - name: String (required)
  - type: String (default: 'TEMPERATURE', values: TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION)
  - port: String (required)
  - baudRate: int (default: 9600)
  - dataFormat: String (default: 'CSV_LINE', values: CSV_LINE, JSON_LINE, RAW_TEXT)
  - pollingIntervalSeconds: int (default: 60)
  - active: bool (default: false)
  - lowThreshold: double? (nullable)
  - highThreshold: double? (nullable)
  - latestReading: SensorReadingModel? (nullable)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== SensorReadingModel ===
Fields:
  - id: String (required)
  - sensorId: String (required)
  - value: double (required)
  - unit: String? (nullable)
  - timestamp: String (required)
Factory: fromJson(Map<String, dynamic>)

=== SensorTestResultModel ===
Fields:
  - success: bool (required)
  - message: String? (nullable)
  - sampleData: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== InsightModel (lib/core/models/insight_model.dart) ===
Fields:
  - id: String (required)
  - content: String (required)
  - category: String (required, values: SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING)
  - read: bool (default: false)
  - dismissed: bool (default: false)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== NotificationModel (lib/core/models/notification_model.dart) ===
Fields:
  - id: String (required)
  - title: String (required)
  - message: String (required)
  - type: String (required, values: ALERT, INFO, WARNING, ERROR, SUCCESS)
  - read: bool (default: false)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== ScheduledEventModel (lib/core/models/event_model.dart) ===
Fields:
  - id: String (required)
  - name: String (required)
  - description: String? (nullable)
  - eventType: String (required, values: SCHEDULED, SENSOR_THRESHOLD, RECURRING)
  - actionType: String (required, values: PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY)
  - enabled: bool (default: true)
  - cronExpression: String? (nullable)
  - sensorId: String? (nullable)
  - thresholdOperator: String? (nullable, values: ABOVE, BELOW, EQUALS)
  - thresholdValue: double? (nullable)
  - recurringIntervalMinutes: int? (nullable)
  - actionPayload: String? (nullable)
  - lastTriggered: String? (nullable)
  - nextTrigger: String? (nullable)
  - createdAt: String? (nullable)
Factory: fromJson(Map<String, dynamic>)

=== PageResponse<T> (lib/core/models/page_response.dart) ===
Fields:
  - content: List<T> (required)
  - totalElements: int (required)
  - totalPages: int (required)
  - size: int (required)
  - number: int (required)
  - first: bool (required)
  - last: bool (required)
  - empty: bool (required)
Factory: fromJson(Map<String, dynamic>, T Function(dynamic))

=== FortressStatusModel (lib/core/models/privacy_models.dart) ===
Fields:
  - enabled: bool (required)
  - lastVerified: String? (nullable)
  - verificationPassed: bool (default: false)
Factory: fromJson(Map<String, dynamic>)

=== DataInventoryModel ===
Fields: conversations, messages, memories, documents, sensors, insights (all int)
Factory: fromJson(Map<String, dynamic>)

=== AuditSummaryModel ===
Fields: totalActions, successCount, failureCount, deniedCount (all int)
Factory: fromJson(Map<String, dynamic>)

=== SovereigntyReportModel ===
Fields: fortress (FortressStatusModel), dataInventory (DataInventoryModel), auditSummary (AuditSummaryModel), dataResidency (String), generatedAt (String?)
Factory: fromJson(Map<String, dynamic>)

=== AuditLogModel ===
Fields: id, action, outcome (SUCCESS/FAILURE/DENIED), userId, details, timestamp (all String)
Factory: fromJson(Map<String, dynamic>)

=== WipeResultModel ===
Fields: conversationsDeleted, memoriesDeleted, documentsDeleted (all int)
Factory: fromJson(Map<String, dynamic>)

=== SystemStatusModel (lib/core/models/system_models.dart) ===
Fields: initialized (bool), fortressEnabled (bool), wifiConfigured (bool), serverVersion (String?), uptime (String?), javaVersion (String?), totalMemory (String?), freeMemory (String?)
Factory: fromJson(Map<String, dynamic>)

=== OllamaModelInfoModel ===
Fields: name (String), size (int), modifiedAt (String?)
Factory: fromJson(Map<String, dynamic>)

=== AiSettingsModel ===
Fields: modelName (String), temperature (double), similarityThreshold (double), memoryTopK (int), ragMaxContextTokens (int)
Factory: fromJson(Map<String, dynamic>)
Method: toJson()

=== StorageSettingsModel ===
Fields: documentsPath (String), modelsPath (String), logsPath (String), totalDiskSpace (int), usedDiskSpace (int), freeDiskSpace (int)
Factory: fromJson(Map<String, dynamic>)

=== ActiveModelInfo ===
Fields: chatModelName (String?), embedModelName (String?)
Factory: fromJson(Map<String, dynamic>)
```

---

## 7. Enum Inventory

```
=== SensorType (lib/core/models/sensor_model.dart) ===
Values: TEMPERATURE, HUMIDITY, PRESSURE, SOIL_MOISTURE, WIND_SPEED, SOLAR_RADIATION
Used in: SensorModel.type, SensorType class constants

=== DataFormat (lib/core/models/sensor_model.dart) ===
Values: CSV_LINE, JSON_LINE, RAW_TEXT
Used in: SensorModel.dataFormat

=== InventoryCategory (lib/core/models/inventory_item_model.dart) ===
Values: FOOD, WATER, FUEL, TOOLS, MEDICINE, SPARE_PARTS, OTHER
Used in: InventoryItemModel.category
Has display label: YES (label getter)

=== InsightCategory (lib/core/models/insight_model.dart) ===
Values: SECURITY, EFFICIENCY, HEALTH, MAINTENANCE, SUSTAINABILITY, PLANNING
Used in: InsightModel.category

=== NotificationType (lib/core/models/notification_model.dart) ===
Values: ALERT, INFO, WARNING, ERROR, SUCCESS
Used in: NotificationModel.type

=== EventType (lib/core/models/event_model.dart) ===
Values: SCHEDULED, SENSOR_THRESHOLD, RECURRING
Used in: ScheduledEventModel.eventType

=== ActionType (lib/core/models/event_model.dart) ===
Values: PUSH_NOTIFICATION, AI_PROMPT, AI_SUMMARY
Used in: ScheduledEventModel.actionType

=== ThresholdOperator (lib/core/models/event_model.dart) ===
Values: ABOVE, BELOW, EQUALS
Used in: ScheduledEventModel.thresholdOperator

=== AuditOutcome (lib/core/models/privacy_models.dart) ===
Values: SUCCESS, FAILURE, DENIED
Used in: AuditLogModel.outcome

=== LoadingSize (lib/shared/widgets/loading_indicator.dart) ===
Values: small(16), medium(24), large(40)
Used in: LoadingIndicator.size
Has display label: NO (dimension only)
```

---

## 8. Repository Layer

**N/A — Flutter client application. No local database or repository pattern. All data access is via HTTP through service classes calling `MyOffGridAIApiClient`.**

---

## 9. Service Layer — Full Method Signatures

```
=== AuthService (lib/core/auth/auth_service.dart) ===
Injects: MyOffGridAIApiClient, SecureStorageService

Public Methods:
  - login(String username, String password): Future<AuthResponse>
    Purpose: Authenticates and stores tokens
    Calls: client.post('/api/auth/login'), storage.saveTokens()
  - register({username, displayName, password, email?, role}): Future<AuthResponse>
    Purpose: Creates account and stores tokens
    Calls: client.post('/api/auth/register'), storage.saveTokens()
  - logout(): Future<void>
    Purpose: Server logout (best-effort) + clear local tokens
    Calls: client.post('/api/auth/logout'), storage.clearTokens()
  - refresh(): Future<AuthResponse>
    Purpose: Refreshes access token using refresh token
    Calls: client.post('/api/auth/refresh'), storage.saveTokens()
  - getCurrentUser(String userId): Future<UserModel>
    Purpose: Fetches user profile from server
    Calls: client.get('/api/users/{id}')

=== ChatService (lib/core/services/chat_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listConversations(): Future<List<ConversationSummaryModel>>
    Calls: client.get('/api/chat/conversations')
  - createConversation(): Future<ConversationModel>
    Calls: client.post('/api/chat/conversations')
  - getConversation(String id): Future<ConversationModel>
    Calls: client.get('/api/chat/conversations/{id}')
  - deleteConversation(String id): Future<void>
    Calls: client.delete('/api/chat/conversations/{id}')
  - renameConversation(String id, String title): Future<void>
    Calls: client.put('/api/chat/conversations/{id}/title')
  - listMessages(String conversationId): Future<List<MessageModel>>
    Calls: client.get('/api/chat/conversations/{id}/messages')
  - sendMessage(String conversationId, String content): Future<MessageModel>
    Calls: client.post('/api/chat/conversations/{id}/messages')

=== ChatMessagesNotifier (lib/core/services/chat_messages_notifier.dart) ===
Extends: AutoDisposeFamilyAsyncNotifier<List<MessageModel>, String>
Injects: ChatService (via ref.watch)

Public Methods:
  - build(String conversationId): Future<List<MessageModel>>
    Purpose: Initial message load for conversation
  - sendMessage(String content): Future<void>
    Purpose: Optimistic send with thinking indicator, re-fetch on success

=== MemoryService (lib/core/services/memory_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listMemories(): Future<List<MemoryModel>>
  - getMemory(String id): Future<MemoryModel>
  - deleteMemory(String id): Future<void>
  - updateTags(String id, List<String> tags): Future<MemoryModel>
  - updateImportance(String id, String importance): Future<MemoryModel>
  - searchMemories(String query): Future<List<MemorySearchResultModel>>
  - exportMemories(): Future<List<MemoryModel>>

=== KnowledgeService (lib/core/services/knowledge_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listDocuments(): Future<List<KnowledgeDocumentModel>>
  - getDocument(String id): Future<KnowledgeDocumentModel>
  - getDocumentContent(String id): Future<DocumentContentModel>
  - uploadDocument(String filename, List<int> bytes, {String? displayName}): Future<KnowledgeDocumentModel>
  - createDocument(String title, String content): Future<KnowledgeDocumentModel>
  - updateDocumentContent(String id, String content): Future<void>
  - updateDisplayName(String id, String displayName): Future<KnowledgeDocumentModel>
  - deleteDocument(String id): Future<void>
  - retryProcessing(String id): Future<KnowledgeDocumentModel>
  - searchDocuments(String query): Future<List<KnowledgeSearchResultModel>>
  - downloadDocument(String id): Future<List<int>>

=== SkillsService (lib/core/services/skills_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listSkills(): Future<List<SkillModel>>
  - getSkill(String id): Future<SkillModel>
  - toggleSkill(String id): Future<SkillModel>
  - executeSkill(String skillId, {Map<String, dynamic>? params}): Future<SkillExecutionModel>
  - listExecutions({int page, int size}): Future<PageResponse<SkillExecutionModel>>

=== InventoryService (lib/core/services/inventory_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listItems(): Future<List<InventoryItemModel>>
  - createItem(InventoryItemModel item): Future<InventoryItemModel>
  - updateItem(String id, InventoryItemModel item): Future<InventoryItemModel>
  - deleteItem(String id): Future<void>

=== SensorService (lib/core/services/sensor_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listSensors(): Future<List<SensorModel>>
  - getSensor(String id): Future<SensorModel>
  - createSensor(SensorModel sensor): Future<SensorModel>
  - deleteSensor(String id): Future<void>
  - startSensor(String id): Future<void>
  - stopSensor(String id): Future<void>
  - getLatestReading(String id): Future<SensorReadingModel>
  - getReadingHistory(String id, {int hours}): Future<List<SensorReadingModel>>
  - updateThresholds(String id, {double? low, double? high}): Future<SensorModel>
  - testConnection(String port, int baudRate, String dataFormat): Future<SensorTestResultModel>
  - getAvailablePorts(): Future<List<String>>

=== EventService (lib/core/services/event_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listEvents(): Future<List<ScheduledEventModel>>
  - createEvent(ScheduledEventModel event): Future<ScheduledEventModel>
  - updateEvent(String id, ScheduledEventModel event): Future<ScheduledEventModel>
  - deleteEvent(String id): Future<void>
  - toggleEvent(String id, bool enabled): Future<ScheduledEventModel>

=== InsightService (lib/core/services/insight_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listInsights(): Future<List<InsightModel>>
  - generateInsights(): Future<List<InsightModel>>
  - markAsRead(String id): Future<void>
  - dismiss(String id): Future<void>
  - getUnreadCount(): Future<int>

=== NotificationService (lib/core/services/notification_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listNotifications(): Future<List<NotificationModel>>
  - markAsRead(String id): Future<void>
  - markAllRead(): Future<void>
  - deleteNotification(String id): Future<void>
  - getUnreadCount(): Future<int>

=== PrivacyService (lib/core/services/privacy_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - getFortressStatus(): Future<FortressStatusModel>
  - enableFortress(): Future<FortressStatusModel>
  - disableFortress(): Future<FortressStatusModel>
  - getSovereigntyReport(): Future<SovereigntyReportModel>
  - getAuditLogs({int page, int size}): Future<List<AuditLogModel>>
  - wipeSelfData(): Future<WipeResultModel>

=== SystemService (lib/core/services/system_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - getSystemStatus(): Future<SystemStatusModel>
  - getModelHealth(): Future<OllamaHealthDto>
  - listModels(): Future<List<OllamaModelInfoModel>>
  - getActiveModel(): Future<ActiveModelInfo>
  - getAiSettings(): Future<AiSettingsModel>
  - updateAiSettings(AiSettingsModel settings): Future<void>
  - getStorageSettings(): Future<StorageSettingsModel>

=== UserService (lib/core/services/user_service.dart) ===
Injects: MyOffGridAIApiClient

Public Methods:
  - listUsers(): Future<List<UserModel>>
  - getUser(String id): Future<UserModel>
  - updateUser(String id, {String? displayName, String? role, String? email}): Future<UserModel>
  - deactivateUser(String id): Future<void>
  - deleteUser(String id): Future<void>
```

---

## 10. Controller / API Layer — Method Signatures Only

**N/A — Flutter client. No controllers. Screen widgets call services directly via Riverpod providers. See Section 9 for service → API mapping.**

---

## 11. Security Configuration

```
Authentication: JWT (Bearer token in Authorization header)
Token issuer/validator: MyOffGridAI-Server (external)
Token storage: flutter_secure_storage
  - iOS: Keychain (KeychainAccessibility.first_unlock)
  - Android: EncryptedSharedPreferences
  - Web: In-memory cache (platform storage best-effort)

Public routes (no auth required):
  - /login
  - /register
  - /device-not-setup

Protected routes (auth required):
  - All other routes (/* via GoRouter redirect guard)

Role-restricted routes:
  - /users → ROLE_OWNER or ROLE_ADMIN only

CORS: N/A (client-side app)
CSRF: N/A (client-side app, JWT-based auth)
Rate limiting: None (handled server-side)
```

---

## 12. Custom Security Components

```
=== _AuthInterceptor (lib/core/api/myoffgridai_api_client.dart:217) ===
Extends: Dio Interceptor
Purpose: Attaches JWT Bearer token to every request, auto-refreshes on 401
Extracts token from: SecureStorageService (in-memory cache + platform storage)
Sets Authorization header: YES ('Bearer $token')
Token refresh: On 401, attempts refreshToken() then retries original request
Refresh guard: _isRefreshing flag prevents concurrent refresh attempts
Skip auth: Requests with '_skipAuth' header bypass token attachment
Never retries: /auth/refresh, /auth/login paths

=== AuthNotifier (lib/core/auth/auth_state.dart) ===
Extends: AsyncNotifier<UserModel?>
Purpose: Manages auth state lifecycle
On build: Decodes stored JWT payload, checks expiry, auto-refreshes if needed
Login: Calls AuthService.login(), sets AsyncData(user)
Register: Calls AuthService.register(), sets AsyncData(user)
Logout: Calls AuthService.logout(), sets AsyncData(null)
JWT decode: Manual base64 decode of JWT payload (no library dependency)

=== SecureStorageService (lib/core/auth/secure_storage_service.dart) ===
Purpose: Encrypted storage wrapper with in-memory cache fallback
Stores: accessToken, refreshToken, serverUrl, themePreference
Write strategy: Cache first, then persist (write failure tolerated)
Read strategy: Cache hit → return; miss → read storage → cache → return
```

---

## 13. Exception Handling & Error Responses

```
=== ApiException (lib/core/api/api_exception.dart) ===
Implements: Exception

Fields:
  - statusCode: int
  - message: String
  - errors: Map<String, dynamic>? (field-level validation errors)

Created by: MyOffGridAIApiClient._handleDioException()
  - Server error response → extracts message + errors from response body
  - Timeout → 408 with "Connection timed out" message
  - Connection failure → 0 with "Cannot reach MyOffGrid AI server"

Standard error display pattern:
  - Screens catch ApiException, show SnackBar with e.message
  - ErrorView widget for full-screen error states with retry button
  - ConnectionLostBanner for persistent connectivity warnings
```

---

## 14. Mappers / DTOs

**No mapper framework.** All models have manual `fromJson(Map<String, dynamic>)` factory constructors. `AiSettingsModel` has a `toJson()` method. The `ApiResponse<T>` envelope class delegates to a `fromJsonT` factory callback.

---

## 15. Utility Classes & Shared Components

```
=== DateFormatter (lib/shared/utils/date_formatter.dart) ===
Methods:
  - formatRelative(DateTime): String — "just now", "X minutes ago", "Yesterday", "Mar 14"
  - formatFull(DateTime): String — "March 14, 2026 at 3:45 PM"
  - formatDate(DateTime): String — "Mar 14, 2026"
Used by: NavigationPanel (conversation timestamps), multiple screens

=== SizeFormatter (lib/shared/utils/size_formatter.dart) ===
Methods:
  - formatBytes(int): String — "1.2 MB", "340 KB"
Used by: DocumentDetailScreen, SystemStatusBar

=== PlatformUtils (lib/shared/utils/platform_utils.dart) ===
Methods:
  - isWeb: bool
  - isMobile: bool (non-web)
  - isTablet(BuildContext): bool (600-1200px)
  - isMobileWidth(BuildContext): bool (<600px)
  - isDesktopWidth(BuildContext): bool (>=1200px)
Used by: AppShell, various responsive layouts

=== DownloadUtils (lib/shared/utils/download_utils.dart) ===
Methods:
  - downloadBytes(List<int>, String): void — Web-only file download via base64 data URI
  - _guessMimeType(String): String — Extension-based MIME type lookup
Used by: DocumentDetailScreen

=== Shared Widgets ===
  - AppShell — Responsive scaffold: BottomNavigationBar (<600px), NavigationPanel (>=600px)
  - NavigationPanel — Collapsible sidebar with nav items, conversation list, search, settings
  - SystemStatusBar — Ollama status dot, model dropdown, notification badge
  - ConnectionLostBanner — Amber banner when server unreachable
  - LoadingIndicator — CircularProgressIndicator in 3 sizes with optional label
  - ErrorView — Error state with icon, title, message, retry button
  - EmptyStateView — Empty list state with icon, title, subtitle
  - ConfirmationDialog — Confirm/cancel dialog with destructive option
  - NotificationBadge — Red circle badge with count overlay
  - ThinkingIndicator — Animated pulsing dots for AI response generation
```

---

## 16. Database Schema (Live)

**N/A — Flutter client application. No local database. All data persisted server-side via MyOffGridAI-Server REST API.**

---

## 17. MESSAGE BROKER DETECTION

No message broker detected. `web_socket_channel` is declared as a dependency but not actively used in the current codebase.

---

## 18. CACHE DETECTION

No Redis or caching layer detected. `SecureStorageService` maintains an in-memory `Map<String, String>` cache for tokens/preferences within a session, but this is not a general caching mechanism.

---

## 19. ENVIRONMENT VARIABLE INVENTORY

**N/A — Flutter client app. No environment variables. Configuration is handled via:**
- `AppConstants` class (compile-time constants)
- `SecureStorageService` (runtime user-configurable: server URL, theme)
- Server URL defaults: `http://localhost:8080` (web) / `http://offgrid.local:8080` (native)

---

## 20. SERVICE DEPENDENCY MAP

```
This Client → Depends On
--------------------------
MyOffGridAI-Server: (configurable URL, default http://localhost:8080)
  Auth endpoints: /api/auth/*
  Chat endpoints: /api/chat/*
  Memory endpoints: /api/memory/*
  Knowledge endpoints: /api/knowledge/*
  Skills endpoints: /api/skills/*
  Inventory endpoints: /api/skills/inventory/*
  Sensor endpoints: /api/sensors/*
  Event endpoints: /api/events/*
  Insight endpoints: /api/insights/*
  Notification endpoints: /api/notifications/*
  Privacy endpoints: /api/privacy/*
  System endpoints: /api/system/*
  Model endpoints: /api/models/*
  User endpoints: /api/users/*

Downstream Consumers: None (end-user client)
```

---

## 21. Known Technical Debt & Issues

```
Issue | Location | Severity | Notes
------|----------|----------|------
Test coverage at 37.2% | project-wide | CRITICAL | BLOCKING — 100% coverage required, currently only models and basic widget tests
Doc coverage 72% (106/147 classes) | 22 files with undocumented classes | CRITICAL | BLOCKING — Private State classes in screens lack DartDoc
web_socket_channel unused | pubspec.yaml | Low | Declared dependency not used anywhere in codebase
DownloadUtils._triggerDownload is no-op | lib/shared/utils/download_utils.dart:40 | Medium | Web download logic incomplete (empty method body)
apiClientProvider throws UnimplementedError | lib/core/api/myoffgridai_api_client.dart:295 | Low | Deliberate Riverpod override pattern, not a stub
Snyk Code SAST scan skipped | project-wide | Medium | Snyk Code not enabled for org — cannot run SAST analysis
No CI/CD pipeline | project root | Medium | No GitHub Actions, Jenkins, or GitLab CI detected
No integration tests | test/ | High | All 221 tests are unit/widget tests — no end-to-end or integration testing
Architecture doc outdated | MyOffGridAI-Client-Architecture.md | Low | References "More" menu and NavigationRail which have been replaced by NavigationPanel
```

---

## 22. Security Vulnerability Scan (Snyk)

Scan Date: 2026-03-16T01:05:49Z
Snyk CLI Version: 1.1303.0

### Dependency Vulnerabilities (Open Source)
Critical: 0
High: 0
Medium: 0
Low: 0

**PASS — No known vulnerabilities in dependencies.**

### Code Vulnerabilities (SAST)
**SKIPPED — Snyk Code not enabled for organization `aallard`.** Activate Snyk Code in the Snyk dashboard and re-run.

### IaC Findings
N/A — No Dockerfile, docker-compose, or Terraform files detected.
