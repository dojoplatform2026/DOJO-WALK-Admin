# DOJO WALK Admin — Finance Operations Module Audit
Date: 2026-11-01

## Scope and evidence
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- Screen: `lib/features/finance/screens/finance_operations_screen.dart`
- Tests: `test/features/finance/finance_operations_screen_test.dart`
- Requirements reviewed: FIN-001, POL-012, POL-013 and POL-033 in Notion.
- Audit type: source and test inspection only; no provider, bank, live Firestore or payout operation was invoked.

## Current implementation finding

The Finance Operations screen is a clearly labelled UI-only prototype. It contains four tabs:
1. Payments
2. Refunds
3. Walker payouts
4. Reconciliation

Displayed records use EXAMPLE IDs and hard-coded values. The screen explicitly says provider confirmation is not connected and example statuses are not real transactions. Verify, Approve and Reconcile buttons are disabled. The UI does not claim that a payment, refund, payout or settlement has been performed.

Existing tests cover the prototype disclaimer, cashless principle, disabled mutation controls, tab switching and a narrow mobile viewport. An additional regression test is being added to exercise all four tabs at 360px width.

## Policy alignment

- Cashless-only customer collection is reflected in the UI; cash must not be accepted.
- Customer collection and Walker payout are separate financial flows.
- Client-side events, screenshots and walker reports must not establish payment success.
- Refund request, refund approval and verified refund completion must remain separate.
- A Walker earning requires trusted completed-Walk verification and a unique Walk ID; duplicate events must not create duplicate ledger entries.
- Payout status must become paid only from trusted provider/bank confirmation or an evidence-backed controlled reconciliation.
- Failed/ambiguous payouts must remain visible and retry-safe; never retry an unknown provider outcome without checking status.
- Reconciliation differences must create owned, evidenced exceptions, not silent balance edits.
- Financial records need least-privilege scope, maker-checker for defined high-risk actions, append-only adjustment history and auditable exports.

## Decisions and document inconsistencies to resolve before implementation

1. POL-033 and FIN-001 remain draft / not approved / not implemented / not tested. The UI prototype is not a production finance module.
2. The saved operating direction discussed for Walker payout is weekly Monday for the previous period's verified completed walks. POL-013/POL-033 still list payout frequency, cutoff and processing targets as unresolved. The canonical approval record and effective date must be reconciled before any payout automation.
3. Current user direction in the operating discussion moved away from an hourly incentive and toward a separate bonus for each completed eligible booking. Older FIN-001/POL-033 material still contains a proposed ₹40-per-walk base and package-level bonus-pool examples. These are not safe to hard-code as current rules; Finance/Founder must reconcile the current rate card, bonus eligibility, amounts, rounding and effective date in one approved version.
4. Refund authority proposal in the operating model is Central Admin up to ₹2,000, above ₹2,000 Founder/CEO, with suspicious cases escalated. Treat it as a proposed authority matrix until the signed approval matrix and backend enforcement are confirmed.
5. Customer gateway intentions (Paytm/PhonePe) do not prove that a merchant integration, webhook verification, settlement feed or refund rail is configured. Provider contracts and test/sandbox evidence are still release dependencies.
6. Tax, GST/SAC, TDS, Walker classification, accounting revenue recognition, refund entitlement and legal terms require qualified India CA/legal review. Planning calculations must not be presented as audited revenue or net profit.

## Required next implementation gates (not started by this audit)

### Gate A — Canonical business approvals
- Publish one effective-dated approved customer payment and refund matrix.
- Confirm the refund ₹2,000 approval boundary and fraud escalation.
- Reconcile Walker earning base, per-booking bonus, payout Monday cutoff, failed-payout handling and dispute/hold rules.
- Confirm Paytm/PhonePe merchant setup, supported transaction types, settlement access and refund behavior.

### Gate B — Backend contract and security
- Obtain Team 01 versioned contracts before connecting Admin.
- Verify callable names, region, payloads, roles, error codes and emulator revision.
- Confirm server-side payment verification, webhook signature validation, idempotency, ledger immutability, transaction concurrency, payout confirmation and reconciliation ownership.
- Enforce geographic and role scopes on the backend; UI visibility alone is not authorization.

### Gate C — Admin read-only integration first
- Replace hard-coded examples only after a read-only, permission-checked contract is approved.
- Provide explicit loading, empty, permission-denied, offline, stale-data and failure states.
- Mask payout destination data and audit all financial exports.
- Keep all financial mutation controls disabled until backend authorization and maker-checker contracts are tested.

### Gate D — Controlled financial pilot
- Run sandbox tests for duplicate payment callbacks, forged callbacks, duplicate refunds, ambiguous payout timeouts, failed payouts, reconciliation mismatches and unauthorized access.
- Reconcile provider receipts, customer entitlements, verified completed Walk IDs, Walker earnings, refunds, payout batches and provider/bank confirmations.
- No production finance release until Founder, CA/legal/provider and technical sign-offs are evidenced.

## Current verdict

**Prototype UI: source-reviewed. Production finance readiness: NO-GO.**

No live payment, refund, payout, bank settlement, Firestore mutation, Firebase Rules/Functions change, main-branch change, merge or deployment was performed by this audit.
