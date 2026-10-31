# POL-007 Founder Decision Register — 2026-10-30

**Status:** Decision worksheet only — NOT APPROVED.
**Policy:** POL-007 — Live Walk & Safe Handover Policy (Notion status: Draft; Founder approval required).
**Scope:** Customer, Partner, Admin, Firebase/backend and Operations.
**Release gate:** NO-GO until required decisions are recorded in the controlling Notion policy, approved by Founder/CEO, implemented and tested.

> This register does not amend POL-007. Options below are decision prompts, not approved policy. No numeric threshold, waiting period, retention duration, or emergency authority is silently selected.

## Decision summary

| ID | Decision | Required approver | Status |
|---|---|---|---|
| D-01 | Tracking phases and visibility window | Founder/CEO + Central Operations | OPEN |
| D-02 | GPS sampling cadence and battery/network behavior | Central Operations + Engineering; Founder approval | OPEN |
| D-03 | Freshness states and stale threshold | Founder/CEO + Central Operations | OPEN |
| D-04 | Accuracy handling | Central Operations + Engineering | OPEN |
| D-05 | Precise route retention and access | Founder/CEO + Privacy/Security owner | OPEN |
| D-06 | Offline start and reconciliation | Founder/CEO + Central Operations | OPEN |
| D-07 | Pickup and handover evidence | Founder/CEO + Central Operations | OPEN |
| D-08 | Customer/recipient unavailable process | Founder/CEO + Central Operations | OPEN |
| D-09 | Emergency exception authority | Founder/CEO + Central Operations | OPEN |
| D-10 | Customer live-location visibility | Founder/CEO + Product/Operations | OPEN |

## D-01 — Tracking phases and visibility window

**Question:** Which operational phases may share precise walker location?

- Option A: Active walk only. Smallest exposure window; does not show approach/return movement.
- Option B: Assigned walker en-route, active walk, and return/handover. More operational visibility; materially expands location exposure and requires clear phase boundaries.
- Option C: A different explicitly named set of phases.

**Required record:** Exact phase names, start/end event for each phase, who can view each phase, and what happens on reassignment, cancellation, pause, incident, and completion.

**Safe engineering constraint pending decision:** Do not expose precise location outside a server-authorized sharing window.

**Founder decision:** ____________________  **Date:** __________

## D-02 — GPS sampling cadence

**Question:** What update interval and/or movement threshold should the Partner app use?

- Option A: Time-based sampling.
- Option B: Distance-based sampling.
- Option C: Combined time + distance policy, with adaptive behavior under battery/network constraints.

**Trade-off:** More frequent samples improve map responsiveness but increase battery, network, storage and privacy costs. Less frequent samples can make movement appear delayed.

**Required record:** Approved interval/distance, maximum upload rate, accuracy metadata, retry/backoff behavior, and whether sampling changes in background.

**Safe engineering constraint pending decision:** Never fabricate/interpolate a GPS point as if it were observed; retain capture time and server receive time separately.

**Founder decision:** ____________________  **Date:** __________

## D-03 — Freshness states and stale threshold

**Question:** After how long without an accepted location update should the UI stop presenting a point as current?

- Option A: One approved threshold for both Customer and Admin.
- Option B: Separate thresholds for Customer and Admin, with the same truthful underlying last-update time.
- Option C: More than two states (for example, current / delayed / unavailable), with explicit boundaries.

**Required record:** Exact duration(s), state labels, transition behavior, and whether a notification/support alert is triggered.

**Safe engineering constraint pending decision:** Always show “last updated” time; never display an old coordinate as a live/current position.

**Founder decision:** ____________________  **Date:** __________

## D-04 — GPS accuracy handling

**Question:** How should location samples with weak accuracy be treated?

- Option A: Accept and visibly mark uncertainty.
- Option B: Keep for diagnostics but do not use as a customer-facing marker.
- Option C: Reject samples beyond an approved accuracy limit.

**Required record:** Accuracy bands, user-facing wording, Admin diagnostics, and behavior when no acceptable sample exists.

**Safe engineering constraint pending decision:** Preserve reported accuracy; do not imply precision the device did not provide.

**Founder decision:** ____________________  **Date:** __________

## D-05 — Route retention and access

**Question:** How long should precise route points be retained, and who may access them?

**Options to compare:** Short operational retention with aggregated/non-precise records retained longer; or a longer precise-route retention period justified by documented safety, dispute and legal needs.

**Required record:** Exact retention periods for raw points and derived summaries; deletion/archive process; authorized roles; audit logging; legal-hold exception; customer access window.

**Safe engineering constraint pending decision:** Least-privilege access, no client-side route edit/delete, and no indefinite precise-location retention by default.

**Founder decision:** ____________________  **Date:** __________

## D-06 — Offline start and reconciliation

**Question:** May a walk start when the device cannot reach the trusted backend?

- Option A: No offline start. Start is shown as confirmed only after server acceptance. Clear but may delay service during outages.
- Option B: Explicit offline-safe procedure, only if separately approved, with local pending state and later reconciliation. More resilient but higher duplicate, fraud and safety risk.
- Option C: Permit offline recording only for non-authoritative diagnostics; operational start waits for server confirmation.

**Required record:** Chosen option, UI wording, reconciliation rules, timestamp semantics, duplicate protection, and escalation if connectivity does not return.

**Safe engineering constraint pending decision:** Never label a locally queued event “server confirmed”; preserve device capture time and server acceptance time.

**Founder decision:** ____________________  **Date:** __________

## D-07 — Pickup checks and safe-handover evidence

**Question:** What must be recorded before start and before completion?

**Pickup evidence to decide:** Dog identity/count, condition/safety check, equipment/leash check, authorized pickup recipient, and acknowledgement.
**Handover evidence to decide:** Dog present and safe, agreed handover point, recipient identity/authorization, acknowledgement method, timestamp, and incident/exception notes.

**Options:** In-app acknowledgement; OTP/verified code; authorized recipient confirmation; photo/evidence only if explicitly approved with privacy controls; or a combination.

**Required record:** Mandatory fields, who confirms each item, failure path, OTP fallback, evidence retention and access.

**Safe engineering constraint pending decision:** No normal completion without backend-validated safe handover; do not collect photos or sensitive evidence unless explicitly approved.

**Founder decision:** ____________________  **Date:** __________

## D-08 — Customer or authorized recipient unavailable

**Question:** What should the Walker do if no authorized person is available at the agreed handover point?

**Options to decide:** Contact customer and Central Operations; remain with the dog while awaiting instructions; transfer only to a pre-authorized alternate recipient; or another explicitly documented safe arrangement.

**Required record:** Approved contact sequence, exact waiting rule (if any), escalation owner, authority to approve alternate arrangements, customer communication, and cost/fee treatment if applicable.

**Safe engineering constraint pending decision:** Walker must not abandon the dog or hand the dog to an unapproved person. Do not invent a waiting limit, fee, or alternate arrangement.

**Founder decision:** ____________________  **Date:** __________

## D-09 — Emergency exception authority

**Question:** Who can authorize a non-standard stop, handover, or other emergency action?

**Required record:** Emergency categories, first-responder actions, decision authority by severity, fallback when Central Operations is unreachable, required evidence, escalation contacts, and post-incident review.

**Safe engineering constraint pending decision:** Preserve the dog's immediate safety; record actor, reason, timestamps and actions; do not let an emergency exception silently rewrite ordinary lifecycle history.

**Founder decision:** ____________________  **Date:** __________

## D-10 — Customer live-location visibility

**Question:** What location information should the customer see?

- Option A: Status + last-updated time, without a precise map.
- Option B: Precise map only during the approved sharing window, with freshness and accuracy cues.
- Option C: Approximate/limited map plus status and last-updated time.

**Required record:** Visibility window, map precision, customer/booking authorization, stale state, stop condition, and support route.

**Safe engineering constraint pending decision:** Customer can access only their own booking's authorized location stream; hide/stop precise sharing immediately when the approved window ends.

**Founder decision:** ____________________  **Date:** __________

## Approval record

All ten decisions remain OPEN until explicitly recorded and approved in the controlling Notion POL-007 page.

- Founder/CEO: ____________________
- Approval date: ____________________
- Notion policy revision / decision reference: ____________________
- Central Operations acknowledgement: ____________________
- Engineering contract version: ____________________

## Implementation gate checklist

- [ ] POL-007 decisions approved in Notion.
- [ ] Shared bookingId / walkId / walkerId data contract approved.
- [ ] Trusted backend owns lifecycle transitions and idempotency.
- [ ] Firestore Rules enforce assignment, customer ownership and City/Zone scope.
- [ ] Location ingestion validates identity, sharing window, timestamps, accuracy and rate.
- [ ] Emulator authorization, rollback and idempotency tests pass.
- [ ] Partner device/background/offline QA passes.
- [ ] Admin and Customer freshness/visibility behavior passes.
- [ ] Emergency contacts, runbooks, monitoring and rollback are ready.
- [ ] Separate release approval recorded.

## Evidence and limitations

- Derived from the POL-007 Draft and the Admin source audit dated 2026-10-30.
- This file is a developer/founder decision aid; it is not a replacement for the controlling Notion policy.
- No policy decision is marked approved here.
- No production Firestore data, Rules, Functions, indexes or deployments were changed.
- PR #51 remains Draft/open; do not merge or deploy based on this worksheet.
