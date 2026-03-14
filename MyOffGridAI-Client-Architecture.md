# MyOffGridAI-Client -- Architecture Specification

**Generated:** 2026-03-14
**Phase:** 9 -- Flutter Client Core
**Version:** 1.0.0

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
│   │   ├── myoffgridai_api_client.dart -- Dio client with JWT interceptors
│   │   ├── api_exception.dart          -- Typed API exceptions
│   │   ├── api_response.dart           -- Server ApiResponse<T> mirror
│   │   └── providers.dart              -- System status, health, notification providers
│   ├── auth/
│   │   ├── auth_service.dart           -- Login, logout, register, refresh
│   │   ├── auth_state.dart             -- Riverpod AsyncNotifier for auth
│   │   └── secure_storage_service.dart -- flutter_secure_storage wrapper
│   └── models/
│       ├── user_model.dart             -- UserSummaryDto mirror
│       └── page_response.dart          -- Spring Page<T> mirror
├── features/
│   ├── auth/
│   │   ├── login_screen.dart           -- Login with server URL config
│   │   ├── register_screen.dart        -- User registration
│   │   ├── device_not_setup_screen.dart-- Setup wizard redirect
│   │   └── users_screen.dart           -- User management (OWNER/ADMIN)
│   ├── chat/                           -- MC-002
│   ├── memory/                         -- MC-002
│   ├── knowledge/                      -- MC-002
│   ├── skills/                         -- MC-002
│   ├── inventory/                      -- MC-002
│   ├── sensors/                        -- MC-002
│   ├── insights/                       -- MC-002
│   ├── proactive/                      -- MC-002
│   ├── privacy/                        -- MC-002
│   └── system/                         -- MC-002
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
        ├── date_formatter.dart         -- Relative/full/short date formatting
        ├── size_formatter.dart         -- Byte size formatting
        └── platform_utils.dart         -- Mobile/web/tablet detection
```

---

## 3. Route Map

| Route | Screen | Auth Required | Role Restriction |
|-------|--------|---------------|------------------|
| `/login` | LoginScreen | No | None |
| `/register` | RegisterScreen | No | None |
| `/device-not-setup` | DeviceNotSetupScreen | No | None |
| `/` | AppShell -> Chat (stub) | Yes | None |
| `/chat` | ChatListScreen (stub) | Yes | None |
| `/chat/:conversationId` | ChatConversationScreen (stub) | Yes | None |
| `/memory` | MemoryScreen (stub) | Yes | None |
| `/knowledge` | KnowledgeScreen (stub) | Yes | None |
| `/skills` | SkillsScreen (stub) | Yes | None |
| `/inventory` | InventoryScreen (stub) | Yes | None |
| `/sensors` | SensorsScreen (stub) | Yes | None |
| `/insights` | InsightsScreen (stub) | Yes | None |
| `/privacy` | PrivacyScreen (stub) | Yes | None |
| `/system` | SystemScreen (stub) | Yes | None |
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

### Token Refresh Flow

```
Request returns 401
    │
    ▼
Is this the /auth/refresh or /auth/login endpoint?
    │                                        │
    YES                                      NO
    │                                        │
    ▼                                        ▼
Pass error through                 POST /api/auth/refresh
(prevent infinite loop)                │
                                       ├── Success: store new tokens,
                                       │            retry original request
                                       │
                                       └── Failure: clear all tokens,
                                                    pass error through
```

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

### Login

```
User enters credentials
  │
  ▼
AuthNotifier.login(username, password)
  ├── state = AsyncLoading
  ├── AuthService.login()
  │   ├── POST /api/auth/login
  │   ├── Parse AuthResponse
  │   └── SecureStorageService.saveTokens()
  ├── state = AsyncData(UserModel)
  └── GoRouter navigates to /
```

### Logout

```
AuthNotifier.logout()
  ├── AuthService.logout()
  │   ├── POST /api/auth/logout (best-effort)
  │   └── SecureStorageService.clearTokens()
  ├── state = AsyncData(null)
  └── GoRouter redirects to /login
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

## 8. Theme System

### Color Palette

| Token | Light | Dark |
|-------|-------|------|
| Primary | #2D5016 (forest green) | #2D5016 |
| Primary Container | #4A7C2F | #4A7C2F |
| Secondary | #8B5E1A (warm amber) | #8B5E1A |
| Background | #F5F0E8 (parchment) | #1A1A14 |
| Surface | #FFFFFF | #242418 |
| Error | #CF6679 | #CF6679 |
| On Primary | #FFFFFF | #FFFFFF |

### Persistence

- Theme preference stored via `SecureStorageService` (key: `theme_preference`)
- Values: `light`, `dark`, `system`
- Managed by `ThemeNotifier` (Riverpod `StateNotifier<ThemeMode>`)
- Default: `system` (follows OS preference)

---

## 9. Platform Adaptations

| Feature | iOS | Android | Web |
|---------|-----|---------|-----|
| Token Storage | Keychain (first_unlock) | EncryptedSharedPreferences | Browser storage |
| Local Network | NSLocalNetworkUsageDescription in Info.plist | INTERNET + usesCleartextTraffic | Standard fetch |
| Navigation | BottomNav (< 600px) | BottomNav (< 600px) | NavigationRail |
| Touch Targets | Standard (48px) | Standard (48px) | Standard (48px) |

---

## 10. Server API Alignment

### Auth Endpoints (OpenAPI verified)

| Client Action | Server Endpoint | Request | Response |
|--------------|-----------------|---------|----------|
| Login | POST /api/auth/login | LoginRequest | ApiResponse<AuthResponse> |
| Register | POST /api/auth/register | RegisterRequest | ApiResponse<AuthResponse> |
| Refresh | POST /api/auth/refresh | RefreshRequest | ApiResponse<AuthResponse> |
| Logout | POST /api/auth/logout | Authorization header | ApiResponse<Void> |

### User Endpoints (OpenAPI verified)

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| List Users | GET /api/users | ApiResponse<List<UserSummaryDto>> |
| Get User | GET /api/users/{id} | ApiResponse<UserDetailDto> |
| Update User | PUT /api/users/{id} | ApiResponse<UserDetailDto> |
| Deactivate | PUT /api/users/{id}/deactivate | ApiResponse<Void> |
| Delete User | DELETE /api/users/{id} | ApiResponse<Void> |

### System Endpoints

| Client Action | Server Endpoint | Response |
|--------------|-----------------|----------|
| System Status | GET /api/system/status | ApiResponse<SystemStatusDto> |
| Model Health | GET /api/models/health | ApiResponse<OllamaHealthDto> |
| Active Model | GET /api/models/active | ApiResponse<ActiveModelDto> |

---

## 11. Security

- JWT tokens stored exclusively in `flutter_secure_storage`
  - iOS: Keychain with `KeychainAccessibility.first_unlock`
  - Android: `EncryptedSharedPreferences`
- Tokens never stored in SharedPreferences or plain text
- Auto-refresh on 401 with single-retry guard (prevents infinite loops)
- Refresh endpoint itself is never retried
- Logging interceptor never logs request bodies containing credentials
- Server URL configurable at runtime (not hardcoded)

---

## 12. Test Coverage

| Category | Test File | Tests |
|----------|-----------|-------|
| LoadingIndicator | test/shared/widgets/loading_indicator_test.dart | 5 |
| ErrorView | test/shared/widgets/error_view_test.dart | 4 |
| EmptyStateView | test/shared/widgets/empty_state_view_test.dart | 3 |
| ConfirmationDialog | test/shared/widgets/confirmation_dialog_test.dart | 3 |
| ConnectionLostBanner | test/shared/widgets/connection_lost_banner_test.dart | 3 |
| NotificationBadge | test/shared/widgets/notification_badge_test.dart | 4 |
| LoginScreen | test/features/auth/login_screen_test.dart | 6 |
| RegisterScreen | test/features/auth/register_screen_test.dart | 4 |
| DeviceNotSetupScreen | test/features/auth/device_not_setup_screen_test.dart | 4 |
| AuthState | test/core/auth/auth_state_test.dart | 4 |
| ApiClient/Models | test/core/api/myoffgridai_api_client_test.dart | 8 |
| DateFormatter | test/shared/utils/date_formatter_test.dart | 7 |
| SizeFormatter | test/shared/utils/size_formatter_test.dart | 6 |
| PageResponse | test/core/models/page_response_test.dart | 3 |
| **Total** | | **65** (after randomized expansion) |
