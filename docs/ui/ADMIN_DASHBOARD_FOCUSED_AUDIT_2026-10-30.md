# DOJO WALK Admin Dashboard — Focused UI/Data Audit

**Date:** 2026-10-30  
**Branch:** `ui/notion-brand-foundation-2026-10-28`  
**Status:** Source inspection only — no code or test changes in this audit.  
**Scope:** Dashboard screen and its read-only data-source contract.

## Inspected source

- `lib/screens/dashboard/dashboard_screen.dart` — blob `2a851c107992e3bcf60063aad089f57c955166f4`
- `lib/screens/dashboard/dashboard_data_source.dart` — blob `f8463020ffada650a4a081dbec2d621280bd4aa7`
- `lib/screens/dashboard/admin_shell.dart` — blob `ef7b6730b4ec4a2fdf01c3b99d980774991576b1`
- `docs/PROJECT_FILE_STRUCTURE.md` — blob `051fd366165c111223c872c2b0900d877a27550e`

The canonical target structure document says the Dashboard is the main company command center and explicitly says the target tree is not proof of implementation. It also requires exact-head `flutter analyze`, `flutter test`, and release web build before claiming completion. PR #51 must remain Draft; no merge, deployment, or Firebase integration in this phase.

## Verified in source

1. Dashboard has responsive column breakpoints for the top stat cards and responsive stacked/two-column sections.
2. Greeting and date are generated at render time.
3. Refresh increments a key to recreate stream subscriptions.
4. Recent bookings and system activity explicitly render waiting, error, and empty states.
5. Stream rows for live counts and alerts render compact error/loading indicators.
6. Dashboard data access is abstracted behind `DashboardDataSource`, allowing deterministic stream fakes in tests.
7. The production data source queries:
   - full snapshots for total bookings, customers, and walkers;
   - `walkers.isOnline == true/false`;
   - booking status aliases via `bookingStatusQueryAliases`;
   - all paid payment documents for total amount;
   - latest 8 bookings ordered by `createdAt`;
   - latest 6 audit logs ordered by `timestamp`.

## Findings and required follow-up

### P1 — Unbounded aggregate reads

`countAll()` uses an unbounded collection snapshot and maps its size. `totalPaidAmount()` reads every document matching `payments.status == paid` and sums client-side. These reads can grow in cost and payload as the platform scales. Do not silently replace them with a guessed aggregate schema: first approve the reporting contract and backend aggregation strategy. Dashboard should eventually consume bounded, server-maintained, or otherwise cost-controlled metrics.

### P1 — Dashboard data scope is global

The inspected data-source interface has no city/zone scope argument. The screen therefore has no visible way to constrain these metrics by the signed-in operational user's assignment. This is not acceptable as a City Manager/Zone Supervisor dashboard contract. Keep role-scoped dashboard data disabled until POL-021 permissions and backend enforcement are approved and implemented. UI filtering alone is not authorization.

### P1 — Booking status labels require contract reconciliation

The screen requests legacy display labels including `Pending`, `Picked Up`, `Walker Accepted`, `Walk In Progress`, and `Completed`. The booking/walk lifecycle draft uses a broader state model. Verify every alias against the approved canonical booking contract before presenting these counts as operational truth. In particular, "Pending" is currently reused as "Waiting Assignment", which may include records not yet eligible for assignment.

### P1 — Payment metric has an unverified source contract

The dashboard assumes a `payments` collection with `status == paid` and numeric `amount`. This source inspection does not prove that this is the canonical, reconciled financial ledger or that client-side totals are finance-grade. Label as provisional until the Finance policy and payment data contract approve it.

### P2 — Offline walkers are not necessarily an actionable alert

The alert counts every Walker with `isOnline == false`. This may include inactive, off-duty, unapproved, or otherwise ineligible accounts. Define the operationally actionable subset (for example, active and scheduled) before treating this count as an alert.

### P2 — Recent booking display is not customer-friendly

The list displays the pet document identifier as `Pet: <petId>` rather than a safe display name, and does not show booking time, zone, assigned Walker, or a booking detail action. Do not add personal/customer fields until a privacy-reviewed read model is defined.

### P2 — Audit activity display is minimal

Activity rows show raw `action` and `actorRole` values. A future presentation should use human-readable event labels and safe timestamps, while preserving the immutable audit source and avoiding disclosure of sensitive payloads.

### P2 — Dashboard test coverage remains unverified

This inspection did not establish a dedicated Dashboard widget-test suite or run any tests. Code-search results are not a complete repository test-tree listing, so absence of a discovered test file must not be interpreted as proof that no tests exist. Next verification must inspect the repository's actual test tree and test workflow, then add focused tests for:
- responsive breakpoints;
- greeting/date rendering with controlled time;
- refresh resubscription;
- loading/error/empty/data states for each stream section;
- booking status alias mapping;
- payment amount type handling and empty result;
- offline Walker eligibility semantics;
- accessibility labels and keyboard navigation.

## Decision / gate

- No changes to Firestore schema, Rules, Functions, indexes, or production data.
- No new status aliases or payment assumptions are approved by this audit.
- Do not mark Dashboard UI complete.
- Next implementation step: inspect the exact branch test tree and existing test helpers, then add tests around the current data-source contract before making UI/data changes.
- Keep PR #51 Draft and unmerged.
