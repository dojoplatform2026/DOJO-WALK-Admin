# Admin Walker Profile Role Visibility Review — 2026-10-31

Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Related PR: #51 (Open / Draft)

## Finding

The inspected Admin UI does not demonstrate role-based field visibility in the walker profile and document-review flow. This is a source review only. Deployed Firestore and Storage authorization were not inspected; UI visibility is not authorization.

## Requirements status

Notion Team 02 requires role-aware navigation, backend-enforced permissions, versioned backend contracts, and separation of Founder decisions from technical and operational roles.

POL-004 remains DRAFT pending Founder approval. It describes an assigned verifier, restricted evidence references, Central Admin process ownership, assigned-area restrictions, and auditable decisions. No final role matrix is approved by this audit.

## Source observations

Reviewed AuthGate, AdminShell, Walker Details, profile sections, document viewer, activity-history dialog, WalkerAdminService and WalkerAdminModel.

- AuthGate checks an active Admin record; the inspected flow does not pass a capability matrix to the shell.
- AdminShell builds a shared navigation menu; role filtering was not found in the inspected code.
- Walker profile sections show contact, birth-date, residential-address, work-location and operational fields together.
- Document tiles have no visible assigned-reviewer capability check at the call site.
- The viewer accepts HTTP/HTTPS URLs or resolves a Storage path. URL expiry, object ownership and deployed Storage Rules are not established.
- Activity history displays actor UID and free-text reason; role-based redaction was not found.
- WalkerAdminModel retains the full source map and verification map in rawData/model.
- A client service transaction checks active Admin status and super_admin role for state changes. This is not proof of server-side authorization or separation of duties.

## Conservative design recommendation — NOT APPROVED POLICY

| Role | Suggested default visibility |
|---|---|
| Central Admin | National operational fields; contact masked by default; no routine access to original identity files |
| City Manager | Assigned City/Area only; minimum operational details; no original identity files |
| Zone Supervisor | Assigned Zone only; minimal readiness indicator; no private profile fields or original files |
| Authorized Verifier | Assigned cases only; minimum necessary identity fields and time-limited evidence access |
| Founder/CEO | Decision summary and evidence reference; original files only through a separately approved exception |
| Super Admin (technical) | Technical diagnostics; no automatic Founder or verifier authority |

These are conservative recommendations, not approved policy. Do not implement by UI hiding alone.

## Required backend contract

1. Trusted, versioned capabilities and City/Zone scope resolution.
2. Least-privilege walker list/detail projections.
3. Case-bound, short-lived HTTPS evidence access with ownership checks and access audit.
4. Firestore and Storage Rules deny-by-default and enforce role, scope, case assignment and active status.
5. Separate verification and approval; the same reviewer cannot approve the case.
6. Emulator tests for inactive/unauthorized/out-of-scope actors, unassigned reviewers, expired access and separation-of-duties violations.

## Admin follow-up after policy and contract approval

Use explicit least-privilege models; fail closed when capabilities are unavailable; gate evidence access on assigned reviewer authority; mask contact and omit birth-date/full home address where not required; separate review workspace from general profile; redact audit details by role; add role-by-field widget tests.

## Status

No application code or backend/security configuration was changed by this review. Do not enable profile/document permissions or lifecycle decisions until POL-004 is approved and the backend contract and Rules/Storage tests are available.
