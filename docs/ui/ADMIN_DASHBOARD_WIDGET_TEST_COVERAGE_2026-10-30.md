# Dashboard Widget Test Coverage — Verified Inventory

**Date:** 2026-10-30  
**Branch:** `ui/notion-brand-foundation-2026-10-28`  
**Source commit:** `3ee6c1212deff220dfb9bfd0c5d82d0bc9a17f3e` (parent of docs-only audit commit `c492c2c693c996204d9757733a9e5ec2150ae563`)  
**Dashboard test:** `test/screens/dashboard/dashboard_screen_test.dart`  
**Dashboard test blob:** `7a5fc87ab3aff5ec8dea97ad29b03b63417f6800`

## Correction to the prior audit

The previous focused audit described the dedicated Dashboard widget-test suite as "unverified". The exact branch test directory has now been inspected and **a dedicated suite does exist**. That earlier wording should be read as "not yet inspected at that time", not as a claim that no suite exists.

## Existing Dashboard widget coverage (source inspected)

The current test file contains these cases:

1. Renders dashboard sections using injected fake streams.
2. Explicit empty states for bookings and audit activity.
3. Booking stream error is not presented as an empty state.
4. Audit activity stream error is shown.
5. Loading state remains visible while streams are pending.
6. Permission-denied errors are surfaced for metric/count/status/alert streams.
7. General query errors do not become false zero counts.
8. Refresh action recreates subscriptions; test asserts count subscriptions increase.
9. Layout smoke test at widths 320, 360, 768 and 1280 px.
10. Long booking and activity text at 320 px does not overflow.
11. Header navigation callbacks open Live Operations and Service Locations.

The fake source supports empty, failing, pending, permission-denied and long-text variants. The tests inject the fake through the Dashboard's `DashboardDataSource` constructor.

## Related booking-status helper tests

`test/screens/bookings/booking_status_helper_test.dart` (blob `bfe446600f80d53635ce724f68a75cecbcf59e99`) tests:
- underscore/hyphen normalization and known legacy values;
- unknown and null status behavior;
- empty-state messaging for unfiltered, status-filtered and searched results;
- queried aliases normalizing to expected canonical labels;
- expected alias membership for the currently supported booking labels.

This is meaningful helper-level coverage; it does not prove that the current production Firestore dataset contains only those aliases or that the labels represent the approved booking lifecycle.

## Remaining gaps / recommendations

1. **Controlled time:** greeting and date are based on `DateTime.now()`; no deterministic clock injection is visible in the inspected Dashboard constructor. Add a clock seam before testing morning/afternoon/evening boundaries.
2. **Data-source contract tests:** the widget suite uses a fake. Add focused tests for `FirestoreDashboardDataSource` query mapping, numeric payment amount handling, missing/non-numeric amount behavior, and status alias query construction using an emulator or a carefully isolated fake.
3. **Live count / alert success values:** add explicit expectations for the exact numeric values and labels of all rows, including offline Walker and payment failure counts.
4. **Partial failure matrix:** current tests include broad count failures and individual recent-booking/activity failures. Add targeted single-stream failures to ensure one failing card does not mask unrelated sections.
5. **Refresh precision:** current test proves subscriptions increase; it does not prove every stream resubscribes exactly once or disposes old subscriptions without leaks.
6. **Accessibility:** no explicit semantics/keyboard-navigation assertions were found in this test file.
7. **Status contract:** helper tests are comprehensive for declared aliases, but reconcile them against the approved POL-005/POL-007 state contract before treating dashboard counts as authoritative.

## Workflow and execution status

The branch contains `.github/workflows/flutter-validation.yml`, which runs:
- `flutter pub get`
- `flutter analyze --no-pub`
- `flutter test --no-pub`
- `flutter build web --release --no-pub`

It also contains `.github/workflows/admin-web-build-check.yml` and `.github/workflows/admin-main-full-validation.yml` with analyze/test/web-build checks for their configured branch/PR triggers.

No current exact-head workflow result was established in this audit. The Dashboard test file and workflow definitions were inspected as source only; **no local Flutter test execution was performed**. The latest docs-only commit does not change Dart/test inputs. The preceding code commit's combined GitHub status query returned no status entries, so no PASS claim is made.

## Next action

Do not rewrite or duplicate the existing Dashboard suite. Add only the missing targeted tests after reviewing the relevant helper and data-source implementations. Keep PR #51 Draft; no merge, deploy, or Firebase changes.
