# DOJO WALK — Admin Final Integration & Navigation Audit
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Scope: read-only review of app composition, AdminShell navigation, approved target structure, team ownership, prior audit evidence and exact-head CI.

## Executive result
The Admin app has a working static shell composition with 14 menu entries and explicit switch destinations. However, the navigation does not fully match the documented company architecture: **Live Operations is exposed both as a sidebar destination and as a Dashboard action**, while the architecture explicitly says it should be opened from Dashboard and not occupy a separate sidebar item.

The repository also remains a hybrid/legacy file layout compared with the approved canonical target structure. The target document itself explicitly says it is a target, not proof of implementation. No full tree migration or route integration test was verified in this pass.

**Overall result: PARTIAL — navigation is wired, but architecture parity and end-to-end route verification remain incomplete.** No application code was changed.

## Source inspected
- `lib/main.dart`
- `lib/app/app.dart`
- `lib/screens/auth/auth_gate.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `docs/PROJECT_FILE_STRUCTURE.md`
- `docs/architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md`
- Prior screen audits for Dashboard, Live Operations, Bookings, Walker Management, Customers, Pets, Notifications, Support, Access Control, Audit Logs, Reports, Finance, Settings and Service Locations.

## Verified app composition
1. `main.dart` initializes Firebase using `DefaultFirebaseOptions.currentPlatform` and runs `DojoWalkAdminApp`.
2. `DojoWalkAdminApp` uses `MaterialApp(home: AuthGate())`; no named route table or declarative router is configured in this file.
3. `AuthGate` listens to Firebase Auth, fetches `admin_users/{uid}`, and checks document existence plus `isActive == true`. It does not pass role/capability/city/zone scope into AdminShell. This is not proof of server authorization.
4. On failed/unknown Admin record, AuthGate signs out and displays Admin Login. The source comment says fail closed; no AuthGate integration test was executed in this audit.
5. `AdminShell` maintains a local selected menu index and maps each menu index to a widget using a switch. There are 14 menu items and explicit cases 0–13; no menu item in the current list falls through to the Coming Soon default.
6. Current menu entries: Dashboard, Live Operations, Bookings, Walker Management, Customers, Pets, Notifications, Support, Admin Users & Roles, Audit Logs, Reports & Analytics, Finance Operations, Settings, Service Locations.
7. Dashboard has a callback that pushes a second `LiveOperationsScreen` route using `MaterialPageRoute`; menu index 1 also renders LiveOperationsScreen directly inside the shell. These are two entry paths to the same screen.
8. Dashboard's Service Locations action selects menu index 13, matching the current list ordering.
9. Logout is available in desktop top bar and sidebar/drawer; it calls `AuthService().signOut()` after confirmation.
10. Responsive shell uses a mobile drawer below 760px and desktop sidebar at/above 760px. This is a source-level observation, not a verified visual pass at every width.

## Navigation parity issue
- The architecture guide says Live Operations is launched from the Dashboard action and is not a separate sidebar destination. It repeats this in the target file-placement section and the 2026-10-20 navigation update.
- Current AdminShell still includes Live Operations as menu item index 1 and switch case 1.
- This duplicates navigation and conflicts with the documented single command-center flow.
- Recommended safe fix: remove the standalone Live Operations menu item and case, preserve the Dashboard action route, then update the Service Locations index from 13 to 12 (or better replace magic indexes with stable menu IDs/routes). Add navigation tests before/after. This was not changed in this audit.

## Canonical structure reconciliation
The approved `docs/PROJECT_FILE_STRUCTURE.md` describes the target as an exact canonical layout and explicitly requires Existing/Correct, Move/Refactor, Missing or Not applicable classification before migration. It also says not to create empty folders or delete historical reports blindly.
- Current app composition is split across `lib/main.dart`, `lib/app/app.dart`, legacy `lib/screens/*` and feature folders under `lib/features/*`.
- This is a hybrid layout, not yet a fully reconciled implementation of the target tree.
- `lib/screens/dashboard/admin_shell.dart` remains a legacy location according to target's intended `lib/features/*` grouping and architecture's recommendation to move common infrastructure into `lib/core/routing` etc.
- Do not bulk-move screens in this final audit; imports, tests, workflows and links need a path-by-path migration plan.
- Coupon-code UI is absent from current menu; preserve the explicit business decision that coupon-code functionality is not to be implemented, regardless of any old structural reference to a coupons folder in target docs.

## Screen-level integration status (from prior source audits)
| Area | Current source-level finding | Production integration status |
|---|---|---|
| Dashboard | Live Firestore listeners; unbounded aggregate risks and no proven scope | Not release-verified |
| Live Operations | Online walker map and route display; freshness/occurrence gaps | Not safety-grade verified |
| Bookings | Customer payload mapping and lifecycle display improvements | Backend lifecycle/occurrence contract incomplete |
| Walker Management | Profile/booking streams, assignment actions blocked by missing contract | Read scope/assignment governance incomplete |
| Customers | Hard-coded example records | UI prototype only |
| Pets | Hard-coded example records | UI prototype only |
| Notifications | Example notifications | Delivery not connected |
| Support | Example cases | Live case intake/escalation not connected |
| Admin Users & Roles | Static role proposal | Authorization/MFA/scope not implemented |
| Audit Logs | Example records | Live audit feed not proven |
| Reports & Analytics | Not-connected report catalog | Reporting/export not connected |
| Finance Operations | Prior finance audit identified policy/backend contract gaps | No financial mutation approval |
| Settings | Policy-mapped preview | No persisted settings |
| Service Locations | Existing feature and integration branches; polygon/backend contract remains separately gated | Must be verified against current pinned backend contract |

This table summarizes source audits; it is not a substitute for executing all screen tests or proving production behavior.

## Test and CI evidence
- A dedicated `test/screens/dashboard/admin_shell_test.dart` was not found at the inspected path.
- A second likely root-level `test/admin_shell_test.dart` was also not found. This does not prove no navigation tests exist under another filename, but no direct shell navigation test was located in this pass.
- Earlier Reports widget test file has catalog, period-chip and narrow viewport presentation tests; not route integration.
- The most recent prior audit commit `fd2a027107ddee6ea950074412868c703532c69f` had CI Run #398 completed successfully (Single CI: Analyze + Tests + Web Build). That is evidence for that exact earlier commit only.
- The present audit commit must be checked separately for exact-head CI; do not inherit Run #398 as evidence for a newer commit.

## Required next actions
1. Resolve the Live Operations duplicate entry to match the documented Dashboard-only entry point.
2. Replace numeric menu indexes with stable destination identifiers or typed route definitions to prevent index drift.
3. Add AdminShell navigation widget tests: every menu entry opens the expected screen; Dashboard Live Operations action opens map; Service Locations shortcut opens correct screen; mobile drawer closes after selection; logout confirmation/cancel works.
4. Add AuthGate tests for unauthenticated, active, inactive, missing Admin record and backend read failure. Keep backend authorization separately enforced by Team 01.
5. Produce a path-by-path migration matrix against `PROJECT_FILE_STRUCTURE.md`; migrate only in small tested batches and preserve old paths until references are clean.
6. Add integration states for loading/empty/denied/offline/error to every live-backed screen; retain explicit prototype labels for disconnected screens.
7. Build cross-app contract verification only against pinned Team 01/03/04 revisions; do not infer successful integration from imports or UI labels.
8. Run formatter, `flutter analyze`, full `flutter test`, `flutter build web --release` and exact-head CI after any code change.
9. Keep PR #51 Draft; no merge or deployment without explicit approval.

## Verification boundary
This is a static source and documentation audit. No Flutter test, analyzer, web build, browser navigation test, device-size visual QA, Firebase emulator, Rules/Functions test or production smoke test was executed in this pass. Only the previously recorded CI Run #398 on commit `fd2a027...` was checked as historical evidence. No app code, Firebase configuration, Rules, Functions, Storage, customer data or production configuration was changed.

## Decision
**PARTIAL / NOT RELEASE-READY.** AdminShell has explicit destinations for all 14 current menu entries, but the Live Operations navigation conflicts with the documented architecture, role/scope is not passed to the shell, and no dedicated shell navigation test was located. Complete the focused navigation correction and test suite, then finish the canonical file-tree reconciliation before calling the Admin UI phase complete. Keep PR #51 open/draft.


## Follow-up verification — 2026-11-01

The earlier navigation findings above describe the pre-correction source snapshot and are retained as historical audit evidence. Re-inspection of the current PR #51 branch shows the correction is now present:

- `AdminShell` has 13 sidebar destinations; the standalone Live Operations menu item and switch case are absent.
- Live Operations remains reachable through the Dashboard's `onOpenLiveOperations` action, as required by the company navigation architecture.
- The Dashboard's Service Locations shortcut selects the current Service Locations destination (index 12).
- A dedicated `test/screens/dashboard/admin_shell_test.dart` now exists. It covers the desktop sidebar without a duplicate Live Operations destination, mobile drawer selection/closure, and safe cancellation of the logout confirmation.
- The test uses an injected deterministic `DashboardDataSource`; it does not initialize Firebase or read/write production data.

### Exact-head validation

- PR #51 current head at verification: `3887866fa13f33f81cb5c77d910b822c4b47eb48`.
- GitHub Actions run [41232609407](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/41232609407) completed successfully for that exact head.
- Job log confirms `flutter analyze`: **No issues found**; full suite: **355 tests passed**; Flutter Web release build: **Built build/web**.
- The PR remains Draft/open/unmerged. No Firebase integration, merge or deployment was performed.

### Remaining navigation acceptance gaps

- Current tests do not yet prove every menu destination opens the intended screen.
- Dashboard → Live Operations route push/pop and browser back behavior are not directly asserted.
- Mobile drawer selection is tested for Settings only; repeat coverage for Service Locations and long/scrolling navigation paths.
- AuthGate role/scope propagation and server authorization remain separate backend/security acceptance gates.

**Updated decision:** the previously reported duplicate Live Operations sidebar entry is **RESOLVED in current source and covered by a passing widget test**. Overall Admin navigation remains **PARTIAL**, pending broader destination and route lifecycle tests plus AuthGate/backend authorization evidence. Keep PR #51 Draft; no merge/deployment authorization is implied.
