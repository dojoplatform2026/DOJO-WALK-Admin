# DOJO WALK Admin — Company-Aligned File Structure

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Status: target architecture / migration plan; not a claim that all files have already been moved.

## 1. Canonical company structure

Pilot management hierarchy (from Company Master / Owner Control Center):

`Founder / CEO → Central Admin → Area Manager → Supervisor → Walker / Partner`

- Supervisor is included in the agreed company reporting flow, but its exact app permissions and whether it needs a distinct authenticated role must be explicitly defined and tested before implementation.
- Supervisor is limited to assigned tasks and records within the relevant Area; it must not receive global Admin access by default.
- Founder/CEO retains company-wide policy, access, approval and go/no-go authority.
- Central Admin operates the company-wide control centre and configures access/scopes.
- Area Manager works only within assigned service-area scope.
- Walker / Partner is the field-work role; it is not an admin navigation tier.
- Enforce role and scope on the server / Firebase Rules, not only by hiding UI elements.

Separate service geography hierarchy:

`India → State/UT → District → City → Area → Locality`

Do not confuse job roles with geographic nodes. For example, an Area Manager's assigned Area is a scope reference, not a nested source-code folder or a new geography record.

## 2. Target Flutter structure

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    app_dependencies.dart
  core/
    config/
    errors/
    permissions/
    scope/
    theme/
    utils/
  data/
    contracts/
    repositories/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    access_control/
      data/
      domain/
      presentation/       # Founder/CEO-approved roles, status, scopes, audit views
    area_management/
      data/
      domain/
      presentation/       # Area Manager assignments and permitted-area summaries
    service_location/
      data/
      domain/
      presentation/
      widgets/            # India → State/UT → District → City → Area → Locality
    live_operations/
      data/
      domain/
      presentation/       # Live booking/walker state and permission-aware My Location
    bookings/
      data/
      domain/
      presentation/
    walkers/
      data/
      domain/
      presentation/       # Walker/Partner records, availability and verification
    coupons/
      data/
      domain/
      presentation/
    payments/
      data/
      domain/
      presentation/       # Server-confirmed payment/refund/payout status only
    audit/
      data/
      domain/
      presentation/
  shared/
    widgets/
    services/

test/
  core/
  features/
    auth/
    access_control/
    area_management/
    service_location/
    live_operations/
    bookings/
    walkers/
    payments/
    audit/
  integration/
docs/
  architecture/
  decisions/
  runbooks/
```

## 3. Responsibilities and boundaries

- `auth`: identity/session and active account checks; must not own business-role policy alone.
- `core/permissions` and `core/scope`: typed role/capability checks and geographic scope model shared by screens. These are UX safeguards; backend authorization remains authoritative.
- `access_control`: role/status/scope assignment UI and audit history; sensitive changes require trusted server functions and approval policy.
- `area_management`: maps an Area Manager to explicitly assigned Area IDs and displays only authorized scope; Supervisor tasks must remain within the Area Manager's authorized Area and explicitly assigned work.
- `service_location`: geographic catalog, boundaries, import/reconciliation and trusted activation workflow.
- `live_operations`: operational status, booking/walker activity, location freshness and privacy-aware location display.
- `walkers`: partner onboarding, document verification status, weekly availability and leave requests according to approved policy.
- `payments`: payment provider confirmation, coupon accounting, refund and walker payout views; never infer payment success from client state.
- `audit`: append-only/read-only audit views where supported; do not edit audit records from the client.

## 4. Navigation rules

- Dashboard is the Central Admin overview and includes the live-operations summary; avoid a redundant standalone Live screen unless a distinct operational workflow justifies it.
- Navigation items are capability- and scope-aware. A hidden menu is not a security boundary.
- Area Manager views must be limited to assigned Areas and their descendants.
- Walker / Partner work actions belong in the Partner app. Admin may review/monitor them but should not duplicate the field-worker app as an admin screen.
- Founder/CEO-only approvals and company-wide controls must be explicitly distinguished from day-to-day Central Admin operations.
- Do not expose “Walker nearby” as a fact unless authorized, sufficiently fresh location data exists; otherwise show “Not checked” / “Location unavailable”.

## 5. Migration and file-safety rules

1. Keep the new presentation layer under `lib/features/**/presentation`; do not add new fresh UI into legacy `lib/screens/**`.
2. Keep Firestore and callable code behind typed repositories/data adapters; no direct client writes to protected location, access-control, payment or audit records.
3. Before moving or deleting a legacy file, search imports/routes/tests/assets and confirm no live dependency remains. Prefer small, tested moves over a large blind rename.
4. Preserve reference datasets and historic decisions. Do not use file cleanup to delete business data or historical policy.
5. Add tests for role × scope access, unauthorized access, parent-selection changes, callable payloads and error states.
6. Record actual file moves and test evidence in this document; do not mark a target folder as implemented merely because it is listed here.
7. Merge/deploy only after review, all required CI checks pass on the current PR head, backend contracts are verified, and explicit Founder/CEO approval is given.

## 6. Current repository observation

The fresh branch currently contains both the new feature-first areas and legacy top-level paths such as `lib/screens`, `lib/services`, and `lib/data`. They are intentionally retained for dependency inventory. Therefore, the repository is **not yet fully normalized to this target structure**. The next implementation phase is to inventory imports and classify each legacy file as (a) keep as shared/domain/data support, (b) migrate into the relevant feature, or (c) remove only after dependency and test proof.

## 7. Acceptance checklist

- [ ] Company hierarchy matches Company Master; no unapproved Supervisor tier.
- [ ] Role and geographic scope are separate typed concepts.
- [ ] Role/scope enforcement is verified server-side and in Rules/callables.
- [ ] Every active feature has a clear data/domain/presentation boundary.
- [ ] Legacy `screens/services/data` files are inventoried and classified.
- [ ] Tests and imports pass after each migration step.
- [ ] Current-head CI, emulator authorization tests and web build pass.
- [ ] PR remains unmerged and no production deploy occurs before approval.
