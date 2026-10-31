# POL-007 Implementation Gap Audit — 2026-10-30

**Status:** Read-only policy-to-code review; no production implementation approval.
**Controlling Notion policy:** POL-007 — Live Walk & Safe Handover Policy (Draft; Founder approval required).
**Related readiness record:** Cross-App Live Tracking & Booking Data Contract — Readiness (Draft).
**Repositories:** DOJO-WALK-Admin, DOJO-WALK-Partner, DOJO-WALK-Firebase.

## 1. Decision

**NO-GO for production live-walk integration.** POL-007 is still Draft and explicitly requires Founder approval. The current Partner screen's client-side start/completion behavior and the Admin/Partner GPS source mismatch leave multiple policy requirements unproven.

This document does not approve a schema, state names, thresholds, or production changes.

## 2. Policy-to-source gap matrix

| POL-007 requirement | Source evidence inspected | Gap / acceptance condition |
|---|---|---|
| Only assigned, approved walker starts | Partner Live Walk screen checks signed-in user for completion writes; no server-authoritative assigned-walker check demonstrated in the inspected start flow | Trusted backend must verify active assignment and walker approval at start |
| Booking active and not reassigned | Partner screen receives bookingId but no trusted start precondition shown in inspected screen | Reject cancelled, terminal, stale or reassigned booking |
| Pickup checks before start | Screen's GPS/start path does not demonstrate all required dog identity, authorized recipient, safety/equipment acknowledgements as server-accepted evidence | Define exact checklist and server acceptance payload |
| Duplicate start protection | No stable idempotency key/server command evidenced in inspected screen | Retry must create one start event and one walk |
| Server-authoritative lifecycle | Partner completion screen writes completed walk document and booking status client-side | Move authoritative transition to trusted backend; rules must reject direct bypass |
| Truthful live GPS | Partner accumulates GPS route in memory; Admin reads currentLocation and walk_locations | Canonical transport must be approved and writer/reader aligned |
| GPS freshness | Admin marker parser reads coordinates without capture/receive freshness metadata | UI must label current/delayed/unavailable using approved threshold |
| Correct walk association | Partner generates walks/{walkId} and stores optional bookingId separately; Admin route query filters by walkerId only | Bind each point to walkId + bookingId + walkerId; query a specific authorized active walk |
| Safe handover | Partner has return-location check and OTP fallback paths, but inspected client screen does not demonstrate server validation of authorized recipient/evidence | Backend validates recipient/handover evidence before completion |
| Missing booking reference | Partner completion code conditionally writes booking update only if bookingId is present, while still writing completed walk document | Block orphan walk in normal flow; any manual exception must be explicit, audited and approved |
| Duplicate completion | No trusted idempotent completion command evidenced in inspected screen | One completion event, notification and payout under retries |
| Area-scoped Admin | Admin UI screen reads online walkers and route data; UI-level filtering is not authorization evidence | Firestore/backend must enforce assigned City/Zone scope |
| GPS gaps / background / offline | In-memory route and device stream are visible; device background/retry behavior not proven by source audit | Device QA and offline reconciliation required; never fabricate points |
| Tracking stop | Partner cancels stream when ending walk/screen disposal | Server must enforce sharing-window end and reject later points for terminal walk |
| Incident priority | POL-007 requires emergency route and safe handover | Emergency flow, local contacts and tested exception authority still need evidence |

## 3. Exact decisions POL-007 leaves open

Do not invent these values or behaviors in code. Founder/Operations approval is required:

1. **Tracking phases:** Is sharing limited to active walk, or may it include en-route/return phases?
2. **Sampling cadence:** Approved GPS update interval/distance policy and battery/network trade-off.
3. **Freshness threshold:** At what elapsed time does Admin/Customer UI change from current to delayed/unavailable?
4. **Accuracy policy:** Which accuracy bands are accepted, displayed as uncertain, or rejected?
5. **Route retention:** How long precise points remain available, and which roles can access them?
6. **Offline policy:** Whether an offline start is prohibited or allowed under a separately approved procedure; how later reconciliation is labeled.
7. **Handover evidence:** Exact authorized-recipient verification and acknowledgement method; OTP use and fallback.
8. **Customer unavailable:** Approved waiting/escalation procedure and authority for alternate recipient/return.
9. **Emergency exception:** Who may authorize a non-standard handover or stop, and what evidence is mandatory.
10. **Customer visibility:** Whether route/activity summary and precise live location are shown, and during which window.

## 4. Safe technical target — subject to approval

Keep the concepts separate:
- Booking identity: bookingId.
- Operational walk identity: walkId.
- Actor identity: walkerId.
- Lifecycle: server-accepted events/transitions.
- Live GPS: timestamped location samples tied to the active walk.
- Route archive: retained route history under an approved retention policy.
- Incident: separate linked record, not silently overwritten by ordinary completion.

Each accepted location sample should be attributable to the authenticated assigned walker and the active booking/walk, include coordinates, accuracy, device capture time and server receive time, and be rejected after the sharing window/terminal state. A fast current-marker projection may be maintained, but it must carry freshness and the same identity linkage.

Admin access must be server-scoped by assigned City/Zone. Customer access must be limited to their own booking. Partner access must be limited to their assigned active walk. Historical route data should be immutable to clients.

## 5. Required test gates

### Firebase Emulator / backend
- Wrong/unassigned walker cannot start, pause, resume, publish location or complete.
- Cancelled/reassigned booking cannot start under stale assignment.
- Missing bookingId and missing pickup checks are rejected.
- Duplicate start/completion retries are idempotent.
- Unauthorized recipient/handover is rejected.
- Location writes with wrong walkerId, bookingId or walkId are denied.
- Location writes after terminal state or approved sharing window are denied.
- Invalid coordinates, poor accuracy, timestamp skew, replay and excessive rate are rejected or explicitly handled.
- Customer cannot read another customer's location.
- Area-scoped Admin cannot read another City/Zone.
- Historical GPS cannot be edited/deleted by clients.
- Incident path remains usable when normal completion is blocked.

### App/device QA
- Permission granted/denied/permanently denied; GPS disabled; timeout.
- App background, OS battery restrictions, app termination/restart.
- Network loss and retry; server-confirmed versus locally queued state.
- Stale/delayed/unavailable labels; no stale marker presented as live.
- Safe handover, unavailable recipient, OTP fallback and emergency route.
- Stop tracking after the approved sharing window.

## 6. Implementation sequence

1. Obtain Founder approval for POL-007 and resolve the ten policy decisions above.
2. Confirm canonical Firestore Rules source and trusted backend ownership.
3. Specify the shared booking/walk/location data dictionary and lifecycle transition table.
4. Implement trusted start, location ingestion, pause/resume (if approved), and completion commands in an isolated Emulator environment.
5. Add Rules/Functions Emulator authorization and idempotency tests.
6. Update Partner writer and Admin reader to the same contract.
7. Add Customer live view only after access and freshness tests pass.
8. Complete device QA, operational training, incident contacts, monitoring and rollback plan.
9. Request separate release approval; do not deploy automatically after tests.

## 7. Evidence and limitations

- This is a static source/policy comparison; no production Firestore reads or writes were performed.
- The Admin/Partner writer-reader mismatch is a source-level finding, not proof about all deployed services or runtime data.
- No app source, Firestore Rules, Functions, indexes, production data or deployment configuration was changed by this audit.
- Do not claim live tracking or safe-handover integration is complete.
- PR #51 remains Draft/open; no merge or deployment.


## 8. FlutterFire integration harness status — 2026-10-30

- The Android integration test currently exercises the real `WalkerAdminService` against Auth + Firestore Emulators for the unauthorized-user/no-admin-record denial path only.
- It does **not** yet prove the successful Super Admin path, transaction rollback in FlutterFire, or production behavior.
- Previous Android attempt on workflow run `41008854821` was cancelled before a test result was produced; this is not a passing test.
- The cancelled job was explicitly re-run. The latest observed job ID was `123930024557`; at the time of this update, emulator dependency installation was still in progress and the integration test had not started.
- Updated this integration workflow's checkout, setup-java and setup-node actions from major version 4 to major version 5 in commit `444e9c1644ce183fefc397966e0d54fd8918c2c0`.
- Re-check the new workflow attempt and inspect the exact test output before claiming PASS.
- No production Firebase configuration or data was touched.
