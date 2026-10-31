# DOJO WALK Admin — Walker KYC Verification & Approval Governance Audit

- Date: 2026-10-31
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (Open / Draft)
- Source head reviewed: `169a5e3ee0cebffabdfa18edbbec325a15699161`
- Notion sources: Team 02 — Admin App; POL-004 — Walker / Partner Management Policy.
- Scope: compare Admin's existing lifecycle transition/service design with POL-004 authority, verification and audit requirements.
- No code, Firebase repository, Rules, Functions, Storage, live data, other app, merge or deployment changed.

## 1. Source-of-truth policy status

Notion POL-004 was fetched on 2026-10-31. It explicitly states:
- Document status: DRAFT — Founder approval required.
- It must not be treated as active in the app until implemented and tested.
- Founder approval must be recorded before activation.
- Authorized Verifier checks documents and readiness using restricted systems and records evidence/decision.
- Central Admin / Walker Operations owns national process, eligibility standards, exceptions and escalations.
- Area Manager coordinates only assigned Area; it cannot approve its own privileged access or independently close a serious incident it handled.
- Material status decisions require actor, timestamp, reason, scope, supporting evidence reference and next review date for temporary status.
- Required system records include document checklist status, reviewer, restricted evidence reference, training, scope, status history and audit events.

The policy contains many explicit Founder/Central decisions still open. No policy approval evidence was found in the fetched page; its status remains DRAFT.

## 2. Existing Admin implementation observed

### UI
- `WalkerDetailsScreen` defines `_lifecycleActionsEnabled = false`.
- Buttons are disabled and the page explains that lifecycle actions remain unavailable until POL-004 authority separation and audit requirements are approved/tested.
- This is the correct safe behavior while the policy remains draft.
- Do not enable these buttons based only on the current local transition helper.

### Service authorization
- `WalkerAdminService.runAdminAction` uses a Firestore transaction to read the admin user and walker, update walker state, and create an audit record atomically.
- Its caller check requires an active Admin record with role exactly `super_admin`.
- The service currently combines verification/approval transitions in a single `approve` action, setting:
  - status = approved
  - verificationStatus = verified
  - isApproved = true
  - isActive = true
- This does not implement the distinct Authorized Verifier and authorized approver responsibilities described by POL-004.
- It does not record a restricted evidence reference, verifier identity, separate verification outcome, training/competency result, approved service scope, or next review date for a temporary suspension in the observed transition payload.
- The service's role gate is a local client-side transaction precondition plus whatever Firestore Rules enforce. It is not proof of deployed backend authorization. Team 02 Notion explicitly says UI visibility is not authorization.

### Transition helper and tests
- `WalkerAdminTransitionPolicy` is a deterministic local state-transition helper; its own comments correctly say it does not authorize callers or write Firestore.
- Unit tests cover allowed/denied status combinations, reason validation, and stable audit event names.
- These tests do not establish role separation, verifier/approver independence, evidence completeness, scope restrictions, or server-side Rules/Function enforcement.

## 3. Governance gaps — do not enable actions

| Requirement from POL-004 | Current Admin source | Result |
|---|---|---|
| Separate Authorized Verifier from approver | One `approve` action sets verified + approved + active | Gap — critical |
| Central owns national eligibility and exceptions | Service accepts only `super_admin` role | Governance mismatch / unresolved mapping |
| Area Manager limited to assigned Area | No scope field/authorization in this lifecycle transaction | Not implemented/verified |
| Founder-only policy/material approval distinct from Super Admin | Local service gate uses `super_admin`; no Founder approval record in this flow | Not represented |
| Document checklist + restricted evidence reference | No evidence reference in transition audit payload | Gap |
| Training and competency readiness | Not checked by transition helper/service | Gap |
| Approved Area/Zone scope | Not checked or recorded in transition helper/service | Gap |
| Status history with actor, timestamp, reason and before/after | Audit record has actor, timestamps, before/after state and optional reason | Partial |
| Temporary suspension next-review date and review owner | Not present in observed transition payload | Gap |
| Independent reviewer for serious incident involving staff | Not implemented in this lifecycle action | Not verified |
| Backend Rules/Functions authorization | Admin repo source only | Not verified |

## 4. Required target workflow (design recommendation, not implemented)

Do not implement this workflow until Founder approves POL-004 and Backend/Firebase publishes versioned contracts.

1. Application Submitted — no booking eligibility.
2. Documents Pending / Under Review — only authorized verifier can access restricted evidence and record checklist outcome.
3. Verification outcome recorded separately: Verified / Correction Required / Rejected, with verifier UID, server timestamp, evidence reference, checklist version and reason/category.
4. Training & Readiness — required training and competency result recorded; no booking eligibility until complete.
5. Scope Readiness — approved State/UT → District → City → Zone scope confirmed; only enabled verified zones allowed.
6. Approval decision — separate authorized approver reviews the completed verification/readiness packet and records Approved — Inactive or Approved — Active as policy permits.
7. Activation — only Approved + Active + in-scope + schedule/capacity eligibility may receive offers. Matching checks must be enforced by trusted backend.
8. Suspension / reactivation / offboarding — distinct authorized workflows with reason, evidence, review owner/deadline, access effect, future-booking handling and immutable audit history.

Suggested separation: a verifier records evidence and recommendation; a different authorized approver makes the final operational approval. Founder retains policy/material exception and Area launch authority, not routine verification. The final role mapping must be approved in Notion and enforced server-side.

## 5. Backend contract needed before Admin implementation

Team 01 must publish:
- Versioned callable/API contract for submit verification, record verifier outcome, approve, request correction, reject, suspend, reactivate and offboard.
- Explicit actor-role matrix and Area/Zone scope checks for Central Admin, City Manager/Area Manager, Zone Supervisor, Authorized Verifier, Finance Owner, Super Admin and Founder/CEO.
- Separation-of-duties enforcement (e.g. verifier cannot approve the same application) on trusted backend, not just disabled UI.
- Canonical application lifecycle fields and immutable status-history/audit schema.
- Restricted KYC evidence reference and Storage read authorization contract; no raw ID document data in Notion or broad list projection.
- Training/competency and zone-scope readiness contract.
- Temporary suspension review owner/deadline and overdue escalation behavior.
- Rules/Functions tests for unauthorized, out-of-scope, inactive, self-approval, same-verifier/approver, stale status, duplicate request/idempotency and audit completeness.
- Emulator revision, indexes, region, callable names, payload examples and error mapping.

## 6. Admin-side acceptance tests after contract approval

- Verifier may review only in-scope applications and only authorized KYC references.
- Verifier can submit a checklist result but cannot activate a walker.
- Same person cannot verify and approve the same application unless an explicit approved exception exists.
- Approver cannot approve if documents, training, terms acceptance or scope readiness is incomplete.
- City/Zone staff cannot access out-of-scope applications or sensitive documents.
- Founder-reserved decisions cannot be performed by Super Admin/Central Admin.
- Every decision has server timestamp, actor, role, before/after, reason, evidence reference, scope and correlation ID.
- Temporary suspension includes review owner and next review date; overdue reviews alert Central.
- UI handles pending, correction required, rejected, approved-inactive, approved-active, suspended, offboarded, permission denied, offline and backend conflict states.
- Audit history displays immutable events and pagination; it never confuses missing data with an empty history.
- All critical tests pass in emulator with Rules/Functions; link exact CI run and tested revision.

## 7. Decision

**NO-GO for enabling lifecycle actions.** Keep the existing buttons disabled. Current Admin service is a legacy Super Admin-only combined verification/approval transaction and is not aligned with POL-004's separate Authorized Verifier and approver roles. The local transition unit tests do not close this governance/security gap.

Next safe dependency: Founder-approved POL-004 + Team 01 versioned verification/approval contract + role/scope Rules tests. Admin then implements only the approved UI integration on this existing branch.
