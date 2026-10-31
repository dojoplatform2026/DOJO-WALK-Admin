# DOJO WALK Admin — Dashboard Deep Source Audit

- Audit date: 2026-10-30
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (Draft/open; do not merge/deploy)
- Audited PR head: `99964e7192f4fc4809de8da42a1464212c9213a3`
- Source: `lib/screens/dashboard/dashboard_screen.dart` (38,744 bytes at inspected head)
- Shell: `lib/screens/dashboard/admin_shell.dart`
- Scope: static source review only. No app code, Firebase configuration, production data or runtime behavior changed.

## 1. What is implemented in source

- Four top metrics: all-time booking count, users count, walkers count, and paid payment amount.
- Live overview: in-progress bookings, walkers with `isOnline == true`, pending bookings and completed bookings.
- Booking status counts use `bookingStatusQueryAliases`.
- Recent bookings: latest eight by `createdAt`, with booking ID, pet ID and normalized status.
- Operations alerts: pending bookings, failed payments and walkers with `isOnline == false`.
- System activity: latest six audit log records.
- Responsive layout: metric cards use 4/2/1 columns; two-column dashboard sections stack below 900 px.
- Header actions route to Live Operations and Service Locations.
- Loading/error/empty handling exists for Recent Bookings and System Activity. Metric cards and live/status rows show partial loading/error indicators.

## 2. Confirmed gaps and risks

| Area | Source finding | Risk / required decision |
|---|---|---|
| Dashboard tests | No dedicated dashboard widget test file was found in the inspected test tree. | Add a dedicated widget test before calling this screen validated. |
| Alert rows | `_AlertStreamRow` always renders `snapshot.data ?? 0`; it does not distinguish waiting, permission denied or query failure. | A failed alert query can look like a genuine zero-alert state. Add explicit loading/error/permission states. |
| Status rows | `_StatusStreamRow` does distinguish errors/loading, but does not expose a retry action. | Add retry/re-subscription behavior or a screen-level refresh strategy. |
| Metric errors | `_StatCard`, `_RevenueCard` and `_LiveStreamRow` show an icon/tooltip on error, without a visible inline explanation or retry. | Important operational numbers can become unclear, especially on touch devices where tooltip discovery is weak. |
| Online walker metric | “Available Walkers” counts every walker with `isOnline == true`. | This is an online flag, not proof of schedule availability, assigned-work capacity, recent heartbeat or location freshness. Rename to “Online Walkers” unless a trusted availability contract is implemented. |
| Offline alert | “Inactive walkers” counts `isOnline == false`. | Offline is not equivalent to inactive/suspended/deactivated. Rename to “Offline Walkers” or query the approved lifecycle status. |
| Pending alert | “Unassigned bookings” counts only exact `status == 'Pending'`, while other booking metrics use alias-aware status queries. | Legacy status spellings can be missed by the alert. Reuse the canonical status alias helper. |
| Waiting assignment | “Waiting Assignment” is also a Pending booking count. | Pending may include records not yet eligible for assignment; confirm the canonical business definition before treating it as unassigned. |
| Revenue | Reads every payment document with exact `status == 'paid'` and sums numeric `amount` values in the client. | No currency filter, refund adjustment, fee deduction, date window or server-side aggregate. The label correctly says gross/all-time and discloses refunds/fees are not deducted; keep it explicitly informational until Finance defines the authoritative metric. |
| Collection counts | `_countAll` subscribes to full collection snapshots and uses `snapshot.size`. | Counts may incur read cost and include records outside the current admin's city/zone scope. Confirm role scope and cost strategy before production use. |
| Recent bookings | Query orders by `createdAt` and limits to eight. | Documents missing `createdAt` may not appear; index/query errors need visible state. No booking detail navigation is wired in this list. |
| System activity | Displays action and actorRole only; latest six audit logs. | No timestamp, actor identity, filtering or “view all” route from the dashboard. |
| Header status | Green dot and “Overview” are static. | It must not be interpreted as Firebase/system health. Replace with neutral “Company overview” or a real health state. |
| Greeting | Always says “Good morning”. | Time-inaccurate after morning; make greeting time-aware or use neutral “Welcome, Admin”. |
| Retry | No dashboard-wide retry control is present. | Provide refresh/retry for streams or ensure stream recreation is explicit and tested. |

## 3. Notion / product guardrails

- Dashboard remains the Admin command center; Live Operations opens from the prominent dashboard action.
- Keep gross paid amount clearly distinguished from net revenue and refunds.
- Do not introduce coupon metrics or coupon navigation.
- Do not show an “online” flag as proof of walker availability or GPS freshness.
- Do not make the UI a security boundary: city/zone scoping and role authorization must be enforced by trusted backend rules/services.
- Do not add Firebase integration or change Firestore contracts in this UI-first phase without the approved Notion contract.

## 4. Recommended next work (ordered)

1. Add dedicated dashboard widget tests using a controllable Firestore test/emulator setup or injectable dashboard data source; do not rely on live production Firebase in widget tests.
2. Fix `_AlertStreamRow` so waiting, error/permission-denied and successful zero are visibly distinct.
3. Rename “Available Walkers” to “Online Walkers” and “Inactive Walkers” to “Offline Walkers” until a verified availability/lifecycle contract exists.
4. Make pending/unassigned counts alias-aware and agree the precise “waiting assignment” state definition.
5. Replace the static green “Overview” indicator and fixed “Good morning” greeting.
6. Add visible refresh/retry and accessible error text for metric cards.
7. Define with Finance whether the gross paid amount is appropriate for this Dashboard role; preserve the explicit gross label until a net metric is approved.
8. Validate narrow mobile, tablet and desktop widths, including long IDs, query failures and permission-denied states.

## 5. Validation status

- Source review: **DONE** for the files listed above.
- Dedicated dashboard widget test: **MISSING**.
- Dashboard UI runtime/screenshot QA: **NOT EVIDENCED**.
- Exact-head CI for this audit commit: **NOT RUN / NOT YET VERIFIED**.
- Firebase integration: **NOT STARTED** (intentionally deferred).
- PR #51: keep **Draft/open**; no merge or deployment.

This report records source-level findings only; it does not claim that Firestore rules, production data, query indexes or runtime behavior have been verified.


## 6. Follow-up source changes (commit 9fcdb139451ab193c6c0d3d397101642c26b2ca7)

The following narrow UI corrections were committed after the source audit:

- Replaced the misleading static green status dot / “Overview” indicator with neutral “Company overview” text.
- Changed the fixed morning greeting to a time-aware morning/afternoon/evening greeting.
- Renamed “Available Walkers” to “Online Walkers”; it still reflects only the `isOnline` field and is not a schedule/capacity guarantee.
- Renamed “Inactive walkers” to “Offline walkers”; it does not imply account deactivation.
- Changed the unassigned-booking alert to use the existing booking-status alias helper for Pending.
- Added explicit loading and error/permission-denied indicators to alert count rows so a failed query is not silently rendered as zero.

These are source-level changes only. They have not been runtime-tested in this commit. The dashboard still lacks a dedicated widget test, and the alert rows still need a visible retry mechanism or an agreed refresh strategy.


## 7. Dashboard widget-test feasibility check (2026-10-30)

Inspected the current PR-branch source, `pubspec.yaml`, and the existing test directory before creating a dashboard test.

### Confirmed test constraints

- `DashboardScreen` is a `StatelessWidget` and its Firestore streams are constructed directly from `FirebaseFirestore.instance` inside private methods.
- The constructor currently injects only the two navigation callbacks; it does not accept a Firestore instance or a dashboard data source.
- The current `pubspec.yaml` includes `flutter_test`, but no `fake_cloud_firestore`, Firebase Auth mock package, or other Firestore test double.
- The test tree has no dashboard screen test file. The existing tests do not provide an established dashboard-specific Firebase mocking harness.
- A widget test that simply pumps `DashboardScreen` would still touch the Firebase singleton during build. It is not safe to assume that this will work in a plain Flutter test, and connecting a test to production Firebase is explicitly out of scope.

### Decision

Do **not** add a superficial widget test or a test that depends on live production Firebase. The correct next implementation step is a small, explicit dashboard data-source seam (or equivalent injectable stream providers), with production defaults backed by the existing Firestore queries and deterministic in-memory streams in widget tests. Keep the existing Firestore query semantics unchanged while introducing that seam.

Before writing the widget test, map every stream consumed by the screen (metrics, revenue, live counts, booking status, recent bookings, alerts and system activity) and define test fixtures for:
- successful populated data;
- successful zero/empty data;
- loading;
- general query failure;
- permission-denied failure;
- retry/refresh behavior, once that behavior is implemented.

### Validation status after feasibility check

- Test harness feasibility review: **DONE** (source/dependency inspection only).
- Dashboard widget test: **NOT CREATED**; blocked on an approved injectable data-source seam.
- Flutter test execution: **NOT RUN**.
- Exact-head CI: **NOT VERIFIED**.
- No application source, Firebase config, production data, merge or deployment changed in this step.


## 8. Injectable dashboard data source and first widget tests (2026-10-30)

Implemented on the Draft PR branch:

- Added `lib/screens/dashboard/dashboard_data_source.dart` with a read-only `DashboardDataSource` contract, typed recent-booking/activity view models, and `FirestoreDashboardDataSource`.
- The production implementation preserves the existing collection names, filters, aliases, ordering and limits. This is a query extraction for testability, not a Firestore schema or authorization change.
- Updated `DashboardScreen` to accept an optional `DashboardDataSource`; when omitted, it creates the production Firestore-backed implementation. Dashboard screen source now contains no direct `.collection(...)` query calls.
- Added `test/screens/dashboard/dashboard_screen_test.dart` with a deterministic fake data source. The initial widget tests cover rendering of the dashboard sections and header navigation callbacks.
- The widget test source does not initialize Firebase and does not use production Firestore.

### Validation still required

- These files were reviewed through GitHub source retrieval only; Flutter Analyze and Flutter Test have **not yet been executed** in this environment.
- The new widget tests currently cover populated-stream rendering and header navigation. Empty, loading, stream-error and permission-denied cases are not yet covered.
- The PR branch must run its CI workflows against the latest head before any test-pass claim.
- No Firebase project/configuration, Firestore rules, production data, merge or deployment was changed.


### Widget-test coverage follow-up

Expanded `test/screens/dashboard/dashboard_screen_test.dart` to cover:
- populated dashboard sections and recent booking/activity rows;
- empty recent-booking and audit-activity states;
- recent-bookings stream failure (asserts an error state, not a false empty state);
- header navigation callbacks.

The fake data source continues to supply all dashboard streams without Firebase initialization. These are test cases added to source, not test results; execution remains pending CI.


### Additional dashboard error-state coverage (2026-10-30)

- Added a widget test for audit activity stream failure. It verifies that the UI shows `Unable to load activity.` and does not misrepresent a failed stream as the empty state.
- Dashboard recent-booking and audit-activity streams now have source-level widget tests for populated, empty and error states.
- Remaining work: loading-state assertions, metric/live/status/alert stream failure assertions, and a genuine user-triggered retry/refresh mechanism. The screen currently has no retry/refresh control; do not imply one exists.
- No Flutter test or analyzer execution has been confirmed yet.


### Dashboard refresh control implementation (2026-10-30)

- Converted `DashboardScreen` to a StatefulWidget and added a header refresh icon with tooltip `Refresh dashboard data`.
- Refresh increments a version key and rebuilds the dashboard subtree, forcing its StreamBuilders to resubscribe to newly requested data streams. This is a client-side stream refresh; it does not write to Firestore or guarantee recovery from persistent permission/rules errors.
- Added a widget test that checks the refresh action causes the injected data source to be queried again.
- The test's fake source counts the three collection-count subscriptions; test execution remains unverified.
- The earlier note that no refresh control exists is superseded by this implementation.
- Still pending: run Flutter Analyze and Flutter Test in CI, add explicit loading and metric/live/status/alert error-state tests, and verify narrow/tablet/desktop layouts.


### Responsive layout pass (2026-10-30)

- Dashboard header now switches to a compact stacked arrangement below 520 logical pixels: brand/title on the first row, company-overview label and refresh action on the second.
- On wider layouts, brand and actions remain on one row.
- Added a widget test that renders the dashboard at 360 px (mobile), 768 px (tablet) and 1280 px (desktop), checks the title and refresh control, and asserts no Flutter layout exception is reported.
- Existing dashboard content breakpoints remain: metric cards use 1/2/4 columns at <600 / <1100 / >=1100 px; the two dashboard section pairs stack below 900 px.
- These are source changes and test cases only. Flutter Analyze and Flutter Test have not yet been executed; responsive behavior is not marked PASS until CI/test execution.


### Dashboard stream error-state pass (2026-10-30)

- Added a shared visible stream-error presentation for dashboard metrics, gross paid amount, Live Operations counts, Booking Status rows and Operations Alerts.
- Permission-denied errors now show an explicit “Access denied” label and accessible guidance to check Admin role/data scope; other stream failures show “Unable to load”.
- Failed streams no longer display a fallback numeric zero in these components. Successful zero remains distinguishable from an error.
- Existing loading indicators and the header refresh action remain in place. Refresh re-subscribes streams; it cannot repair a persistent Firestore rules/role denial.
- Expanded test/screens/dashboard/dashboard_screen_test.dart with permission-denied and general query-failure cases covering metric, revenue, live count, booking status and alert streams.
- Source commits: 71232badd1f0741e4f00aca02b0c13db4dd5e4d4, 2405bfbdee2699d7956e6f4b97c61d31a7b7b4ea.
- Widget-test source commit: efaeb97c104905367ebe4f0e34709b7fdac904f1.
- Validation: source edits and test cases are committed, but Flutter Analyze and Flutter Test have NOT been executed/verified in this step. No exact-head CI PASS is claimed.
- No Firestore schema/rules, production data, merge or deployment changed. PR #51 remains Draft/open.


### Dashboard loading-state coverage (2026-10-30)

- Extended the dashboard fake data source with streams that intentionally remain pending, without emitting data or closing.
- Added a widget test asserting the dashboard keeps progress indicators visible while metric, revenue, live/status/alert, recent-booking and activity streams are pending.
- The test also asserts pending streams are not misrepresented as numeric zero, empty states, permission errors or generic failures.
- Test source commit: 4ba97509405a948bd08da8903ad623223dac1b98.
- Flutter Analyze and Flutter Test have not been run in this environment; the test is added but not marked passing. No exact-head CI result is claimed.


### Final dashboard source/UI consistency pass (2026-10-30)

- Reviewed the current dashboard source, data-source seam, widget-test inventory and audit notes on the Draft PR branch.
- Confirmed the metric and revenue cards share the same surface treatment; operational sections use the shared dashboard card; status, alert and activity rows retain bounded/ellipsized booking status text and expanded text columns.
- Confirmed the header switches to a stacked layout below 520 px, metrics collapse to one column below 600 px, and the two paired operational sections stack below 900 px.
- Removed an unused local variable from the revenue stream error branch; no behavior or query semantics changed (source commit eb841b492d42183f3f22249f0a83cc6d0d4020ea).
- Expanded the responsive widget-test viewport matrix to include 320 px in addition to 360, 768 and 1280 px (test-source commit aaf914c3f64a80fa02fd33c36b1a37b213e3e698). This adds a regression assertion; it is not evidence that the test has executed or passed.
- Remaining product/data-contract caveats: “Online Walkers” is only the stored `isOnline` flag, “Waiting Assignment” and “Unassigned bookings” both use Pending aliases, and the all-time paid amount is gross before refunds/fees. These labels must not be interpreted as authoritative capacity, assignment SLA or net finance metrics.
- Validation: Flutter Analyze, Flutter Test, runtime screenshot QA and exact-head CI are **NOT VERIFIED** in this pass. No Firebase integration, merge or deployment was performed. PR #51 remains Draft/open.


### Narrow-mobile long-content regression coverage (2026-10-30)

- Extended the dashboard fake data source with deliberately long booking ID, pet reference, status and audit action/actor text.
- Added a 320 px widget-test case that asserts long booking and activity text render without a Flutter layout exception.
- Test-source commit: `a93e271a30a971c0b796ba04146afbd7874d04fd`.
- This is a test added to source only; Flutter Test/Analyze and exact-head CI have not been run/verified here. Do not treat it as PASS.

## Walker Details Sections — Widget Test Coverage (2026-10-30)

- Added `test/features/walkers/walker_details_sections_test.dart`.
- Covers rendering of personal details, current address, work location, KYC, performance snapshot and account information.
- Covers opening a KYC document only when a document reference exists, and verifies missing-document presentation.
- Adds responsive layout smoke coverage at 320, 390, 768 and 1280 logical pixels using a long walker name/address.
- These are authored tests only. Flutter Test/Analyze has not been executed in this workflow, so no test-pass claim is made.
- The test targets the reusable `WalkerDetailsSections` component; the full `WalkerDetailsScreen` still lacks an injected service seam and an end-to-end widget test for live Firestore loading/error/retry. Lifecycle actions remain intentionally disabled pending POL-004 approval.

## Walker Details Screen Stream Testability (2026-10-30)

- Added optional `walkerStream` injection to `WalkerDetailsScreen`; production continues to use `WalkerAdminService.watchWalker(uid)` when no stream is supplied.
- Made the service lazy so stream-driven widget tests can run without eagerly initializing Firebase. Activity history still uses the production service when opened.
- Added `test/features/walkers/walker_details_screen_test.dart` covering pending/loading, missing walker, stream error/retry affordance, successful detail rendering, and the lifecycle-action safety guard.
- Lifecycle actions remain unavailable. The tests are authored but have not been executed; Flutter Analyze, Flutter Test and full CI remain required before treating this screen as validated.

## Walker Details Dialogs — Widget Coverage (2026-10-30)

- Added `test/features/walkers/walker_details_dialogs_test.dart`.
- Security dialog: verifies read-only account facts and the notice that it does not change login access or permissions.
- Activity history dialog: covers loading, empty, populated audit record (action/actor/reason/status transition), and stream failure without misreporting it as empty.
- KYC viewer: covers missing document reference, user-facing error and retry affordance. Remote Firebase Storage/PDF/image rendering is not exercised by this test.
- Tests are authored only; Flutter Test/Analyze and exact-head CI have not been run for these changes. No production Firebase access or lifecycle action was invoked.

### Walker Details final source/test consistency review (2026-10-30)

- Re-reviewed the three dialog widgets and the Walker Details section/screen tests.
- Corrected the dialog test file structure so the KYC viewer test is inside `main()`, not accidentally nested in the fake service class (commit `842d5fc1207e98728cb2107204851969c887cef8`).
- Corrected the address assertion to include the house/flat value rendered by the component (`A-101`) (commit `2720e351f94d3c4c5aebe15ace3b42c50619f924`).
- Confirmed missing KYC document entries are expected to show `Document not uploaded`; entries with a malformed/non-empty map can instead show `Document reference unavailable`. The section test fixture uses an empty documents map.
- KYC viewer test covers missing-reference handling only; it does not validate Firebase Storage URL resolution, network image decoding, PDF rendering, authorization, or retry success.
- Dialog tests cover read-only security content and activity loading/empty/populated/error states. These are authored tests only.
- Flutter Analyze, Flutter Test, screenshot QA, and exact-head CI remain unverified. Do not mark Walker Details as PASS until these checks are executed.
- Lifecycle decisions remain disabled pending the approved POL-004 authority and audit contract. No merge or deployment.
