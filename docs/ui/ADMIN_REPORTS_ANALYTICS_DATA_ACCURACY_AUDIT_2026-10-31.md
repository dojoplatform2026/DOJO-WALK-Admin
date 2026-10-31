# DOJO WALK — Admin Reports & Analytics / Data Accuracy Audit
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Scope: read-only source review of report catalog, dashboard data source and tests; Notion policy alignment.

## Executive result
The Reports & Analytics page is a **UI-only report catalog**. It does not query a reporting service, display actual report values, define custom date boundaries, export files or schedule reports. Six report categories are listed, each marked Not connected; Open report and Export controls are disabled.

The Dashboard does contain live Firestore listeners for several headline figures, but these are not a substitute for governed reporting: some queries are unbounded, there is no verified role/city/zone scope, and paid-payment total is a gross sum of payment documents with status `paid`, not a reconciled revenue/profit measure.

**Release assessment: NO-GO for management, finance, performance or city/zone decisions based on Reports & Analytics.** No code was changed and no data export was performed.

## Source inspected
- `lib/features/reports/screens/reports_analytics_screen.dart`
- `test/features/reports/reports_analytics_screen_test.dart`
- `lib/screens/dashboard/dashboard_data_source.dart`
- Related previous source audits: Dashboard operational scope, Finance Operations, Walker Assignment Desk, Walker read scope and access-control governance.

## Verified report-catalog facts
1. Reports screen is a `StatefulWidget` with a local period string defaulting to `Last 7 days`.
2. Period chips are `Last 7 days`, `Last 30 days` and `Custom range`; selection only changes local UI state. No date picker, query boundary or backend request is implemented.
3. Six report cards are present:
   - Booking lifecycle
   - Walker performance
   - Zone readiness
   - Safety & incidents
   - Payments & refunds
   - Support resolution
4. Every card is marked `Not connected`; Open report and Export actions are disabled.
5. Screen text explicitly says KPI values, totals and trends are not fabricated and requires approved data definitions and authorized sources.
6. Export, scheduled reports and data refresh are explicitly disabled pending source definitions, permissions, retention and audit requirements.
7. The test file contains three widget tests: report catalog labels/no fabricated KPIs, local period-chip selection, and 320px narrow viewport rendering. These are presentation tests, not reporting correctness tests.

## Dashboard data accuracy context
The reviewed `FirestoreDashboardDataSource` has these query shapes:
- `countAll(collection)`: unfiltered `.snapshots()` for any supplied collection.
- `countWhere(collection, field, value)`: equality-filtered listener without a date window or pagination.
- `countBookingStatus(label)`: `bookings.where(status, whereIn: aliases).snapshots()`, without a date window.
- `totalPaidAmount()`: queries every `payments` document where `status == paid`, then sums numeric `amount` values client-side.
- `recentBookings()`: `createdAt desc`, limit 8.
- `recentActivity()`: `createdAt desc`, limit 6.

The dashboard audit previously established that all-time paid amount is labelled as gross paid payments; it does not deduct refunds, provider fees, taxes, chargebacks or adjustments. It must not be labelled revenue, net revenue or profit without a reconciled definition. No evidence in this source proves city/zone authorization, server-side aggregation, or financial ledger reconciliation.

## Notion policy alignment
- **POL-033 — Walker Earnings, Payouts, Adjustments & Financial Reconciliation:** Draft — not approved, implemented or tested. Requires backend-authoritative immutable ledger entries, effective-dated earning rules, unique earning/payout identifiers, idempotency, provider verification and reconciliation. Client UI must not create earnings or mark payouts paid.
- **POL-012 — Payment, Refund & Reconciliation:** Draft specification only. Requires payment state distinct from booking state, trusted provider verification, unique transaction references, settlement reconciliation, and no claim of paid status from screenshots or walk lifecycle.
- **POL-034 — Walker Performance, Ratings, Incentives & Disciplinary Management:** Draft — not approved, implemented or tested. Requires balanced evidence-based measures, defined periods/thresholds/sample sizes, contextual review and appeal safeguards. A single low rating or unverified allegation must not drive serious penalties.
- **POL-020 — Data Privacy, Retention & Deletion:** Draft — not approved, implemented or tested. Requires approved retention schedule, least-privilege access, export restrictions, deletion evidence and no invented retention periods.
- **POL-021 — Access Control, Admin Roles & Privileged Account Security:** Draft — not approved, implemented or tested. Requires server-side role/city/zone scope and export permission enforcement; UI hiding alone is not security.
- Policies referenced by report cards (POL-016, POL-026, POL-029, POL-038, POL-040, POL-009, POL-024) are not evidence that corresponding report datasets or workflow controls are implemented.

## Material gaps / risks
1. **No connected report datasets:** no report-specific data source, repository, query, aggregate endpoint or generated report model was found in the inspected report feature.
2. **No true custom range:** period controls only update local selected chip; there is no date-range picker, timezone boundary, inclusive/exclusive rule or backend filter.
3. **No KPI definitions:** formulas, inclusion/exclusion rules, cancelled/rescheduled handling, duplicate occurrence treatment, refunds, fees, tax and time zone are not defined in code.
4. **No walk-occurrence grain:** recurring/multiple-walk bookings need a canonical occurrence ID; booking-level counts may misstate actual completed walks, walker performance and payouts.
5. **No city/zone scope proof:** report cards do not receive role/capability/geographic scope; no evidence of backend scoped aggregates or Rules tests.
6. **Financial misinterpretation risk:** Dashboard paid sum is gross payment amount from paid-status docs; it is not reconciled revenue or profit and may omit refunds, adjustments, provider settlement timing and duplicates.
7. **Performance fairness risk:** no evidence of sample-size, excused-event, data-quality, appeal or context rules in report calculations. Do not rank or discipline walkers from unverified raw metrics.
8. **Export/privacy risk:** no export service, field allowlist, redaction, authorization, purpose/reason, audit event, watermark, expiry or download retention controls.
9. **Freshness/reliability risk:** no generated-at timestamp, data-through watermark, stale/error state, reconciliation status or source lineage for reports.
10. **No report correctness tests:** existing tests verify catalog display, local chip selection and viewport only; no formula, date boundary, scope, reconciliation, export or security tests were executed.

## Required cross-team contracts before implementation
- Team 01: versioned reporting API/read-model contracts, trusted server-side aggregates, canonical walk-occurrence grain, pagination and index definitions.
- Finance: approved definitions for gross collections, refunds, net collections, provider fees, tax, walker payable, payout status, adjustments and reconciliation cut-off.
- Operations: approved booking, cancellation, incident, support and zone-readiness metric definitions, owner and reporting cadence.
- Walker Management: approved performance dimensions, fair sample-size thresholds, excused events, data correction, appeal and incentive separation.
- Access/Security: capability and city/zone scoped report access; export-specific permissions; server-side enforcement and negative tests.
- Privacy: report field classification, minimization, aggregation thresholds where needed, approved retention and export lifecycle.
- QA: deterministic fixture-based formula tests, date/timezone boundaries, duplicate/replay tests, scope isolation, permission denial, stale source indicators, export audit and reconciliation comparison.

## Safe Admin-only next steps
- Keep report cards explicitly Not connected; keep Open, Export, scheduled reports and refresh disabled.
- Do not add mock KPIs or present Dashboard gross paid amount as revenue/profit.
- Do not implement client-side aggregation as a substitute for trusted reporting endpoints.
- After contracts are approved, connect one report at a time with formula specification, source timestamp, scope, loading/empty/error/permission-denied states and tests.
- Do not change Firebase schema, Rules, indexes, Functions, Storage, finance provider configuration or production data from this Admin repository.

## Verification boundary
Static source and Notion policy inspection only. The report widget test file was read but not executed in this audit. No Flutter tests, emulator, Rules/Functions tests, report calculation fixtures, finance reconciliation, export/download, scheduled report, or production data checks were run. No application code was changed.

## Decision
**NO-GO for production reporting and exports** until report definitions, canonical occurrence/ledger sources, trusted scoped aggregates, finance reconciliation, privacy/export controls and automated correctness/security tests are approved and independently evidenced. Keep PR #51 open/draft; do not merge or deploy based on this audit.
