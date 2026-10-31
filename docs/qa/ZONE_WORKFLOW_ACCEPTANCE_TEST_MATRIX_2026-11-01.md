# DOJO WALK Zone Workflow — Acceptance Test Matrix

- Date: 2026-11-01
- Related audit: `docs/architecture/ADMIN_ZONE_UI_CALLABLE_CONTRACT_AUDIT_2026-11-01.md`
- Status: **PLANNED — NOT EXECUTED**
- Scope: QA criteria only. No API wiring, Firebase changes, merge or deployment.

## 1. Preconditions and authority

The current Admin Create Zone screen uses sample hierarchy data and local-only polygon state. Save Draft and Submit for Review are disabled. The Admin service exposes callable-shaped methods, but the callable map is only source-level evidence from a Draft Firebase branch. It is not an approved/deployed contract.

Before implementation, Backend/Firebase and product governance must approve the canonical callable names, request/response/error envelopes, role claims and scopes, authoritative hierarchy IDs, geometry limits/canonicalization/hash rules, revision semantics, and reactivation state machine.

Do not mark any scenario PASS until it has run against an identified emulator/CI build. Numeric polygon limits are deliberately not invented here; use the approved backend contract.

## 2. Non-negotiable invariants

1. Exactly four hierarchy levels: **State/UT → District → City → Zone**; no Locality selector.
2. Only Zone has an operational activation/deactivation lifecycle.
3. A newly created Zone draft is inactive by default.
4. No client-side state, Founder approval alone, or generic status shortcut may activate a Zone.
5. Boundary evidence must be uploaded and independently verified before Founder submission.
6. Approval binds to the exact Zone revision and verified boundary hash. Changes make prior evidence stale.
7. Emergency suspension is a safety stop, not an approval shortcut or reactivation authority.
8. Every privileged transition is server-authorized and auditable; hidden/disabled UI controls are not security.
9. Retries and concurrent updates must not create duplicate or stale transitions.
10. A saved, submitted or approved Zone is not automatically customer-serviceable; downstream availability follows final active state and operational readiness.

## 3. Role matrix (confirm exact claims/scopes before automation)

| Operation | Central Admin | Founder / CEO | Super Admin | Manager / Supervisor |
|---|---|---|---|---|
| Create/edit Zone draft | Allow within scope | Not routine | Oversight/configuration | Deny |
| Upload boundary | Allow if scoped | Not routine | Oversight | Deny |
| Verify boundary | Designated reviewer only; apply separation-of-duties | Not routine | Oversight/assignment | Deny |
| Submit for Founder review | Allow | Not requester | Oversight | Deny |
| Approve/reject/request changes | Deny | Allow | Deny unless explicitly delegated | Deny |
| Execute approved activation | Allow via dedicated operation | Approval only | Oversight | Deny |
| Request deactivation | Allow | Only if policy explicitly permits | Oversight | Deny |
| Approve deactivation | Deny | Allow | Deny unless explicitly delegated | Deny |
| Execute approved deactivation | Allow | Approval only | Oversight | Deny |
| Emergency suspend | Only narrowly authorized emergency operator | Oversight/escalation | Only if explicitly assigned | Report/escalate |
| Request reactivation | Allow | Decision is separate | Oversight | Deny |
| Approve reactivation | Deny | Allow | Deny unless explicitly delegated | Deny |

Negative authorization tests must include unauthenticated, inactive admin, wrong role, out-of-scope city/zone, Manager attempting out-of-area action, and self-approval where separation-of-duties applies. All must be denied server-side.

## 4. Acceptance scenarios

### A. Draft creation and editing

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| ZD-01 | Valid parent IDs + normalized Zone name | One inactive draft; response contains Zone ID | Callable emulator |
| ZD-02 | Missing State/UT, District, City or name | Validation error; no write | Unit + callable |
| ZD-03 | District does not belong to State/UT | Reject invalid parent-child relation | Callable |
| ZD-04 | City does not belong to District | Reject invalid parent-child relation | Callable |
| ZD-05 | Duplicate normalized name in agreed uniqueness scope | Conflict; no duplicate document/index | Callable |
| ZD-06 | Retry after timeout | Approved idempotency behavior; no duplicate Zone | Callable |
| ZD-07 | Client submits protected active/boundary/approval/revision/hash fields | Reject or ignore protected fields; remains inactive/unapproved | Callable |
| ZD-08 | Edit existing draft | Same Zone ID; revision/stale-write behavior follows contract | Callable |
| ZD-09 | Inactive admin, wrong role or no auth | Denied; no mutation | Callable + Rules |
| ZD-10 | Change upstream selector | Clear downstream selections and Zone name | Widget |

### B. Boundary geometry and review

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| BD-01 | Upload valid polygon for saved Zone | Boundary ID and canonical hash linked to correct Zone/revision | Callable |
| BD-02 | Open/unclosed ring | Reject with documented geometry error | Unit + callable |
| BD-03 | Too few/many vertices or oversized payload | Reject using approved geometry limits | Unit + callable |
| BD-04 | Malformed, non-finite or out-of-range coordinates | Reject; never mark verified | Unit + callable |
| BD-05 | Self-intersection/invalid ring topology | Authoritative validator rejects | Unit + callable |
| BD-06 | Polygon outside selected city/jurisdiction | Hold/reject per approved spatial policy | Callable |
| BD-07 | Interrupted or repeated upload | No partial verified state; deterministic retry | Callable |
| BD-08 | Reviewer rejects with notes | Not eligible for Founder submission; reviewer and decision audited | Callable |
| BD-09 | Reviewer verifies boundary | Verified ID/hash linked to exact revision; actor/time audited | Callable |
| BD-10 | Unauthorized boundary review | Denied server-side | Callable |
| BD-11 | Zone revision changes after verification | Old evidence becomes stale/invalid per contract | Callable |
| BD-12 | Equivalent geometry encoded with different ring order/precision | Canonical hash is deterministic under approved canonicalization | Unit |

### C. Founder submission and decision

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| SB-01 | Central Admin submits current verified revision | Submission bound to exact revision + boundary hash | Callable |
| SB-02 | Submit without boundary | Reject; state unchanged | Callable |
| SB-03 | Submit rejected/unverified boundary | Reject | Callable |
| SB-04 | Submit stale revision/hash | Reject as stale; fresh evidence required | Callable |
| SB-05 | Manager, inactive admin or unauthenticated requester | Deny | Callable |
| SB-06 | Repeat unchanged submission | Idempotent/already-submitted response; no duplicate review item | Callable |
| SB-07 | Founder approves current submission | Approval bound to revision/hash; Zone remains inactive | Callable |
| SB-08 | Founder rejects | Rejection/notes audited; Zone inactive | Callable |
| SB-09 | Founder requests changes | Defined correction state; prior approval not reusable after edits | Callable |
| SB-10 | Non-Founder decision or stale decision | Deny/conflict; no lifecycle mutation | Callable |
| SB-11 | Repeat Founder decision | No duplicate or contradictory transition | Callable |

### D. Activation

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| AC-01 | Central Admin activates approved current revision/hash with verified boundary | Dedicated activation succeeds; active state + audit event | Callable |
| AC-02 | Activate before Founder approval | Reject; remains inactive | Callable |
| AC-03 | Activate without verified boundary | Reject; remains inactive | Callable |
| AC-04 | Activate after revision/hash changed | Reject stale approval | Callable |
| AC-05 | Manager/unauthorized Central Admin activates | Deny server-side | Callable |
| AC-06 | Generic status callable receives isActive=true | Reject; only dedicated activation path may activate | Callable |
| AC-07 | Repeat activation | Safe documented idempotent result | Callable |
| AC-08 | Successful activation | Audit actor/time/prior-new state/revision/hash; downstream availability updated per contract | Callable + integration |

### E. Deactivation and emergency suspension

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| DD-01 | Central Admin requests deactivation with reason | Request recorded; Zone stays active pending Founder decision and execution | Callable |
| DD-02 | Missing reason/invalid Zone ID | Reject; no transition | Unit + callable |
| DD-03 | Founder rejects/requests changes | Zone remains active; decision audited | Callable |
| DD-04 | Founder approves exact current revision/hash | Approval recorded; execution remains separate | Callable |
| DD-05 | Central Admin executes approved deactivation | Zone inactive; audit event | Callable |
| DD-06 | Execute without approval or with stale hash | Reject; Zone remains active | Callable |
| DD-07 | Generic status shortcut bypasses approval | Reject | Callable |
| DD-08 | Manager deactivates or changes parent lifecycle | Deny; only Zone lifecycle is in scope | Widget + callable |
| DD-09 | Authorized emergency operator supplies reason + SEV-1…SEV-4 | Dedicated safety suspension; audit and required alerts | Callable |
| DD-10 | Missing reason, invalid severity or unauthorized actor | Reject; no emergency transition | Unit + callable |
| DD-11 | Retry emergency suspension | Idempotent; notification retry policy prevents alert storm | Callable |
| DD-12 | Emergency endpoint/generic status used to reactivate | Reject; suspension grants no reactivation authority | Callable |

### F. Reactivation

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| RA-01 | Central Admin requests reactivation with reason | Fresh request; Zone remains inactive/suspended | Callable |
| RA-02 | Founder approves current reactivation request | Approval recorded for current revision and required boundary evidence; no implicit activation | Callable |
| RA-03 | Founder rejects/requests changes | Zone remains inactive; notes audited | Callable |
| RA-04 | Stale approval, changed boundary or missing review | Reject; fresh review/approval required | Callable |
| RA-05 | Manager/unauthorized actor requests or approves | Deny | Callable |
| RA-06 | Repeat reactivation request/decision | Safe idempotent behavior | Callable |

**Open contract question:** the inspected Admin service exposes `requestReactivation` and Founder decision `reactivate`, but whether a separate Central Admin execution callable is required after approval is not established. Backend must define the final state machine before this section is executable QA.

### G. UI, security and cross-cutting checks

| ID | Scenario | Expected result | Layer |
|---|---|---|---|
| UI-01 | Open Create Zone | Four selectors only; no Locality | Widget |
| UI-02 | Example catalog shown | Clearly marked sample/mock; save/submit unavailable | Widget |
| UI-03 | Select existing sample Zone | Never presented as a new Zone | Widget |
| UI-04 | Enter new Zone name | Local validation does not imply persistence/server validation | Widget |
| UI-05 | Draw polygon locally | Explicitly says not uploaded/not verified | Widget |
| UI-06 | Backend contract/emulator tests not approved | Save/submit/lifecycle controls stay disabled | Widget |
| UI-07 | Open Boundary Review preview | Clearly marked preview, not a live review submission | Widget |
| UI-08 | 360px mobile viewport | No overflow/crash; controls and safety notes usable | Widget |
| UI-09 | Zone list/detail | Role/scope-aware controls; server state, not optimistic local state | Widget + E2E |
| UI-10 | Manager views out-of-scope city/zone | Data/actions unavailable or denied | Widget + callable |
| SEC-01 | Direct Firestore client write to protected workflow fields | Rules deny protected mutations | Rules emulator |
| SEC-02 | Callable with wrong role/scope | Callable independently denies | Callable emulator |
| SEC-03 | Two admins update/review same revision | Explicit stale conflict; no silent overwrite | Callable emulator |
| SEC-04 | Timeout/permission/validation/conflict/internal error | Safe mapped UI message; no false success or optimistic activation | Widget + E2E |
| SEC-05 | Failed transaction | No orphan name-index/boundary records | Callable emulator |
| AUD-01 | Any privileged transition | Actor, target, operation, before/after state, revision/hash, time and outcome audited per approved schema | Callable emulator |
| NOT-01 | Review/lifecycle/emergency event | Correct approved recipients notified; retries follow deduplication policy | Callable emulator |

## 5. Test execution evidence register

Fill this table only after running tests. Include exact commit SHA and run URL; never pre-fill PASS.

| Evidence | Required proof | Status |
|---|---|---|
| Dart unit tests | Geometry/canonicalization + model/service tests; command and output | Not run |
| Callable emulator | Positive, negative, authorization, stale revision, idempotency scenarios | Not run |
| Firestore Rules Emulator | Protected direct writes denied; permitted access tested | Not run |
| Admin widget tests | Hierarchy, resets, disabled actions, roles/scopes, mobile | Existing focused tests inspected; matrix additions not run |
| Admin E2E | Draft → boundary → review → Founder decision → activation; deactivation/emergency | Not run |
| CI | Exact tested commit, workflow run and all job/step outcomes | Not run for this matrix |
| Canonical API approval | Notion POL-041 decision + request/response/error contract | Pending |
| Cross-team compatibility | Team 01 Backend, Team 02 Admin, Team 03 Partner, Team 04 Customer sign-off | Pending |

## 6. Recommended execution order after approval

1. Approve API operation map, role matrix, state machine, geometry constraints and error envelope in Notion.
2. Add backend unit tests for geometry, canonical hash, revision checks and transition guards.
3. Add callable emulator tests for all positive/negative scenarios.
4. Add Rules Emulator tests proving protected fields cannot be client-mutated.
5. Replace mock hierarchy with approved read-only catalog; keep write/lifecycle controls disabled.
6. Add Admin widget tests for role/scope and server-state rendering.
7. Integrate one stage at a time, starting with draft save; require emulator evidence before enabling the next stage.
8. Run full Admin tests and Flutter Web build on exact PR head. Keep PR #51 Draft; no merge/deploy without owner approval.

## 7. Provisional source-level callable map

The companion audit records this observed mapping: `saveDraft` → `saveServiceLocationWithNameIndex`; `submitForFounderReview` → `submitServiceZoneForFounderReview`; `reviewBoundary` → `reviewServiceLocationBoundary`; `decideFounderApproval` → `decideServiceZoneFounderApproval`; `activate` → `activateServiceZone`; `requestDeactivation` → `requestServiceZoneDeactivation`; `deactivate` → `setServiceLocationStatus` with `isActive:false`; `emergencySuspend` → `suspendServiceZoneForEmergency`; `requestReactivation` → `requestServiceZoneReactivation`.

This map is provisional until Backend/Firebase confirms it against the exact approved contract and emulator implementation.
