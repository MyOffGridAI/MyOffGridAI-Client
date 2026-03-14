# MyOffGridAI-Client -- Architecture Specification

**Generated:** 2026-03-14
**Phase:** 10 -- Flutter Client Features (MC-002)
**Version:** 2.0.0

---

## 1. Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Dart | 3.11.0 |
| Framework | Flutter | 3.41.1 |
| State Management | flutter_riverpod | 2.6.1 |
| Routing | go_router | 14.8.1 |
| HTTP Client | dio | 5.9.x |
| Secure Storage | flutter_secure_storage | 9.2.4 |
| Charts | fl_chart | 0.70.2 |
| File Picker | file_picker | 8.3.7 |
| Internationalization | intl | 0.20.2 |
| WebSockets | web_socket_channel | 3.0.x |
| Testing | flutter_test, mocktail, mockito | SDK / 1.0.4 / 5.4.6 |

### Platforms

| Platform | Status |
|----------|--------|
| Web | Supported (PWA) |
| iOS | Supported |
| Android | Supported |
| Desktop Linux | Not supported (headless appliance) |

---

## 2. Project Structure

```
lib/
├── main.dart                           -- App entry point, provider initialization
├── config/
│   ├── constants.dart                  -- All app constants (URLs, timeouts, routes)
│   ├── theme.dart                      -- Light/dark theme + ThemeNotifier
│   └── router.dart                     -- GoRouter with auth guards
├── core/
│   ├── api/
│   │   ├── myoffgridai_api_client.dart -- Dio client with JWT interceptors (GET/POST/PUT/PATCH/DELETE)
│   │   ├── api_exception.dart          -- Typed API exceptions
│   │   ├── api_response.dart           -- Server ApiResponse<T> mirror
│   │   └── providers.dart              -- System status, health, notification providers
│   ├── auth/
│   │   ├── auth_service.dart           -- Login, logout, register, refresh
│   │   ├── auth_state.dart             -- Riverpod AsyncNotifier for auth
│   │   └── secure_storage_service.dart -- flutter_secure_storage wrapper
│   ├── models/
│   │   ├── user_model.dart             -- UserSummaryDto mirror
│   │   ├── page_response.dart          -- Spring Page<T> mirror
│   │   ├── conversation_model.dart     -- ConversationModel + ConversationSummaryModel
│   │   ├── message_model.dart          -- MessageModel (USER/ASSISTANT/SYSTEM roles)
│   │   ├── memory_model.dart           -- MemoryModel + MemorySearchResultModel
│   │   ├── knowledge_document_model.dart -- KnowledgeDocumentModel + KnowledgeSearchResultModel
│   │   ├── skill_model.dart            -- SkillModel + SkillExecutionModel
│   │   ├── inventory_item_model.dart   -- InventoryItemModel + InventoryCategory
│   │   ├── sensor_model.dart           -- SensorModel + SensorReadingModel + SensorTestResultModel
│   │   ├── insight_model.dart          -- InsightModel + InsightCategory
│   │   ├── notification_model.dart     -- NotificationModel + NotificationType
│   │   ├── privacy_models.dart         -- FortressStatusModel, SovereigntyReportModel, AuditLogModel
│   │   └── system_models.dart          -- SystemStatusModel, OllamaModelInfoModel, ActiveModelInfo
│   └── services/
│       ├── chat_service.dart           -- ChatService + conversationsProvider + messagesProvider
│       ├── memory_service.dart         -- MemoryService + memoriesProvider
│       ├── knowledge_service.dart      -- KnowledgeService + knowledgeDocumentsProvider
│       ├── skills_service.dart         -- SkillsService + skillsProvider
│       ├── inventory_service.dart      -- InventoryService + inventoryProvider
│       ├── sensor_service.dart         -- SensorService + sensorsProvider
│       ├── insight_service.dart        -- InsightService + insightsProvider
│       ├── notification_service.dart   -- NotificationService + notificationsProvider
│       ├── privacy_service.dart        -- PrivacyService + fortressStatusProvider
│       ├── system_service.dart         -- SystemService + systemStatusDetailProvider + ollamaModelsProvider
│       └── user_service.dart           -- UserService + usersListProvider
├── features/
│   ├── auth/
│   │   ├── login_screen.dart           -- Login with server URL config
│   │   ├── register_screen.dart        -- User registration
│   │   ├── device_not_setup_screen.dart-- Setup wizard redirect
│   │   └── users_screen.dart           -- User management (role change, deactivate, delete)
│   ├── chat/
│   │   ├── chat_list_screen.dart       -- Conversation list with FAB, swipe-to-delete
│   │   └── chat_conversation_screen.dart -- Message list with input bar
│   ├── memory/
│   │   └── memory_screen.dart          -- Memory list with search, importance filter, detail sheet
│   ├── knowledge/
│   │   ├── knowledge_screen.dart       -- Document list with upload, status icons
│   │   └── document_detail_screen.dart -- Document metadata, edit display name
│   ├── skills/
│   │   └── skills_screen.dart          -- Skills grid with detail sheet, execute button
│   ├── inventory/
│   │   └── inventory_screen.dart       -- Inventory list with category filter, add/edit dialogs
│   ├── sensors/
│   │   ├── sensors_screen.dart         -- Sensor card grid with toggle switches
│   │   ├── sensor_detail_screen.dart   -- Sensor info + fl_chart historical readings
│   │   └── add_sensor_screen.dart      -- Sensor registration form with connection test
│   ├── insights/
│   │   └── insights_screen.dart        -- Tabbed insights + notifications, generate button
│   ├── privacy/
│   │   └── privacy_screen.dart         -- Fortress toggle, sovereignty report, audit log (3 tabs)
│   └── system/
│       └── system_screen.dart          -- System status, Ollama health, model list
└── shared/
    ├── widgets/
    │   ├── app_shell.dart              -- Responsive scaffold + navigation
    │   ├── loading_indicator.dart      -- Standard loading widget (3 sizes)
    │   ├── error_view.dart             -- Error state with retry
    │   ├── empty_state_view.dart       -- Empty list state
    │   ├── confirmation_dialog.dart    -- Confirm/cancel dialog
    │   ├── connection_lost_banner.dart -- Server unreachable banner
    │   ├── system_status_bar.dart      -- Ollama status + notifications
    │   └── notification_badge.dart     -- Unread count badge
    └── utils/
        ├── date_formatter.dart         -- Static: formatRelative, formatFull, formatDate
        ├── size_formatter.dart         -- Static: formatBytes
        └── platform_utils.dart         -- Mobile/web/tablet detection
```

---

## 3. Route Map

| Route | Screen | Auth Required | Role Restriction |
|-------|--------|---------------|------------------|
| `/login` | LoginScreen | No | None |
| `/register` | RegisterScreen | No | None |
| `/device-not-setup` | DeviceNotSetupScreen | No | None |
| `/` | AppShell -> ChatListScreen | Yes | None |
| `/chat` | ChatListScreen | Yes | None |
| `/chat/:conversationId` | ChatConversationScreen | Yes | None |
| `/memory` | MemoryScreen | Yes | None |
| `/knowledge` | KnowledgeScreen | Yes | None |
| `/knowledge/:documentId` | DocumentDetailScreen | Yes | None |
| `/skills` | SkillsScreen | Yes | None |
| `/inventory` | InventoryScreen | Yes | None |
| `/sensors` | SensorsScreen | Yes | None |
| `/sensors/add` | AddSensorScreen | Yes | None |
| `/sensors/:sensorId` | SensorDetailScreen | Yes | None |
| `/insights` | InsightsScreen | Yes | None |
| `/privacy` | PrivacyScreen | Yes | None |
| `/system` | SystemScreen | Yes | None |
| `/users` | UsersScreen | Yes | OWNER, ADMIN |

---

## 4. State Management Architecture (Riverpod)

```
                    ┌──────────────────────┐
                    │   ProviderScope      │
                    │   (main.dart)        │
                    └──────────┬───────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                     │
┌─────────▼──────────┐ ┌──────▼──────────┐ ┌───────▼──────────┐
│ secureStorageProvider│ │ apiClientProvider │ │ themeProvider     │
│ (Provider)           │ │ (Provider)        │ │ (StateNotifier)   │
└─────────┬──────────┘ └──────┬──────────┘ └──────────────────┘
          │                    │
          ├────────────────────┤
          │                    │
┌─────────▼──────────┐ ┌──────▼──────────┐
│ authServiceProvider  │ │ routerProvider    │
│ (Provider)           │ │ (Provider)        │
└─────────┬──────────┘ └──────────────────┘
          │
┌─────────▼──────────┐
│ authStateProvider    │
│ (AsyncNotifier)      │
└──────────────────────┘

          System Providers (auto-dispose, polled):
┌──────────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ connectionStatusProv. │ │ modelHealthProv.  │ │ unreadCountProv.  │
│ (StreamProvider)      │ │ (FutureProvider)  │ │ (FutureProvider)  │
│ polls /api/system/    │ │ polls /api/models │ │ polls /api/notif. │
│ status every 10s      │ │ /health every 60s │ │ /unread-count 30s │
└──────────────────────┘ └──────────────────┘ └──────────────────┘

          Domain Service Providers (auto-dispose):
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ chatService      │ │ memoryService    │ │ knowledgeService │
│ conversationsProv│ │ memoriesProvider  │ │ knowledgeDocsProv│
│ messagesProv(id) │ │                  │ │                  │
└─────────────────┘ └─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ skillsService    │ │ inventoryService │ │ sensorService    │
│ skillsProvider   │ │ inventoryProvider│ │ sensorsProvider   │
└─────────────────┘ └─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ insightService   │ │ notifService     │ │ privacyService   │
│ insightsProvider  │ │ notifsProvider   │ │ fortressProvider  │
└─────────────────┘ └─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐
│ systemService    │ │ userService      │
│ statusDetailProv │ │ usersListProv    │
│ ollamaModelsProv │ │                  │
└─────────────────┘ └─────────────────┘
```

---

## 5. API Client Architecture

### Interceptor Chain

```
Request
  │
  ▼
┌─────────────────────┐
│ AuthInterceptor      │  Adds Authorization: Bearer {token}
│ onRequest()          │  Reads token from SecureStorageService
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ LoggingInterceptor   │  Debug mode only
│ (optional)           │  Logs method, path, status
└─────────┬───────────┘
          │
          ▼
      Network Request
          │
          ▼
┌─────────────────────┐
│ AuthInterceptor      │  On 401: attempt token refresh
│ onError()            │  If refresh succeeds: retry request
│                      │  If refresh fails: clear tokens
└─────────────────────┘
```

### HTTP Methods

| Method | Use Case |
|--------|----------|
| GET | List/fetch resources |
| POST | Create resources, send messages, upload files |
| PUT | Update resources |
| PATCH | Toggle skill enabled state |
| DELETE | Remove resources, wipe data |

---

## 6. Auth Flow

### Startup

```
main()
  │
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── SecureStorageService.getServerUrl()
  ├── Create MyOffGridAIApiClient with resolved URL
  ├── ProviderScope with overrides
  └── runApp(MyOffGridAIApp)
        │
        ▼
GoRouter redirect
  │
  ├── Read authStateProvider
  │   ├── Has stored token?
  │   │   ├── YES: decode JWT, check expiry
  │   │   │   ├── Valid: return UserModel (authenticated)
  │   │   │   └── Expired: try refresh
  │   │   │       ├── Success: return UserModel
  │   │   │       └── Failure: return null (unauthenticated)
  │   │   └── NO: return null (unauthenticated)
  │   │
  │   ├── Unauthenticated + not on /login or /register?
  │   │   └── Redirect to /login
  │   │
  │   └── Authenticated + on /login or /register?
  │       └── Redirect to /
  │
  └── Check /users route: require OWNER/ADMIN role
```

---

## 7. Responsive Layout Strategy

### Breakpoints

| Width | Classification | Navigation |
|-------|---------------|------------|
| < 600px | Mobile | BottomNavigationBar (5 items) |
| 600-1199px | Tablet | NavigationRail (left side) |
| >= 1200px | Desktop/Web | NavigationRail (left side) |

### AppShell Navigation Destinations

**Primary (always visible):**
1. Chat (home)
2. Memory
3. Knowledge
4. Sensors
5. More (opens drawer)

**Drawer (via "More"):**
- Skills
- Inventory
- Insights
- Privacy
- System
- Users (OWNER/ADMIN only)

---

## 8. Server API Alignment

### Auth Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| Login | POST /api/auth/login | ApiResponse<AuthResponse> |
| Register | POST /api/auth/register | ApiResponse<AuthResponse> |
| Refresh | POST /api/auth/refresh | ApiResponse<AuthResponse> |
| Logout | POST /api/auth/logout | ApiResponse<Void> |

### Chat Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Conversations | GET /api/chat/conversations | ApiResponse<List<ConversationSummaryDto>> |
| Create Conversation | POST /api/chat/conversations | ApiResponse<ConversationDto> |
| Get Conversation | GET /api/chat/conversations/{id} | ApiResponse<ConversationDto> |
| Delete Conversation | DELETE /api/chat/conversations/{id} | ApiResponse<Void> |
| Archive Conversation | PUT /api/chat/conversations/{id}/archive | ApiResponse<Void> |
| List Messages | GET /api/chat/conversations/{id}/messages | ApiResponse<List<MessageDto>> |
| Send Message | POST /api/chat/conversations/{id}/messages | ApiResponse<MessageDto> |

### Memory Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Memories | GET /api/memory | ApiResponse<List<MemoryDto>> |
| Get Memory | GET /api/memory/{id} | ApiResponse<MemoryDto> |
| Delete Memory | DELETE /api/memory/{id} | ApiResponse<Void> |
| Update Tags | PUT /api/memory/{id}/tags | ApiResponse<MemoryDto> |
| Update Importance | PUT /api/memory/{id}/importance | ApiResponse<MemoryDto> |
| Search | POST /api/memory/search | ApiResponse<List<MemorySearchResultDto>> |
| Export | GET /api/memory/export | ApiResponse<List<MemoryDto>> |

### Knowledge Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Documents | GET /api/knowledge/documents | ApiResponse<List<KnowledgeDocumentDto>> |
| Get Document | GET /api/knowledge/documents/{id} | ApiResponse<KnowledgeDocumentDto> |
| Upload Document | POST /api/knowledge/documents (multipart) | ApiResponse<KnowledgeDocumentDto> |
| Update Display Name | PUT /api/knowledge/documents/{id}/display-name | ApiResponse<KnowledgeDocumentDto> |
| Delete Document | DELETE /api/knowledge/documents/{id} | ApiResponse<Void> |
| Retry Processing | POST /api/knowledge/documents/{id}/retry | ApiResponse<KnowledgeDocumentDto> |
| Search | POST /api/knowledge/search | ApiResponse<List<KnowledgeSearchResultDto>> |

### Skills Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Skills | GET /api/skills | ApiResponse<List<SkillDto>> |
| Get Skill | GET /api/skills/{id} | ApiResponse<SkillDto> |
| Toggle Skill | PATCH /api/skills/{id}/toggle | ApiResponse<SkillDto> |
| Execute Skill | POST /api/skills/execute | ApiResponse<SkillExecutionDto> |
| List Executions | GET /api/skills/executions | ApiResponse<Page<SkillExecutionDto>> |

### Inventory Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Items | GET /api/skills/inventory | ApiResponse<List<InventoryItemDto>> |
| Create Item | POST /api/skills/inventory | ApiResponse<InventoryItemDto> |
| Update Item | PUT /api/skills/inventory/{id} | ApiResponse<InventoryItemDto> |
| Delete Item | DELETE /api/skills/inventory/{id} | ApiResponse<Void> |

### Sensor Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Sensors | GET /api/sensors | ApiResponse<List<SensorDto>> |
| Get Sensor | GET /api/sensors/{id} | ApiResponse<SensorDto> |
| Create Sensor | POST /api/sensors | ApiResponse<SensorDto> |
| Delete Sensor | DELETE /api/sensors/{id} | ApiResponse<Void> |
| Start Sensor | POST /api/sensors/{id}/start | ApiResponse<Void> |
| Stop Sensor | POST /api/sensors/{id}/stop | ApiResponse<Void> |
| Get Latest Reading | GET /api/sensors/{id}/readings/latest | ApiResponse<SensorReadingDto> |
| Get History | GET /api/sensors/{id}/readings | ApiResponse<List<SensorReadingDto>> |
| Update Thresholds | PUT /api/sensors/{id}/thresholds | ApiResponse<SensorDto> |
| Test Connection | POST /api/sensors/test-connection | ApiResponse<SensorTestResult> |
| List Ports | GET /api/sensors/available-ports | ApiResponse<List<String>> |

### Insight Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Insights | GET /api/insights | ApiResponse<List<InsightDto>> |
| Generate Insights | POST /api/insights/generate | ApiResponse<List<InsightDto>> |
| Mark as Read | PUT /api/insights/{id}/read | ApiResponse<Void> |
| Dismiss | PUT /api/insights/{id}/dismiss | ApiResponse<Void> |
| Unread Count | GET /api/insights/unread-count | ApiResponse<Integer> |

### Notification Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Notifications | GET /api/notifications | ApiResponse<List<NotificationDto>> |
| Mark as Read | PUT /api/notifications/{id}/read | ApiResponse<Void> |
| Mark All Read | PUT /api/notifications/read-all | ApiResponse<Void> |
| Delete | DELETE /api/notifications/{id} | ApiResponse<Void> |
| Unread Count | GET /api/notifications/unread-count | ApiResponse<Integer> |

### Privacy Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| Fortress Status | GET /api/privacy/fortress/status | ApiResponse<FortressStatus> |
| Enable Fortress | POST /api/privacy/fortress/enable | ApiResponse<FortressStatus> |
| Disable Fortress | POST /api/privacy/fortress/disable | ApiResponse<FortressStatus> |
| Sovereignty Report | GET /api/privacy/sovereignty-report | ApiResponse<SovereigntyReport> |
| Audit Logs | GET /api/privacy/audit-logs | ApiResponse<List<AuditLogDto>> |
| Wipe Self Data | DELETE /api/privacy/wipe/self | ApiResponse<WipeResult> |

### System Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| System Status | GET /api/system/status | ApiResponse<SystemStatusDto> |
| Model Health | GET /api/models/health | ApiResponse<OllamaHealthDto> |
| List Models | GET /api/models | ApiResponse<List<OllamaModelInfo>> |
| Active Model | GET /api/models/active | ApiResponse<ActiveModelDto> |

### User Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Users | GET /api/users | ApiResponse<List<UserSummaryDto>> |
| Get User | GET /api/users/{id} | ApiResponse<UserDetailDto> |
| Update User | PUT /api/users/{id} | ApiResponse<UserDetailDto> |
| Deactivate | PUT /api/users/{id}/deactivate | ApiResponse<Void> |
| Delete User | DELETE /api/users/{id} | ApiResponse<Void> |

---

## 9. Security

- JWT tokens stored exclusively in `flutter_secure_storage`
  - iOS: Keychain with `KeychainAccessibility.first_unlock`
  - Android: `EncryptedSharedPreferences`
- Tokens never stored in SharedPreferences or plain text
- Auto-refresh on 401 with single-retry guard (prevents infinite loops)
- Refresh endpoint itself is never retried
- Logging interceptor never logs request bodies containing credentials
- Server URL configurable at runtime (not hardcoded)

---

## 10. Test Coverage

| Category | Test File | Tests |
|----------|-----------|-------|
| ConversationModel | test/core/models/conversation_model_test.dart | 4 |
| MessageModel | test/core/models/message_model_test.dart | 4 |
| MemoryModel | test/core/models/memory_model_test.dart | 6 |
| KnowledgeDocumentModel | test/core/models/knowledge_document_model_test.dart | 6 |
| SkillModel | test/core/models/skill_model_test.dart | 5 |
| InventoryItemModel | test/core/models/inventory_item_model_test.dart | 7 |
| SensorModel | test/core/models/sensor_model_test.dart | 7 |
| InsightModel | test/core/models/insight_model_test.dart | 3 |
| NotificationModel | test/core/models/notification_model_test.dart | 3 |
| PrivacyModels | test/core/models/privacy_models_test.dart | 8 |
| SystemModels | test/core/models/system_models_test.dart | 5 |
| PageResponse | test/core/models/page_response_test.dart | 3 |
| ApiClient/Models | test/core/api/myoffgridai_api_client_test.dart | 8 |
| AuthState | test/core/auth/auth_state_test.dart | 4 |
| ChatListScreen | test/features/chat/chat_list_screen_test.dart | 4 |
| ChatConversationScreen | test/features/chat/chat_conversation_screen_test.dart | 4 |
| MemoryScreen | test/features/memory/memory_screen_test.dart | 5 |
| KnowledgeScreen | test/features/knowledge/knowledge_screen_test.dart | 4 |
| SkillsScreen | test/features/skills/skills_screen_test.dart | 3 |
| InventoryScreen | test/features/inventory/inventory_screen_test.dart | 5 |
| SensorsScreen | test/features/sensors/sensors_screen_test.dart | 5 |
| AddSensorScreen | test/features/sensors/add_sensor_screen_test.dart | 8 |
| InsightsScreen | test/features/insights/insights_screen_test.dart | 5 |
| PrivacyScreen | test/features/privacy/privacy_screen_test.dart | 5 |
| SystemScreen | test/features/system/system_screen_test.dart | 8 |
| UsersScreen | test/features/auth/users_screen_test.dart | 6 |
| LoginScreen | test/features/auth/login_screen_test.dart | 6 |
| RegisterScreen | test/features/auth/register_screen_test.dart | 4 |
| DeviceNotSetupScreen | test/features/auth/device_not_setup_screen_test.dart | 4 |
| LoadingIndicator | test/shared/widgets/loading_indicator_test.dart | 5 |
| ErrorView | test/shared/widgets/error_view_test.dart | 4 |
| EmptyStateView | test/shared/widgets/empty_state_view_test.dart | 3 |
| ConfirmationDialog | test/shared/widgets/confirmation_dialog_test.dart | 3 |
| ConnectionLostBanner | test/shared/widgets/connection_lost_banner_test.dart | 3 |
| NotificationBadge | test/shared/widgets/notification_badge_test.dart | 4 |
| DateFormatter | test/shared/utils/date_formatter_test.dart | 7 |
| SizeFormatter | test/shared/utils/size_formatter_test.dart | 6 |
| **Total** | | **189** |
