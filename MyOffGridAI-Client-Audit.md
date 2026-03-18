# MyOffGridAI-Client — Codebase Audit

**Audit Date:** 2026-03-18T00:22:40Z
**Branch:** main
**Commit:** 3f8d787eb623885c1b0a9518e0f3dfa54022e6ce P15-Fix: Wire LM Studio-style Discover tab layout into settings screen
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
Repository URL:        https://github.com/MyOffGridAI/MyOffGridAI-Client (assumed)
Primary Language:      Dart / Flutter
Dart SDK Version:      ^3.11.0
Build Tool:            Flutter SDK + pub
Current Branch:        main
Latest Commit Hash:    3f8d787eb623885c1b0a9518e0f3dfa54022e6ce
Latest Commit Message: P15-Fix: Wire LM Studio-style Discover tab layout into settings screen
Audit Timestamp:       2026-03-18T00:22:59Z
```

---

## 2. Directory Structure

```
./.claude/settings.local.json
./analysis_options.yaml
./CONVENTIONS.md
./lib/config/constants.dart
./lib/config/router.dart
./lib/config/theme.dart
./lib/core/api/api_exception.dart
./lib/core/api/api_response.dart
./lib/core/api/myoffgridai_api_client.dart
./lib/core/api/providers.dart
./lib/core/auth/auth_service.dart
./lib/core/auth/auth_state.dart
./lib/core/auth/secure_storage_service.dart
./lib/core/models/conversation_model.dart
./lib/core/models/device_registration_model.dart
./lib/core/models/enrichment_models.dart
./lib/core/models/event_model.dart
./lib/core/models/inference_stream_event.dart
./lib/core/models/insight_model.dart
./lib/core/models/inventory_item_model.dart
./lib/core/models/judge_models.dart
./lib/core/models/knowledge_document_model.dart
./lib/core/models/library_models.dart
./lib/core/models/memory_model.dart
./lib/core/models/message_model.dart
./lib/core/models/model_catalog_models.dart
./lib/core/models/notification_model.dart
./lib/core/models/page_response.dart
./lib/core/models/privacy_models.dart
./lib/core/models/sensor_model.dart
./lib/core/models/skill_model.dart
./lib/core/models/system_models.dart
./lib/core/models/user_model.dart
./lib/core/services/chat_messages_notifier.dart
./lib/core/services/chat_service.dart
./lib/core/services/device_registration_service.dart
./lib/core/services/enrichment_service.dart
./lib/core/services/event_service.dart
./lib/core/services/foreground_service_manager.dart
./lib/core/services/insight_service.dart
./lib/core/services/inventory_service.dart
./lib/core/services/judge_service.dart
./lib/core/services/knowledge_service.dart
./lib/core/services/library_service.dart
./lib/core/services/local_notification_service.dart
./lib/core/services/memory_service.dart
./lib/core/services/model_catalog_service.dart
./lib/core/services/mqtt_service.dart
./lib/core/services/notification_service.dart
./lib/core/services/privacy_service.dart
./lib/core/services/sensor_service.dart
./lib/core/services/skills_service.dart
./lib/core/services/system_service.dart
./lib/core/services/user_service.dart
./lib/features/auth/device_not_setup_screen.dart
./lib/features/auth/login_screen.dart
./lib/features/auth/register_screen.dart
./lib/features/auth/users_screen.dart
./lib/features/books/book_reader_screen.dart
./lib/features/books/books_screen.dart
./lib/features/chat/chat_conversation_screen.dart
./lib/features/chat/chat_list_screen.dart
./lib/features/chat/widgets/inference_metadata_row.dart
./lib/features/chat/widgets/message_action_bar.dart
./lib/features/chat/widgets/message_bubble.dart
./lib/features/chat/widgets/thinking_block.dart
./lib/features/chat/widgets/thinking_indicator.dart
./lib/features/events/event_dialog.dart
./lib/features/events/events_screen.dart
./lib/features/insights/insights_screen.dart
./lib/features/inventory/inventory_screen.dart
./lib/features/knowledge/document_detail_screen.dart
./lib/features/knowledge/document_editor_screen.dart
./lib/features/knowledge/knowledge_screen.dart
./lib/features/memory/memory_screen.dart
./lib/features/notifications/notifications_screen.dart
./lib/features/privacy/privacy_screen.dart
./lib/features/search/search_screen.dart
./lib/features/sensors/add_sensor_screen.dart
./lib/features/sensors/sensor_detail_screen.dart
./lib/features/sensors/sensors_screen.dart
./lib/features/settings/settings_screen.dart
./lib/features/settings/widgets/discover_model_list.dart
./lib/features/settings/widgets/model_detail_panel.dart
./lib/features/settings/widgets/smart_quant_selector.dart
./lib/features/skills/skills_screen.dart
./lib/features/system/system_screen.dart
./lib/main.dart
./lib/shared/utils/date_formatter.dart
./lib/shared/utils/download_trigger_stub.dart
./lib/shared/utils/download_trigger_web.dart
./lib/shared/utils/download_utils.dart
./lib/shared/utils/platform_utils.dart
./lib/shared/utils/size_formatter.dart
./lib/shared/widgets/app_shell.dart
./lib/shared/widgets/confirmation_dialog.dart
./lib/shared/widgets/connection_lost_banner.dart
./lib/shared/widgets/empty_state_view.dart
./lib/shared/widgets/error_view.dart
./lib/shared/widgets/loading_indicator.dart
./lib/shared/widgets/navigation_panel.dart
./lib/shared/widgets/notification_badge.dart
./lib/shared/widgets/system_status_bar.dart
./MyOffGridAI-Client-Architecture.md
./MyOffGridAI-Client-Audit.md
./pubspec.yaml
./README.md
./test/config/constants_test.dart
./test/config/router_coverage_test.dart
./test/config/router_test.dart
./test/config/theme_test.dart
./test/core/api/myoffgridai_api_client_test.dart
./test/core/api/providers_test.dart
./test/core/auth/auth_service_test.dart
./test/core/auth/auth_state_test.dart
./test/core/auth/secure_storage_service_test.dart
./test/core/models/conversation_model_test.dart
./test/core/models/device_registration_model_test.dart
./test/core/models/enrichment_models_test.dart
./test/core/models/event_model_test.dart
./test/core/models/inference_stream_event_test.dart
./test/core/models/insight_model_test.dart
./test/core/models/inventory_item_model_test.dart
./test/core/models/judge_models_test.dart
./test/core/models/knowledge_document_model_test.dart
./test/core/models/library_models_test.dart
./test/core/models/memory_model_test.dart
./test/core/models/message_model_test.dart
./test/core/models/model_catalog_models_test.dart
./test/core/models/notification_model_test.dart
./test/core/models/page_response_test.dart
./test/core/models/privacy_models_test.dart
./test/core/models/sensor_model_test.dart
./test/core/models/skill_model_test.dart
./test/core/models/system_models_test.dart
./test/core/models/user_model_test.dart
./test/core/services/chat_messages_notifier_test.dart
./test/core/services/chat_service_test.dart
./test/core/services/device_registration_service_test.dart
./test/core/services/enrichment_service_test.dart
./test/core/services/event_service_test.dart
./test/core/services/foreground_service_manager_test.dart
./test/core/services/insight_service_test.dart
./test/core/services/inventory_service_test.dart
./test/core/services/knowledge_service_test.dart
./test/core/services/library_service_test.dart
./test/core/services/local_notification_service_test.dart
./test/core/services/memory_service_test.dart
./test/core/services/model_catalog_service_test.dart
./test/core/services/mqtt_service_test.dart
./test/core/services/notification_service_test.dart
./test/core/services/privacy_service_test.dart
./test/core/services/sensor_service_test.dart
./test/core/services/skills_service_test.dart
./test/core/services/system_service_test.dart
./test/core/services/user_service_test.dart
./test/features/auth/device_not_setup_screen_test.dart
./test/features/auth/login_screen_test.dart
./test/features/auth/register_screen_test.dart
./test/features/auth/users_screen_test.dart
./test/features/books/book_reader_screen_test.dart
./test/features/books/books_screen_test.dart
./test/features/chat/chat_conversation_screen_test.dart
./test/features/chat/chat_list_screen_test.dart
./test/features/chat/widgets/inference_metadata_row_test.dart
./test/features/chat/widgets/message_action_bar_test.dart
./test/features/chat/widgets/message_bubble_test.dart
./test/features/chat/widgets/thinking_block_test.dart
./test/features/chat/widgets/thinking_indicator_test.dart
./test/features/events/event_dialog_test.dart
./test/features/events/events_screen_test.dart
./test/features/insights/insights_screen_test.dart
./test/features/inventory/inventory_screen_test.dart
./test/features/knowledge/document_detail_screen_test.dart
./test/features/knowledge/document_editor_screen_test.dart
./test/features/knowledge/knowledge_screen_test.dart
./test/features/memory/memory_screen_test.dart
./test/features/notifications/notifications_screen_test.dart
./test/features/privacy/privacy_screen_test.dart
./test/features/search/search_screen_test.dart
./test/features/sensors/add_sensor_screen_test.dart
./test/features/sensors/sensor_detail_screen_test.dart
./test/features/sensors/sensors_screen_test.dart
./test/features/settings/settings_screen_test.dart
./test/features/skills/skills_screen_test.dart
./test/features/system/system_screen_test.dart
./test/shared/utils/date_formatter_test.dart
./test/shared/utils/download_trigger_stub_test.dart
./test/shared/utils/download_utils_test.dart
./test/shared/utils/platform_utils_test.dart
./test/shared/utils/size_formatter_test.dart
./test/shared/widgets/app_shell_test.dart
./test/shared/widgets/confirmation_dialog_test.dart
./test/shared/widgets/connection_lost_banner_test.dart
./test/shared/widgets/empty_state_view_test.dart
./test/shared/widgets/error_view_test.dart
./test/shared/widgets/loading_indicator_test.dart
./test/shared/widgets/navigation_panel_test.dart
./test/shared/widgets/notification_badge_test.dart
./test/shared/widgets/system_status_bar_test.dart
./test/widget_test.dart
./web/index.html
./web/manifest.json
```

**Layout:** Single-module Flutter client application. Source code is in `lib/` organized by feature. `lib/config/` holds app-wide configuration (routing, theme, constants). `lib/core/` contains the API client, auth layer, data models, and services. `lib/features/` has per-feature screens and widgets. `lib/shared/` holds reusable utilities and widgets. `test/` mirrors `lib/` structure 1:1.

---

## 3. Build & Dependency Manifest

**Build file:** `pubspec.yaml`

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter (sdk) | — | Core Flutter framework |
| flutter_localizations (sdk) | — | Internationalization support |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| dio | ^5.7.0 | HTTP client for REST API calls |
| go_router | ^14.8.1 | Declarative routing |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod code generation annotations |
| flutter_secure_storage | ^9.2.4 | Secure token/credential storage |
| fl_chart | ^0.70.2 | Chart/graph rendering |
| file_picker | ^8.3.7 | File selection dialog |
| desktop_drop | ^0.4.4 | Drag-and-drop file support |
| cross_file | ^0.3.5+2 | Cross-platform file abstraction |
| intl | ^0.20.2 | Date/number formatting, i18n |
| flutter_quill | ^11.4.0 | Rich text editor |
| mqtt_client | ^10.2.1 | MQTT pub/sub messaging |
| flutter_local_notifications | ^17.2.3 | Local push notifications |
| flutter_foreground_task | ^8.13.0 | Background/foreground service |
| permission_handler | ^11.3.1 | Runtime permission requests |
| webview_flutter | ^4.10.0 | Embedded web views |
| webview_flutter_android | ^4.3.0 | Android WebView impl |
| webview_flutter_wkwebview | ^3.18.0 | iOS WKWebView impl |
| epub_view | ^3.2.0 | EPUB book reader |
| pdfx | ^2.9.0 | PDF viewer |
| path_provider | ^2.1.5 | Platform file paths |
| open_filex | ^4.6.0 | Open files with system app |
| cached_network_image | ^3.4.1 | Image caching |
| flutter_markdown | ^0.7.4+3 | Markdown rendering |
| markdown | ^7.3.0 | Markdown parsing |
| flutter_highlight | ^0.7.0 | Code syntax highlighting |
| highlight | ^0.7.0 | Syntax highlighting engine |

### Dev Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter_test (sdk) | — | Widget/unit testing framework |
| flutter_lints | ^6.0.0 | Dart lint rules |
| build_runner | ^2.4.15 | Code generation runner |
| riverpod_generator | ^2.6.3 | Riverpod provider codegen |
| mockito | ^5.4.6 | Mock framework |
| mocktail | ^1.0.4 | Mock framework (no codegen) |

### Build Commands

```
Build:   flutter build apk / flutter build ios / flutter build web
Test:    flutter test
Run:     flutter run
Package: flutter build appbundle (Android) / flutter build ipa (iOS)
```

---

## 4. Configuration & Infrastructure Summary

### Configuration Files

- **`pubspec.yaml`** — App identity (myoffgridai_client v1.0.0+1), Dart SDK ^3.11.0, all dependencies.
- **`analysis_options.yaml`** — Extends `package:flutter_lints/flutter.yaml`, disables `unnecessary_underscores`.
- **`lib/config/constants.dart`** — All app-wide constants. Server URL defaults: `localhost:8080` (web) / `offgrid.local:8080` (native). API paths, route names, pagination, timeouts, MQTT config, UI breakpoints, validation rules.
- **`web/manifest.json`** — PWA manifest. Theme `#2D5016`, background `#1A1A14`.
- **`web/index.html`** — Flutter web bootstrap.

### Connection Map

```
Backend API:     http://localhost:8080 (web) / http://offgrid.local:8080 (native)
MQTT Broker:     offgrid.local:1883 (pub/sub real-time messaging)
Kiwix Server:    localhost:8888 (offline library/ebook serving)
Database:        None (client-side only — all persistence via API)
Cache:           None (client-side only)
Message Broker:  MQTT (mqtt_client package, topic prefix /myoffgridai/)
External APIs:   None directly — all external API calls routed through backend
Cloud Services:  None
```

### CI/CD

None detected.

---

## 5. Startup & Runtime Behavior

**Entry point:** `lib/main.dart` → `main()`

### Startup Sequence
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `SecureStorageService()` instantiated
3. Server URL resolved from secure storage (defaults: `localhost:8080` web, `offgrid.local:8080` native)
4. `LocalNotificationService.initialize()` — sets up local push notifications
5. `ProviderScope` created with overrides for `secureStorageProvider`, `localNotificationServiceProvider`, `apiClientProvider`
6. `MyOffGridAIApp` widget launched — `MaterialApp.router` with GoRouter, light/dark theme, localization

### Auth Guard (Router)
- Unauthenticated users → redirected to `/login`
- Authenticated users hitting `/login` or `/register` → redirected to `/`
- `/users` restricted to `ROLE_OWNER` or `ROLE_ADMIN`

### Background Services
- MQTT client for real-time pub/sub (topic prefix `/myoffgridai/`)
- Flutter foreground service for persistent connection on mobile
- Notification polling every 30 seconds
- Connection health polling every 10 seconds
- Model health polling every 60 seconds

### Health Check
No dedicated health endpoint on the client. The client checks backend health via `/api/system` endpoints.

---

## 6. Entity / Data Model Layer

This is a Flutter client — models are DTOs for JSON serialization, not database entities. All persistence is server-side.

### user_model.dart
```
UserModel
  Fields: id (String), username (String), displayName (String), role (String), isActive (bool)
  Methods: fromJson(), toJson()
```

### page_response.dart
```
PageResponse<T> (Generic)
  Fields: content (List<T>), totalElements (int), totalPages (int), number (int), size (int), first (bool), last (bool), empty (bool)
  Methods: fromJson(json, itemFactory)
```

### conversation_model.dart
```
ConversationModel
  Fields: id (String), title (String?), isArchived (bool), messageCount (int), createdAt (String?), updatedAt (String?)
  Methods: fromJson()

ConversationSummaryModel
  Fields: id (String), title (String?), isArchived (bool), messageCount (int), updatedAt (String?), lastMessagePreview (String?)
  Methods: fromJson()
```

### message_model.dart
```
MessageModel
  Fields: id (String), role (String), content (String), tokenCount (int?), hasRagContext (bool), thinkingContent (String?), tokensPerSecond (double?), inferenceTimeSeconds (double?), stopReason (String?), thinkingTokenCount (int?), sourceTag (String?), judgeScore (double?), judgeReason (String?), createdAt (String?)
  Methods: fromJson(), copyWith()
  Getters: isUser, isAssistant, isEnhanced, hasJudgeScore
```

### memory_model.dart
```
MemoryModel
  Fields: id (String), content (String), importance (String), tags (String?), sourceConversationId (String?), createdAt (String?), updatedAt (String?), lastAccessedAt (String?), accessCount (int)
  Methods: fromJson()
  Getters: tagList (List<String>)

MemorySearchResultModel
  Fields: memory (MemoryModel), similarityScore (double)
  Methods: fromJson()
```

### knowledge_document_model.dart
```
KnowledgeDocumentModel
  Fields: id (String), filename (String), displayName (String?), mimeType (String?), fileSizeBytes (int), status (String), errorMessage (String?), chunkCount (int), uploadedAt (String?), processedAt (String?), hasContent (bool), editable (bool)
  Methods: fromJson()
  Getters: isProcessing, isIndexed, isFailed

DocumentContentModel
  Fields: documentId (String), title (String), content (String?), mimeType (String?), editable (bool)
  Methods: fromJson()

KnowledgeSearchResultModel
  Fields: chunkId (String), documentId (String), documentName (String), content (String), pageNumber (int?), chunkIndex (int), similarityScore (double)
  Methods: fromJson()
```

### skill_model.dart
```
SkillModel
  Fields: id (String), name (String), displayName (String), description (String?), version (String?), author (String?), category (String?), isEnabled (bool), isBuiltIn (bool), parametersSchema (String?), createdAt (String?), updatedAt (String?)
  Methods: fromJson()

SkillExecutionModel
  Fields: id (String), skillId (String), skillName (String), userId (String?), status (String), inputParams (String?), outputResult (String?), errorMessage (String?), startedAt (String?), completedAt (String?), durationMs (int?)
  Methods: fromJson()
  Getters: isRunning, isSuccess, isFailed
```

### inventory_item_model.dart
```
InventoryItemModel
  Fields: id (String), name (String), category (String), quantity (double), unit (String?), notes (String?), lowStockThreshold (double?), createdAt (String?), updatedAt (String?)
  Methods: fromJson()
  Getters: isLowStock

InventoryCategory (Constants)
  Values: food, water, fuel, tools, medicine, spareParts, other
```

### sensor_model.dart
```
SensorModel
  Fields: id (String), name (String), type (String), portPath (String?), baudRate (int), dataFormat (String?), valueField (String?), unit (String?), isActive (bool), pollIntervalSeconds (int), lowThreshold (double?), highThreshold (double?), createdAt (String?), updatedAt (String?)
  Methods: fromJson()

SensorReadingModel
  Fields: id (String), sensorId (String), value (double), rawData (String?), recordedAt (String?)
  Methods: fromJson()

SensorTestResultModel
  Fields: success (bool), portPath (String), baudRate (int), sampleData (String?), message (String)
  Methods: fromJson()

SensorType (Constants): temperature, humidity, pressure, soilMoisture, windSpeed, solarRadiation
DataFormat (Constants): csvLine, jsonLine, rawText
```

### event_model.dart
```
ScheduledEventModel
  Fields: id (String), userId (String?), name (String), description (String?), eventType (String), isEnabled (bool), cronExpression (String?), recurringIntervalMinutes (int?), sensorId (String?), thresholdOperator (String?), thresholdValue (double?), actionType (String), actionPayload (String), lastTriggeredAt (String?), nextFireAt (String?), createdAt (String?), updatedAt (String?)
  Methods: fromJson(), toJson()

EventType (Constants): scheduled, sensorThreshold, recurring
ActionType (Constants): pushNotification, aiPrompt, aiSummary
ThresholdOperator (Constants): above, below, equals
```

### insight_model.dart
```
InsightModel
  Fields: id (String), content (String), category (String), isRead (bool), isDismissed (bool), generatedAt (String?), readAt (String?)
  Methods: fromJson()

InsightCategory (Constants): security, efficiency, health, maintenance, sustainability, planning
```

### notification_model.dart
```
NotificationModel
  Fields: id (String), title (String), body (String), type (String), severity (String), isRead (bool), createdAt (String?), readAt (String?), metadata (String?)
  Methods: fromJson()

NotificationType (Constants): sensorAlert, systemHealth, insightReady, modelUpdate, general
NotificationSeverity (Constants): info, warning, critical
```

### device_registration_model.dart
```
DeviceRegistrationModel
  Fields: id (String), deviceId (String), deviceName (String), platform (String), mqttClientId (String), lastSeenAt (String?)
  Methods: fromJson()
```

### privacy_models.dart
```
FortressStatusModel
  Fields: enabled (bool), enabledAt (String?), enabledByUsername (String?), verified (bool)

DataInventoryModel
  Fields: conversationCount (int), messageCount (int), memoryCount (int), knowledgeDocumentCount (int), sensorCount (int), insightCount (int)

AuditSummaryModel
  Fields: successCount (int), failureCount (int), deniedCount (int), windowStart (String?), windowEnd (String?)

SovereigntyReportModel
  Fields: generatedAt (String?), fortressStatus (FortressStatusModel?), outboundTrafficVerification (String?), dataInventory (DataInventoryModel?), auditSummary (AuditSummaryModel?), encryptionStatus (String?), telemetryStatus (String?), lastVerifiedAt (String?)

AuditLogModel
  Fields: id (String), userId (String?), username (String?), action (String), resourceType (String?), resourceId (String?), httpMethod (String?), requestPath (String?), outcome (String), responseStatus (int?), durationMs (int?), timestamp (String?)

WipeResultModel
  Fields: targetUserId (String?), stepsCompleted (int), completedAt (String?), success (bool)

AuditOutcome (Constants): success, failure, denied
All: fromJson() factory constructors
```

### system_models.dart
```
SystemStatusModel
  Fields: initialized (bool), instanceName (String?), fortressEnabled (bool), wifiConfigured (bool), serverVersion (String?), timestamp (String?)

OllamaModelInfoModel
  Fields: name (String), size (int), modifiedAt (String?)

AiSettingsModel
  Fields: modelName (String), temperature (double), similarityThreshold (double), memoryTopK (int), ragMaxContextTokens (int), contextSize (int), contextMessageLimit (int)
  Methods: fromJson(), toJson()

StorageSettingsModel
  Fields: knowledgeStoragePath (String), totalSpaceMb (int), usedSpaceMb (int), freeSpaceMb (int), maxUploadSizeMb (int)
  Methods: fromJson(), toJson()

ActiveModelInfo
  Fields: modelName (String?), embedModelName (String?)
```

### enrichment_models.dart
```
ExternalApiSettingsModel
  Fields: anthropicEnabled (bool), anthropicModel (String), anthropicKeyConfigured (bool), braveEnabled (bool), braveKeyConfigured (bool), huggingFaceEnabled (bool), huggingFaceKeyConfigured (bool), maxWebFetchSizeKb (int), searchResultLimit (int), grokEnabled (bool), grokKeyConfigured (bool), openAiEnabled (bool), openAiKeyConfigured (bool), preferredFrontierProvider (String?), judgeEnabled (bool), judgeModelFilename (String?), judgeScoreThreshold (double)

UpdateExternalApiSettingsRequest
  Fields: anthropicApiKey (String?), anthropicModel (String), anthropicEnabled (bool), braveApiKey (String?), braveEnabled (bool), huggingFaceToken (String?), huggingFaceEnabled (bool), maxWebFetchSizeKb (int), searchResultLimit (int), grokApiKey (String?), grokEnabled (bool?), openAiApiKey (String?), openAiEnabled (bool?), preferredFrontierProvider (String?), judgeEnabled (bool?), judgeModelFilename (String?), judgeScoreThreshold (double?)
  Methods: toJson()

SearchResultModel
  Fields: title (String), url (String), description (String), publishedDate (String?)

EnrichmentStatusModel
  Fields: claudeAvailable (bool), braveAvailable (bool), maxWebFetchSizeKb (int), searchResultLimit (int)
All: fromJson() factory constructors
```

### judge_models.dart
```
JudgeStatusModel
  Fields: enabled (bool), processRunning (bool), judgeModelFilename (String?), port (int), scoreThreshold (double)

JudgeTestResultModel
  Fields: score (double), reason (String?), needsCloud (bool), judgeAvailable (bool), error (String?)
All: fromJson() factory constructors
```

### library_models.dart
```
ZimFileModel
  Fields: id (String), filename (String), displayName (String?), description (String?), language (String?), category (String?), fileSizeBytes (int), articleCount (int), mediaCount (int), createdDate (String?), kiwixBookId (String?), uploadedAt (String?), uploadedBy (String?)

EbookModel
  Fields: id (String), title (String), author (String?), description (String?), isbn (String?), publisher (String?), publishedYear (String?), language (String?), format (String), fileSizeBytes (int), gutenbergId (String?), downloadCount (int), hasCoverImage (bool), uploadedAt (String?), uploadedBy (String?)
  Getters: isFromGutenberg

KiwixStatusModel
  Fields: available (bool), url (String?), bookCount (int)

GutenbergBookModel
  Fields: id (int), title (String), authors (List<String>), subjects (List<String>), languages (List<String>), downloadCount (int), formats (Map<String, String>)
  Getters: hasEpub

GutenbergSearchResultModel
  Fields: count (int), next (String?), previous (String?), results (List<GutenbergBookModel>)
All: fromJson() factory constructors
```

### model_catalog_models.dart
```
HfModelModel
  Fields: id (String), author (String), modelId (String), downloads (int), likes (int), tags (List<String>), isGated (bool), lastModified (DateTime?), files (List<HfModelFileModel>)
  Getters: hasGguf, hasMlx, ggufFiles

HfModelFileModel
  Fields: filename (String), sizeBytes (int?), isRecommended (bool), qualityLabel (String?), qualityRank (int?), estimatedRamBytes (int?), quantizationType (String?)
  Getters: quantLabel, formattedSize, estimatedRamMb, fitsInRam

DownloadProgressModel
  Fields: downloadId (String), repoId (String), filename (String), status (String), bytesDownloaded (int), totalBytes (int), percentComplete (double), speedBytesPerSecond (double), estimatedSecondsRemaining (int), errorMessage (String?)
  Getters: isActive, isComplete, isFailed, isCancelled

LocalModelFileModel
  Fields: filename (String), repoId (String?), format (String), sizeBytes (int), lastModified (DateTime?), isCurrentlyLoaded (bool)
All: fromJson() factory constructors
```

### inference_stream_event.dart
```
InferenceEventType (Enum)
  Values: thinking, content, done, error, judgeEvaluating, judgeResult, enhancedContent, enhancedDone

InferenceMetadata
  Fields: tokensGenerated (int), tokensPerSecond (double), inferenceTimeSeconds (double), stopReason (String?), thinkingTokenCount (int?)

InferenceStreamEvent
  Fields: type (InferenceEventType), content (String?), metadata (InferenceMetadata?), messageId (String?)
All: fromJson() factory constructors
```

**Total:** 20 model files, ~51 classes/constants holders, 1 enum. All use manual JSON serialization (fromJson/toJson).

---

## 7. Enum Inventory

### InferenceEventType (lib/core/models/inference_stream_event.dart)
```
Values: thinking, content, done, error, judgeEvaluating, judgeResult, enhancedContent, enhancedDone
Used in: InferenceStreamEvent, ChatConversationScreen SSE handling
```

### Constants Holders (String constants, not Dart enums)

| Class | File | Values |
|---|---|---|
| InventoryCategory | inventory_item_model.dart | food, water, fuel, tools, medicine, spareParts, other |
| SensorType | sensor_model.dart | temperature, humidity, pressure, soilMoisture, windSpeed, solarRadiation |
| DataFormat | sensor_model.dart | csvLine, jsonLine, rawText |
| EventType | event_model.dart | scheduled, sensorThreshold, recurring |
| ActionType | event_model.dart | pushNotification, aiPrompt, aiSummary |
| ThresholdOperator | event_model.dart | above, below, equals |
| InsightCategory | insight_model.dart | security, efficiency, health, maintenance, sustainability, planning |
| NotificationType | notification_model.dart | sensorAlert, systemHealth, insightReady, modelUpdate, general |
| NotificationSeverity | notification_model.dart | info, warning, critical |
| AuditOutcome | privacy_models.dart | success, failure, denied |

---

## 8. Repository Layer

Not applicable — this is a Flutter client application. All data persistence is handled server-side. The client communicates exclusively via REST API (Dio HTTP client) and MQTT.

---

## 9. Service Layer — Full Method Signatures

### API Layer

#### MyOffGridAIApiClient (lib/core/api/myoffgridai_api_client.dart)
```
Injects: String baseUrl, SecureStorageService storage, Ref ref
Interceptors: _AuthInterceptor (JWT + 401 refresh), _LoggingInterceptor (debug only)

Public Methods:
  - get<T>(String path, {queryParams?, fromJson?}): Future<T>
  - post<T>(String path, {data?, fromJson?}): Future<T>
  - put<T>(String path, {data?, fromJson?}): Future<T>
  - patch<T>(String path, {data?, fromJson?}): Future<T>
  - delete(String path): Future<void>
  - getBytes(String path): Future<List<int>>
  - getStream(String path, {queryParams?, receiveTimeout?}): Future<ResponseBody?>
  - postStream(String path, {data?, receiveTimeout?}): Future<ResponseBody?>
  - postMultipart<T>(String path, FormData formData, {fromJson?}): Future<T>
  - refreshToken(): Future<bool>
  - updateBaseUrl(String newBaseUrl): void
Provider: apiClientProvider
```

#### ApiException (lib/core/api/api_exception.dart)
```
Fields: statusCode (int), message (String), errors (Map<String, dynamic>?)
Purpose: Typed HTTP error wrapping status code and validation errors
```

#### ApiResponse<T> (lib/core/api/api_response.dart)
```
Fields: success (bool), message (String?), data (T?), timestamp (String?), requestId (String?), totalElements (int?), page (int?), size (int?)
Methods: fromJson(json, fromJsonT)
Purpose: Server response envelope — consistent success/failure signaling
```

#### Providers (lib/core/api/providers.dart)
```
systemStatusProvider — polls device initialization status
modelHealthProvider — polls Ollama model health every 60s
unreadCountProvider — fetches unread notification count
connectionStatusProvider — pings server periodically
serverUrlProvider — resolves server URL from storage
DTOs: OllamaHealthDto, SystemStatusDto
```

### Auth Layer

#### AuthService (lib/core/auth/auth_service.dart)
```
Injects: MyOffGridAIApiClient client, SecureStorageService storage

Public Methods:
  - login(String username, String password): Future<AuthResponse>
  - register({username, displayName, password, email?, role?}): Future<AuthResponse>
  - logout(): Future<void>
  - refresh(): Future<AuthResponse>
  - getCurrentUser(String userId): Future<UserModel>
Provider: authServiceProvider
```

#### AuthNotifier (lib/core/auth/auth_state.dart)
```
Public Methods:
  - build(): Future<UserModel?> — checks stored tokens on startup
  - login(String username, String password): Future<void>
  - register({username, displayName, password, email?}): Future<void>
  - logout(): Future<void>
Provider: authStateProvider (AsyncNotifierProvider)
```

#### SecureStorageService (lib/core/auth/secure_storage_service.dart)
```
Injects: FlutterSecureStorage? storage (optional, test injection)

Public Methods:
  - saveTokens({accessToken, refreshToken}): Future<void>
  - getAccessToken(): Future<String?>
  - getRefreshToken(): Future<String?>
  - clearTokens(): Future<void>
  - saveServerUrl(String url): Future<void>
  - getServerUrl(): Future<String> — returns stored or default
  - saveThemePreference(String theme): Future<void>
  - getThemePreference(): Future<String> — returns stored or 'system'
  - saveDeviceId(String deviceId): Future<void>
  - getDeviceId(): Future<String?>
Provider: secureStorageProvider
```

### Domain Services

#### ChatService (lib/core/services/chat_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listConversations({page?, size?, archived?}): Future<List<ConversationSummaryModel>>
  - createConversation({title?}): Future<ConversationModel>
  - getConversation(String id): Future<ConversationModel>
  - deleteConversation(String id): Future<void>
  - archiveConversation(String id): Future<void>
  - renameConversation(String id, String title): Future<ConversationModel>
  - searchConversations(String query): Future<List<ConversationSummaryModel>>
  - listMessages(String convId, {page?, size?}): Future<List<MessageModel>>
  - sendMessage(String convId, String content, {stream?}): Future<MessageModel>
  - sendMessageStream(String convId, String content): Stream<InferenceStreamEvent>
  - editMessage(String convId, String msgId, String content): Future<MessageModel>
  - deleteMessage(String convId, String msgId): Future<void>
  - branchConversation(String convId, String msgId, {title?}): Future<ConversationModel>
  - regenerateMessage(String convId, String msgId): Stream<InferenceStreamEvent>
Providers: chatServiceProvider, conversationsProvider, messagesProvider, aiThinkingProvider, judgeEvaluatingProvider, sidebarCollapsedProvider
```

#### ChatMessagesNotifier (lib/core/services/chat_messages_notifier.dart)
```
Extends: AutoDisposeFamilyAsyncNotifier<List<MessageModel>, String>

Public Methods:
  - build(String arg): Future<List<MessageModel>> — loads messages for conversation
  - sendMessage(String content): Future<void> — SSE streaming with typed events
  - editMessage(String messageId, String newContent): Future<void>
  - deleteMessage(String messageId): Future<void>
  - regenerateMessage(String messageId): Future<void> — SSE streaming regeneration
Provider: chatMessagesNotifierProvider (family, keyed by conversation ID)
```

#### MemoryService (lib/core/services/memory_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listMemories({page?, size?, importance?, tag?}): Future<List<MemoryModel>>
  - getMemory(String id): Future<MemoryModel>
  - deleteMemory(String id): Future<void>
  - updateTags(String id, String tags): Future<MemoryModel>
  - updateImportance(String id, String importance): Future<MemoryModel>
  - search(String query, {topK?}): Future<List<MemorySearchResultModel>>
  - exportMemories(): Future<List<MemoryModel>>
Providers: memoryServiceProvider, memoriesProvider
```

#### KnowledgeService (lib/core/services/knowledge_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listDocuments({page?, size?}): Future<List<KnowledgeDocumentModel>>
  - getDocument(String id): Future<KnowledgeDocumentModel>
  - uploadDocument(String filename, List<int> bytes): Future<KnowledgeDocumentModel>
  - updateDisplayName(String id, String name): Future<KnowledgeDocumentModel>
  - deleteDocument(String id): Future<void>
  - retryProcessing(String id): Future<KnowledgeDocumentModel>
  - search(String query, {topK?}): Future<List<KnowledgeSearchResultModel>>
  - getDocumentContent(String id): Future<DocumentContentModel>
  - downloadDocument(String id): Future<List<int>>
  - createDocument({title, content}): Future<KnowledgeDocumentModel>
  - updateDocumentContent(String id, String content): Future<KnowledgeDocumentModel>
Providers: knowledgeServiceProvider, knowledgeDocumentsProvider, documentContentProvider
```

#### SkillsService (lib/core/services/skills_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listSkills(): Future<List<SkillModel>>
  - getSkill(String id): Future<SkillModel>
  - toggleSkill(String id, bool enabled): Future<SkillModel>
  - executeSkill(String id, {params?}): Future<SkillExecutionModel>
  - listExecutions({page?, size?}): Future<List<SkillExecutionModel>>
Providers: skillsServiceProvider, skillsProvider
```

#### InventoryService (lib/core/services/inventory_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listItems({category?}): Future<List<InventoryItemModel>>
  - createItem({name, category, quantity, unit?, notes?, lowStockThreshold?}): Future<InventoryItemModel>
  - updateItem(String id, Map<String, dynamic> updates): Future<InventoryItemModel>
  - deleteItem(String id): Future<void>
Providers: inventoryServiceProvider, inventoryProvider
```

#### SensorService (lib/core/services/sensor_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listSensors(): Future<List<SensorModel>>
  - getSensor(String id): Future<SensorModel>
  - createSensor({name, type, portPath, baudRate?, dataFormat?, valueField?, unit?, pollIntervalSeconds, lowThreshold?, highThreshold?}): Future<SensorModel>
  - deleteSensor(String id): Future<void>
  - startSensor(String id): Future<SensorModel>
  - stopSensor(String id): Future<SensorModel>
  - getLatestReading(String id): Future<SensorReadingModel?>
  - getHistory(String id, {hours?, page?, size?}): Future<List<SensorReadingModel>>
  - updateThresholds(String id, {lowThreshold?, highThreshold?}): Future<SensorModel>
  - testConnection(String portPath, int baudRate): Future<SensorTestResultModel>
  - listPorts(): Future<List<String>>
Providers: sensorServiceProvider, sensorsProvider
```

#### EventService (lib/core/services/event_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listEvents({page?, size?}): Future<List<ScheduledEventModel>>
  - getEvent(String id): Future<ScheduledEventModel>
  - createEvent(Map<String, dynamic> body): Future<ScheduledEventModel>
  - updateEvent(String id, Map<String, dynamic> body): Future<ScheduledEventModel>
  - deleteEvent(String id): Future<void>
  - toggleEvent(String id): Future<ScheduledEventModel>
Providers: eventServiceProvider, eventsListProvider
```

#### InsightService (lib/core/services/insight_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listInsights({page?, size?, category?}): Future<List<InsightModel>>
  - generateInsights(): Future<List<InsightModel>>
  - markAsRead(String id): Future<InsightModel>
  - dismiss(String id): Future<InsightModel>
  - getUnreadCount(): Future<int>
Providers: insightServiceProvider, insightsProvider
```

#### NotificationService (lib/core/services/notification_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listNotifications({unreadOnly?, page?, size?}): Future<List<NotificationModel>>
  - markAsRead(String id): Future<NotificationModel>
  - markAllAsRead(): Future<void>
  - deleteNotification(String id): Future<void>
  - getUnreadCount(): Future<int>
Providers: notificationServiceProvider, notificationsProvider, notificationsUnreadCountProvider (StreamProvider, polls 30s)
```

#### LocalNotificationService (lib/core/services/local_notification_service.dart)
```
Injects: FlutterLocalNotificationsPlugin? plugin (optional, test injection)

Public Methods:
  - initialize(): Future<void>
  - requestPermission(): Future<bool>
  - showNotification({id, title, body, payload?}): Future<void>
  - showAlertNotification(NotificationModel notification): Future<void>
  - isInitialized: bool (getter)
Provider: localNotificationServiceProvider
```

#### PrivacyService (lib/core/services/privacy_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - getFortressStatus(): Future<FortressStatusModel>
  - enableFortress(): Future<void>
  - disableFortress(): Future<void>
  - getSovereigntyReport(): Future<SovereigntyReportModel>
  - getAuditLogs({outcome?, page?, size?}): Future<List<AuditLogModel>>
  - wipeSelfData(): Future<WipeResultModel>
Providers: privacyServiceProvider, fortressStatusProvider
```

#### SystemService (lib/core/services/system_service.dart)
```
Injects: MyOffGridAIApiClient client

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

#### EnrichmentService (lib/core/services/enrichment_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - getExternalApiSettings(): Future<ExternalApiSettingsModel>
  - updateExternalApiSettings(UpdateExternalApiSettingsRequest): Future<ExternalApiSettingsModel>
  - fetchUrl({url, summarizeWithClaude?}): Future<KnowledgeDocumentModel>
  - search({query, storeTopN?, summarizeWithClaude?}): Future<({results, storedDocuments})>
  - getStatus(): Future<EnrichmentStatusModel>
Providers: enrichmentServiceProvider, enrichmentStatusProvider, externalApiSettingsProvider
```

#### JudgeService (lib/core/services/judge_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - getStatus(): Future<JudgeStatusModel>
  - start(): Future<JudgeStatusModel>
  - stop(): Future<JudgeStatusModel>
  - test({query, response}): Future<JudgeTestResultModel>
Providers: judgeServiceProvider, judgeStatusProvider
```

#### ModelCatalogService (lib/core/services/model_catalog_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - searchCatalog({query, format?, limit?}): Future<List<HfModelModel>>
  - getModelDetails(String author, String modelId): Future<HfModelModel>
  - getModelFiles(String author, String modelId): Future<List<HfModelFileModel>>
  - startDownload({repoId, filename}): Future<Map<String, dynamic>>
  - getAllDownloads(): Future<List<DownloadProgressModel>>
  - streamDownloadProgress(String downloadId): Stream<DownloadProgressModel>
  - cancelDownload(String downloadId): Future<void>
  - listLocalModels(): Future<List<LocalModelFileModel>>
  - deleteLocalModel(String filename): Future<void>
Providers: modelCatalogServiceProvider, localModelsProvider, activeDownloadsProvider
```

#### DeviceRegistrationService (lib/core/services/device_registration_service.dart)
```
Injects: MyOffGridAIApiClient client, SecureStorageService storage

Public Methods:
  - registerDevice(): Future<void>
  - getRegisteredDevices(): Future<List<DeviceRegistrationModel>>
  - unregisterDevice(String id): Future<void>
Provider: deviceRegistrationServiceProvider
```

#### LibraryService (lib/core/services/library_service.dart)
```
Injects: MyOffGridAIApiClient client

Public Methods:
  - listZimFiles(): Future<List<ZimFileModel>>
  - uploadZimFile({filename, bytes, displayName, category?}): Future<ZimFileModel>
  - deleteZimFile(String id): Future<void>
  - getKiwixStatus(): Future<KiwixStatusModel>
  - getKiwixUrl(): Future<String>
  - listEbooks({search?, format?, page?, size?}): Future<List<EbookModel>>
  - getEbook(String id): Future<EbookModel>
  - uploadEbook({filename, bytes, title, author?}): Future<EbookModel>
  - deleteEbook(String id): Future<void>
  - downloadEbookContent(String id): Future<List<int>>
  - searchGutenberg(String query, {limit?}): Future<GutenbergSearchResultModel>
  - getGutenbergBook(int id): Future<GutenbergBookModel>
  - importGutenbergBook(int gutenbergId): Future<EbookModel>
Providers: libraryServiceProvider, zimFilesProvider, ebooksProvider, kiwixStatusProvider, kiwixUrlProvider
```

#### MqttServiceNotifier (lib/core/services/mqtt_service.dart)
```
Extends: StateNotifier<MqttState>
Injects: Ref _ref

Public Methods:
  - connect(String userId): Future<void>
  - disconnect(): void
  - dispose(): void
States: MqttConnectionStatus {disconnected, connecting, connected, error}
Provider: mqttServiceProvider (StateNotifierProvider)
```

#### ForegroundServiceManager (lib/core/services/foreground_service_manager.dart)
```
Public Methods:
  - startService(): Future<void> — Android only
  - stopService(): Future<void> — Android only
  - isRunning: bool (getter)
Provider: foregroundServiceManagerProvider
```

#### UserService (lib/core/services/user_service.dart)
```
Injects: MyOffGridAIApiClient client
Additional DTO: UserDetailModel (id, username, email, displayName, role, isActive, createdAt, updatedAt, lastLoginAt)

Public Methods:
  - listUsers({page?, size?}): Future<List<UserModel>>
  - getUser(String id): Future<UserDetailModel>
  - updateUser(String id, {displayName?, email?, role?}): Future<UserDetailModel>
  - deactivateUser(String id): Future<void>
  - deleteUser(String id): Future<void>
Providers: userServiceProvider, usersListProvider
```

---

## 10. Controller / API Layer — Method Signatures Only

Not applicable — this is a Flutter client. There are no server-side controllers. The equivalent is the **feature screens** that consume services. See Section 9 for all service→API mappings and the architecture doc for screen→service relationships.

### API Endpoints Consumed (Base Paths from constants.dart)

| Path Prefix | Service |
|---|---|
| /api/auth | AuthService |
| /api/users | UserService |
| /api/chat | ChatService |
| /api/models | ModelCatalogService, SystemService |
| /api/memory | MemoryService |
| /api/knowledge | KnowledgeService |
| /api/skills | SkillsService |
| /api/skills/inventory | InventoryService |
| /api/sensors | SensorService |
| /api/events | EventService |
| /api/insights | InsightService |
| /api/notifications | NotificationService |
| /api/notifications/devices | DeviceRegistrationService |
| /api/privacy | PrivacyService |
| /api/system | SystemService |
| /api/enrichment | EnrichmentService |
| /api/settings/external-apis | EnrichmentService |
| /api/ai/judge | JudgeService |
| /api/library | LibraryService |

---

## 11. Security Configuration

This is a client-side Flutter application. Security is enforced server-side. The client handles:

```
Authentication: JWT Bearer tokens (obtained from /api/auth/login, stored in FlutterSecureStorage)
Token Storage: flutter_secure_storage (OS keychain on iOS, EncryptedSharedPreferences on Android)
Token Refresh: Automatic via _AuthInterceptor (intercepts 401 → refreshes → retries)
Password Encoder: N/A (server-side)

Public Routes (no auth required):
  - /login
  - /register
  - /device-not-setup

Protected Routes:
  - All routes under ShellRoute (GoRouter redirect guard)
  - /users → ROLE_OWNER or ROLE_ADMIN only (client-side guard in router)

CORS: N/A (client-side)
CSRF: N/A (client-side — API uses JWT, not cookies)
Rate limiting: N/A (server-side)
```

---

## 12. Custom Security Components

### _AuthInterceptor (lib/core/api/myoffgridai_api_client.dart)
```
Extends: Interceptor (Dio)
Purpose: Attaches JWT Bearer token to all requests, handles 401 with automatic token refresh
Extracts token from: SecureStorageService
Validates via: Server response (401 triggers refresh)
Sets SecurityContext: N/A (Flutter — sets Authorization header)
Refresh flow: 401 → call /api/auth/refresh with stored refresh token → retry original request → if refresh fails → clear tokens → redirect to login
```

### SecureStorageService (lib/core/auth/secure_storage_service.dart)
```
Purpose: Secure credential storage wrapper
Storage: FlutterSecureStorage (platform keychain/keystore)
Stores: access_token, refresh_token, server_url, theme_preference, device_id
```

### AuthNotifier (lib/core/auth/auth_state.dart)
```
Purpose: Manages auth state as Riverpod AsyncNotifier
On build: Checks for stored access token → fetches user profile → sets state
Login: Calls AuthService.login → saves tokens → updates state
Logout: Calls AuthService.logout → clears tokens → resets state to null
```

---

## 13. Exception Handling & Error Responses

### ApiException (lib/core/api/api_exception.dart)
```
Implements: Exception
Fields: statusCode (int), message (String), errors (Map<String, dynamic>?)
Thrown by: MyOffGridAIApiClient on non-2xx HTTP responses
Usage: Services catch specific status codes; UI displays message via SnackBar
```

### Error Handling Pattern
- `MyOffGridAIApiClient` wraps all Dio errors into `ApiException` with status code and server message
- Services propagate `ApiException` to UI layer
- Screen widgets catch exceptions in try/catch blocks and display SnackBars
- `_AuthInterceptor` handles 401 errors by attempting token refresh before propagating

### ApiResponse<T> (lib/core/api/api_response.dart)
```
Standard envelope: { success, message, data, timestamp, requestId, totalElements, page, size }
All API responses wrapped in this structure
```

---

## 14. Mappers / DTOs

No separate mapper layer. All models have manual `fromJson()` factory constructors and optional `toJson()` methods inline. The `ApiResponse.fromJson()` acts as the top-level deserializer, delegating to model-specific factories.

**Serialization pattern:** Manual JSON (no code generation, no json_serializable, no freezed).

---

## 15. Utility Classes & Shared Components

### DateFormatter (lib/shared/utils/date_formatter.dart)
```
Methods:
  - formatRelative(DateTime dt): String — "just now", "X minutes ago", "Yesterday", "Mar 14"
  - formatFull(DateTime dt): String — "March 14, 2026 at 3:45 PM"
  - formatDate(DateTime dt): String — "Mar 14, 2026"
Used by: Chat screens, notification screens, event screens, memory screens
```

### SizeFormatter (lib/shared/utils/size_formatter.dart)
```
Methods:
  - formatBytes(int bytes): String — "1.2 MB", "340 KB"
Used by: Knowledge/library screens, model catalog screens
```

### DownloadUtils (lib/shared/utils/download_utils.dart)
```
Methods:
  - downloadBytes(List<int> bytes, String filename): void — Web only (data URI trigger)
  - _guessMimeType(String filename): String — MIME type from extension
Used by: Knowledge document download, ebook download
```

### PlatformUtils (lib/shared/utils/platform_utils.dart)
```
Methods:
  - isWeb: bool (getter)
  - isMobile: bool (getter)
  - isTablet(BuildContext): bool — width 600-1200
  - isMobileWidth(BuildContext): bool — width < 600
  - isDesktopWidth(BuildContext): bool — width >= 1200
Used by: AppShell, NavigationPanel, responsive layout decisions
```

### Shared Widgets (lib/shared/widgets/)

| Widget | Purpose |
|---|---|
| AppShell | Root layout with NavigationPanel + content area |
| NavigationPanel | Collapsible side navigation with route links |
| ConfirmationDialog | Reusable confirm/cancel dialog |
| ConnectionLostBanner | Banner shown when server connection lost |
| EmptyStateView | Placeholder for empty lists |
| ErrorView | Error display with retry button |
| LoadingIndicator | Centered loading spinner |
| NotificationBadge | Badge count overlay |
| SystemStatusBar | Bottom bar showing connection/model status |

---

## 16. Database Schema (Live)

Not applicable — this is a Flutter client application. No local database. All data persistence is server-side, accessed via REST API.

**Local storage:** `FlutterSecureStorage` for tokens and preferences only (5 key-value pairs, not a database).

---

## 17. Message Broker Configuration

```
Broker: MQTT (Mosquitto on server)
Client Library: mqtt_client ^10.2.1
Connection: offgrid.local:1883 (configurable via constants)
Client ID: myoffgridai-flutter-{userId}

Topics:
  - /myoffgridai/broadcast — System-wide broadcast messages
  - /myoffgridai/user/{userId}/notifications — Per-user notifications

Consumer: MqttServiceNotifier
  - Subscribes on connect
  - Parses JSON payloads into NotificationModel
  - Dispatches to LocalNotificationService for display
  - Updates unread count

Reconnect: Automatic with 5-second delay (mqttReconnectDelay)
Keep Alive: 60 seconds (mqttKeepAliveSeconds)
```

---

## 18. Cache Layer

No Redis or caching layer detected. The app uses:
- `cached_network_image` for image caching (disk cache, not application-level)
- Riverpod `.autoDispose` providers for automatic state cleanup
- No explicit TTL-based caching strategy

---

## 19. Environment Variable Inventory

No environment variables used directly. All configuration is via:

| Setting | Storage | Default | Configurable |
|---|---|---|---|
| Server URL | FlutterSecureStorage | localhost:8080 (web) / offgrid.local:8080 (native) | Yes, via settings screen |
| Access Token | FlutterSecureStorage | (none) | Set on login |
| Refresh Token | FlutterSecureStorage | (none) | Set on login |
| Theme Preference | FlutterSecureStorage | system | Yes, via settings screen |
| Device ID | FlutterSecureStorage | (auto-generated) | No |

---

## 20. Service Dependency Map

```
MyOffGridAI-Client → Depends On
------------------------------------
MyOffGridAI Server (Spring Boot): http://localhost:8080 or http://offgrid.local:8080
  - All /api/* REST endpoints
  - JWT authentication (/api/auth/*)
  
Mosquitto MQTT Broker: offgrid.local:1883
  - Real-time notifications and broadcasts
  
Kiwix Serve: localhost:8888
  - Offline library content serving (ZIM files)
  - Accessed via WebView

External APIs (via server proxy):
  - Anthropic Claude API (enrichment)
  - Brave Search API (web search)
  - HuggingFace API (model catalog)
  - Grok API (enrichment)
  - OpenAI API (enrichment)
  - Project Gutenberg API (ebook search)

Downstream Consumers:
  - None (this is a client-only application)
```

---

## 21. Known Technical Debt & Issues

### TODO/Placeholder/Stub Scan Results

The scan found 0 genuine TODO/FIXME/placeholder patterns.

**False positives analyzed and cleared:**
- `apiClientProvider` throws `UnimplementedError` — this is **intentional**: the provider is overridden in `main()` after resolving the server URL. It is never invoked without override.
- `download_trigger_stub.dart` — this is **intentional**: conditional import stub for non-web platforms where file download is a no-op.
- `TEMPERATURE` references in sensor_model.dart — these are string constants, not the word "TEMP" as a code quality issue.

### Issues Discovered During Audit

| Issue | Location | Severity | Notes |
|---|---|---|---|
| No test coverage measurement | project-wide | Medium | `flutter test --coverage` not run in CI; no lcov enforcement |
| No CI/CD pipeline | project-wide | Medium | No .github/workflows or equivalent detected |
| Manual JSON serialization | lib/core/models/*.dart | Low | All 20 model files use hand-written fromJson/toJson; json_serializable/freezed would reduce boilerplate and prevent field mismatches |
| No error boundary widget | lib/ | Low | No global error handler for uncaught widget exceptions (e.g., ErrorWidget.builder override) |
| Timestamp fields as String not DateTime | lib/core/models/*.dart | Low | Most `createdAt`/`updatedAt` fields stored as `String?` rather than parsed `DateTime?` — requires parsing at display time |

---

## 22. Security Vulnerability Scan (Snyk)

Scan Date: 2026-03-18T00:31:03Z
Snyk CLI Version: 1.1303.0

### Dependency Vulnerabilities (Open Source)
Critical: 0
High: 0
Medium: 0
Low: 0

**Result: PASS — No known vulnerabilities in dependencies.**

### Code Vulnerabilities (SAST)
Errors: 0
Warnings: 0
Notes: 0

**Result: PASS — No code vulnerabilities detected.**

### IaC Findings
Not applicable — no Dockerfile or infrastructure-as-code files in this Flutter client project.

---
