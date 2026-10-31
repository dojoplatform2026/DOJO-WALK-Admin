# DOJO WALK Admin — Walker Management Dashboard Deep Audit

- Audit date: 2026-10-30
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch reviewed: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (keep Draft/open)
- Source reviewed: `lib/features/walkers/screens/walker_management_dashboard_screen.dart`
- Helper reviewed: `lib/features/walkers/utils/walker_admin_helpers.dart`
- Existing related test: `test/features/walkers/walker_lifecycle_filter_helpers_test.dart`
- Governing contract: `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md` (POL-004, POL-026)
- Scope: source-level UI and behavior audit only. No Firebase, production data, merge, or deployment changes.

## 1. Existing implementation confirmed

- Walker list is read through `WalkerAdminService.watchWalkers()`.
- Running status is derived from booking stream records with statuses `in_progress`, `active_walk`, `walking`, and `walk_started`.
- Search currently checks name, phone, email, UID, area, city, state, account status, and verification status.
- Lifecycle tabs: Available, Running, Verification, Training Required, Rejected, Suspended, Inactive / Offboarded, All Walkers.
- Results are alphabetically sorted by walker name.
- Walker card tap opens `WalkerDetailsScreen` with UID and existing raw profile data.
- Loading and error states are present for walker and booking streams; permission-denied is distinguished.
- Empty state distinguishes no matches from an empty selected lifecycle tab.
- Screen is scrollable and constrained to a maximum width of 1000 logical pixels.
- Lifecycle helper tests cover Training Required separation, approved-but-inactive filtering, and legacy left/offboarded mapping.

## 2. Gaps and risks found

| Area | Source finding | Required follow-up |
|---|---|---|
| Dedicated screen tests | Only helper-level test exists; no `walker_management_dashboard_screen_test.dart` was found in the PR file inventory. | Add widget tests using injectable walker/booking streams or a service seam; never use production Firebase in tests. |
| Filter tab layout | Eight lifecycle tabs are rendered through `WalkerAdminTabs`; this screen's narrow-width behavior and keyboard/focus semantics have not been evidenced. | Inspect the shared tab widget and test 320/360/390/768/1280 px, including horizontal overflow and selected-state semantics. |
| Search hint | Hint says “name, phone or Walker ID”, but actual search also matches email, UID, area, city, state and statuses. | Make the hint accurately describe supported search fields, or deliberately narrow search to the advertised fields. |
| Search coverage | Search is a single substring over joined fields; no explicit normalization for phone punctuation or alternate phone formats. | Decide expected phone matching and add tests for case, whitespace, partial phone, email and location. |
| Available label | Eligibility checks approved + verified + approved flag + active flag and excludes running walkers. It does not check schedule, zone, capacity, GPS freshness or assignment conflicts beyond currently loaded running bookings. | Keep the UI meaning explicit: eligible account / not currently marked running, not guaranteed real-time availability. Confirm POL-026 definition before renaming or expanding logic. |
| Running detection | Running walker IDs depend on a limited set of booking status strings and the booking stream's query scope. | Compare with the canonical booking status helper/assignment contract; add alias and missing-walkerId tests. |
| Stream errors | A booking stream error replaces the entire list with the generic walker data error panel; no retry control is visible in this screen. | Separate walker-list and booking-status failures; provide safe retry/refresh that only resubscribes and performs no writes. |
| Stream lifecycle | The booking StreamBuilder is nested inside the walker StreamBuilder and calls `watchBookings()` during each parent build. | Consider caching/injecting the stream to avoid unnecessary resubscriptions when search or tabs change; verify service stream behavior first. |
| Counts | Count is the filtered in-memory list length, not a server-side total. | Label as visible/filtered results if product semantics require clarity; test count changes with search and tab selection. |
| Profile navigation | Tap route passes raw walker data and UID; no dedicated navigation test exists. | Test correct UID/data handoff and back navigation; keep lifecycle mutation actions disabled pending POL-004 authorization/audit requirements. |
| Accessibility | Search has a hint and clear tooltip; tab/card semantics and focus order have not been demonstrated. | Add semantics, keyboard traversal and screen-reader assertions. |
| Responsive evidence | ScrollView/max-width constrain the page, but this alone does not prove tabs/cards fit or remain usable on small screens. | Add widget viewport matrix and inspect overflow exceptions. |

## 3. Safety and policy guardrails

- Do not enable Approve, Reject, Suspend, Reactivate, Correction, or offboarding actions in this UI audit.
- POL-004 authority separation and audit requirements must be approved and enforced server-side before lifecycle mutations are enabled.
- A UI filter is not authorization. City/zone scope and record access must be enforced by trusted backend rules/services.
- Do not interpret the Available tab as proof of a bookable slot or GPS freshness.
- Do not add a second Walker Management implementation or move files without the Notion-to-file migration map.
- Keep the screen in the existing `lib/features/walkers/` ownership path.

## 4. Next implementation sequence

1. Inspect `WalkerAdminTabs`, `WalkerAdminCard`, and `WalkerAdminService` to establish tab overflow, semantics, and stream query behavior.
2. Add an injectable read-only data source/service seam for deterministic widget tests.
3. Add screen tests for populated list, empty tab, no search matches, search fields, each lifecycle filter, running detection, loading, generic error, permission denied, retry, profile navigation, and responsive widths.
4. Fix only confirmed UI defects (including inaccurate search hint and any proven narrow-screen overflow).
5. Run Flutter Analyze, targeted walker tests, full test suite, and Flutter Web release build on the exact resulting commit; record run IDs and results.
6. Keep PR #51 Draft/open. No merge, deployment, or production Firebase integration in this phase.

## 5. Validation status

- Source review: DONE for the files listed above.
- Dedicated Walker Management screen widget tests: MISSING in inspected PR file inventory.
- Existing helper tests: PRESENT, execution status not verified in this audit.
- Flutter Analyze / Flutter Test / Web build: NOT RUN or NOT VERIFIED in this audit.
- Responsive screenshot/device QA: NOT EVIDENCED.
- Firebase integration, merge, deployment: NOT performed.

This report records source findings and recommended tests; it does not claim runtime behavior or tests have passed.

## 6. UI/testability implementation update (2026-10-30)

Implemented on this branch after the source audit:

- Added optional read-only walkersStream and runningWalkerIdsStream inputs to WalkerManagementDashboardScreen. Production defaults still use WalkerAdminService; tests can provide deterministic streams without Firebase initialization.
- Cached the production walker and running-booking streams in initState, rather than creating the booking stream from every parent rebuild.
- Extracted production booking snapshot → running walker ID conversion into a typed adapter. The recognized booking status set remains unchanged; no unverified status aliases were added.
- Added a Retry control to the error panel. Retry recreates the production Firestore streams and remounts the StreamBuilders; it performs no Firestore write or lifecycle action.
- Updated the search hint to reflect actual searchable fields: name, phone, email, ID, location and status.
- Added test/features/walkers/walker_management_dashboard_screen_test.dart.

New widget test coverage authored:
- populated list and filtered result count;
- email and location search;
- running tab membership;
- Available filter excluding running and account-ineligible walkers;
- Verification vs Training Required separation;
- no search matches;
- pending loading streams;
- generic stream error and Retry affordance;
- viewport widths 320, 360, 390, 768 and 1280 px with long text.

## 7. Remaining caveats after implementation

- Widget tests are authored but have NOT been executed. No Flutter Analyze or Flutter Test result is available for the exact head.
- Retry affordance is source-implemented; runtime retry behavior is not yet verified.
- Permission-denied rendering is handled by the shared classifier, but a dedicated permission-denied widget test remains to be added.
- Walker card navigation still lacks a route-level widget test.
- Lifecycle filters beyond Available, Running, Verification and Training Required still need direct widget coverage (Rejected, Suspended, Inactive / Offboarded, All Walkers).
- Search normalization for phone punctuation/alternate formats is not implemented; current matching remains lower-cased substring matching.
- The service still streams the full walkers and bookings collections. Query scope, city/zone authorization and read-cost optimization require a separate approved backend/data contract review. UI filters are not authorization.
- Available remains an account-eligibility view excluding currently detected running IDs; it does not prove schedule, zone, GPS freshness, capacity or an actually bookable slot.
- The result count is the current in-memory filtered list size, not a server aggregate.
- No Firebase integration, merge or deployment was performed.
## 8. Shared Walker Admin widget tests authored

Added test/features/walkers/walker_admin_widgets_test.dart with coverage for:
- lifecycle tab semantics/selection callback;
- eight-tab horizontal scrolling at 320 px;
- walker card profile/contact/location and Running status presentation;
- long text and invalid-photo URL fallback at narrow width;
- walker card tap callback;
- KYC View enabled/disabled behavior based on the supplied availability flag.

These are source-level test additions only. They have not been executed; exact-head Flutter validation remains outstanding.