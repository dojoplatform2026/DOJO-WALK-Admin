# DOJO WALK Admin Role & Permission Matrix

**Status:** Proposed contract for review; not proof of implementation.  
**Applies to:** Founder / CEO, Central Admin, Area Manager.  
**Decision:** A separate Super Admin role is not required for the target company model. Do not silently map the legacy `super_admin` role to Founder or Central Admin.

## 1. Authority principles

1. Founder / CEO is the sole holder of Founder-reserved company authority.
2. Central Admin operates company-wide within explicitly granted operational permissions; it cannot exercise Founder-reserved powers.
3. Area Manager is restricted to assigned Area scope and descendants; it cannot access unrelated Areas or grant itself broader scope.
4. Authorization must be enforced by trusted backend/Firestore Rules, not by hiding UI controls.
5. Default is deny. Each role needs explicit module + action + data-scope permission.
6. High-risk actions require an approval record, actor, target, timestamp, reason, and audit event.
7. Do not change production accounts, deployed rules, or data as part of this documentation change.

## 2. Roles

### Founder / CEO
- Company-wide read access to approved business, operational, and financial summaries.
- Appoint, suspend, and revoke Central Admin access.
- Control role/permission policy and approve changes to sensitive authority.
- Set company-wide pricing, discount, coupon, refund, payout, and cancellation policies.
- Hold reserved approval for first/major Service Area launch where company policy requires it.
- Review escalations, high-risk financial exceptions, security events, and audit records.
- Founder-only actions cannot be delegated or self-assigned by another role.

### Central Admin
- Manage company-wide daily operations within approved policy.
- Maintain Service Location records and submit launch/activation requests; cannot bypass Founder-reserved approval.
- Monitor and coordinate bookings, assignment/reassignment, walker onboarding/verification workflow, availability, customer support, and escalations.
- Review payment status, reconciliation, payout records, and discrepancies; money movement and exceptions require explicit financial permissions/limits.
- Manage coupons only within Founder-approved limits.
- Assign/manage Area Managers only within the policy and permissions explicitly granted.
- View operational reports and authorized audit records.
- Cannot appoint or impersonate Founder, change Founder-reserved policy, or grant itself higher permissions.

### Area Manager
- Access only assigned Area(s) and allowed descendants.
- Manage local bookings, walker availability/attendance, live-operation exceptions, service quality, and customer complaints within approved workflows.
- Submit verification, refund, payout, location, and policy exceptions for Central review.
- View only scoped performance reports and records needed for assigned work.
- Cannot view unrelated Area data, change company-wide pricing/coupons/policies, appoint Central Admin, change roles, or approve financial exceptions beyond an explicit limit.

### Supervisor — operational level, permission contract pending
- Supervisor appears in the agreed company reporting flow: Founder / CEO → Central Admin → Area Manager → Supervisor → Walker / Partner.
- Until the Founder/CEO approves the exact permission set, Supervisor is an operational assignment level, not an automatically privileged canonical Admin role.
- If a distinct authenticated Supervisor role is later approved, it must be explicitly assigned to a specific Area Manager/Area and limited to assigned tasks and necessary records within that scope.
- No company-wide dashboard, cross-Area access, role management, policy changes, pricing/coupon control, financial approval, or self-assignment of scope by default.
- Every task assignment, completion, escalation, and permission-sensitive action must be attributable and auditable.

## 3. Module/action matrix

Legend: **Full** = within role's reserved authority; **Policy** = define/approve policy; **Operate** = perform approved day-to-day actions; **Scoped** = assigned Area only; **Request** = submit for approval; **No** = denied.

| Module / action | Founder / CEO | Central Admin | Area Manager | Supervisor (if approved) |
|---|---|---|---| --- |
| Company dashboard | Full | Operate, company operations | Scoped | Assigned task summary only; no global metrics |
| Admin appointment/revocation | Central Admin and role policy | Only explicitly delegated lower-role tasks | No | No |
| Role/permission policy | Policy | No self-elevation; only delegated changes | No | No |
| Service Location records | Full oversight | Operate; request activation | Scoped view/request | View assigned work context only; no activation |
| Reserved Area launch approval | Full | Request/review | Request | Deny by default until explicitly approved |
| Bookings | Full oversight/escalations | Operate company-wide | Scoped operate | Only assigned booking/task details, if approved |
| Walker/Partner records | Full oversight/escalations | Operate verification workflow | Scoped operations; escalate verification decisions | Assigned task context only; no verification/role changes |
| Availability/attendance | Full oversight | Operate company-wide | Scoped | Deny by default until explicitly approved |
| Live operations | Full oversight | Operate company-wide | Scoped; location freshness must be visible | Assigned tasks only; location access only if approved and necessary |
| Pricing policy | Policy | Apply policy; request change | No change | No |
| Coupons/discounts | Policy and limits | Operate within limits | No change | No |
| Payment/reconciliation reports | Company-wide | Authorized operational/finance access | Scoped/minimum required only | Deny by default until explicitly approved |
| Refunds/payouts | Reserved/high-risk approval per policy | Within explicit limits; otherwise request | Request/review only unless explicitly limited permission granted | No approval; escalate only |
| Customer support | Escalations | Operate company-wide | Scoped | Deny by default until explicitly approved |
| Reports | Company-wide | Authorized operational reports | Scoped | Deny by default until explicitly approved |
| Audit logs | Company-wide sensitive logs | Authorized operational logs | Own/relevant scoped actions | Own assigned-task actions only, if enabled |
| Security settings | Founder-reserved control | No Founder control | No | No |
| Self-elevation | No; Founder identity is provisioned securely | Deny | Deny | Deny by default until explicitly approved |

## 4. Required backend data contract (proposal)

Every authorization decision should evaluate:
- authenticated Firebase UID;
- active admin membership;
- canonical role;
- explicit permission for module + action;
- assigned Area scope for scoped roles;
- approval state/limits for sensitive actions.

The exact document schema and claims must be reconciled with deployed Firestore Rules, Cloud Functions, Admin UI, and existing records before implementation. Do not infer Founder identity from a role string supplied by a client. Founder authority must be bound through a controlled trusted procedure.

## 5. Migration and release blockers

- Current Admin fresh architecture is reported to gate UI on active `super_admin`; current Firebase Rules helper also recognizes active `super_admin` as the administrative role. This is legacy behavior and is not equivalent to the target three-role model.
- Do not simply remove `super_admin` from Rules or rename it: that could lock out current access or create privilege escalation.
- Define a backward-compatible identity/permission migration and verify the real Founder UID through an approved trusted procedure.
- Add Auth + Firestore Emulator integration tests for inactive accounts, role changes, revoked access, self-elevation, unauthorized role grants, cross-Area reads/writes, Founder-only approvals, and financial thresholds.
- Verify Rules/Functions/Admin use the same contract; run Admin analyze/tests/Web build and Firebase Rules/Functions tests.
- Keep PRs draft/open and do not deploy or alter production records until review, tests, deployed-parity checks, and explicit release approval are complete.

## 6. Acceptance criteria

- [ ] Founder, Central Admin, Area Manager are the canonical target roles.
- [ ] No separate Super Admin role is required by the target design.
- [ ] Founder-reserved permissions are technically unavailable to other roles.
- [ ] Central Admin cannot access Founder-reserved controls.
- [ ] Area Manager cannot access unassigned Area records or broader admin controls.
- [ ] Server-side authorization and audit tests pass.
- [ ] Existing accounts and legacy role data have a reviewed migration path.
- [ ] All relevant CI passes on the exact integrated commit.
- [ ] No production deployment until separately approved.


**Matrix rule:** Any Supervisor cell marked “Deny by default until explicitly approved” means no access until a permission is expressly approved, implemented in trusted backend/Rules, and covered by tests. This table is a proposed contract, not deployed authorization.
