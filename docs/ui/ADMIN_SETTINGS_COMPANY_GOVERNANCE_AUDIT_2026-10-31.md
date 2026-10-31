# DOJO WALK — Admin Settings & Company Governance Audit
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Scope: read-only source review of Settings, navigation, access-control prototype, notification prototype, tests and Notion governance policies.

## Executive result
Settings & Governance is a **policy-mapped, read-only UI preview**, not a live company configuration console. It correctly avoids inventing defaults and leaves sensitive controls disabled. However, there is no evidence of persisted admin preferences, session/MFA configuration, company profile/branding settings, notification channel provisioning, privacy retention controls, or company support-channel configuration.

The current role matrix is also a static proposal; it does not load real admin users, enforce role/scope in the UI, or prove backend authorization.

**Release assessment: NO-GO for privileged setting changes or company governance operations from this screen.** This audit did not modify code, Firebase or production configuration.

## Source inspected
- `lib/features/settings/screens/settings_governance_screen.dart`
- `test/features/settings/settings_governance_screen_test.dart`
- `lib/features/access_control/screens/admin_access_control_screen.dart`
- `lib/features/notifications/screens/notification_center_screen.dart`
- `lib/screens/dashboard/admin_shell.dart`

## Verified implementation facts
### Settings & Governance
1. Screen is a `StatelessWidget`; it has no settings repository, Firestore data source, save/apply action, or persistence mechanism.
2. It presents five policy-mapped cards:
   - Language & accessibility — “Not connected”; preference button disabled.
   - Security & sessions — “Policy Draft”; routes to Admin Users & Roles prototype.
   - Notification channels — “Not configured”; routes to Notification Center prototype.
   - Data privacy & retention — “Approval required”; retention control disabled.
   - Company support channels — “Not verified”; edit control disabled.
3. Screen explicitly says no configuration changes are saved and shows “Not configured” rather than inventing values.
4. No company legal identity, registered address, tax/GST, brand/domain, service-area defaults, pricing, payout, emergency contact, operational hours, or release-environment settings are configured here.
5. Tests assert the five cards and verify retention/contact controls remain disabled. The test file was inspected but not executed in this audit.

### Access Control / privileged governance
1. Role cards are hard-coded proposals for Founder/CEO, Super Admin, Central Head/Operations, City Manager, Zone Supervisor, Support, Finance and Walker/Partner.
2. Grant role, change scope and MFA state are disabled/not connected.
3. The role matrix screen explicitly says policy is Draft and no real user roles are loaded or changed.
4. Earlier Admin access audit found AuthGate checks Admin record existence and `isActive`, while role/capability/geographic scope are not passed into AdminShell. AdminShell's menu is shared across roles. This current screen does not close that backend authorization gap.
5. Hiding or disabling controls is not security. Server-side Rules/Functions/API authorization remains required.

### Notifications / company channels
1. Settings links to Notification Center, which is a local example prototype; no provider delivery configuration or verified channel is established.
2. Push/email/SMS/phone delivery, retry, idempotency, delivery-state semantics and emergency fallback are not proven operational.
3. POL-032 requires service notifications to reflect trusted backend state, marketing to remain separate and consent-based, and urgent safety communications not to rely solely on push.

### Navigation
- AdminShell exposes Settings as a menu item and routes to SettingsGovernanceScreen.
- No dedicated company profile, tax/legal identity, business hours, support contacts, emergency contacts, feature flags, environment switch or release controls were found in the reviewed Settings route.

## Notion governance alignment
- **TEAM 02 — Admin App:** UI visibility is not authorization; backend Rules/Functions must enforce permissions. Admin must consume versioned Team 01 contracts and must not change Firebase schemas/rules/functions from this repo. Founder-only approvals remain distinct from Super Admin technical access and Central Admin operations.
- **POL-021 — Access Control, Admin Roles & Privileged Account Security:** Draft — not approved, implemented or tested. It proposes deny-by-default, individual accounts, MFA for privileged users, role-permission matrix, city/zone scope, server-side enforcement, access lifecycle, audit monitoring, emergency access and negative security tests.
- **POL-032 — Customer Notifications, Communication Preferences & Messaging:** Draft — not approved, implemented or tested. It requires verified channels, authoritative backend state, separate marketing consent, retry/idempotency, delivery-state distinctions and emergency fallback.
- **POL-022 — Secure Software Development, Code Review & Release Management:** Draft — not approved, implemented or tested. It requires commit-tied evidence, current-head CI, protected production controls and explicit PASS/FAIL/BLOCKED/NOT RUN/UNVERIFIED reporting.
- No approved company-wide configuration policy or authoritative configuration schema was identified in this review. Draft policy text is not proof of implementation or authority.

## Material gaps / risks
1. **No configuration persistence:** all Settings cards are explanatory UI. There is no safe, versioned source of truth for company settings.
2. **No role-aware settings authorization:** current navigation and settings route do not receive capability/scope context. A future UI gate alone would not be sufficient.
3. **Privileged account security unverified:** MFA, session expiry, re-authentication, recovery, account revocation and break-glass controls are not connected.
4. **Founder vs Super Admin separation:** UI role descriptions are directionally clear, but there is no enforced approval workflow proving Founder-reserved business decisions cannot be exercised by technical Super Admin.
5. **Company profile/config missing:** legal identity, tax details, company contacts, support hours, emergency roster, service launch configuration and operational defaults are not implemented in this route.
6. **Notification configuration missing:** provider credentials, verified sender/destination, consent/preferences, delivery status, retries and escalation are not connected.
7. **No audit-backed setting mutation:** no actor, before/after value, reason, approval, timestamp, correlation ID or immutable history for configuration changes.
8. **No safe change lifecycle:** no draft → review → approval → apply → verify → rollback flow for high-impact configuration.
9. **No tests for authorization or persistence:** current Settings tests are presentation-only; no backend Rules/Functions, security, recovery or configuration rollback tests were run.

## Required cross-team contracts before implementation
- Founder/Company governance: approve company configuration ownership, which settings are Founder-reserved, which are delegated, and change approval thresholds.
- Team 01: versioned typed configuration contract with environment separation, server-controlled defaults, validation, effective dates, audit records, safe rollback and capability/scope checks.
- Team 01: privileged account role/scope/MFA/session contracts and negative Rules/Functions tests; no client-side role grant.
- Operations: verified support hours, monitored company channels, named emergency contacts and on-call backups before displaying them.
- Notifications: approved providers, template ownership, channel verification, preference/consent model, delivery/retry semantics and emergency fallback.
- QA/Security: test unauthorized direct API access, self-approval, role escalation, scope crossover, stale configuration, concurrent edits, failed apply, rollback, audit immutability and environment separation.

## Safe Admin-only next steps
- Keep Settings read-only and preserve disabled sensitive controls.
- Do not invent or hard-code company legal, tax, support, emergency, business-hour or provider values.
- Do not add generic “Save Settings” until Team 01 defines a versioned configuration API and authorization model.
- Once contracts are approved, implement least-privilege read-only configuration display first, then audited change requests and separate approval/apply flow.
- Keep Founder approval distinct from Super Admin technical maintenance.
- Do not change Firebase repository, schema, Rules, Functions, Storage, IAM, secrets or production settings from this Admin repository.

## Verification boundary
Static source and Notion policy inspection only. Settings widget tests were read but not executed. No Flutter test, emulator, Rules/Functions security test, MFA/session test, provider configuration test, audit immutability test, or production configuration check was performed. No application code was changed.

## Decision
**NO-GO for live privileged settings/company governance mutations** until approved governance ownership, versioned Team 01 configuration and access contracts, server-side enforcement, audit/rollback controls and automated security tests are implemented and independently evidenced. Keep PR #51 open/draft; do not merge or deploy based on this audit.
