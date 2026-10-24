# DOJO WALK Admin — Legacy File Migration Audit

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Scope: static repository-tree and entry-point/import review. This is not a full Dart dependency-graph scan or emulator test.

## Verified entry point

- `lib/main.dart` is present in the inspected branch tree.
- `lib/app/app.dart` builds `DojoWalkAdminApp` and sets `FreshAdminAuthGate` as the app home.
- `lib/features/shell/admin_app_shell.dart` imports the fresh Dashboard, Add Location, Boundary Review, and Live Operations screens.
- The new shell does not import the legacy `lib/screens/dashboard/admin_shell.dart`.

## File inventory and decision

| Path / group | Decision | Reason / safe next action |
|---|---|---|
| `lib/app/app.dart`, `lib/core/auth/**`, `lib/core/theme/**` | KEEP | Fresh app entry, auth gate, identity and theme dependencies. Review authorization tests before production. |
| `lib/features/dashboard/presentation/admin_dashboard_screen.dart` | KEEP | Fresh Dashboard presentation. Dashboard counts intentionally remain unclaimed until data contracts are connected. |
| `lib/features/live_operations/presentation/live_operations_screen.dart` | KEEP | Fresh Live Operations presentation. Nearby-walker status is explicitly not checked; no live feed is claimed. |
| `lib/features/service_location/**` | KEEP / REVIEW | Current fresh location workflow and domain/import/boundary code. Review callable, Firestore read-after-write, security rules and emulator coverage before production. |
| `lib/screens/auth/**`, `lib/screens/dashboard/**`, `lib/screens/live/**`, `lib/screens/bookings/**`, `lib/screens/coupons/**` | PRESERVE; migration candidate | Legacy shell still imports these files. The inspected new entry point does not route to the old shell, but do not delete until repository-wide imports, tests, and any rollback needs are fully checked. |
| `lib/features/walkers/**` | PRESERVE; classify individually | Legacy walker feature files are in a feature-named directory but use older `screens/services/widgets` organization. The current fresh shell does not import them. Preserve until walker scope and future Admin-vs-Partner responsibilities are reviewed. |
| `lib/services/auth_service.dart` | PRESERVE; migration candidate | Imported by legacy `AdminShell`; not imported by the fresh shell shown in this audit. Do not delete while the legacy code remains. |
| `lib/data/reference/india_locations/**`, `review/lgd_exports/**`, `test/data/reference/**` | KEEP | Reference data and audit/review material; never remove as part of UI cleanup. |
| `lib/firebase_options.dart`, `pubspec.yaml`, workflows, tests | KEEP / REVIEW | Required configuration and validation surface; check project/platform values and dependency use before any changes. |

## Structural gaps against the approved target

1. Fresh code is only partially feature-first; the shell currently has no fresh routes for access control, Area Manager assignments, bookings, walkers, coupons, payments or audit.
2. The documented target has `app/router.dart` and dependency setup, but the inspected current app uses `home: FreshAdminAuthGate()` and no router/dependency container is visible in `lib/app/app.dart`.
3. The existing `lib/features/walkers/**` files are not yet normalized to `data/domain/presentation`; keep them preserved and migrate only after the Admin/Partner responsibility contract is defined.
4. Legacy screens remain in the repository. Their presence is intentional until dependency and rollback review is complete; fresh UI should not be added to `lib/screens/**`.

## Workflow evidence for inspected HEAD

Inspected commit: `4c130f5ee31ad71452b42f40df8017a6e468f5d0`.

- Service Location Geometry Tests run `40052990042`: completed successfully.
- Admin Web Build Check (No Deploy) run `40052990023`: in progress at audit time.
- Admin Main Full Validation (No Deploy) run `40052989990`: in progress at audit time.

These are commit-specific GitHub Actions states; they do not prove production readiness, live Firebase behavior, or successful deployment.

## Next safe migration steps

1. Wait for the Web Build and Full Validation results on the inspected HEAD; inspect logs if either fails.
2. Enumerate all Dart imports/references to legacy screens and services, including tests and route entry points; mark each KEEP / MIGRATE / REMOVE with evidence.
3. Add missing role/scope model and authorization tests before exposing Area Manager or access-control screens.
4. Verify callable request/response and Firestore read permissions using emulator-backed tests, including save → re-read → inactive state and duplicate handling.
5. Only remove a legacy file after a full reference scan, passing checks, and explicit confirmation that rollback/preserved functionality is not needed.
6. Do not merge or deploy without explicit approval.


## Latest verified checkpoint — 24 Oct 2026

Reviewed PR #37 current head `6ccf4bac253cc40a15f665afbaa0ac80c111d123` after the earlier checkpoint above.

- PR #37 remains open and draft; no merge or deployment was performed.
- The three PR-triggered checks associated with this inspected head are complete and successful: Service Location Geometry Tests (`40068826948`), Admin Main Full Validation / No Deploy (`40068826832`), and Admin Web Build Check / No Deploy (`40068826773`).
- Current navigation has Dashboard, Add Location, and Boundary Review. Live Operations is embedded within Dashboard as requested; it is not a separate navigation destination.
- Dashboard intentionally displays placeholders instead of invented booking/walker totals. The embedded Live Operations view offers a permission-aware device/browser “My Location” action, labels “Possible Walker Nearby” as “Not checked,” and states that the live feed is not connected.
- File structure remains **partially normalized, not complete**: fresh files are in feature-first folders, but legacy `lib/screens/**`, `lib/services/**`, and older `lib/features/walkers/**` organization remain. They are preserved intentionally because the full reference/dependency and rollback scan has not been demonstrated.
- Production blockers remain: authenticated Firebase Emulator coverage for Admin identity revocation and Add Location save/read-back; real geographic map-based boundary review; live walker/booking feed and authorized actions; Founder/CEO approval controls; Area Manager assigned-area server enforcement; and verification that deployed Firebase revisions match reviewed source.

### Migration rule

Do not bulk-delete or bulk-move legacy files merely to make the tree look clean. First run a repository-wide reference/dependency scan, classify each candidate KEEP / MIGRATE / REMOVE, move one coherent feature at a time, and require formatter, analyzer, full tests, web build, and relevant emulator tests after each migration. Keep this PR draft until those gates and explicit review are complete.


## Verified checkpoint — PR #37 HEAD 464fbe5 (24 Oct 2026, latest inspection)

The PR was re-fetched from GitHub and its exact current head was checked against PR-triggered Actions. PR #37 is still **open + draft + unmerged**.

- Exact head: `464fbe5339b062c074401835a0fb87d565cb1beb`.
- Service Location Geometry Tests run `40092744439`: completed successfully.
- Admin Web Build Check (No Deploy) run `40092744414`: completed successfully.
- Admin Main Full Validation (No Deploy) run `40092744423`: completed successfully.
- Add Location repository now verifies the callable's returned ID, re-reads the created document, and checks that its type-specific active flag is explicitly `false` before reporting success. This is code-level verification, not proof of a real authenticated Firebase Emulator round trip.
- Boundary Review now contains a Google Maps polygon preview using stored coordinates. This improves on the earlier shape-only preview, but does not by itself verify the boundary's official source, accuracy, containment, or suitability; trusted server review remains required.
- Dashboard widget coverage checks the embedded Live Operations section, “My Location”, “Possible Walker Nearby” and the honest “Not checked”/unconnected-feed state.

### Still open — do not mark Admin complete

1. No demonstrated authenticated Admin Emulator integration test covering login/role revocation, callable save, read-back, duplicate names and inactive/unauthorized access.
2. Legacy City records without `districtId` remain a compatibility issue for the District-required City selector used when adding an Area/Locality. Do not silently assign a District or mutate legacy records; implement an explicitly labelled and tested compatibility path before enabling those records for selection.
3. Canonical Founder/CEO, Central Admin and Area Manager role/scope enforcement is not implemented end-to-end in this Admin UI; UI gating to `super_admin` is not a replacement for server authorization.
4. Live walker/booking feeds and authorized live-operation actions remain unconnected.
5. Full legacy import/reference/dependency inventory and safe file migration are not complete.
6. Deployed Rules/Functions revision parity and real-admin production behavior remain unverified.

No production data was changed. No merge, deployment, branch deletion, or production action was performed by this checkpoint.


## Re-verified checkpoint — PR #37 exact HEAD 23adbb3 (24 Oct 2026)

Re-fetched PR #37 and checked PR-triggered Actions against its current head, rather than relying on older audit snapshots.

- Exact head: `23adbb3c81d4836d4a4b15a9194f5a879660e283`.
- PR #37 remains **open, draft, and unmerged**.
- Service Location Geometry Tests run `40093383345`: completed successfully.
- Admin Web Build Check (No Deploy) run `40093383187`: completed successfully.
- Admin Main Full Validation (No Deploy) run `40093383200`: completed successfully.
- Source inspection confirms Add Location repository checks the callable-returned ID, re-reads the new document, and requires its type-specific active flag to be explicitly `false` before returning success. This is a client code path; it is not a substitute for authenticated Emulator integration evidence.
- Dashboard/Live Operations remains deliberately honest: live booking/walker feed is not connected and “Possible Walker Nearby” is not asserted without data.
- The legacy City-without-`districtId` selection gap, role/scope enforcement, real authenticated Emulator coverage, complete dependency inventory, and deployed Firebase revision parity remain open.

**Decision:** CI is green for this exact Admin branch head, but Admin is **not complete or release-ready**. Keep the PR draft; do not merge, deploy, or delete legacy files/branches on the strength of these checks alone. No production data or deployment was changed.


## Verified checkpoint — PR #37 exact HEAD c09350c (24 Oct 2026)

Re-fetched the current PR and checked the Actions runs associated with exact head `c09350c4b3eefa33b3ea01e2fe65e88a11b69d91`.

- PR #37 remains **open, draft, and unmerged**.
- Service Location Geometry Tests run `40094652622`: completed successfully.
- Admin Main Full Validation (No Deploy) run `40094652596`: completed successfully.
- Admin Web Build Check (No Deploy) run `40094652590`: completed successfully.
- Current Boundary Review source now includes a Google Maps polygon preview from stored coordinates, with range/finite-value checks and a fallback when fewer than three valid points exist. This is a UI preview only; the map key/runtime configuration and official boundary source/accuracy still need verification, and the trusted backend remains authoritative.
- Add Location repository re-reads the saved record and requires the type-specific active flag to be explicitly `false` before reporting success. This is not yet a demonstrated authenticated Firebase Emulator end-to-end test.
- Dashboard widget test exists for embedded Live Operations, My Location, and the honest “Possible Walker Nearby: Not checked” / unconnected-feed state.

### Outstanding blockers unchanged

1. Authenticated Emulator coverage for Admin login/role revocation, save/read-back, duplicate-name rejection, and inactive/unauthorized access.
2. Legacy City records without `districtId` still need a documented, tested compatibility path; do not silently mutate or infer their district.
3. Founder/CEO → Central Admin → Area Manager role and assigned-area enforcement is not integrated end-to-end in this Admin UI/server policy.
4. Live walker/booking feeds and authorized live-operation actions remain unconnected.
5. Full legacy dependency inventory and safe migration/removal of old files remain incomplete.
6. Deployed Rules/Functions revision parity and real-admin runtime behavior remain unverified.

**Decision:** Latest inspected Admin branch CI is green, but this does not mean Admin is complete or release-ready. Keep PR #37 draft. No merge, deployment, production data write, or branch deletion was performed.


## Latest verified CI checkpoint — 24 Oct 2026

- Re-fetched draft PR #37: branch `feature/admin-fresh-architecture-2026-10-24`, inspected head `29075423be92c93a55c317b5e6badad5595b7816`; PR remains open, draft, and unmerged.
- Exact-head workflow results: Admin Main Full Validation / No Deploy run `40095026727` passed its completed job steps for full-project analysis, full test suite, and Flutter Web build; Admin Web Build Check / No Deploy run `40095026687` passed the same validation steps; Service Location Geometry Tests run `40095026681` passed geometry/CSV planner analysis and unit tests.
- Boundary Review code now renders a Google Maps polygon preview for valid stored coordinates. This is not proof that the production Maps key, official boundary source, or human verification process is configured correctly.
- Add Location performs callable save then document read-back and checks the correct inactive flag. The exact-head CI does not replace authenticated Firebase Emulator coverage for save/read-back, duplicate names, inactive-admin rejection, or authorization revocation.
- No merge, deployment, production write, or branch deletion was performed. Keep PR #37 draft until the outstanding blockers above have evidence-backed closure.


## Exact-head verification — 24 Oct 2026, 18:38 IST

Re-fetched PR #37 from GitHub and checked the workflow runs associated with its exact current head.

- Current head: `522c895489ab883bbf16ff4b1e3decd61ad9c3e6`.
- PR #37 remains open, draft, and unmerged.
- Admin Main Full Validation run `40095995169`: passed complete Admin analysis, full test suite, and Flutter Web build.
- Admin Web Build Check run `40095995157`: passed complete Admin analysis, full test suite, and Flutter Web build.
- Service Location Geometry Tests run `40095995168`: passed geometry/CSV planner analysis and unit tests.
- The Add Location repository now checks the callable result, reads the created document back, and verifies its location-type-specific active flag is explicitly false before reporting success.
- Boundary Review now renders a Google Maps polygon preview from stored coordinates and rejects malformed/out-of-range points from the preview. A rendered polygon is not official-source verification; Maps key/runtime configuration, source accuracy, containment and human review still need evidence.
- The current automated runs do not establish authenticated Firebase Emulator end-to-end coverage for role revocation, callable save/read-back, duplicate-name rejection, or inactive/unauthorized access.

### Remaining gates — unchanged

1. Add authenticated Emulator integration tests for Admin identity and Service Location save/read-back/duplicate/denied paths.
2. Decide and test a safe explicit compatibility path for legacy City records with no `districtId`; never infer or silently mutate their parent.
3. Implement and verify the company role model Founder/CEO → Central Admin → Area Manager, including assigned-area server enforcement; the current `super_admin` UI gate is not a substitute.
4. Connect live walker/booking data and only authorized live-operation actions.
5. Complete the legacy dependency/reference inventory before file moves or deletions.
6. Verify deployed Rules/Functions revision parity and Maps runtime configuration.

**Decision:** latest exact-head CI is green, but Admin remains incomplete and not release-ready. Keep PR #37 draft. No merge, deployment, production write, or branch deletion was performed.


## Latest exact-head verification — 24 Oct 2026, 18:52 IST

Reviewed the current open draft PR #37 head `97d8074d8dbae60cda4b4565a14bc77144fb6cef` (branch `feature/admin-fresh-architecture-2026-10-24`). This is newer than the previously documented checkpoint.

### Exact-head CI evidence

All three PR-triggered workflows completed successfully on this head:
- Admin Main Full Validation (No Deploy), run `40097711878`: job `Analyze, test and build Admin Web` — success.
- Admin Web Build Check (No Deploy), run `40097711870`: job `build-web` — success.
- Service Location Geometry Tests, run `40097711863`: job `geometry-unit-tests` — success.

This verifies the repository workflows for that exact head; it does **not** prove live Firebase integration, production deployment parity, or launch readiness.

### Source changes rechecked

- Boundary Review now imports `google_maps_flutter` and renders a polygon on a geographic map when at least three valid coordinate points are available. Invalid/out-of-range points are filtered; degenerate bounds are guarded. The UI warns that the polygon source must be verified independently. **Maps key/platform configuration and real-browser runtime behavior remain unverified.**
- Add Location retains the hierarchy `India → State/UT → District → City → Area → Locality`. If a live catalog update removes a selected parent option, the screen clears that selection and its descendants after the current frame, preventing stale IDs from being submitted.
- Legacy City records without `districtId` are still not selectable in the District-dependent City picker. The UI displays an explicit compatibility warning; no parent is guessed and no legacy record is mutated.
- Save success currently reports the callable's returned ID; a server read-back of the newly created record and its inactive state is still a verification gap.
- The fresh branch still contains legacy `lib/screens/**`, `lib/services/**`, and older feature files. No file deletion/move is authorized until a repository-wide reference/dependency inventory is complete.

### Current gate

PR #37 remains open, draft, and unmerged. Continue with focused tests for parent dropdown reset/stale-option handling and authenticated Emulator save/read-back/duplicate/denied cases; verify Maps runtime configuration and deployed Rules/Functions parity. Company roles and Area Manager assigned-area server enforcement are still unresolved.

**No merge, deployment, production data write, or branch deletion was performed.**
