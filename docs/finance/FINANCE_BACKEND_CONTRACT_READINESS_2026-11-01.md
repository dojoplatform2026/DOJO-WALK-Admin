# DOJO WALK Admin — Finance Backend Contract Readiness Audit
Date: 2026-11-01
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
PR: #51 (Draft/Open; do not merge or deploy)

## Decision and scope
This is a read-only contract inventory. Per the owner's integration rule, external APIs / provider SDKs / payment integrations are not to be installed or configured now. Prepare and document requirements only. Installation and setup happen together after the DOJO WALK apps and backend are ready, followed by sandbox testing and controlled verification.

No backend source, Firebase configuration, Rules, Functions, production data, payment provider, payout rail, or deployment was changed by this audit.

## Evidence inspected
- Notion: TEAM 01 — Backend & Firebase.
- Notion: Booking API Contract & Callable Implementation Gate (working draft; not approved for production).
- Notion: FIN-001, POL-012, POL-013 and POL-033 (financial planning/policy material; approval state remains unresolved/draft).
- Firebase repository: `functions/src/index.ts` on `main`, blob SHA `2b13994aff949f38e626e1929422e5de84755312`.
- Firebase PR #43: merged into main; Rules and emulator coverage only, with documented limitation for nested custom dateSchedules walks.
- Admin PR #51: Draft/Open; its guardrail explicitly defers new Firebase integration until Admin UI and validation are complete.

## Backend source inventory (verified)
The inspected Firebase Functions entry point exports these five callable functions:
1. `reviewServiceLocationBoundary`
2. `activateServiceLocation`
3. `setServiceLocationStatus`
4. `saveServiceLocationWithNameIndex`
5. `manageServiceLocationImportRun`

These are service-location / hierarchy workflows. The inspected entry point contains no payment, refund, Walker payout, settlement, or finance callable export. A repository code search for the terms `createBookingRequest` and `payment refund payout` returned no matches in the indexed default-branch search. This is a scoped source inspection, not a claim that no related code exists anywhere in all branches or external provider dashboards.

## Finance API contract matrix

| Capability | Backend contract evidence | Admin integration state | Gate |
|---|---|---|---|
| Customer payment initiation / status verification | No finance callable identified in inspected Functions entry point; provider and webhook design not evidenced | Finance screen is prototype-only; no provider-confirmed state | BLOCKED — contract and provider selection/docs |
| Refund request / approval / execution | No refund callable identified in inspected Functions entry point; policy docs remain draft/unapproved | UI actions disabled; no real refund operation | BLOCKED — approved refund policy, authority matrix, provider flow |
| Walker earnings / payout preparation and execution | No payout callable identified in inspected Functions entry point; final rate/bonus model unresolved | Prototype/example data only; no real Walker ledger or payout | BLOCKED — approved rate card, eligibility, weekly cutoff, payout rail |
| Settlement / reconciliation | No settlement or reconciliation callable identified in inspected Functions entry point | Prototype-only reconciliation tab; no bank/provider feed | BLOCKED — provider settlement format, bank evidence, exception workflow |

No callable names, request DTOs, response DTOs, role claims, provider IDs, webhook URLs, or error codes are invented in this matrix. They must be supplied and approved by Backend & Finance before app integration.

## Cross-team contract handoff requirements
For each eventual API, Backend must document:
- Exact callable/endpoint name, version, Firebase region and source commit.
- Purpose and authoritative state transition.
- Request and response schema, including currency minor-unit representation.
- Firebase Auth requirement, custom claim / admin role and geographic scope checks.
- Server-side validation; client fields that are ignored or rejected.
- Error codes and retry guidance.
- Idempotency key, duplicate delivery behavior and concurrency handling.
- Provider webhook signature/status verification where applicable.
- Audit event, maker-checker approval and immutable correction/reversal behavior.
- Emulator tests, role-negative tests, duplicate/retry tests and CI evidence.
- Backward-compatibility notes for Admin, Customer and Partner consumers.

## Known policy decisions and unresolved items
- Cashless customer collection is the operating direction; cash collection is not to be added.
- Weekly Monday Walker payout for the previous verified period has been discussed as the intended operating cadence, but the policy documents still need one approved cutoff, processing window, eligibility and failure/retry rule before automation.
- Refund approval proposal: Central Admin up to ₹2,000; above ₹2,000 Founder/CEO; suspicious cases escalate. Treat as a proposal until the signed approval matrix is approved and represented in backend authorization.
- Walker compensation material contains older proposed hourly / package-pool assumptions. Current product direction discussed separately is a bonus per eligible completed booking. No rate or bonus amount is approved by this audit; do not hard-code historical figures.
- Paytm / PhonePe interest is not evidence of an active merchant account, API credentials, webhook, settlement configuration, refund capability or commercial fee schedule.
- CA/legal review is required for GST/SAC, invoice, TDS, accounting/revenue recognition and Walker legal classification.

## Required sequence (owner's integration rule)
1. Finish and validate all app and backend feature work.
2. Approve the business policies, roles, rate cards and provider choices.
3. Complete and version the API contracts and cross-app compatibility review.
4. Only then install/configure the required provider APIs/SDKs and credentials together in the planned setup phase.
5. Run sandbox/emulator, security, idempotency, refund/payout and reconciliation tests.
6. Complete controlled pilot and written release approval before production enablement.

## Status
- Finance API integration: NOT STARTED (intentionally deferred).
- Provider SDK/API installation: DEFERRED by owner decision.
- Finance backend contract readiness: BLOCKED / documentation only.
- Production finance release: NO-GO.
- Admin PR #51: remains Draft/Open.
- No merge, deployment, Firebase mutation or live financial transaction was performed.

## Next action
Backend & Firebase team: prepare a complete finance API contract proposal and evidence inventory in its own backend planning workflow. Admin team will map approved contracts to the Finance Operations UI only after the system-wide readiness gate is lifted.
