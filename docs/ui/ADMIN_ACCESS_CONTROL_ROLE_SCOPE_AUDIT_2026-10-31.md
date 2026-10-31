# Admin Access Control & Role Scope Audit — 2026-10-31

## Scope and evidence
Repository: `DOJOWALK/DOJO-WALK-Admin`
Branch: `ui/notion-brand-foundation-2026-10-28`
Reviewed:
- `lib/features/access_control/screens/admin_access_control_screen.dart`
- `test/features/access_control/admin_access_control_screen_test.dart`
- `lib/screens/auth/auth_gate.dart`
- `lib/screens/dashboard/admin_shell.dart`
- Notion `TEAM 02 — Admin App`
- Notion `POL-021 — Access Control, Admin Roles & Privileged Account Security Policy`

This is a source and policy audit, not a deployed-security assessment. No Firebase repository, rules, functions, Storage, production data, or IAM configuration was changed or verified.

## Findings

### 1. Access Control screen is a static prototype
- The screen contains a hard-coded role matrix for Founder/CEO, Super Admin, Central Head/Central Operations, City Manager, Zone Supervisor, Support, Finance and Walker/Partner.
- The screen explicitly labels POL-021 as Draft and says no real user roles are loaded or changed.
- Role grant and scope-change controls are disabled; MFA is not connected.
- No admin-user listing, role editor, permission CRUD, geographic scope assignment, activation/revocation workflow, review date, or live audit-history integration exists in this screen.
- The role cards are descriptive text, not an executable permission matrix.

### 2. Authentication gate checks active admin record, not capability
- `AuthGate._isAdmin` reads `admin_users/{uid}` and accepts the account when the document exists and `isActive == true`.
- It does not inspect or pass role, capability, city scope, zone scope, or record-state permissions to the shell.
- The check fails closed on read errors, which is appropriate for this gate, but it does not prove backend authorization for later reads/writes.

### 3. Shared navigation is not role-aware
- `AdminShell` builds one static menu for all authenticated active admin users.
- Admin Users & Roles, Walker Management, Finance, Audit Logs, Service Locations and other modules are all present in the same menu.
- No role/capability filtering is applied before menu construction.
- This is a UI visibility gap, but hiding menu items alone would not provide security; backend enforcement remains mandatory.

### 4. Notion policy is explicitly unapproved
POL-021 status is **DRAFT — NOT APPROVED, NOT IMPLEMENTED, NOT TESTED**. It proposes:
- deny-by-default and least privilege;
- named individual accounts and separation of operational, technical, finance, developer and deployment privileges;
- role-permission matrix by read/create/update/delete/export/approval/deploy;
- authorization based on active account + role + assigned geographic/operational scope + permitted action + current record state;
- server-side enforcement in Firestore Rules, Storage Rules, Functions and APIs;
- no self-grant/self-activation, direct API bypass tests, privileged audit trail, MFA and revocation lifecycle.
TEAM 02 independently requires role-aware navigation while explicitly prohibiting Admin-repository changes to Firebase schemas, rules or functions and preserving Founder-only authority distinct from Super Admin and Central Admin.

## Gap matrix

| Requirement | Observed Admin implementation | Result |
|---|---|---|
| Real admin users loaded | No; static role cards only | Missing |
| Role grant/revoke | Disabled prototype controls | Not implemented |
| Permission-level matrix | Text descriptions only | Not implemented |
| State/City/Zone scope assignment | Static descriptive labels only | Not implemented |
| Role-aware navigation | One shared menu | Gap |
| Active-account gate | Checks document + isActive | Partial |
| Role/capability passed from AuthGate | Not observed | Gap |
| Founder-only approval distinct from Super Admin | Distinction documented in prototype | UI concept only |
| MFA status / enforcement | “MFA state not connected” | Not implemented |
| Access request/review/expiry workflow | Not observed | Missing |
| Audit of role/scope changes | Not connected in this screen | Missing |
| Backend authorization proof | Not available in Admin source review | Unverified |

## Tests reviewed
The existing widget test file verifies:
- Founder and Super Admin are described separately;
- role grant and scope controls remain disabled;
- a 360px viewport does not throw a widget exception.

These tests validate the static prototype only. They do not test real users, capabilities, city/zone scopes, navigation denial, backend rules, direct API bypass, MFA, audit events, or privilege escalation. Source was inspected; these tests were not executed during this audit.

## Required next implementation dependencies
Do not turn on role grants or claim access control is secure until:
1. Founder-approved POL-021 and an approved versioned role-permission matrix exist.
2. Team 01 provides the trusted Admin identity/capability/scope contract, including exact role IDs, permission names, city/zone scope representation, revocation behavior and error mapping.
3. Backend Rules/Functions enforce each read/write and direct API bypass tests cover inactive, unauthenticated, unauthorized, out-of-scope, self-grant, self-activation and Founder-only actions.
4. Access lifecycle defines request, independent approval, grant, review interval, expiry, emergency access and revocation.
5. Audit contract records actor, capability, target, scope, reason, timestamp, outcome and correlation ID.
6. Admin consumes that contract for role-aware navigation and denied/loading/offline/error states; UI visibility is never treated as authorization.
7. Tests cover role × capability × scope combinations and verify no privilege leakage.

## Safe Admin-only conclusion
This branch currently provides a clearly labeled, non-functional role-matrix prototype. The active-account gate is a minimal entry check, not a full authorization system. Shared navigation does not implement role-aware visibility. Because POL-021 remains Draft and the trusted backend contract is not established in this repo, no role-grant, scope-edit or authorization behavior was implemented in this audit.

## Change boundary
Documentation only. No Dart source, Firebase repository/configuration, Firestore schema/rules/indexes/data, Functions, Storage, IAM, production, merge or deployment changed.
