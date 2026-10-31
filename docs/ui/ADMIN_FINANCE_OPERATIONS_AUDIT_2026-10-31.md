# DOJO WALK Admin Finance Operations Audit — 2026-10-31

**Repository:** `DOJOWALK/DOJO-WALK-Admin`  
**Branch:** `ui/notion-brand-foundation-2026-10-28`  
**Scope:** Admin finance UI, available tests, and Notion finance policy alignment. Source review only; no financial mutation or backend work.

## 1. Executive result

**Finance Operations is a UI-only prototype, not an operational finance module.** The current screen uses hard-coded illustrative records and explicitly states that no gateway, settlement, refund API, or payout provider is connected. Verify/Approve/Reconcile controls are disabled. This is the correct fail-closed posture while policies and backend contracts remain unapproved.

No payment, refund, payout, ledger, reconciliation, or customer balance data was changed.

## 2. Source files inspected

- `lib/features/finance/screens/finance_operations_screen.dart`
- `test/features/finance/finance_operations_screen_test.dart`

Candidate service/model/payment/refund/payout paths checked under the expected feature directories were not found at those paths. The current Finance screen contains its own private `_FinanceRow` model and hard-coded in-memory example lists; no finance service/model abstraction was found in the inspected paths.

### UI facts

- Four tabs: Payments, Refunds, Walker payouts, Reconciliation.
- Example IDs are explicitly suffixed `EX`; example amounts/statuses are not real transactions.
- Screen warns that provider confirmation is not connected and cash is not accepted.
- All financial mutation controls are disabled.
- Test file checks cashless messaging, example-only data, disabled controls, tab switching, and a 360px viewport.
- These are source/test assertions only. The audit did not execute Flutter tests or CI for a new commit.

## 3. Notion policy alignment

Pages reviewed:
- POL-012 — Payment, Refund & Reconciliation Policy (Draft; last fetched 2026-10-29)
- POL-013 — Walker Earnings & Payout Policy (Draft — not approved/implemented/tested; fetched 2026-10-25)
- POL-033 — Walker Earnings, Payouts, Adjustments & Financial Reconciliation Policy (Draft — not approved/implemented/tested; fetched 2026-10-30)
- POL-030 — Pricing, Packages, Discounts & Payment Controls Policy
- POL-029 — Booking Cancellation, Rescheduling, No-Show & Refund Policy (Draft — not approved/implemented/tested)
- FIN-001 — Master Financial Blueprint (Consolidated Draft; not Founder-approved, not CA/legal-cleared, not implemented/tested)

### Payment collection

POL-012 requires cashless collection, one approved gateway first, server-side order creation and trusted provider verification/webhooks, provider secrets held only on backend/secret manager, and settlement reconciliation. Paytm/PhonePe are intended UPI/payment options, but provider selection, merchant onboarding, production credentials, fee terms and settlement account are not confirmed. A customer screenshot or client-side success message must never mark a payment paid.

POL-012 distinguishes booking state from payment state and requires separate gross customer receipts, provider fees, net settlement, refunds, adjustments and outstanding balance. Auto-Pay is removed; the documented direction is manual customer-initiated payment. No coupon workflow is allowed; approved discounts remain separate from money received.

### Refunds

POL-012 requires a request with booking/payment reference, amount, reason and evidence; approval separate from provider initiation/completion; refund amount capped by verified refundable amount; provider evidence before showing REFUNDED; idempotency and immutable audit trail.

**Gap:** POL-012 still says exact refund/write-off/waiver authority limits remain a Founder/Finance decision. The Admin prototype displays an example ₹2,000 routing threshold but that is illustrative UI text, not an approved or enforced authority matrix. The ₹2,000 Central Admin / above-₹2,000 Founder split must be formally reflected in an approved policy and enforced by backend authorization before controls are enabled.

### Walker earnings and payout

POL-013 and POL-033 require a trusted booking/walk-linked ledger, approved effective-dated rate card, unique earning entries, trusted completion evidence, maker-checker approval, provider-confirmed payout status, safe retries/idempotency, masked payout destination, immutable adjustments, disputes and reconciliation. Customer payment and walker payout are separate ledgers.

**Important policy mismatch:** POL-013 explicitly says no earning rate, company commission, payout schedule, minimum payout or payout method is approved by its draft. POL-033 likewise leaves the earning model, rate card, payout frequency/cutoff, payout rail, approval limits and incentives for Founder/Finance decision. The operational direction discussed elsewhere (weekly Monday payout for the prior verified period, hourly base and a per-completed-booking incentive) is not yet reflected as an approved, versioned rate/payout rule in these policy pages. Do not hard-code it from chat context into production.

### Cancellation/refund dependency

POL-029 remains Draft and leaves cancellation cutoffs, no-show evidence, fee rules, partial-refund matrix and exception authority for approval. Therefore refund eligibility and walker earning treatment for cancellation, no-show, partial walk, emergency interruption and replacement cannot safely be automated yet.

## 4. Critical implementation gaps / release blockers

1. **No trusted payment gateway integration** evidenced in this Admin screen; no provider-backed transaction ledger or verified webhook state.
2. **No refund workflow**: no real request/approval/provider-initiation/provider-success/reconciliation state machine.
3. **No payout workflow**: no earning ledger, rate-card versioning, payout batch, maker-checker, provider response or safe retry service evidenced in this screen.
4. **No finance data source**: UI records are static examples, not live Firestore/API records.
5. **No role/scope authorization evidence**: disabled buttons are not authorization. Backend must enforce who can view, verify, approve, adjust, export and reconcile.
6. **No reconciliation evidence**: no imported provider settlement/payout statement, matching engine, exception owner, or period-close record.
7. **No approved authority/rate schedule**: refund thresholds, earnings model, payout timing, incentives, fees/tax and exception limits need formal approval.
8. **No acceptance-test evidence** for webhook forgery, duplicate callbacks, concurrent updates, refund/payout idempotency, unauthorized access, maker-checker, failed payout recovery, settlement mismatch or end-to-end pilot.

## 5. Required cross-team contracts (do not implement in Admin repo)

Team 01 / Backend & Firebase must provide versioned, tested contracts for:
- Provider order creation, signature/webhook verification, idempotent transaction ingestion, payment status transitions and customer receipt.
- Refund eligibility decision, approval authority, provider refund initiation, provider status polling/webhook, completion evidence and reversal/failure handling.
- Authoritative per-walk completion eligibility and immutable earning ledger using effective-dated approved rate-card versions.
- Payout batch preparation, independent approval, payout provider execution/status, ambiguous-timeout resolution and safe retry.
- Scoped finance read projections, append-only audit events, maker-checker and server-side authorization.
- Settlement reconciliation (gross, fees, net settlement, refunds, chargebacks, adjustments) and owned exception queues.

Admin may consume these contracts and present approved actions; it must not invent finance calculations or use client-side Firestore writes as financial authority.

## 6. Safe next implementation sequence

1. Founder/Finance approve POL-012, POL-013/POL-033, POL-029 and the refund/payout authority matrix; CA/legal clearance where required.
2. Publish approved rate-card, incentive, refund and payout schedule versions with effective dates.
3. Team 01 implements and emulator-tests trusted payment/refund/earning/payout/reconciliation APIs and Rules.
4. Admin adds read-only ledger/exception views against the versioned contracts.
5. Add maker-checker UI only after server-side capability checks and audit tests pass.
6. Run sandbox payment and payout pilots; reconcile provider statements end-to-end before production activation.

## 7. Safety decision

**NO-GO for live payment verification, refunds, walker payouts, financial adjustments or reconciliation actions from Admin UI.** Keep all mutation controls disabled. The existing example-only prototype is appropriate as a visual shell; do not label it operational or complete.

## 8. Change boundary

This audit changed no application code, Firebase project/configuration, Firestore data/Rules/indexes, Functions, payment provider, production environment, merge state or deployment. No PR merge or deployment was performed.
