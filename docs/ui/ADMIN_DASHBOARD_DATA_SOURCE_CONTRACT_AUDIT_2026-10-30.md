# Admin Dashboard Data Source — Focused Contract Audit

**Date:** 2026-10-30  
**Branch:** `ui/notion-brand-foundation-2026-10-28`  
**Source:** `lib/screens/dashboard/dashboard_data_source.dart`  
**Source blob:** `f8463020ffada650a4a081dbec2d621280bd4aa7`  
**Scope:** Read-only source inspection. No Firestore schema or production behavior changed.

## Current implementation verified

`FirestoreDashboardDataSource` currently performs these reads:

| Method | Current query | Transformation |
|---|---|---|
| `countAll(collection)` | Entire collection snapshot | `snapshot.size` |
| `countWhere(collection, field, value)` | Equality-filtered collection snapshot | `snapshot.size` |
| `countBookingStatus(label)` | `bookings` where `status` is in helper aliases | Snapshot size; unknown label returns 0 |
| `totalPaidAmount()` | `payments` where `status == paid` | Sums numeric `amount` values client-side; non-numeric/missing amounts silently skipped |
| `recentBookings()` | `bookings` ordered by `createdAt DESC`, limit 8 | Maps document ID, raw `petId`, normalized status |
| `recentActivity()` | `audit_logs` ordered by `timestamp DESC`, limit 6 | Maps action and actorRole strings |

The dashboard uses an injectable `DashboardDataSource` interface, which is a good seam for deterministic widget tests. The production implementation still reads whole collections for totals and does not apply City/Zone scope.

## Findings and risk

### P1 — Whole-collection snapshot counts
`countAll` and `countWhere` subscribe to document snapshots and transfer documents just to count them. This is not a scalable aggregate strategy and may create unnecessary reads/cost. Do not silently replace it with a different count source until expected freshness, billing, offline behavior and backend contract are agreed. Consider server-side count aggregation or trusted summary documents with explicit freshness and authorization.

### P1 — Dashboard totals have no geographic scope
The data-source methods accept collection/filter fields but no authorized City/Zone scope. This conflicts with the intended operational separation where City Manager and Zone Supervisor see only their assigned scope. UI filtering alone is not an authorization boundary. Keep operational role access gated until backend-enforced scope is implemented and tested.

### P1 — Paid amount is not yet a verified finance ledger
The dashboard assumes `payments.status == paid` and numeric `amount` represent revenue. It ignores missing/non-numeric amounts and sums every matching document. The inspected code does not establish refund, reversal, duplicate, currency, settlement, tax, or ledger semantics. Label this as an unverified operational metric, not audited revenue, until Finance/POL-011 and the payment backend contract define it.

### P1 — Booking aliases are a compatibility list, not an approved state machine
The helper recognizes multiple legacy spellings. `whereIn` queries only those exact values. Any unlisted stored spelling is omitted from counts, while unknown values are preserved by display normalization. A successful helper unit test does not prove production dataset completeness or policy approval.

### P2 — Recent booking data is minimally descriptive
The query returns `petId` directly and does not resolve a pet display name, Walker, zone, scheduled time, or customer-facing booking reference. The UI currently risks showing an opaque identifier instead of useful operational context.

### P2 — Recent activity trusts raw fields
The query maps raw `action` and `actorRole` strings. This is display-only data and does not validate actor identity, event integrity, or whether the event is authoritative.

### P2 — Time is not injectable
The Dashboard greeting and date use `DateTime.now()` directly. Existing tests cannot reliably pin greeting/date boundaries without introducing a clock seam.

## Targeted test plan (not executed)

1. Add Firestore Emulator tests for exact query filters and returned document counts.
2. Test status alias queries against fixtures for every supported legacy value, plus an unknown value.
3. Test paid amount aggregation with integer, double, missing, string, zero, negative, refunded, reversed, and duplicate-like fixtures; use results to document current behavior, not to endorse financial semantics.
4. Test missing `createdAt` / `timestamp` behavior and required indexes using emulator fixtures.
5. Add widget-level partial-failure cases so one failing stream does not hide healthy metrics.
6. Introduce an injectable clock in a separate reviewed change, then test greeting boundaries at 11:59, 12:00, 16:59, 17:00 and date rollover.
7. Add authorized City/Zone scope only after POL-021/POL-037 and backend enforcement are approved; test cross-city and cross-zone denial at Rules/Functions level.

## Release gates

- No production schema migration or Firebase deployment in this task.
- No claim that dashboard figures are finance-certified.
- No role-based dashboard access rollout until server-side scope enforcement exists.
- No test PASS claim until the test suite and emulator checks are actually run on the exact commit.
- Keep PR #51 Draft/open; do not merge or deploy.
