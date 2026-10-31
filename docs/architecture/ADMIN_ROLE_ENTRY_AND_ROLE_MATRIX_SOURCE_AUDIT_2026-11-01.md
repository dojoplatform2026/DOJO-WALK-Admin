# Admin role-entry and role-matrix source audit — 2026-11-01

## Scope
Read-only review of the Admin branch `ui/notion-brand-foundation-2026-10-28`. Reviewed:
- `lib/screens/auth/auth_gate.dart`
- `lib/services/auth_service.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `lib/features/access_control/screens/admin_access_control_screen.dart`

No code, Firebase, rules, data, or policy changes were made.

## Findings

### 1. App entry gate is active-membership only
`AuthGate._isAdmin` reads `admin_users/{uid}` and permits AdminShell when the document exists and `isActive == true`. Read failures return false; an unknown/inactive membership does not expose the shell. It does not inspect `role` or geographic scope.

`AuthService.signInAdmin` independently checks that the membership document exists and is active, then returns the data. Its comment explicitly defers role-specific permissions to feature gates and trusted Firebase callables.

**Interpretation:** this is a deliberate broad membership gate, not an authorization decision for privileged actions. It must not be treated as the security boundary.

### 2. Admin role screen is a static policy prototype
`AdminAccessControlScreen` labels itself UI-only and says POL-021 is Draft. The role cards are hard-coded descriptions for Founder/CEO, Super Admin, Central Head/Central Operations, City Manager, Zone Supervisor, Support, Finance, and Walker/Partner. No real role records are loaded or changed. Grant role, change scope, and MFA controls are disabled.

The screen itself states that authorization must combine active account, role, assigned scope, permitted action, and current record state, and that backend rules must enforce reads/writes.

**Interpretation:** the screen communicates the intended governance model but does not implement a role matrix, geographic scope checks, or role assignment workflow.

### 3. Navigation currently exposes a common Admin shell
`AdminShell` defines one common menu and routes to feature screens without a role/scope decision in the shell. Feature-level and trusted backend checks therefore remain essential. Menu visibility alone would not secure data.

### 4. Team 01 decision gate remains open
The Team 01 Zone API decision request D01–D05 remains unanswered in the latest PR #51 conversation read (2026-11-01). In particular, Team 02 must not infer that `super_admin` maps to `central_admin`, or that Founder/Central Admin roles can pass Zone callable authorization, until Team 01 supplies its exact source SHA, contract and emulator evidence.

## Required next decisions / acceptance evidence
1. Team 01 confirms the canonical role identifiers and whether/how `super_admin`, `central_admin`, and `founder` are distinct.
2. POL-021 is approved and aligned with POL-041, including role-to-action matrix and city/zone scope semantics.
3. For every privileged Admin feature, identify the client gate and the authoritative server/rules enforcement. Include positive and negative emulator tests for each role and scope.
4. Keep the common AuthGate as membership-only unless the approved cross-role product policy explicitly requires an entry restriction. Do not solve a callable role mismatch by arbitrarily narrowing app entry to `super_admin`.
5. Add Admin widget/unit tests for role-aware presentation only after the canonical contract is approved; never treat those tests as backend security evidence.

## Status
- Source inspection: COMPLETE for the four files listed above.
- Role/scope enforcement: NOT ESTABLISHED by this audit.
- POL-021 approval: NOT VERIFIED.
- Team 01 D01–D05 response: NOT FOUND in PR #51 comments as checked on 2026-11-01.
- Emulator tests: NOT RUN by Team 02.
- API integration: NOT STARTED (intentionally blocked pending contract).
- Firebase changes / merge / deployment: NONE.
