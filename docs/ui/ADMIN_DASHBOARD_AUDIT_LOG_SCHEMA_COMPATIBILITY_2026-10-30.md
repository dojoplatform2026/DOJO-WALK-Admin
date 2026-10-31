# Dashboard Audit Log Schema Compatibility — 2026-10-30

## Scope

Source audit and minimal Admin-side query correction for the Dashboard's planned Firestore Emulator integration. No production configuration, Rules, indexes, or data were changed.

## Pinned source evidence

- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch: `ui/notion-brand-foundation-2026-10-28`
- Corrected Dashboard data source blob: `80caaf6f73db0d73c1b5104eff5d29a91d11140c`
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`
- Firebase `firestore.rules` blob: `104467bab5dcc66c01a1f0f70df321ac0b193249`
- Firebase `firestore.indexes.json` blob: `add7c655c19cb240e35624e23c3e9a1041ef15bf`
- Firebase `firebase.json` blob: `ec27a2d7b8880c12cc76ebf7c1ea5ac5e05f6ea9`
- Firebase Rules test file: `test/firestore.rules.test.mjs`, blob `e7bfeb73b09438dd6252f8232d41ea78de57cf0f`

These are blob identifiers observed during this audit, not substitutes for pinning repository commit SHAs in a CI checkout.

## Confirmed mismatch and correction

The previous Admin `FirestoreDashboardDataSource.recentActivity()` queried `audit_logs` ordered by `timestamp`.

The authoritative Firebase Rules require audit records to include `createdAt`, allow `createdAt` in the field whitelist, and require `createdAt == request.time`. The Rules do not whitelist a `timestamp` field. The existing Walker Admin writer also writes `createdAt: FieldValue.serverTimestamp()`, and the Walker audit-history reader orders by `createdAt`.

The Admin Dashboard data source has now been corrected to:

```dart
.collection('audit_logs')
.orderBy('createdAt', descending: true)
.limit(6)
```

The existing `action` and `actorRole` mapping and the `Admin` fallback are unchanged. The canonical Rules were not weakened or edited.

## Remaining test work

1. Add a focused Dashboard data-source test proving records with `createdAt` are ordered/read correctly and legacy `timestamp` is not required.
2. Seed Emulator audit fixtures with `createdAt`, `action`, `actorUid`, `targetType`, and `targetId`; use only allowed `action` values for client-created test audit entries.
3. Test Rules authorization independently from Dashboard query mapping. Do not interpret a successful Admin read as permission to create arbitrary audit events.

The focused test file has not been added; the attempted GitHub file-create operation was blocked and no test result is claimed.

## Emulator configuration

The Firebase repository's `firebase.json` declares Auth (9099), Functions (5001), and Firestore (8080) Emulator ports, and points to the canonical `firestore.rules` and `firestore.indexes.json` files. Its package script runs Node's test runner against `test/*.test.mjs`.

The Admin repository should not duplicate or independently edit canonical Rules/indexes. A CI workflow can check out a pinned Firebase commit and start the Emulator using the Firebase repository's configuration/artifacts, while the Admin Flutter integration test targets only a dedicated demo project ID.

## Index finding

The inspected indexes file contains one composite index for `audit_logs` on `targetType`, `targetId`, and `createdAt`. The Dashboard's unfiltered single-field `orderBy('createdAt')` query does not require that composite index; Firestore's automatic single-field index is sufficient unless index exemptions or additional filters are introduced.

## Status and non-claims

- Source compatibility audit: complete.
- Timestamp mismatch: confirmed and corrected in the Admin Dashboard query.
- Corrected source fetched back from GitHub and verified to use `createdAt`; no legacy `orderBy('timestamp')` remains in this data source.
- Focused data-source test: pending.
- Emulator integration: not implemented.
- Flutter tests / Rules tests / Emulator tests / CI: not run for this change; no PASS is claimed.
- No merge, deployment, production write, Rules edit, or indexes edit.

## Dashboard Emulator integration design audit — 2026-10-30

A second pass inspected the Admin repository's existing emulator integration pattern and the canonical Rules for every Dashboard collection.

### Reusable CI pattern found

The Admin repository already has:
- `.github/workflows/walker-admin-emulator-integration.yml`, which checks out the Firebase Rules repository, starts Auth + Firestore emulators on 9099/8080, and runs a real FlutterFire integration test on an Android emulator.
- `integration_test/walker_admin_service_emulator_test.dart`, which uses a dedicated `demo-dojo-admin-integration` project ID, routes Android emulator traffic through `10.0.2.2`, and seeds fixtures through the Emulator-only owner endpoint.

This is a proven repository pattern to adapt; it is not evidence that a Dashboard integration test exists or has run. The existing workflow currently checks out Firebase Rules at `main`; a future Dashboard workflow should pin the Firebase Rules checkout to an audited commit SHA so the tested Rules/indexes are reproducible.

### Dashboard read authorization findings

The inspected canonical Rules establish:
- `bookings`, `users`, `walkers`, `payments`, and `audit_logs` reads are permitted to `isAdmin()`.
- `isAdmin()` specifically requires an authenticated user with an `admin_users/{uid}` document where `isActive == true` and `role == 'super_admin'`.
- A normal active `admin` or `support` role does not satisfy this helper and must be denied these Dashboard collection reads.
- `audit_logs` client writes are narrowly restricted to approved Walker actions and the exact field whitelist. Integration fixtures should therefore be seeded only through the local Emulator owner endpoint, not by weakening Rules or inventing client-side audit writes.
- `payments` is readable by `isAdmin()`; the Dashboard's paid-total stream filters `status == 'paid'` and sums numeric `amount` values.

### Proposed integration assertions

1. Seed an active `super_admin` fixture and representative booking, user, walker, paid/unpaid payment, and audit documents in the Firestore Emulator only.
2. Verify the real `FirestoreDashboardDataSource` emits expected collection counts, paid-only amount total, recent bookings, and recent activity ordered by `createdAt`.
3. Authenticate a non-admin role (for example active `support`) and verify the corresponding Dashboard reads fail with permission denied; do not mistake a UI fallback/error state for authorized access.
4. Verify no fixture helper can reach a non-emulator host; keep the project ID fixed to a `demo-` identifier and assert emulator endpoints before seeding.
5. Run the test through a separate Dashboard-scoped CI workflow or a carefully extended existing workflow. Do not broaden the Walker workflow triggers until the Dashboard test file and workflow command both exist.

### Current boundary

This pass was read-only. No integration test, workflow, Firebase configuration, Rules, indexes, or application source was changed. The integration test and all execution results remain pending.

## Dashboard Emulator integration implementation — 2026-10-30

### Added files

- `integration_test/dashboard_data_source_emulator_test.dart`
  - Uses the real `FirestoreDashboardDataSource` with Firebase Auth + Firestore Emulator endpoints.
  - Requires a `demo-*` project ID and uses Android's emulator host bridge (`10.0.2.2`) when running on Android.
  - Seeds all fixtures through the Firestore Emulator owner endpoint; it does not use production credentials or a production project.
  - Covers active `super_admin` reads for booking/customer/walker counts, paid-only payment total, recent bookings ordering, and recent audit activity ordering by `createdAt`.
  - Covers an active `support` role being denied a Dashboard collection read by the canonical Rules.
- `.github/workflows/dashboard-emulator-integration.yml`
  - Starts Auth and Firestore Emulators from the Firebase repository.
  - Checks out Firebase Rules/indexes at pinned commit `42923ecabedb60c158cdec91a5397f9925b3e07a`.
  - Runs the integration test on an Android API 34 emulator.
  - Has no deployment step and uses a dedicated `demo-dojo-dashboard-integration` project ID.

### Safety and scope

No production Firebase project is configured in the test. The test aborts if the project ID does not start with `demo-`. Fixture seeding targets the local emulator host/port only. No canonical Rules, indexes, production data, or app runtime configuration were changed.

### Verification status

- Test file fetched back from GitHub and reviewed: yes.
- Workflow fetched back from GitHub and reviewed: yes.
- Firebase Rules checkout pinned to a commit SHA: yes.
- GitHub Actions run result: not returned/available at the time of this audit; do not mark CI as passed.
- Flutter analyzer, unit tests, and Emulator integration test: not executed in this chat.
- Merge and deployment: not performed.

The first CI run must be inspected for compile/runtime issues before this integration is treated as verified. In particular, confirm Android runner generation remains compatible with the current Flutter toolchain and that Emulator REST fixture seeding works against the pinned Firebase CLI/Emulator version.

## Scope correction after controlling Draft PR guardrail — 2026-10-30

A review of Draft PR #51 found an explicit owner-approved guardrail: do not start new Firebase integration until the Admin UI and its validation are complete. The Dashboard Emulator test and workflow were briefly added as implementation drafts, but they crossed that sequencing boundary. Both files have therefore been removed from this branch before any run or deployment:

- Removed `integration_test/dashboard_data_source_emulator_test.dart`.
- Removed `.github/workflows/dashboard-emulator-integration.yml`.
- No workflow was dispatched; no Emulator test ran; no production Firebase was contacted by these changes.
- The earlier design notes below are retained as future planning only, not as active implementation or an instruction to proceed now.

The next permitted work is Admin UI completion and exact-head UI validation under Draft PR #51. Revisit Dashboard Emulator integration only after that gate is satisfied and the sequencing decision is still current.

## UI-phase unit-test correction — 2026-10-30

To stay within Draft PR #51's UI-first gate, the next change was kept inside the existing Dashboard unit-test suite (no new Firebase integration):

- Updated `test/screens/dashboard/dashboard_data_source_test.dart` so its recent-activity fixture uses `createdAt`, matching the corrected production query rather than the obsolete `timestamp` field.
- Added a focused fake-Firestore test asserting recent activity is ordered newest-first by `createdAt`.
- The test file was fetched back from GitHub and the new assertions were confirmed present.
- Exact-head CI status and workflow runs were queried for commit `5d30218376573d9686cb0e9ecce673f521eb5071`; both returned no status/run records at the time of checking. The tests have not been executed locally in this session, so no PASS is claimed.
- This is Dashboard UI-phase test maintenance only. Emulator integration remains deferred under Draft PR #51's guardrail.

## Service Zone Details UI regression coverage — 2026-10-30

- Added `test/features/service_location/zone_details_screen_test.dart`.
- The new widget tests cover Zone identity/revision, State→District→City parent path display, lifecycle/readiness metadata, the explicit example-only warning, and the absence of a live boundary hash.
- They also assert that Edit and lifecycle controls remain disabled in the UI prototype and check a 320px-wide mobile viewport for layout exceptions.
- Test file commit: `e1ac02ee0cb3b1e224c3392dca29cbdd4123f4b0`.
- File creation was confirmed by GitHub response; Flutter tests and analyzer have not been executed in this session. This remains UI-only and does not connect or mutate Firebase.


## Zone Directory to Zone Details consistency check — 2026-10-30

- Re-fetched both UI screens and their widget tests from the active UI branch.
- Confirmed the directory passes the same row values into Zone Details for zone ID, name, State/UT → District → City parent path, lifecycle status, revision, boundary status, readiness blocker, last-updated time, and updated-by metadata.
- Confirmed both screens label the data as examples/prototype content and keep activation/deactivation/edit actions disabled; no Firestore-backed live hash is implied.
- Strengthened the directory navigation widget test to assert the exact first-row values are preserved on the details screen, including Not verified, Polygon evidence pending, and the example audit metadata.
- Test update commit: 7f634b6b479cf9f86dc2b737e742b028146674e7.
- This is a data-presentation regression check, not a validation of real zone data or backend lifecycle behavior.
- Flutter test/analyzer execution remains pending; no CI result or PASS is claimed.


## Boundary Review ↔ Founder Approval Queue example-state consistency — 2026-10-30

- Compared shared sample Zone IDs across Zone Directory, Boundary Review, and Founder Approval Queue.
- Confirmed the sample workflow intent: Example Zone A is awaiting review but blocked because its boundary is not verified; Example Zone B requires boundary re-review after its hash changes; Example Zone C has example-verified boundary evidence but still awaits the separate Founder/CEO business decision, while the Directory keeps it not activated.
- Found one label mismatch for Example Zone C: Boundary Review used `Integrity matched` while Directory and Founder Approval Queue used `Verified (example)`. Normalized Boundary Review to `Verified (example)`; the separate review-queue status `Verified` still describes the boundary review stage, not launch approval or activation.
- Added a widget-test assertion that locks the shared label and rejects the old inconsistent wording.
- UI source commit: 8cf1f5ee4e518201ea0a920bb66ae0232058c6c7. Test commit: 14a22a1f35a7c94f0b4032590b7aebdf9077727b.
- Existing sample Example Zone D status/revision representation remains illustrative; these screens are mock datasets, not a shared live record store. It must be reconciled against a canonical Zone record model before backend integration.
- Flutter tests/analyzer remain unexecuted; no CI result or PASS is claimed. No Firebase integration or server-side action was added.


## Create Zone → review → approval vertical-flow audit — 2026-10-30

### UI flow observed
- ServiceLocationScreen routes Add Service Zone, Zone Directory, Boundary Review and Founder Approval Queue as separate screens.
- AddZoneScreen exposes the four required dependent selectors State/UT → District → City → Zone. Its catalog and existing Zone options are explicitly mock/example values.
- AddZoneScreen currently has Validate readiness enabled, while Save Draft and Submit for Review are disabled. The boundary editor/upload control is also disabled; the screen explicitly says nothing is saved or submitted.
- Boundary Review can navigate to the Founder Approval Queue preview. Zone Directory can open Zone Details. These are navigation links between UI prototypes, not a persisted workflow or shared live record state.
- Founder Approval Queue keeps decisions disabled and distinguishes boundary verification from the separate Founder/CEO business decision.

### Important implementation contract gap
- The existing `ServiceLocationBoundary` model and `ServiceLocationBoundaryService` still bind boundaries to `locationId` + `locationType`, and the service accepts only `city` or `area`.
- Its `saveDraft` persists a boundary as `pending`; `requestVerification` and the trusted `reviewServiceLocationBoundary` callable manage boundary review. This is not yet a Zone-boundary contract.
- The current AddZone UI does not call that service; its boundary editor is a placeholder. Therefore no complete persisted Zone draft → boundary submission → review → Founder approval → Zone Directory lifecycle is implemented.
- Existing location hierarchy schema and legacy Partner `zones` are separate compatibility concerns. Do not silently map or rewrite them. No Firebase changes are permitted under the current UI-first guardrail.

### Next permitted UI work / acceptance gates
1. Keep the four-selector State/UT → District → City → Zone hierarchy; no Locality selector.
2. Preserve the UI-only safety state: no Save Draft / Submit for Review until the Zone record and boundary evidence contract is approved and implemented.
3. Make navigation labels/status wording explicit that the screens are preview-only and do not share persisted state.
4. Before enabling actions, define a canonical Zone identity + revision + boundary hash + readiness snapshot contract and a Founder decision binding to that exact tuple. A boundary revision/hash change must invalidate the prior decision.
5. Backend/service/Rules/Functions/Emulator work remains deferred until the Admin UI validation gate and owner-approved sequencing decision permit it.

### Verification
- AddZoneScreen, ServiceLocationScreen, boundary model/service, Boundary Review and Founder Approval Queue were inspected from the UI branch.
- This was a source inspection and documentation-only checkpoint; no code change to workflow actions, no Firebase access/write, no tests executed, no CI PASS claimed, no merge/deploy.


## Create Zone form validation-state coverage — 2026-10-30

- Added widget coverage that a syntactically valid new Zone name still cannot pass readiness while boundary evidence remains `Not uploaded`; Save Draft and Submit for Review remain disabled.
- Added widget coverage that changing the selected District clears downstream City, Zone selection and new Zone name, preventing stale child selections from being retained across hierarchy changes.
- Existing tests continue to cover the four selectors/no Locality, mock Zone protection, disabled persistence actions, Boundary Review preview navigation and narrow mobile layout.
- Test source updated in commit `fb475355dcae918dd7dc1e37d8ae27064e005274` (`test/features/service_location/add_zone_screen_test.dart`). Tests have been added but were not executed in this step; no CI PASS is claimed.
- No production code or Firebase integration changed. Save Draft, Submit for Review and boundary editor remain intentionally disabled until the canonical Zone/boundary contract and UI-first validation gate are approved.


## Create Zone boundary editor — local preview only — 2026-10-30

- Reused the existing `ServiceBoundaryEditor` in the Create Zone screen behind an explicit **Open boundary editor** action. The editor opens only after **Create new Zone…** is selected; mock existing Zones cannot be edited from this form.
- Boundary points are held only in the current screen's in-memory state. The parent does not provide an `onSaveRequested` callback, and there is no Firestore write, upload, boundary verification, hash generation, or approval submission.
- The status deliberately reports **Not drawn** or **Local preview only — N points; not saved**. A locally drawn polygon is not treated as verified evidence or as satisfying the readiness gate.
- Changing State/UT, District, City, or leaving the new-Zone selection clears the local polygon preview to prevent geometry being accidentally carried into a different hierarchy.
- Save Draft and Submit for Review remain disabled. The authoritative location catalog, GIS validation, boundary hash, persistence, and Founder/CEO approval flow remain out of scope until the Admin UI gate is complete.
- Added widget coverage for the editor action being disabled before a new Zone is selected and enabled after selecting one; updated the narrow-viewport assertion and readiness status wording.
- The native Google Maps platform view itself was not opened in widget tests in this pass; Flutter tests/analyzer were not executed. These tests are added, not executed, and no PASS is claimed.
- No Firebase integration, Rules/indexes changes, merge, or deployment.


## Boundary editor local geometry feedback — 2026-10-30

- The reusable `ServiceBoundaryEditor` now reports local feedback as points are added, undone, or cleared: minimum point count, distinct-point checks, coordinate range checks, self-intersection/zero-area rejection, or a locally valid basic polygon.
- The Create Zone form surfaces the point count and local geometry message. Feedback explicitly says **Not GIS-verified** when the basic polygon check passes; it is not a boundary verification result.
- The editor's **Use This Boundary** save action is hidden when no `onSaveRequested` callback is supplied. Create Zone deliberately supplies no save callback, so this preview cannot be submitted from the map.
- Added a widget test for the initial local geometry feedback and non-verification wording. Map interaction/point mutations are not exercised in Flutter widget tests here because the editor embeds the native Google Maps platform view.
- Flutter tests/analyzer were not executed; tests are added, not executed. No CI status is assumed. No Firebase integration, boundary persistence, hash, approval, merge, or deployment.


## Boundary editor preview controls and validator test coverage — 2026-10-30

- Follow-up UI review caught a control-visibility regression: Undo/Clear had been hidden in local preview mode together with the save action. Corrected the editor so editable previews retain Undo/Clear, while **Use This Boundary** remains hidden unless an explicit save callback is supplied.
- Extracted the local geometry feedback into `ServiceBoundaryPreviewValidator`, allowing focused unit tests without constructing the Google Maps platform view.
- Added unit cases for empty/fewer-than-three points, repeated vertices, out-of-range coordinates, self-intersection, collinear/zero-area geometry, and a valid simple polygon. Valid feedback still explicitly says **Not GIS-verified**.
- These tests are added but have not been executed in this session. Flutter analyze/test and CI remain unverified. No Firebase, upload, persistence, hash, approval, merge, or deployment.


## Boundary preview usability follow-up — 2026-10-30

- Made the map viewport responsive to screen height (42% of available screen height, clamped to 260–420 px) rather than always occupying 420 px. The surrounding bottom sheet remains scrollable, keeping controls reachable on shorter devices.
- The editor footer now displays the same explicit local geometry feedback as the Create Zone form, including the distinction between a locally valid shape and GIS verification.
- Added a plain-language warning that local shape validation is not GIS verification or service-area approval.
- UI-only change. No boundary persistence, GIS verification, Firestore integration, or approval workflow was enabled. Automated Flutter tests/analyzer have not been run in this session.


## Create Zone readiness dialog audit — 2026-10-31

- Replaced the generic readiness explanation with explicit blockers based on the local preview state.
- The dialog now distinguishes a failed local polygon-shape check from GIS verification; even a locally valid polygon is explicitly described as **not GIS-verified**.
- It separately reports that boundary evidence has not been uploaded and the State/UT → District → City selectors still use example catalog data. Save Draft and Submit for Review remain disabled.
- Updated the existing widget test to assert these blocker messages and the no-save guarantee.
- This is still a UI-only validation preview. No authoritative catalog, GIS service, backend, Firestore, draft persistence or approval action is connected. Test/analyzer execution has not been confirmed.


## Service Location lifecycle terminology audit — 2026-10-31

- Reviewed the Zone Directory, Zone Details, Boundary Review and Founder Approval Queue prototypes together.
- Confirmed the example Zone C lifecycle is intentionally staged: Boundary Review = boundary evidence marked “Verified (example)”; Founder Approval Queue = “Awaiting decision”; Zone Directory = “Not activated”. These are separate technical-verification, business-approval and operational-lifecycle states, not conflicting statuses.
- Added a prominent Boundary Review explanation: a verified boundary does not activate a Zone or grant launch approval; the separate Founder Approval Queue owns the final business decision.
- Added widget assertions for that governance distinction.
- All screens remain example-data UI prototypes. No live state transition, approval, activation, Firestore integration, merge or deployment. Flutter tests/analyzer have not been executed in this session.


## Cross-screen Zone lifecycle acceptance coverage — 2026-10-31

- Added a widget test that follows Example Zone C from Zone Directory → Zone Details → Founder Approval Queue.
- The test asserts that the same illustrative Zone ID remains boundary-verified while its operational state remains “Not activated” and its separate Founder business decision remains “Awaiting decision”.
- The test is added but has not been executed; Flutter test/analyzer results are not claimed.
- Policy reconciliation: POL-038 and POL-040 define “Suspended” as a temporary emergency stop, distinct from Founder-approved deactivation. Central Admin may suspend immediately for safety/material risk with a reason and immutable audit event, then notify Founder promptly for review. Suspension does not authorize activation/reactivation. The Directory now explains this distinction; no suspension action is enabled in the prototype.


### Policy evidence used for suspension clarification

- POL-038 — India Admin Panel: Service Zone Setup, Approval, Activation & Deactivation Flow (Notion): https://app.notion.com/p/404756abedb981729cf9ecf3a35ce915
- POL-040 — Admin Service Location UI: Screen-by-Screen Design & Developer Checklist (Notion): https://app.notion.com/p/405756abedb98179bd47f0ae8082e937
- Both specify Zone-only service lifecycle and distinguish emergency suspension from Founder-approved deactivation/reactivation. POL-040 records this as a confirmed operating decision; overall policy/code implementation and test status remain unverified.
- Added a Zone Directory UI explanation and widget assertions for emergency suspension authority, audit reason and Founder notification.


## Service Location navigation identity audit — 2026-10-31

- Responsive structure reviewed across Create Zone, Zone Directory, Zone Details, Boundary Review and Founder Approval Queue. Existing scrollable layouts, responsive LayoutBuilder/Wrap usage and narrow-viewport widget tests were found; no broad layout rewrite was justified by this source review.
- Found a navigation-context defect: Directory and Details opened Boundary Review / Founder Approval Queue without carrying the selected Zone ID, so the destination could appear detached from the originating row.
- Added optional `focusZoneId` context to Boundary Review and Founder Approval Queue. Directory row actions and Zone Details now pass their Zone ID; Boundary Review carries the same ID onward to Founder Approval Queue. App-bar titles identify the focused Zone when supplied.
- Updated Directory widget assertions to verify Zone identity survives the route transitions, including Example Zone C through Details → Founder Approval Queue.
- Source review only. Flutter tests/analyzer have not been run; map native-view behavior and real device responsive behavior remain unverified. All screens remain example-data prototypes; no backend, Firebase, approvals, activation, merge or deployment.
