# DOJO WALK Admin — Walker Management & Assignment Desk Cross-App Audit

- Date: 2026-10-31
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (keep Draft / open)
- Audited Admin head: `9e17a77d48edec413dd4d0e2a0c3e214dc3d3918`
- Scope: Walker Management UI/service and the cross-app booking assignment/offer boundary.
- Safety: Source-only audit. No Firebase repository, Firestore data/rules, Partner/Customer source, production, merge, or deployment changed.

## 1. Exact-head Admin validation

GitHub Actions run `41190556747` completed with conclusion `success` for the exact Admin head `9e17a77d48edec413dd4d0e2a0c3e214dc3d3918`. The workflow is the consolidated Analyze + full Flutter tests + Flutter Web build. This is an exact-head CI result; it does not certify backend integration, production data, or visual/device QA.

## 2. Walker Management — current implementation

Verified in:
- `lib/features/walkers/screens/walker_management_dashboard_screen.dart`
- `lib/features/walkers/services/walker_admin_service.dart`
- `lib/features/walkers/models/walker_admin_model.dart`
- `lib/features/walkers/utils/walker_admin_helpers.dart`
- `test/features/walkers/walker_management_dashboard_screen_test.dart`

Confirmed:
- The dashboard accepts optional read-only walker and running-walker streams for tests.
- Production streams are initialized and cached in `initState`; search/tab rebuilds do not create a new stream from the nested builder.
- The error panel includes Retry; retry recreates streams and performs no Firestore write.
- Search hint now describes name, phone, email, ID, location and status.
- Widget tests cover populated list/count, email/location search, Running, Available eligibility, Verification vs Training Required, no-match, loading, generic stream error/Retry, and viewport widths 320/360/390/768/1280.
- The production service still subscribes to the complete `walkers` and `bookings` collections. The bookings stream is used to derive running walker IDs from booking status + `walkerId`.
- Account eligibility is only: normalized `status == approved`, `verificationStatus == verified`, `isApproved == true`, and `isActive == true`. It does not prove schedule availability, service-zone membership, capacity, booking conflict freedom, or GPS freshness.
- Running status currently recognizes `in_progress`, `active_walk`, `walking`, and `walk_started`.

Risk boundary:
- Full-collection reads remain a privacy, rules-scope, cost and scale concern. Do not solve this by broadening Firestore access or adding client-side filters as authorization. Any scoped query/projection requires an approved canonical schema, indexes and Rules contract.
- The Available tab must not be presented as a guaranteed bookable slot.

## 3. Assignment Desk — cross-app source findings

Partner source revision inspected: `DOJOWALK/DOJO-WALK-Partner` branch `audit/partner-flow-2026-10-31`, commit `276e922f00ec7524e86d99afc59ae7a26b184ad8`.

Partner audit documents inspected:
- `docs/architecture/PARTNER_BOOKING_OFFER_ASSIGNMENT_ACCEPTANCE_AUDIT_2026-10-31.md`
- `docs/architecture/PARTNER_HOME_BOOKING_SCHEDULE_CONTRACT_AUDIT_2026-10-31.md`
- `docs/architecture/PARTNER_AVAILABILITY_SCHEDULE_POLICY_AUDIT_2026-10-31.md`

Confirmed source-level gaps:
1. Customer creates parent bookings with `status: pending` and `walkerId: null`; schedule intent is represented through `scheduledAt`, `preferredTime`, `walkSchedules`, `dateSchedules`, `selectedDates`, and/or regular-booking templates.
2. Partner Home queries bookings by `walkerId == current UID`, then selects today's work using top-level `date` and sorts by `startTime`. The inspected Customer writer does not write top-level `date` or `startTime`. A fallback to `scheduledAt` alone would not model recurring or multiple-walk-per-day occurrences.
3. Partner's Walk Details action writes `bookings/{bookingId}.status = accepted` when the walker taps Navigate to Pickup. It does not show a separate offer Accept/Decline action or validate offer ID/expiry/current assignment at that boundary.
4. The inspected Firebase Functions entry point did not expose a booking offer/assignment/acceptance callable. Admin walker service handles walker lifecycle decisions and reads bookings; no assignment transaction was found in the inspected Admin service.
5. Existing rules/source evidence allows constrained admin assignment-field writes and assigned walker lifecycle updates, but does not establish a concurrency-safe offer acceptance workflow. Deployed rules/functions were not verified by this source audit.
6. The Partner Schedule tab is a placeholder rather than an assigned-occurrence calendar; Working Schedule stores availability on the walker profile. Availability is not proof of confirmed work.

These are scoped source findings, not proof that no separate external or deployed service exists.

## 4. Policy and security gate

The Partner audit records POL-026 as Draft / not approved. Therefore Admin must not add a client-only Assign, Accept, Decline, Reassign or Confirm action, and must not write `walkerId`, `assignedAt` or booking status to simulate assignment.

Before implementation, the owner/backend team must confirm:
- whether an external/manual assignment process already exists;
- manual, automatic or hybrid assignment intent;
- authoritative per-walk occurrence model for one-time, selected-date, recurring and multiple-walk-per-day bookings;
- stable occurrence and offer IDs, offer expiry, retry/no-response/decline states and escalation;
- exact eligibility fields for approved/active/trained walker, zone coverage, schedule, leave, conflicts and capacity;
- trusted server-side atomic/idempotent assignment and acceptance transaction;
- Admin role authorization, audit event schema and client Firestore Rules restrictions;
- approved POL-026 ranking, timeouts, attempt limits and Central escalation ownership.

## 5. Admin implementation boundary / next sequence

1. Keep Walker Management read-only for assignment purposes; existing walker approve/reject/suspend/reactivate controls remain governed by their separate authorization and policy contract.
2. Do not add an Assignment Desk screen until the authoritative offer/occurrence API contract is approved by Backend, Customer, Partner and Admin teams.
3. Once approved, Admin should display server-authoritative occurrence/offer states and expose only backend callable actions permitted to the actor's role. It must not implement assignment selection or concurrency control in the client.
4. Replace full-collection running-booking reads only after the canonical occurrence query/projection and least-privilege Rules/indexes are agreed.
5. Add cross-app emulator tests for duplicate/concurrent offers, expiry, decline, no response, inactive/unapproved/out-of-zone walker, recurring occurrence isolation, and audit history before release.

## 6. Status

- Walker Management UI source audit: updated against current PR head.
- Walker Management widget tests: present; exact-head consolidated CI succeeded.
- Full-collection read-scope/performance review: OPEN.
- Canonical assignment writer / Assignment Desk: NOT FOUND in inspected Admin/Partner/Firebase paths; external/deployed service not ruled out.
- POL-026: Draft / not approved according to the inspected Partner audit.
- Backend integration, production verification, visual/device QA, PR merge and deployment: NOT performed.
