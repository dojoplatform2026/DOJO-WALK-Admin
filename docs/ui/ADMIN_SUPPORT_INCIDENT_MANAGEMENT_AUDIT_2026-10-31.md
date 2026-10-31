# DOJO WALK — Admin Support & Incident Management Audit
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Scope: read-only Admin source review and Notion policy alignment.

## Executive result
The Admin Support screen is a clearly labelled **UI-only prototype with illustrative example cases**. It is not connected to customer/walker case intake, a live case database, incident records, on-call routing, notifications or an operational SLA engine. Assignment/transfer/resolve controls are disabled. The Admin menu has a Support entry but no separate Incident Management screen was found in the reviewed navigation.

**Release assessment: NO-GO for live support or emergency case handling from this UI.** This audit does not establish that support channels, emergency contacts, staff coverage or escalation integrations are operational.

## Source inspected
- `lib/features/support/screens/support_center_screen.dart`
- `test/features/support/support_center_screen_test.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `lib/features/notifications/screens/notification_center_screen.dart`
- `lib/features/audit/screens/admin_audit_logs_screen.dart`

## Verified implementation facts
1. `SupportCenterScreen` creates three in-memory example cases (`CASE-EX-001..003`). It does not read live case/customer/walker/booking/incident data.
2. Search and severity chips filter only this local example list. The displayed owner, status, related reference, next step and timestamps are illustrative.
3. “View example case” explicitly states that no live support or incident data was accessed.
4. Transfer and Resolve buttons are disabled (`onPressed: null`). No case create, assign, transfer, escalate, add-note, reopen, close or appeal workflow is implemented in this screen.
5. Support menu routes only to `SupportCenterScreen`. No dedicated incident command/response screen is wired into the Admin navigation reviewed.
6. Notification Center is also a local example prototype; it explicitly states that delivery channels are not connected and send/retry controls are disabled.
7. Audit Logs is a local example prototype; its entries are not live audit records and export is disabled.
8. The Support widget test verifies the example queue, severity filter, example-only dialog, narrow viewport and disabled mutation controls. It does not verify case intake, backend authorization, on-call delivery, incident escalation, evidence access, SLA timers or end-to-end resolution.
9. AdminShell's navigation is shared; role/city/zone scope is not passed into SupportCenterScreen. This is not proof of backend authorization.

## Notion policy alignment
- **POL-009 — Customer Support & Complaints Policy:** Draft — Founder approval required. It defines one company-owned process for customers and walkers; a primary owner remains accountable until transfer is explicitly accepted; safety/privacy override ordinary queue priority; actual support channels and monitored hours must be verified; response targets, named owners/backups, refund authority and retention remain decisions required. Its proposed support severity is S0–S3.
- **POL-024 — Customer Support, Complaints, Refunds & Dispute Resolution Policy:** Draft — not approved, implemented or tested. It separates receipt, investigation, decision, payment action and closure; screenshots are not authoritative payment proof; unknown payment outcomes require provider reconciliation; closure must not occur merely because a response was sent.
- **POL-016 — Incident & Emergency Management Policy:** Draft — not approved, implemented or tested. It uses SEV-1 through SEV-4, requires immediate safety action without waiting for internal approval, and requires a case ID, severity, owner, current state, next action, evidence and accountable escalation/handoff. It explicitly says emergency contacts, on-call rota, response targets and backup contacts must be configured and tested before launch.

## Material gaps / risks
1. **Severity taxonomy mismatch:** Support UI and POL-009 use S0–S3, while POL-016 uses SEV-1–SEV-4. No approved mapping or shared severity enum is evidenced. A critical incident could be misrouted if teams interpret the labels differently.
2. **No live case intake/store:** no trusted case ID allocation, reporter verification, category/risk triage, linked booking/walk/payment references, evidence attachments or case history.
3. **No accountable handoff:** UI has an example owner but no transfer acceptance, primary-owner continuity, conflict-of-interest reassignment or escalation fallback.
4. **No emergency response command:** no live SEV queue, incident lead/backup roster, acknowledgement, timed escalation, safety clearance or emergency contact configuration.
5. **No operational SLA:** example timestamps do not establish acknowledgement/response targets, business hours, overdue logic or actual staffing.
6. **No evidence controls:** no verified restricted evidence store, redaction/access policy, retention/legal hold, immutable decision trail or incident-linked audit.
7. **No integrated workflows:** no verified connection to booking lifecycle, GPS freshness, walker safety restrictions, payment reconciliation/refund decision or notification delivery.
8. **Role/scope unproven:** UI visibility and disabled buttons are not authorization. No Rules/Functions authorization test or city/zone case-scope evidence was reviewed.
9. **Testing gap:** current tests cover prototype presentation only; no backend, integration, security, delivery drill or production evidence exists in this Admin source review.

## Required cross-team contract before implementation
- Team 01: canonical case and incident records; unique IDs; case-to-booking/walk/payment links; status transitions; server timestamps; evidence references; immutable audit events.
- Team 01: server-enforced capabilities and geographic scope, least-privilege projections, restricted evidence access, retention and Rules/Functions tests.
- Operations/Founder: approve one severity taxonomy and explicit POL-009 ↔ POL-016 mapping; name primary/backup Support Lead, Safety Lead, Finance and area owners; approve response/update targets, operating coverage, emergency contacts and backup escalation.
- Notifications: verified channels, delivery status semantics, retry/idempotency and emergency fallback; urgent safety response must not depend on push delivery alone.
- Finance: authorized refund/payment/payout handoff; support agents cannot promise or execute unapproved financial remedies.
- QA: case lifecycle, role/scope denial, transfer acceptance, conflict-of-interest, urgent escalation, missed acknowledgement, offline fallback, evidence privacy, reopen/appeal, payment dispute and closure acceptance tests.

## Safe Admin-only next steps
- Keep Support as an explicitly labelled prototype; retain disabled mutations.
- Do not invent SLA timers, contact numbers, staff coverage or case status.
- Once policy and backend contract are approved, build read-only scoped case views first, then controlled mutations with server-side authorization and audit.
- Keep urgent incident response independent of routine support ticket closure and push delivery.
- Do not modify Firebase schema, Rules, indexes, Functions, Storage or production data from this Admin repository.

## Verification boundary
Static source and Notion policy inspection only. The Flutter test file was read but not executed in this audit. No emulator, Rules/Functions, notification delivery, contact-channel, emergency drill, SLA or production test was performed. No application code was changed.

## Decision
**NO-GO for production Support/Incident operations** until Founder-approved policies, unified severity mapping, verified channels/on-call coverage, backend case/incident contracts, role/scope enforcement, evidence controls, notifications, training and end-to-end drills are implemented and independently evidenced. Keep PR #51 open/draft; do not merge or deploy based on this audit.
