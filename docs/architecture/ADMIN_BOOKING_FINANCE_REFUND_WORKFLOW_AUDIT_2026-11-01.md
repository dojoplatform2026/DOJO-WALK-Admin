# Admin Booking, Finance & Refund Workflow Audit — 2026-11-01

## Scope
Read-only source review on Admin branch `ui/notion-brand-foundation-2026-10-28`.

Reviewed:
- `lib/screens/bookings/bookings_screen.dart`
- `lib/screens/bookings/booking_data_source.dart`
- `lib/screens/bookings/booking_status_helper.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/dashboard/dashboard_data_source.dart`
- `docs/STEP_198_WALKER_ASSIGNMENT_PATH_AUDIT.md`
- `docs/STEP_199_ASSIGNMENT_WRITER_DEEP_SEARCH.md`
- `docs/STEP_200_BOOKING_ASSIGNMENT_SECURITY_CONTRACT.md`

This audit did not modify runtime code, Firebase, rules, data, or deployment.

## 1. Booking Management

### Observed
- `BookingsScreen` uses `FirestoreBookingsDataSource.watchBookings()`, which subscribes to `bookings` snapshots and maps them to read-only `BookingRecord` objects.
- UI supports search, status filtering, and display of customer, walker, dog, service, preferred time, created time, walk time, amount, and cancellation request metadata.
- Cancellation display reads `cancelRequest.status`, `requestedBy`, and `requestedAt`; no approve/reject/cancel action or write operation is present in the inspected screen.
- The booking data-source interface exposes only `watchBookings()`; it has no assignment, cancellation, refund, or status mutation method.
- Status helper normalizes/display-maps lifecycle labels; display mapping is not a lifecycle transition implementation.

### Assignment gate
- Existing Step 198/199/200 evidence says no authoritative assignment writer was found in inspected Admin, Firebase Functions, Partner, and Customer paths. Admin booking UI reads/displays assignment only.
- Step 200 remains a planning contract: trusted server-side assignment, eligibility, concurrency/idempotency, audit and Emulator tests are requirements, not proof of implementation.
- Do not add a client-side `walkerId` write or infer a manual/automatic assignment path. Confirm whether an external backend or manual workflow exists and get the canonical Team 01 role/API contract first.

## 2. Finance / Payment Dashboard

### Observed
- Dashboard exposes a revenue card and a Payment Failures alert count.
- `FirestoreDashboardDataSource.totalPaidAmount()` queries `payments` where `status == 'paid'`, sums numeric `amount` fields, and emits one gross total.
- Dashboard labels this value **Paid Payments (All Time)** and explicitly explains **Gross paid amount; refunds and fees not deducted**.
- Payment failures alert counts documents in `payments` where `status == 'failed'`.

### Gaps / risks
- This is a gross paid-payment aggregate, not net revenue, settlement, wallet balance, walker payout, tax, fee, or reconciliation.
- The inspected query does not join refunds, reversals, chargebacks, payment gateway settlement IDs, or payout records.
- It does not establish currency handling, duplicate-payment/idempotency protection, or whether amount is stored in rupees vs paise. These require the authoritative payment schema and gateway contract.
- Dashboard currently reads whole collections for counts and paid total; data volume, query cost, index needs, and role/scope constraints require separate review before production scale.

## 3. Refund Workflow

### Observed
- Repository code search and the inspected Booking/Dashboard screens did not identify a dedicated Admin refund screen/service or a refund action in these flows.
- Booking screen displays the booking's cancellation request metadata only.
- Dashboard gross paid amount explicitly excludes refunds; no refund deduction/reconciliation is present in this calculation.

### Not established
- No claim is made that refunds are absent from every repository or external gateway. The current bounded Admin source search does not establish an authoritative refund workflow.
- Refund approval thresholds, approval roles, gateway API, refund status state machine, idempotency key, audit schema, and customer notification contract are not confirmed by this audit.

## 4. Required gates before implementation
1. Confirm the actual payment provider and authoritative payment/refund collections and fields from Team 01; do not assume Paytm/PhonePe or any gateway contract from UI.
2. Define payment lifecycle: initiated, pending, paid, failed, reversed/partially refunded/refunded, and settlement/reconciliation states as applicable.
3. Define refund lifecycle and authorization matrix, including the approved amount thresholds and escalation path; align with current company policy before coding.
4. Refund must be initiated by trusted server code, never by a direct Admin client write; use idempotency and immutable audit records.
5. Verify booking cancellation policy and refund eligibility are separate decisions; cancellation request display is not refund approval.
6. Add Emulator/integration tests for unauthorized roles, amount threshold boundaries, duplicate requests, gateway timeout/retry, partial/full refunds, failed refunds, audit atomicity, and customer-visible status.
7. For assignment, resolve Step 200 Gate 0 and approve the canonical assignment contract before adding UI controls.

## Status
- Admin source inspection: COMPLETE for listed files.
- Booking list/display: PRESENT.
- Cancellation request display: PRESENT; action workflow NOT FOUND in inspected screen/service.
- Booking assignment writer: NOT FOUND in inspected paths; remains a separate gated contract.
- Finance dashboard gross paid aggregate: PRESENT.
- Net revenue / settlement / payout reconciliation: NOT ESTABLISHED.
- Dedicated refund workflow: NOT FOUND in inspected Admin paths; not proof of organization-wide absence.
- Relevant tests executed by this audit: NO.
- Emulator/gateway evidence: NOT RUN / NOT PROVIDED.
- Firebase changes, production data, merge, deployment: NONE.
