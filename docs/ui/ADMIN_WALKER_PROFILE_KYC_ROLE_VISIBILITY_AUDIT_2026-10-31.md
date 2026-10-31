# Admin Walker Profile & Sensitive Document Role-Visibility Audit — 2026-10-31

Repository: DOJOWALK/DOJO-WALK-Admin  
Branch: ui/notion-brand-foundation-2026-10-28  
Audit base: f423f29ac0e6a0b039c345283a4048f7a55f218d  
PR #51: Open / Draft. No merge or deployment.

## Executive finding

The inspected Admin source does not implement role-based field visibility for Walker Details or sensitive verification documents. This is a source-level finding only; deployed Firestore and Storage authorization were not inspected or tested. UI hiding is not authorization.

## Notion requirements

Team 02 — Admin App requires role-aware navigation, backend-enforced permissions, versioned Backend & Firebase contracts, and separation of Founder-reserved decisions from Super Admin technical access and Central Admin operations.

POL-004 remains DRAFT — Founder approval required. It describes an Authorized Verifier, restricted evidence references, Central Admin national process ownership, Area Manager assigned-scope limits, and auditable decisions. This audit does not treat the draft as approved policy.

## Source evidence

Inspected:
- lib/screens/auth/auth_gate.dart
- lib/screens/dashboard/admin_shell.dart
- lib/features/walkers/screens/walker_details_screen.dart
- lib/features/walkers/widgets/walker_details_sections.dart
- lib/features/walkers/widgets/kyc_document_viewer_dialog.dart
- lib/features/walkers/widgets/walker_activity_history_dialog.dart
- lib/features/walkers/services/walker_admin_service.dart
- lib/features/walkers/models/walker_admin_model.dart

Observed:
1. AuthGate checks that the signed-in user has an admin_users record with isActive == true; no role/capability set is passed into AdminShell.
2. AdminShell presents a common menu, including Walker Management; no role-based menu filtering was found in the inspected shell.
3. Walker Details renders contact details, date of birth, full current address, work location, assigned zones, availability, verification status and sensitive-document tiles together.
4. The document viewer accepts HTTP or HTTPS URLs directly, or resolves a Firebase Storage path. URL expiry, object ownership and Storage Rules enforcement are not established by this Admin source. HTTP acceptance should be removed in a future approved implementation.
5. Activity history displays actor UID, status transitions and free-text reason; role-based redaction was not found at the inspected call path.
6. WalkerAdminModel.fromMap retains the entire source document in rawData and the full verification map. This is not a least-privilege projection.
7. WalkerAdminService.watchWalker(uid) reads one complete walker document. A single-document listener is narrower than a collection listener but does not minimize fields.
8. The existing state-write transaction checks active admin status and role == super_admin as a client-side precondition. This does not prove deployed server-side authorization or separation of verifier and approver. Lifecycle controls remain disabled in the screen.

## Proposed conservative visibility matrix — NOT APPROVED POLICY

| Actor | Operational profile | Contact | Full home address / DOB | Sensitive document files | Verification metadata | Authority |
|---|---|---|---|---|---|---|
| Central Admin | National operational fields, least privilege | Mask by default; purpose-based reveal | No routine access | No routine file access; request authorized verification | Status/checklist and restricted evidence reference | National operations/escalation; not Founder-reserved approval |
| City Manager | Assigned City/Area only | Mask by default; limited case-based reveal | No routine access | No | Minimum readiness indicators | Local coordination only |
| Zone Supervisor | Assigned Zone only | Mask; approved contact relay | No | No | Minimal readiness indicator | Zone execution/escalation only |
| Authorized Verifier | Assigned cases only | Minimum necessary | Only checklist-required fields | Case-bound, time-limited access through restricted evidence system | Checklist, reviewer, evidence reference, outcome and reason | Verification only; cannot approve own case |
| Founder/CEO | Decision brief and escalation summary | Not routine | Not routine | Not routine; separately approved exception only | Decision packet and evidence reference | Founder-reserved business approval |
| Super Admin (technical) | Technical diagnostics/metadata | No default business need | No | No | No routine evidence access | Technical administration only |

This is a safe design recommendation, not an approved role matrix. It must not be implemented as UI-only hiding.

## Severity-ranked gaps

- Critical: active-admin authentication is not a role/capability matrix; common navigation has no role filter.
- Critical: no visible verifier/case-bound gate before opening sensitive documents; actual file access depends on unverified Storage Rules.
- High: contact details, date of birth and full home address are displayed together without purpose or role masking.
- High: complete walker document and verification map are retained in rawData/model.
- High: signed URL expiry, case ownership, access audit and storage authorization are not established; viewer accepts HTTP.
- Medium: activity history exposes actor UID and free-text reason without visible role-based redaction.
- Critical dependency: POL-004 is still Draft.

## Required Team 01 backend contract

1. Versioned capabilities and trusted server-side scope for Founder, Super Admin, Central Admin, City Manager, Zone Supervisor and Authorized Verifier.
2. Least-privilege list/detail projections; general operations must not receive sensitive document payloads.
3. Case-bound evidence access with HTTPS-only short-lived tokens, ownership and assignment checks, expiry and audit.
4. Firestore and Storage Rules enforce role, assigned City/Zone, case assignment and active account; deny by default.
5. Separate verification and approval actions; verifier cannot approve same case; technical role cannot act as Founder.
6. Access audit includes actor, capability, target, case, purpose, evidence reference, timestamp and outcome.
7. Emulator tests for unauthenticated/inactive actors, unauthorized role, out-of-scope area, unassigned verifier, expired token, direct URL bypass, same-verifier/approver and exception access.
8. Approved minimization, retention and incident response controls.

## Admin follow-up after approval

- Use explicit least-privilege DTOs rather than raw full-document model data.
- Consume approved capability provider; fail closed when capability is unavailable.
- Gate sensitive-document access on verifier capability and assigned case, with backend enforcement.
- Mask contact details and omit DOB/full home address unless a documented purpose permits access.
- Separate verification workspace from general Walker Details.
- Redact actor identifiers and free-text reasons where not needed.
- Add role × field widget tests and Team 01 Rules/Storage emulator tests.

## CI and decision

At audit time PR #51 was Open / Draft, mergeable true, at head f423f29ac0e6a0b039c345283a4048f7a55f218d. Exact-head workflow run 41191506421 was in_progress; no conclusion was available. No application code, Firebase repository, Rules, Functions, Storage, production data, merge or deployment was changed.

**NO-GO:** Do not enable role-specific sensitive-document access or lifecycle decisions from Admin UI alone. Await Founder approval of POL-004 and Team 01's tested authorization/evidence contract.
