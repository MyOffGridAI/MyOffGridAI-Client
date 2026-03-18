# MyOffGridAI-Client — Quality Scorecard

**Generated:** 2026-03-18T18:31:02Z
**Branch:** main
**Commit:** a3cf2693bec00c2b6457df0fcde7779fcdee2de4 Add centralized file-based logging for client — replace all debugPrint with LogService

---

## Security (10 checks, max 20)

| Check | Result | Score |
|---|---|---|
| SEC-01 Secure token storage (FlutterSecureStorage) | PASS (7 refs) | 2 |
| SEC-02 JWT interceptor with auto-refresh | PASS (33 refs) | 2 |
| SEC-03 No hardcoded secrets in source | PASS (0 found) | 2 |
| SEC-04 Auth guard on all routes | PASS (5 refs) | 2 |
| SEC-05 Rate limiting | N/A (server-side responsibility) | 2 |
| SEC-06 No sensitive data in logs | PASS (0 leaked) | 2 |
| SEC-07 Input validation on forms | PASS (120 refs) | 2 |
| SEC-08 Role-based access control | PASS (16 refs — OWNER/ADMIN/MEMBER) | 2 |
| SEC-09 Secrets externalized | PASS (no secrets in source) | 2 |
| SEC-10 Tokens cleared on logout | PASS (6 refs) | 2 |

**Security Score: 20 / 20 (100%)**


## Data Integrity (8 checks, max 16)

| Check | Result | Score |
|---|---|---|
| DI-01 Models have audit fields | 8/20 models with createdAt/updatedAt | 1 |
| DI-02 Immutable models (const constructors) | PASS (48 const constructors) | 2 |
| DI-03 Null-safe field handling | PASS (492 null-safe casts) | 2 |
| DI-04 Default values for nullable JSON | PASS (190 defaults) | 2 |
| DI-05 Type-safe fromJson | PASS (350 typed casts) | 2 |
| DI-06 Pagination support | PASS (PageResponse + 14 refs) | 2 |
| DI-07 Consistent enum handling | PASS (50 enum constants) | 2 |
| DI-08 copyWith pattern | PARTIAL (only MessageModel) | 1 |

**Data Integrity Score: 14 / 16 (88%)**


## API Quality (8 checks, max 16)

| Check | Result | Score |
|---|---|---|
| API-01 Consistent error handling (ApiException) | PASS (93 refs) | 2 |
| API-02 Pagination on list endpoints | PASS (30 refs) | 2 |
| API-03 ApiResponse envelope used consistently | PASS (106 refs) | 2 |
| API-04 HTTP method variety (GET/POST/PUT/PATCH/DELETE) | PASS (128 calls) | 2 |
| API-05 SSE streaming support | PASS (10 refs) | 2 |
| API-06 Request/response logging | PASS (5 refs) | 2 |
| API-07 Centralized API base paths | PASS (18 paths in constants.dart) | 2 |
| API-08 Multipart upload support | PASS (11 refs) | 2 |

**API Quality Score: 16 / 16 (100%)**


## Code Quality (11 checks, max 22)

| Check | Result | Score |
|---|---|---|
| CQ-01 Riverpod DI (proper dependency injection) | PASS (78 providers) | 2 |
| CQ-02 No print/debugPrint statements | PASS (0 found — all replaced with LogService) | 2 |
| CQ-03 Centralized logging used | PASS (37 refs to LogService) | 2 |
| CQ-04 Constants extracted (no magic strings) | PASS (444 refs) | 2 |
| CQ-05 Models separate from services | PASS (20 models, 22 services) | 2 |
| CQ-06 Feature-first architecture | PASS (16 feature modules) | 2 |
| CQ-07 Shared widgets extracted | PASS (15 shared files) | 2 |
| CQ-08 Analysis rules configured | PASS (analysis_options.yaml) | 2 |
| CQ-09 DartDoc on classes = 100% (BLOCKING) | FAIL (231/239 = 97%) | 0 |
| CQ-10 DartDoc on public methods = 100% (BLOCKING) | FAIL (131/197 = 66%) | 0 |
| CQ-11 No TODO/FIXME/stub (BLOCKING) | PASS (2 intentional provider guards, 0 actual TODOs) | 2 |

**CQ-09 and CQ-10 are BLOCKING: Code Quality category scores 0.**

Missing class docs in:
- `lib/features/settings/settings_screen.dart` (20/22)
- `lib/features/settings/widgets/discover_model_list.dart` (3/4)
- `lib/features/settings/widgets/model_detail_panel.dart` (3/4)
- `lib/features/chat/widgets/thinking_block.dart` (1/2)
- `lib/features/chat/widgets/message_action_bar.dart` (2/3)
- `lib/features/notifications/notifications_screen.dart` (2/4)

**Code Quality Score: 0 / 22 (BLOCKED — doc coverage below 100%)**


## Test Quality (12 checks, max 24)

| Check | Result | Score |
|---|---|---|
| TST-01 Test files exist | 95 test files | 2 |
| TST-02 Source-to-test ratio | 95 / 101 (94%) | 2 |
| TST-03 No untested source files | 8 files without dedicated tests | 1 |
| TST-04 Widget tests present | 42 widget test files | 2 |
| TST-05 Test coverage = 100% (BLOCKING) | 80% (6452/7980 lines) | 0 |
| TST-06 All tests pass | PASS (1788 tests, 0 failures) | 2 |
| TST-07 Mock framework used | PASS (mocktail + mockito, 341 refs) | 2 |
| TST-08 Auth flow tests | PASS (auth_service_test, auth_state_test) | 2 |
| TST-09 Model serialization tests | PASS (20 model test files) | 2 |
| TST-10 Service layer tests | PASS (20+ service test files) | 2 |
| TST-11 Screen/widget tests | PASS (42 screen/widget test files) | 2 |
| TST-12 Total test methods | 1788 | 2 |

**TST-05 is BLOCKING: Test coverage 80% < 100%. Test Quality category scores 0.**

Missing test files for:
- `lib/core/api/api_exception.dart` — Simple data class
- `lib/core/api/api_response.dart` — Simple data class
- `lib/core/services/judge_service.dart` — Service
- `lib/features/settings/widgets/discover_model_list.dart` — Widget
- `lib/features/settings/widgets/model_detail_panel.dart` — Widget
- `lib/features/settings/widgets/smart_quant_selector.dart` — Widget
- `lib/main.dart` — Entry point
- `lib/shared/utils/download_trigger_web.dart` — Web-only (platform-specific)

**Test Quality Score: 0 / 24 (BLOCKED — coverage below 100%)**


## Infrastructure (6 checks, max 12)

| Check | Result | Score |
|---|---|---|
| INF-01 No Dockerfile (client app) | N/A — Flutter client, no container needed | 2 |
| INF-02 Platform configs present | PASS (Android, iOS, Web targets) | 2 |
| INF-03 Environment separation | PASS (kIsWeb platform detection, configurable server URL) | 2 |
| INF-04 Health check mechanism | PASS (connectionStatusProvider polls every 10s) | 2 |
| INF-05 Centralized logging | PASS (LogService — rotating file-based, replaced all debugPrint) | 2 |
| INF-06 CI/CD config | FAIL — No pipeline configuration | 0 |

**Infrastructure Score: 10 / 12 (83%)**

## Snyk Vulnerabilities (5 checks, max 10)

| Check | Result | Score |
|---|---|---|
| SNYK-01 Zero critical dependency vulnerabilities | PASS (0 critical) | 2 |
| SNYK-02 Zero high dependency vulnerabilities | PASS (0 high) | 2 |
| SNYK-03 Medium/low dependency vulnerabilities | PASS (0 total) | 2 |
| SNYK-04 Zero code (SAST) errors | PASS (0 errors) | 2 |
| SNYK-05 Zero code (SAST) warnings | PASS (0 warnings) | 2 |

**Snyk Vulnerabilities Score: 10 / 10 (100%)**


---

## Scorecard Summary

| Category | Score | Max | % |
|---|---|---|---|
| Security | 20 | 20 | 100% |
| Data Integrity | 14 | 16 | 88% |
| API Quality | 16 | 16 | 100% |
| Code Quality | 0 | 22 | 0% (BLOCKED) |
| Test Quality | 0 | 24 | 0% (BLOCKED) |
| Infrastructure | 10 | 12 | 83% |
| Snyk Vulnerabilities | 10 | 10 | 100% |
| **OVERALL** | **70** | **120** | **58%** |

**Grade: C (55-69%)**

### Blocking Issues

1. **CQ-09 DartDoc on classes** — 231/239 (97%). 8 undocumented classes in settings widgets, chat widgets, and notifications.
2. **CQ-10 DartDoc on public methods** — 131/197 (66%). Multiple files with undocumented public methods.
3. **TST-05 Test coverage** — 80% (6452/7980 lines). Missing test files for 8 source files.

### Non-Blocking Issues

4. **INF-06** — No CI/CD pipeline configuration.
5. **DI-01** — Only 8/20 model files have createdAt/updatedAt audit fields (appropriate — not all models need them).
6. **DI-08** — Only MessageModel has copyWith pattern (appropriate — most models are immutable DTOs).

### Path to Grade A

1. Add DartDoc `///` comments to the 8 undocumented classes → CQ-09 unblocks (+22)
2. Add DartDoc `///` comments to undocumented public methods → CQ-10 unblocks
3. Add test files for 8 missing sources → improve coverage toward 100% → TST-05 unblocks (+24)
4. Add CI/CD pipeline → INF-06 passes (+2)

**If CQ and TST unblocked: 116/120 = 97% → Grade A**

