# Admin feature-level permission and test coverage audit — 2026-11-01

## Scope
Read-only source and test inspection on `ui/notion-brand-foundation-2026-10-28`. No source changes, Firebase changes, policy approval, merge or deployment.

Files reviewed:
- `lib/features/walkers/services/walker_admin_service.dart`
- `lib/features/service_location/services/location_csv_import_service.dart`
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/access_control/screens/admin_access_control_screen.dart`
- `test/features/walkers/walker_admin_transition_policy_test.dart`
- `test/features/service_location/services/location_csv_import_failure_test.dart`
- `test/features/access_control/admin_access_control_screen_test.dart`

## Findings

### A. Walker Management
**Observed implementation**
- Walker read streams (`watchWalkers`, `watchWalker`, booking and audit streams) do not perform a local role/scope check in this service.
- Mutating `runAdminAction` reads the current caller's `admin_users/{uid}` inside a Firestore transaction and requires document existence, `isActive == true`, and exact `role == 'super_admin'`.
- Walker status and audit log are written in the same transaction.
- Audit record sets `actorRole: 'super_admin'`; action names and before/after fields are explicit.

**Test coverage found**
- `walker_admin_transition_policy_test.dart` covers allowed/denied state transitions, required reason rules, reason length and stable audit action names.
- No `WalkerAdminService` transaction authorization test was found at the inspected likely test paths / code search. The transition-policy unit tests do not prove Firestore transaction authorization, audit atomicity, or Rules enforcement.

**Risk / gate**
- This service's client-side role check is defense-in-depth, not the security boundary. Confirm Firestore Rules deny unauthorized reads/writes and test unauthenticated, inactive, non-`super_admin`, and active `super_admin` cases in the Emulator.
- Do not assume the global `super_admin` requirement is the final governance policy; Team 01 D01 and approved POL-021 must reconcile Founder/Central/Manager roles before role expansion.

### B. CSV Service Location Import
**Observed implementation**
- Import preflight requires an active `super_admin` membership, checks immutable audit/run markers, validates a bounded plan, and fails closed except on a definitive `not-found` marker response.
- Writes are routed through `ServiceLocationService` trusted callables; importer does not activate zones or create boundaries.
- Import run marker and plan are recorded before location writes; ambiguous callable outcomes block automatic retries pending reconciliation.

**Test coverage found**
- `location_csv_import_failure_test.dart` covers run ID validation, fail-closed error classification, existing marker/audit rejection and failure classification.
- It does not exercise the full `LocationCsvImportService.importPreview` orchestration, real Firestore transaction semantics, the `_requireSuperAdmin` membership check, or callable authorization in an Emulator.

**Risk / gate**
- Keep import execution blocked from broad rollout until full emulator tests cover missing/inactive/wrong-role admin, duplicate marker, preflight failure (zero location writes), partial callable failure, and successful bounded import with immutable audit evidence.

### C. Admin Users & Roles
**Observed implementation**
- Screen is a static UI-only role matrix; POL-021 is labelled Draft.
- Role grants, scope changes and MFA state are not connected and remain disabled.

**Test coverage found**
- `admin_access_control_screen_test.dart` verifies Founder and Super Admin are described distinctly, grant/scope controls remain disabled, and the screen renders at a narrow viewport.
- These are presentation tests only; they do not validate actual role assignment, scope resolution or authorization.

### D. Global entry and navigation context
- AuthGate/AuthService only establish active Admin membership; AdminShell presents a common navigation menu.
- Feature-specific controls and trusted server/Rules must enforce the role, scope, action and record-state policy. Menu hiding or client-side checks alone are insufficient.

## Acceptance tests still needed (not run by this audit)
1. Walker action transaction: unauthenticated, missing admin doc, inactive admin, wrong role, permitted role; assert both walker state and audit record remain unchanged on denial.
2. Walker audit atomicity: force a transaction failure and assert neither partial walker update nor audit entry remains.
3. Walker read isolation: verify Rules deny out-of-scope / unauthorized collection reads, including direct client queries.
4. CSV import service emulator suite: missing/inactive/wrong-role admin, marker exists, only definitive not-found continues, preflight error produces zero location writes, ambiguous callable outcome blocks retry, successful plan/audit flow.
5. Role matrix: once POL-021 and Team 01 D01–D05 are approved, test every role against each action and city/zone scope; assert backend denial even when UI is bypassed.

## Status
- Source inspection: COMPLETE for listed files.
- Existing unit/widget test source inspected: COMPLETE for listed tests.
- Tests executed in this audit: NO.
- Emulator authorization evidence: NOT PROVIDED / NOT RUN by Team 02.
- Role/scope security approval: NOT ESTABLISHED.
- API integration: NOT STARTED (intentionally gated).
- Firebase, production data, merge, deployment: NO CHANGES.
