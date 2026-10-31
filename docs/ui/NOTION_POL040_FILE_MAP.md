# DOJO WALK Admin UI — POL-040 File Map & Gap Audit

**Source of truth:** Notion POL-040 — Admin Service Location UI: Screen-by-Screen Design & Developer Checklist  
**Related specifications:** POL-038 (Zone lifecycle), POL-041 (API/backend contract), POL-042 (implementation/test plan)  
**Working branch:** `ui/notion-brand-foundation-2026-10-28`  
**Scope boundary:** UI and file organization only. Do not add Firebase integration, merge, or deploy from this workstream.

## Governing rules

- Founder/CEO is the final business approver for Zone launch/activation, material boundary changes, deactivation and reactivation.
- Central Admin prepares the request and executes an approved activation only after checks; it cannot approve its own request.
- Super Admin is not automatically Founder.
- State/UT, District and City are hierarchy/reference records; only Zone has service activation status.
- Zone polygon verification is mandatory before activation. Radius-only coverage is insufficient.
- Deactivation blocks new bookings but must preserve existing bookings and safely handle running walks.
- Use `#FF7900`, `#FFFAF5`, and `#252525`; display operational timestamps in IST.
- All mock/example data and disabled actions must remain clearly labelled. Do not present them as live data or completed server actions.

## Screen-to-file map

| POL-040 screen / requirement | Current file(s) | Audit status based on repository inspection |
|---|---|---|
| Location Dashboard / overview | `lib/features/service_location/screens/service_location_screen.dart`, `lib/features/service_location/utils/boundary_preview_status.dart`, `test/features/service_location/boundary_preview_status_test.dart` | Partial: existing Service Locations screen has hierarchy tabs/map preview. Boundary preview status now distinguishes loading, error, disconnected source, and a real non-empty polygon count; the empty placeholder is no longer reported as zero active Zones. Compare summary cards, attention panel and recent changes against spec. |
| Location Directory | `lib/features/service_location/screens/zone_directory_screen.dart`, `service_location_screen.dart` | Prototype: search/status filters, parent path, Zone ID, boundary/readiness metadata, update metadata, links to review screens, and disabled lifecycle actions. Live pagination and data-backed states remain pending. |
| Add Location / Create Zone | `lib/features/service_location/screens/add_zone_screen.dart` | Prototype has four dependent selectors (State/UT → District → City → Zone). The fourth selector offers a create-new path plus city-dependent, explicitly marked mock existing-Zone options because the approved Zone catalog is not connected; name input appears only for the create-new choice, and selecting a mock existing Zone never edits it. A clearly labelled preview navigation opens Boundary Review without submitting. Boundary drawing, save and submission remain unavailable. |
| Location Details | `lib/features/service_location/screens/zone_details_screen.dart` | UI prototype receives example Zone metadata from Directory, shows hierarchy/readiness/audit details and keeps edit/lifecycle actions disabled. No live Zone record is loaded. |
| Boundary Review | `lib/features/service_location/screens/boundary_review_screen.dart` | Prototype: example rows, explicit unconnected map placeholder and evidence labels; no live boundary data or decision actions. Preview navigation opens Founder Approval Queue. |
| Founder Approval Queue | `lib/features/service_location/screens/zone_approval_queue_screen.dart` | Prototype: example rows with parent path, submitter, timestamp, revision, boundary status/hash and blockers; decision action remains disabled and approval remains separate from activation. |
| Activate / Suspend / Deactivate / Reactivate | `lib/features/service_location/screens/suspended_zones_screen.dart`, service-location service files | Partial: suspension/deactivation screen is a mock UI; verify activation lifecycle screen/guards and safe handling of bookings/running walks. No new Firebase actions in UI-only phase. |
| Import & Reconciliation | `service_location_screen.dart`, `services/location_csv_*.dart` | Existing UI/service files: audit visual states and alignment with POL-040; no claim that full acceptance suite passes. |
| Audit History | `audit_history_screen.dart`, `zone_audit_history_screen.dart` | Screens exist; verify loading, empty, error, permission-denied and success states and that mock data is not confused with live audit records. |
| Required UX states | All screens | Not yet proven complete: Loading, Empty, Error, Permission Denied and Success must be checked screen by screen. |

## Cross-screen Zone identity and evidence contract

The UI-only examples intentionally share the same illustrative Zone ID, revision and boundary hash across Directory, Boundary Review and Founder Approval Queue. These are test fixtures only, not live Zone records.

| Example | Stable Zone ID | Revision | Boundary evidence | Expected workflow state |
|---|---|---|---|---|
| Example Zone A | `ZONE-EX-001` | Revision 1 | Not verified; hash not generated | Blocked — boundary pending; Founder decision must wait |
| Example Zone B | `ZONE-EX-002` | Revision 2 | `EXAMPLE-HASH-CHANGED`; re-verification required | Blocked — re-review; previous approval must not be reused |
| Example Zone C | `ZONE-EX-003` | Revision 3 | `EXAMPLE-SHA256-VERIFIED-003`; integrity matched | Boundary Review shows Verified; Founder queue shows Awaiting decision; Directory remains Not activated until approval and activation steps are completed |

Tests in the three screen suites assert stable IDs/revisions and the corresponding boundary evidence. Founder decision controls stay disabled because server authorization, readiness checks and append-only audit logging are not connected.

## Structural observations

- Service-location screens are grouped under `lib/features/service_location/screens/`; models, services and widgets have separate folders. Keep new work in these existing feature folders unless the source-of-truth architecture explicitly requires a change.
- The main Admin shell is `lib/screens/dashboard/admin_shell.dart`. Top-level destinations now route to UI prototypes or existing screens for Live Operations, Bookings, Walkers, Customers, Pets, Notifications, Support, Admin Users & Roles, Audit Logs, Reports, Finance, Settings Governance and Service Locations. Existing Dashboard/Bookings/Walker/Live Operations screens still need a policy-by-policy visual/interaction audit.
- Existing Firebase/service imports are already present in the repository. This UI-only phase must not expand or change backend integration.
- Coupons must not be reintroduced as an Admin menu item; the business decision is no coupon system.

## Confirmed form gap — fourth Zone selector

The Unified UI/UX Design System and POL-038/POL-040 explicitly require exactly four dependent selectors: State/UT → District → City → Zone. The prototype now includes the fourth Zone selector after City. Because the approved Zone catalog is not connected, existing choices are explicitly marked mock records; this is intentionally not represented as live Zone data. Existing Zone choices must come from an authoritative catalog when the UI data contract is approved. The Zone name/details input appears only for the create-new path. Do not add a Locality selector. Changing State/UT, District or City must clear all downstream selections.

## Validation record

- Baseline validation: GitHub Actions run `40687163413` completed successfully at commit `c41a1568bc54d0f2de16112fd1ece3c1ae4af7c7`. For recent UI changes, run `40741909918` passed at `3dd6943244944e31f5e7d2acd73c9238cf70b60e` (Zone Directory clear-search); run `40742326990` passed at `152e0e3eddf020375dd6be56cf37bf51632cf7a8` (Zone Audit History clear-search); and run `40742444471` passed at `d84a6a50b39f4a1cef9a768a9c100198f6b7071d` (Zone Audit History detail line breaks). Each run completed `flutter analyze`, the complete test suite, and Flutter Web release build successfully.
- Latest Service Location validation: run `40743210291` passed at `a721e31c730dac5b499443493d6becf48062f298` (raw provider exception details removed from user-facing location screens); run `40743789957` passed at `be4f34d5002e6d4982afbd89febae98471ae121a` (nested State/UT streams now show visible loading/error feedback); and run `40744272652` passed at `a65e8cdef73b142381a3fc029385efceeaf0e156` (City streams show loading/error feedback and State/City search has contextual empty messages). Each run completed analyze, full tests and web release build. Continue the screen-by-screen audit; do not infer that all POL-040 acceptance criteria are complete from these targeted fixes.
- The Suspended Zones filter test was updated to reveal lazy filter controls before interacting; it passed in a later full test run.
- Widget tests for the fourth dependent Zone selector, city-dependent mock options, parent-change resets, disabled Save Draft/Submit, Approval Queue safeguards, Directory lifecycle filters, Zone Details metadata, preview navigation, booking-status normalization, permission error classification and sensitive-field omission passed in run `40687163413`.
- A separate widget test was added for Founder Approval Queue authority copy, disabled decision buttons, and status filtering.
- Latest full validation: run [40769067311](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40769067311) passed `flutter analyze`, the complete `flutter test` suite and `flutter build web --release` at test/code commit `2bd457a79ffc4b4c3fa62e97c9a21428391413bd`. It includes Zone identity/revision/hash safeguards, disabled Founder decisions, narrow-mobile Create Zone and Zone Directory tests, booking empty-state tests, Dashboard lifecycle-status alias tests, disabled finance mutation tests, and narrow-mobile layout tests for Customer Management, Pet Management, Notification Center, Support & Complaints, Admin Users & Roles and Finance Operations. Customer, Pet and Notification cards initially overflowed on mobile; their lifecycle/status chips now stack below the identity row at narrow widths. Additional regression tests assert support transfer/resolution and notification send/retry controls remain disabled. The full suite and Web build pass; this does not mean every POL-040 acceptance criterion or real backend integration is complete.
- Suspended Zones UI explicitly documents the narrow emergency safety-suspension exception: only to prevent immediate harm, with an append-only audit record and prompt Founder/CEO notification. Its widget assertion is covered by full passing run [40768278346](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40768278346).
- Main Service Locations map status no longer reports `Active boundaries: 0` when the Zone-specific source is an intentional empty placeholder. It explicitly says `Zone boundary source not connected` (or shows loading/error), so an unconnected source is not misrepresented as verified zero coverage. Covered by full passing run [40769067311](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40769067311).
- The boundary preview status logic is isolated in `lib/features/service_location/utils/boundary_preview_status.dart` with unit cases for loading, error, disconnected/empty source and non-empty polygon count. These tests passed in full validation run [40769067311](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40769067311).
- Walker Management audit against draft POL-004: added dedicated Training Required, Suspended and Inactive / Offboarded filters; search now includes lifecycle and verification status. Helper tests cover Training Required, approved-inactive and offboarded mapping. The existing Walker Details service combines verification and approval and lacks all required POL-004 audit evidence fields, so lifecycle-changing UI actions are disabled in this UI-validation branch; existing Firestore reads remain, and the service was not expanded. Run [40764383490](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40764383490) passed for code commit `93c5426bc2d688389faafd3e3fd39a23fe64071c`; the broader current branch validation [40769067311](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40769067311) also passed after the added mobile viewport and disabled-action regression tests.
- Dashboard booking counts now query known legacy status variants through `bookingStatusQueryAliases`, aligned with `displayBookingStatus`. Tests assert that every queried alias maps to its canonical lifecycle label and preserve `Picked Up` as a distinct state; run [40767404188](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40767404188) passed the status-alias consistency tests, and full branch run [40769067311](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40769067311) passed afterward.
- Do not infer success from an in-progress run; record the run ID and commit for every PASS claim.
- Working-branch sync check: comparison against `main` reports `diverged`, 197 commits ahead and 5 behind at the time checked. The main-only commits include a Zone audit-history screen, the fourth Zone-selector test, and booking-status test add/revert history; the working branch already contains similarly named files, so overlapping paths may conflict. Do not merge or rebase blindly; reconcile these changes after this UI-only scope and its CI validation are settled.
- Legacy CSV import copy now explicitly identifies the State/District/City/Area flow as reference-data import only, separate from the current Create Zone flow, and states it does not create or activate service Zones. Existing import behavior was not changed.
- No merge, deployment, or new Firebase integration is authorized by this file.

## Next UI-only sequence

1. Continue the Service Location screen-by-screen audit against POL-040, especially hierarchy navigation, empty/error/permission-denied states and disabled lifecycle actions.
2. Audit existing Dashboard, Live Operations, Bookings and Walker Management screens against their Notion policies, including loading/empty/error/permission-denied/success states.
3. Run final full validation against the latest branch head and record the exact run link.
4. Only after UI and tests are complete, start the planned Firebase/auth/Firestore integration.


## Continued screen-level evidence review — 2026-10-29

This is a source inspection of the checked-in UI and test files, **not** a claim that tests were executed in this session.

### Create Zone form

- Implementation: `lib/features/service_location/screens/add_zone_screen.dart`.
- Focused widget tests: `test/features/service_location/add_zone_screen_test.dart`.
- Observed coverage includes exactly four selectors (State/UT → District → City → Zone), downstream selection reset behavior, mock existing-Zone selection not editing a record, draft/review actions disabled without backend, boundary review preview navigation without submission, narrow mobile viewport, polygon-required/radius-insufficient messaging, and empty-form validation.
- Explicit current gap: hierarchy options are a small hard-coded UI catalog (e.g. Uttar Pradesh/Delhi and sample districts/cities), not the authoritative location catalog. The screen correctly labels mock Zones and explains that nothing is saved. Do not treat these dropdown options as production-ready.
- Explicit current gap: boundary drawing/upload and real polygon verification are not implemented/connected; save and submit controls remain disabled. This is appropriate for the UI-only phase and must stay so until the Notion backend and authorization gates are implemented and tested.

### Founder Approval Queue

- Implementation: `lib/features/service_location/screens/zone_approval_queue_screen.dart`.
- Focused widget tests: `test/features/service_location/zone_approval_queue_screen_test.dart`.
- Observed coverage includes Founder/CEO versus Super Admin authority wording, blocked boundary-pending and changed-hash revisions, filter behavior, disabled server decision actions, and narrow mobile viewport.
- Explicit current gap: queue rows are local illustrative examples; no live requests, server authorization, revision-bound approval transaction, or append-only audit write is connected. Decision buttons are disabled and the screen labels itself as a prototype.

### Validation status

The source and test assertions above were inspected from the branch. The test runner, formatter, analyzer and release build were **not executed by this source-inspection pass**. Do not mark them PASS based on test-file presence. Exact-head GitHub status must still be checked independently after each commit.

### Next implementation priority

1. Keep mock catalog and approval decisions visibly non-production; do not wire Firebase in this phase.
2. Continue screen-by-screen comparison with POL-040 and the linked POL-038/POL-041/POL-042 contracts, especially Loading, Empty, Error, Permission Denied and Success states.
3. Only change code when a specific requirement gap is confirmed and a focused regression test can accompany the change.
4. Keep PR #51 Draft; do not merge or deploy.


## Continued audit — Location Audit History test coverage (2026-10-29)

- Screen: `lib/features/service_location/screens/audit_history_screen.dart` (`LocationAuditHistoryScreen`).
- Added focused widget tests: `test/features/service_location/audit_history_screen_test.dart` in commit `bc33ccd36ddede6460be554b5c362ae89608b183`.
- The new tests assert explicit prototype/not-live wording, append-only expectations, outcome-chip filtering, empty-filter recovery, absence of edit/delete controls, and a narrow 360px mobile viewport.
- This closes a test-file gap for the existing Location Audit History prototype only. It does **not** implement or validate live audit queries, loading/error/permission-denied server states, pagination, date/actor filters, or server-side access control. Those remain pending until the approved backend contract is implemented.
- Exact-head CI for `bc33ccd36ddede6460be554b5c362ae89608b183` was queried immediately after commit and returned no associated PR workflow runs. Test execution, analysis, formatting and Web release build therefore remain **Pending / unverified**, not PASS.
- No Firebase integration, production data write, merge or deployment was performed. PR #51 remains Draft.


## Continued Service Location audit — Zone Audit History (29 Oct 2026)

- Added two widget-test cases in commit `3240e2911b84d072df94d5e7971c1f8db12191eb`: 360px mobile viewport and read-only UI (no edit/delete/mutation controls).
- Existing tests already cover sample-data warning, searching across event/zone/actor/status, clearing a search, and no-match recovery.
- Review note: the clear-search IconButton is conditional and must not appear before a query is entered. The read-only test asserts no IconButton is shown in the initial state; the clear-search behavior remains covered by the existing search tests.
- Remaining gaps are integration-level, not solved by these UI tests: live audit_logs query, server-side pagination, stable ordering, loading/error/permission-denied states, and authorization. Keep the prototype label until those exist.
- No Flutter CLI was available in this connector session. Formatter, analyzer, tests and Web release build are **not executed / Pending**; no passing result is inferred from test source.
- Latest branch head after this change: `3240e2911b84d072df94d5e7971c1f8db12191eb`. Exact-head workflow status must be checked separately. Keep PR #51 Draft; no backend integration, merge or deployment.


## Follow-up implementation — fail closed on legacy location status calls (30 Oct 2026)

- File changed: `lib/features/service_location/services/service_location_service.dart`.
- Commit: `2c3ff32a77076c373d6633791e5ad8a34dab7015`.
- Updated the service contract comments to identify the legacy City/Area/Locality records as compatibility/read-only records and Zone as the only service-status unit.
- `_setTrustedStatus` now rejects all non-Zone status mutations locally and rejects Zone activation through the generic status callable; a Zone deactivation request is passed only as `isActive: false` to the trusted endpoint, which must still validate Founder-approved deactivation server-side.
- `_activateTrustedBoundaryLocation` no longer calls the legacy `activateServiceLocation` callable; it fails closed with a clear StateError. This prevents old City/Area UI actions from sending legacy activation requests from this Admin branch.
- Scope note: this does not implement the new Zone UI/backend integration, remove every legacy status control from screens, or prove production protection. Legacy methods may still be reachable from old UI, but their service-layer mutations now fail closed.
- Validation status at time of writing: CI for the new exact head has not yet been checked; analyzer, tests and Web release build are **Pending** until GitHub Actions provides exact-head evidence. No Firebase writes, merge or deployment. PR #51 remains Draft.


## Follow-up — approval queue prototype audit and exact-head CI closeout (30 Oct 2026)

- Rechecked Admin CI run `40949534432` for code commit `f03d0cd0c5235fdda77929aff9e3bdf45ab435cc`: workflow conclusion is `success`; dependencies, full-project analyze, complete Admin tests, Flutter Web release build, and cleanup all completed successfully. This run is for that application-code commit, not the later docs-only branch head.
- Audited `lib/features/service_location/screens/zone_approval_queue_screen.dart` and `test/features/service_location/zone_approval_queue_screen_test.dart`. The screen is explicitly a UI-only prototype with illustrative records, and all decision buttons are disabled; tests assert no server decisions can be triggered. Do not wire live Founder decisions into this mock queue until real request loading, revision/hash validation display, authorization and callable error states are implemented.
- Rechecked Firebase Draft PR #40 head `494d83f4abf3305ca1f1671b7ef52f26dcf227e7`, base `feat/zone-name-index-schema-2026-10-26`; it remains open, Draft and unmerged.
- Blocking policy decision remains: `activateServiceZone` requires a verified parent City polygon and Zone-within-City containment, while the current approved Admin policy establishes Zone polygon verification but does not clearly require a City polygon as a separate prerequisite. No change made to backend behavior. Resolve the policy decision before Zone activation integration; no production deployment or data write.


## Policy decision implemented in Firebase Draft PR #40 — City polygon optional (30 Oct 2026)

- Decision recorded in Notion POL-041, POL-042 and POL-038: parent City is required as a valid hierarchy record, but its own polygon is not a prerequisite for Zone boundary verification or activation. Each Zone must have its own verified polygon; Founder approval must match exact current revision and canonical boundary hash; Central Admin activation rechecks hierarchy, verified Zone boundary and approval and writes audit.
- Firebase branch `fix/disable-legacy-location-activation-2026-10-28` updated `functions/src/index.ts` (commit `00e441accb6323503b307a191600faea072ee6c0`) to remove City-polygon containment from Zone boundary review and Zone activation. Legacy Area boundary review retains its previous City-containment behavior; legacy City/Area activation remains blocked. Follow-up comment-only commit: `00c16322e52bc6e80aba115aa73813100e9b4254`.
- Updated `functions/test/zone_service_location.integration.test.cjs` (commit `ebe7e5c76786ad7ae9009d33b1b6333161c24fc0`) to exercise Zone boundary review without a City boundary and activation without a City polygon. Tests have not yet been observed running against these new commits; do not claim test pass until a CI run for the exact current head completes.
- Current Firebase PR #40 head at time of audit: `00c16322e52bc6e80aba115aa73813100e9b4254`, still Draft/open/unmerged. Existing CI success on earlier head `494d83f4abf3305ca1f1671b7ef52f26dcf227e7` does not verify this policy change. No deployment or production writes.


## Follow-up QA note (30 Oct 2026)

- Reviewed the updated integration-test fixture cleanup and added an explicit restore of `service_cities/{id}.verifiedBoundaryId` after the test proves Zone activation works with no City polygon (`functions/test/zone_service_location.integration.test.cjs`, commit `69057362f87d7b47a79d5c7f7f8f15713dd2ee46`). This prevents the policy test from leaking a modified City fixture into later tests.
- Latest Firebase PR #40 head: `69057362f87d7b47a79d5c7f7f8f15713dd2ee46`. No Actions run is currently visible for this exact head. CI and emulator tests remain unverified; do not mark the policy change PASS until an exact-head workflow succeeds.
