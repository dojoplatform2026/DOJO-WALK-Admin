# Dashboard Partial-Failure Tests and Emulator Readiness

**Date:** 2026-10-30  
**Branch:** `ui/notion-brand-foundation-2026-10-28`  
**Scope:** Dashboard UI resilience and feasibility review for Firestore-backed tests.

## Partial-failure tests added

Updated `test/screens/dashboard/dashboard_screen_test.dart` with three independent failure scenarios:

1. Recent bookings stream fails while System Activity remains visible and populated.
2. System Activity stream fails while Recent Bookings remains visible and populated.
3. Paid amount stream fails while the main dashboard count cards remain visible.

These use the existing injected `DashboardDataSource` fake. They validate widget isolation/resilience; they do not validate Firestore Rules, indexes, network behavior, or emulator semantics.

## Emulator readiness finding

The Admin repository's current `firebase.json` contains Hosting configuration only. It does not define Auth or Firestore Emulator ports. The Admin repo also does not own the canonical Firestore Rules or Functions source; those live in the separate Firebase repository.

The newly added `dashboard_data_source_test.dart` uses `fake_cloud_firestore`. It is useful for deterministic query mapping checks but is not a real Firestore Emulator test.

## Safe next-step architecture

Before adding a real emulator workflow to this Admin repository:

1. Confirm the authoritative Firestore Rules and indexes branch/commit in `DOJO-WALK-Firebase`.
2. Avoid copying or duplicating Rules into the Admin repo.
3. Use a dedicated demo project ID and local Emulator only; never point tests at the production Firebase project.
4. Start Firestore Emulator with the exact Rules artifact from the Firebase repo, plus required indexes if query/index behavior is in scope.
5. Run a Dart integration test that initializes a named Firebase app against localhost, seeds isolated fixtures, calls `FirestoreDashboardDataSource`, and tears down only that named app.
6. Verify query behavior and Rules separately: query result tests must not be mistaken for authorization tests.
7. Ensure CI has Java, Firebase CLI, emulator startup/readiness wait, deterministic teardown, and artifact/log capture on failure.

## Release / evidence status

- Three widget partial-failure tests are committed as source.
- No Flutter test command was run in this task.
- No Firestore Emulator was started.
- No emulator PASS, Rules PASS, or CI PASS is claimed.
- No Firebase production configuration, Rules, indexes, or data was changed.
- Keep PR #51 Draft/open; no merge or deployment.
