# Admin Dashboard & Operational Scope Audit — 2026-10-31

## Scope and evidence
Repository: `DOJOWALK/DOJO-WALK-Admin`
Branch: `ui/notion-brand-foundation-2026-10-28`

Reviewed source:
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/dashboard/dashboard_data_source.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `lib/screens/auth/auth_gate.dart`
- `test/screens/dashboard/dashboard_screen_test.dart`
- Notion `TEAM 02 — Admin App`

This is a static source review. No emulator, production Firestore, deployed Rules/Functions, billing metrics, or user-specific role sessions were tested. No Firebase repo or configuration was changed.

## Findings

### 1. Dashboard has no role or geographic scope input
- `DashboardScreen` accepts callbacks, a data-source injection and a clock; it receives no authenticated Admin identity, capability set, city scope, zone scope or scope resolver.
- `AdminShell` constructs the same Dashboard for every authenticated Admin and exposes the same menu list.
- `AuthGate` checks only that `admin_users/{uid}` exists and `isActive == true`; it does not pass role or assigned geography into the shell.
- Consequently, the Admin UI source does not demonstrate City Manager / Zone Supervisor scoped dashboard behavior. It also does not demonstrate that Central Admin is national-only or Founder sees reserved decisions. This is an implementation gap, not proof that deployed backend rules are bypassable.

### 2. Dashboard metric queries are broad
The production `FirestoreDashboardDataSource` uses:
- `collection(collection).snapshots()` for total Bookings, Customers and Walkers. These are unfiltered live collection listeners and count client-delivered documents.
- `bookings.where(status, whereIn: aliases).snapshots()` for booking-status counts.
- `payments.where(status == paid).snapshots()` and iterates every matching payment document client-side to sum `amount`.
- Recent bookings are bounded to 8 records ordered by `createdAt desc`.
- Recent activity is bounded to 6 records ordered by `createdAt desc`.

The first three all-record count listeners and paid-payments listener are unbounded. At scale this can create high read/listener cost and may expose more records to the client than needed for aggregate cards, subject to the deployed Rules. No production read/billing evidence was available.

### 3. Revenue card is a gross paid sum, not financial reporting
- UI labels the metric “Paid Payments (All Time)” and states that refunds and fees are not deducted.
- Query includes only `status == paid`, sums numeric `amount`, and does not apply refund, reversal, chargeback, gateway fee, payout or settlement reconciliation.
- It is therefore a gross paid-payment indicator, not company net revenue, profit, payable balance or reconciled finance total. Do not use it for Founder financial decisions without a separate approved finance contract.

### 4. Recent operational activity is not a scoped action queue
- Recent bookings and audit activity are read from global collections, with limits 8 and 6.
- Activity projection includes `action` and `actorRole`; there is no visible city/zone scope filter or capability-specific redaction in this dashboard adapter.
- The dashboard's “Operations Alerts” are derived from status counts; source review does not show a dedicated trusted alert/incident feed with severity, ownership, acknowledgement or escalation state.
- This is not a substitute for the dedicated incident/support workflow.

### 5. Existing tests prove UI states, not role/scope authorization
The reviewed widget tests use an injected fake data source and verify metric rendering, loading/error/empty states, refresh behavior, recent content and responsive layout. They do not instantiate different Admin roles, city/zone assignments, or verify that cross-scope records are denied by backend Rules/Functions. The tests were inspected, not executed in this audit.

## Gap matrix

| Requirement | Observed implementation | Result |
|---|---|---|
| Founder/Central/City/Zone dashboard variants | No identity/scope input | Missing |
| City Manager city-only data | No scope filter in Dashboard adapter | Not demonstrated |
| Zone Supervisor zone-only data | No scope filter in Dashboard adapter | Not demonstrated |
| Central national operational overview | Global collection queries, no capability contract | Not established |
| Founder-reserved approval queue | Not part of Dashboard data source | Missing here |
| Least-privilege aggregate counts | Full collection snapshots for counts | Gap / scale risk |
| Paid-payment summary | Reads all paid payment docs and sums client-side | Gross indicator only; scale risk |
| Recent bookings/activity | Limits 8 and 6, respectively | Bounded but globally queried |
| Trusted operational alert feed | Status-count-derived alerts | Partial |
| Backend enforcement | Not verified from Admin source | Unverified |

## Required Team 01 backend contract
Before implementing scoped dashboards or replacing broad reads, Team 01 must define:
1. Trusted identity claims/capabilities and canonical State/UT → District → City → Zone assignment scope.
2. Server-enforced, least-privilege aggregate endpoints/projections for counts and operational KPIs; do not rely on client-side filtering or hiding widgets.
3. A canonical booking occurrence/status aggregation definition, including recurring bookings and multiple walks/day.
4. A finance summary contract that distinguishes gross paid, refunds/reversals, gateway fees, walker payouts, settlement and company net; specify currency, timezone, date boundaries and reconciliation source.
5. Scoped recent-booking and audit-activity read contracts with redaction, pagination, freshness and access audit.
6. Trusted alert/incident feed contract with severity, assignment, acknowledgement, escalation and closure.
7. Rules/Functions emulator tests for unauthenticated, inactive, unauthorized, cross-city, cross-zone, role mismatch and Founder-only operations.
8. Versioned callable/API names, region, payload, indexes, error mapping and pinned emulator revision.

## Safe Admin-only conclusion
Do not add client-side city/zone filters as a security fix, and do not replace broad reads with arbitrary limits that could silently produce incorrect totals. The safe next step is to agree the trusted backend contracts and acceptance matrix, then adapt the Admin dashboard to consume scoped aggregates and projections. Until then, the dashboard is a global operational overview prototype with broad Firestore listeners; its current data is not proven role-scoped.

## Change boundary
Documentation only. No Dart source, Firestore schema/rules/indexes/data, Functions, Storage, IAM, production, merge or deployment changed.
