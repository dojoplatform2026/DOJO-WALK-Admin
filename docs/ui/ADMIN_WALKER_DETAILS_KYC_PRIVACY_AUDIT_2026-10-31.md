# DOJO WALK Admin — Walker Details, KYC & Activity History Audit

- Date: 2026-10-31
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (Open / Draft)
- Audited source head before this report: `8bedab0f408a7ef11db71f5fead831085c1a9651`
- Scope: Admin Walker Details UI, KYC viewer, account security dialog, activity history, related tests.
- No Firebase repository, Firestore Rules, Storage Rules, deployed data, Partner/Customer source, merge, or deployment changed.

## 1. Files reviewed

- `lib/features/walkers/screens/walker_details_screen.dart`
- `lib/features/walkers/widgets/walker_details_sections.dart`
- `lib/features/walkers/widgets/kyc_document_viewer_dialog.dart`
- `lib/features/walkers/widgets/walker_activity_history_dialog.dart`
- `lib/features/walkers/widgets/walker_security_dialog.dart`
- `lib/features/walkers/models/walker_admin_model.dart`
- `lib/features/walkers/services/walker_admin_service.dart`
- `test/features/walkers/walker_details_screen_test.dart`
- `test/features/walkers/walker_details_sections_test.dart`
- `test/features/walkers/walker_details_dialogs_test.dart`

## 2. Confirmed UI behavior

- Walker Details listens to one walker document via `watchWalker(uid)`; it does not fetch the full walkers collection itself.
- Loading, missing-record and stream-error states are represented; Retry rebuilds the widget.
- Profile sections display personal details, phone/email, date of birth, current address, work location, zone IDs, availability, KYC document tiles, performance counters and account decision metadata.
- KYC UI currently renders Aadhaar Front, Aadhaar Back and PAN Card references. Missing references disable View; document open errors are converted to a user-facing message.
- Activity History uses a bounded audit listener: targetType + targetId filters, createdAt descending order, limit clamped to 1–200 (default 50).
- Security dialog is read-only; it displays account status, verification status, approved/active flags, application submitted and last decision metadata.
- Lifecycle decision buttons are currently disabled in this branch because POL-004 is draft and verifier/approver separation is unresolved.
- Widget tests cover loading, missing record, stream failure, profile rendering, disabled lifecycle action, KYC reference availability, activity loading/empty/error and narrow/wide layouts. This source review does not itself execute tests.

## 3. Data-minimization and privacy findings

### High — broad raw profile payload is retained in the UI model
`WalkerAdminModel.fromMap` stores the complete Firestore walker document in `rawData` and retains the KYC map. The details widget reads selected values, but the complete payload remains available to every consumer of the model. This is not a field-level access boundary.

Required follow-up: Backend must define a least-privilege Admin profile projection and a separately authorized KYC document reference endpoint/read path. Avoid returning full Aadhaar/PAN metadata or unrelated private fields to list screens.

### High — full personal contact and address shown together
Details screen displays phone, email, date of birth, full residential address and work location in one view. The current screen has no visible role-based masking or reason/need gate in the inspected widget.

Required follow-up: confirm which roles (Central Admin, City Manager, Zone Supervisor) may see full contact, DOB, residential address and work zone. Add server-enforced read scope; UI masking alone is not authorization. If partial masking is approved, reveal should be explicit, audited and time-bounded.

### High — KYC document URL handling needs a Storage contract
KYC viewer accepts direct HTTPS URLs or Firebase Storage references/paths and resolves Storage paths using `getDownloadURL()`. The Admin source does not prove that each returned URL is short-lived, that the underlying Storage object is protected by current user/role Rules, or that document references are restricted to the requested walker's own KYC folder.

Required follow-up: Backend/Storage team to define canonical object path, ownership binding, allowed MIME types/size, upload validation, read authorization, URL lifetime/revocation expectations and access audit events. Do not rely on obscurity of Storage paths or UI hiding. Confirm whether arbitrary HTTPS document URLs are an allowed legacy format; otherwise reject them at the canonical contract boundary.

### Medium — activity history exposes actor and free-text reason
Activity history renders actor UID and reason. This is useful for accountability but should be scoped to authorized roles and the specific walker. Current source filters by walker target and limits results; effective Rules enforcement and composite index deployment were not verified.

### Medium — performance metrics are read from walker profile fields
Total walks, completed walks, rating and cancellations are rendered from profile fields if present. The inspected UI does not establish who maintains these aggregates, when they are reconciled, or whether stale/missing values are clearly distinguished from authoritative metrics. UI fallbacks say Not available, but a numeric profile field can still be stale.

Required follow-up: identify trusted aggregate writer, definition, freshness and reconciliation before using these metrics for operational decisions.

## 4. Governance and workflow findings

- The details screen contains approve/reject/suspend/reactivate/correction action code, but `_lifecycleActionsEnabled = false` keeps those controls unavailable in this validation branch.
- The service transaction currently permits only active `super_admin` to perform lifecycle actions and writes walker state plus audit record atomically.
- POL-004 is described in source comments as draft. Do not enable lifecycle buttons or treat the current Super Admin-only service as final governance until approved policy confirms verifier/approver separation, City/Zone responsibilities, Founder/Central authority and audit requirements.
- Security dialog is informational; it does not actually change authentication or login access.

## 5. Test coverage and missing cases

Present tests cover core loading/rendering, KYC missing/available references, activity stream failure/empty state, and responsive widths.

Add after policy and data contracts are approved:
- Role matrix tests for Central Admin, City Manager, Zone Supervisor, unauthorized zone, inactive admin and unauthenticated user.
- Masked vs revealed contact/address/DOB tests, including audit of reveal if approved.
- KYC wrong-owner path, deleted object, expired/revoked URL, unsupported MIME, oversized file, malformed reference, non-HTTPS URL and Storage permission-denied cases.
- Ensure KYC document payload/URL is not emitted in debug logs, analytics, crash reports or unrelated list views.
- Activity log pagination/cursor tests beyond first 50 records; no unbounded history listener.
- Aggregate freshness/stale/missing values and reconciliation tests.
- Tests that lifecycle actions remain unavailable until approved policy and server authorization contract are present.

## 6. Decisions / blockers

| Area | Status |
|---|---|
| Single-walker details read | Confirmed in source |
| Bounded walker activity query | Confirmed in source; deployed index/Rules not verified |
| KYC viewer reference handling | Source reviewed; Storage security/lifetime unverified |
| Role-based PII visibility | Not implemented/verified |
| Least-privilege profile projection | Not found in inspected Admin source |
| POL-004 lifecycle enablement | Blocked — draft per source comments |
| Backend/Storage Rules audit | Not performed; outside Admin-only scope |
| Production data verification | Not performed |
| Visual/device QA | Not performed |
| CI on current audit commit | Pending; see PR checks, do not infer pass from previous SHA |

## 7. Safe next step

Keep the details page read-only. Ask Backend/Firebase team to publish the canonical walker profile projection and KYC Storage authorization contract, and ask Governance/Notion to approve the role-to-field visibility matrix and POL-004 before enabling any lifecycle or sensitive-data reveal action.
