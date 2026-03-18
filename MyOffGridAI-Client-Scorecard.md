# MyOffGridAI-Client — Quality Scorecard

**Generated:** 2026-03-18T00:31:18Z
**Branch:** main
**Commit:** 3f8d787eb623885c1b0a9518e0f3dfa54022e6ce P15-Fix: Wire LM Studio-style Discover tab layout into settings screen

---

## Security (10 checks, max 20)

| Check | Result | Score |
|---|---|---|
| SEC-01 Secure token storage (FlutterSecureStorage) | PASS (7 refs) | 2 |
| SEC-02 JWT token handling | PASS (48 refs) | 2 |
| SEC-03 No hardcoded secrets in code | PASS (0 found) | 2 |
| SEC-04 HTTPS/TLS awareness | PARTIAL (1 ref — defaults to http for dev) | 1 |
| SEC-05 Input validation on forms | PASS (143 refs) | 2 |
| SEC-06 No sensitive data in logs | PASS (0 found) | 2 |
| SEC-07 Auth guard on routes | PASS (4 refs) | 2 |
| SEC-08 Role-based access control | PASS (8 refs) | 2 |
| SEC-09 Token auto-refresh on 401 | PASS (12 refs) | 2 |
| SEC-10 Secure storage for device ID | PASS (6 refs) | 2 |

**Security Score: 19 / 20 (95%)**


## Data Integrity (8 checks, max 16)

| Check | Result | Score |
|---|---|---|
| DI-01 Models have timestamp fields | PARTIAL (8/20 models) | 1 |
| DI-02 Immutable models (final fields) | PASS (373 final fields) | 2 |
| DI-03 Null safety (nullable fields explicit) | PASS (320 refs) | 2 |
| DI-04 Validation on model creation | PASS (184 required/assert) | 2 |
| DI-05 Null-safe JSON parsing | PASS (uses ?? and as Type? patterns inline) | 2 |
| DI-06 Consistent serialization | PASS (20/20 models have fromJson) | 2 |
| DI-07 Pagination support | PASS (PageResponse + 14 refs) | 2 |
| DI-08 Type-safe enums/constants | PASS (50 constant/enum defs) | 2 |

**Data Integrity Score: 15 / 16 (94%)**


## API Quality (8 checks, max 16)

| Check | Result | Score |
|---|---|---|
| API-01 Consistent error handling | PASS (84 refs — ApiException + catch blocks) | 2 |
| API-02 Pagination on list endpoints | PASS (13 refs — PageResponse used) | 2 |
| API-03 Response envelope (ApiResponse) | PASS (6 refs) | 2 |
| API-04 Streaming support (SSE) | PASS (8 refs — Stream, getStream, postStream) | 2 |
| API-05 API versioning | PASS (19 /api/ paths defined) | 2 |
| API-06 Request/response logging | PASS (5 refs — LoggingInterceptor in debug) | 2 |
| API-07 Typed exceptions | PASS (17 refs — ApiException with statusCode) | 2 |
| API-08 Multipart upload support | PASS (11 refs — FormData, postMultipart) | 2 |

**API Quality Score: 16 / 16 (100%)**


## Code Quality (11 checks, max 22)

| Check | Result | Score |
|---|---|---|
| CQ-01 Immutability/const usage | PASS (2843 refs — final/const/static) | 2 |
| CQ-02 Logging framework (debugPrint) | PASS (59 refs) | 2 |
| CQ-03 No raw print statements | PASS (0 found) | 2 |
| CQ-04 State management (Riverpod) | PASS (507 refs) | 2 |
| CQ-05 Constants extracted | PASS (442 refs — AppConstants + static const) | 2 |
| CQ-06 Separation of concerns | PASS (20 models, 21 services, 24 screens, 18 widgets) | 2 |
| CQ-07 Service layer exists | PASS (21 service files) | 2 |
| CQ-08 Config layer exists | PASS (3 config files) | 2 |
| CQ-09 Doc comments on classes (BLOCKING) | PARTIAL (229/237 = 97%) | 0 |
| CQ-10 Doc comments on public methods (BLOCKING) | FAIL (232/738 = 31%) | 0 |
| CQ-11 No TODO/FIXME/placeholder (BLOCKING) | PASS (0 found) | 2 |

**CQ-09 and CQ-10 are BLOCKING:** Documentation coverage below 100% zeroes the category.

**Code Quality Score: 0 / 22 (0%) — BLOCKED by CQ-09 and CQ-10**


## Test Quality (12 checks, max 24)

| Check | Result | Score |
|---|---|---|
| TST-01 Test files exist | PASS (94 test files) | 2 |
| TST-02 Source-to-test ratio | GOOD (94 tests / 100 source = 94%) | 2 |
| TST-03 Widget tests | PASS (42 files with testWidgets/pumpWidget) | 2 |
| TST-04 Unit tests | PASS (53 files with test()) | 2 |
| TST-05 Test coverage = 100% (BLOCKING) | FAIL (80.7% — 6396/7916 lines) | 0 |
| TST-06 Test per source file | GOOD (92/100 source files have matching tests) | 2 |
| TST-07 All tests pass | PASS (1770/1770 pass) | 2 |
| TST-08 Mock usage | PASS (1558 mock/when/verify references) | 2 |
| TST-09 Missing test files | 8 source files without tests (api_exception, api_response, judge_service, 3 settings widgets, main, download_trigger_web) | 0 |
| TST-10 Auth flow tested | PASS (auth_service_test, auth_state_test, login/register screen tests) | 2 |
| TST-11 Service layer tested | PASS (21 service test files) | 2 |
| TST-12 Widget tests for screens | PASS (24 screen test files) | 2 |

**TST-05 is BLOCKING:** Test coverage below 100% zeroes the category.

**Test Quality Score: 0 / 24 (0%) — BLOCKED by TST-05 (80.7% < 100%)**


## Infrastructure (6 checks, max 12)

| Check | Result | Score |
|---|---|---|
| INF-01 No hardcoded URLs (configurable) | PASS (server URL from SecureStorage) | 2 |
| INF-02 Platform-aware builds | PASS (conditional imports, kIsWeb checks) | 2 |
| INF-03 Responsive layout | PASS (PlatformUtils breakpoints, mobile/tablet/desktop) | 2 |
| INF-04 Health monitoring | PASS (connectionStatusProvider, modelHealthProvider polling) | 2 |
| INF-05 Structured logging (debugPrint) | PASS (59 debugPrint refs, 0 raw print) | 2 |
| INF-06 CI/CD config | FAIL (no pipeline detected) | 0 |

**Infrastructure Score: 10 / 12 (83%)**

## Security Vulnerabilities — Snyk (5 checks, max 10)

| Check | Result | Score |
|---|---|---|
| SNYK-01 Zero critical dep vulnerabilities | PASS | 2 |
| SNYK-02 Zero high dep vulnerabilities | PASS | 2 |
| SNYK-03 Medium/low dep vulnerabilities | PASS (0 found) | 2 |
| SNYK-04 Zero code (SAST) errors | PASS | 2 |
| SNYK-05 Zero code (SAST) warnings | PASS | 2 |

**Snyk Vulnerabilities Score: 10 / 10 (100%)**


---

## Scorecard Summary

| Category | Score | Max | % |
|---|---|---|---|
| Security | 19 | 20 | 95% |
| Data Integrity | 15 | 16 | 94% |
| API Quality | 16 | 16 | 100% |
| Code Quality | 0 | 22 | 0% |
| Test Quality | 0 | 24 | 0% |
| Infrastructure | 10 | 12 | 83% |
| Snyk Vulnerabilities | 10 | 10 | 100% |
| **OVERALL** | **70** | **120** | **58%** |

**Grade: C (55-69%)**

### BLOCKING ISSUES

1. **CQ-09 Doc comments on classes:** 229/237 (97%) — 8 classes missing DartDoc `///` comments
2. **CQ-10 Doc comments on public methods:** 232/738 (31%) — 506 public methods missing DartDoc `///` comments
3. **TST-05 Test coverage:** 80.7% (6396/7916 lines) — 19.3% uncovered. Missing test files for: api_exception.dart, api_response.dart, judge_service.dart, discover_model_list.dart, model_detail_panel.dart, smart_quant_selector.dart, main.dart, download_trigger_web.dart

### Categories Below 60%

- **Code Quality (0%):** BLOCKED by CQ-09 (class doc comments 97%) and CQ-10 (method doc comments 31%). All non-blocking checks pass.
- **Test Quality (0%):** BLOCKED by TST-05 (coverage 80.7%). All 1770 tests pass, 94/100 source files have test files.

### Note
Without the blocking checks, the effective score would be 70/74 (95%) on non-blocked categories. The primary remediation path is adding DartDoc comments and increasing test coverage to 100%.

