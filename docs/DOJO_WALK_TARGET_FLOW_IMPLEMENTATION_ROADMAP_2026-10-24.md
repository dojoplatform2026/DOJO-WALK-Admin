# DOJO WALK — Target Company Flow and Implementation Roadmap

Date: 2026-10-24  
Status: **Planning contract only** — current Admin app, deployed Firestore Rules, Firebase data, and production behavior are intentionally left unchanged.

## 1. Instruction and safety boundary

The current Admin app and Firestore setup are the existing baseline. Do not replace, migrate, deploy, merge, or modify production behavior just to make the target model look complete. Prepare the target architecture and implementation in review branches, with tests and compatibility steps, then ask for approval at the release gates.

No production accounts, roles, rules, documents, bookings, walkers, or location records are changed by this document.

## 2. Company operating hierarchy

**Founder / CEO → Central Admin → Area Manager → Supervisor → Walker / Partner**

Customer remains a separate app and customer-facing flow.

### Authority interpretation

- **Founder / CEO:** final company authority; approves company-wide policies, pricing/discount limits, coupon rules, payout/refund/cancellation exceptions, service-area launch approvals, and appointments/suspensions of Central Admin. Every high-risk action must record actor, target, reason, timestamp, and audit event.
- **Central Admin:** manages day-to-day company operations, location setup, booking operations, walker verification, customer support, reconciliation, and Area Manager assignments within Founder-approved policy. Cannot exercise Founder-reserved powers or grant itself Founder authority.
- **Area Manager:** manages only explicitly assigned Area(s) and their verified descendants. Handles local bookings, walkers, attendance/availability, complaints, and escalation. Cannot access unrelated Areas or expand its own scope.
- **Supervisor:** operational reporting line under an Area Manager. Supervisor handles only tasks and records explicitly assigned to them within the relevant Area. This is an operational level in the company hierarchy; do not silently grant it global Admin permissions. Its exact UI permissions and whether it needs a distinct authenticated role must be decided and tested before implementation.
- **Walker / Partner:** uses the Partner app; sees only their own onboarding, availability, assigned walks, and permitted walk records.
- **Customer:** uses the Customer app; sees only their own profile, pets, addresses, bookings, payments and permitted support interactions.

## 3. Admin app structure to prepare

Keep one Admin app with role-appropriate navigation; do not build separate Admin apps for each management level.

1. **Founder Control Center** — company-wide overview and Founder-only approvals/settings.
2. **Central Admin dashboard** — operational overview and permitted management actions.
3. **Area Manager dashboard** — assigned-Area-only operational view.
4. **Supervisor work queue** — assigned tasks and Area-bounded records, subject to a separately reviewed permission contract.
5. **Shared modules** — Dashboard, Bookings, Walkers/Partners, Service Location, Live Operations, Support/Complaints, Coupons/Payments as allowed by role.

The UI may hide unavailable actions, but UI visibility is never the security boundary. Firestore Rules and every privileged backend callable must independently enforce role and data scope.

## 4. Required authorization contract

- Default deny; explicit module + action + data-scope permissions.
- The target company roles are Founder/CEO, Central Admin and Area Manager. Supervisor is not automatically treated as a global Admin role; settle its least-privilege role model before coding.
- Never silently convert existing `super_admin` users into Founder or Central Admin. Keep the current legacy gate until a reviewed, tested migration is approved.
- Role grants, revocations, Area assignments and privileged changes must be server-owned and audited. Users cannot grant themselves roles or scopes.
- Area access is based on canonical service-location IDs and verified ancestry, not free-text `area`, `zone`, city, or PIN alone.
- Revocation must take effect in Rules and backend callables; stale UI state is not authority.
- Founder-only actions must be denied to Central Admin and all lower levels even if they call an API directly.

## 5. Dependency order — prepare in this order

### Phase A — Admin baseline and UI
- Preserve the current app and current production behavior.
- Finish reviewing Dashboard, Add Location and Live Operations screens against the target hierarchy.
- Mark every action with its intended role and scope.
- Wire loading, empty, error and permission-denied states; do not present mock data as live data.
- Run build and existing tests on the exact review commit.

### Phase B — Firebase authorization contract
- Inventory legacy `admin_users/{uid}`, current Rules, and each privileged callable.
- Design the server-owned canonical membership/role and Area-assignment model.
- Test self-elevation denial, role revocation, cross-Area denial, Founder-only action denial and audit events in emulators.
- Keep legacy authorization active until the coordinated compatibility plan is approved; no one-repository role flip.

### Phase C — Trusted location-to-booking link
- Customer currently writes booking documents directly from `booking_confirmation_screen.dart`; preserve compatibility while designing the migration.
- Verify the saved customer address schema and whether it contains a canonical verified Locality reference.
- Design trusted booking creation that derives Area server-side from verified address/location ancestry. Do not trust client-submitted Area ID, price, status, walker assignment or payment status.
- Migrate Customer to the callable with retry/idempotency handling before removing the old direct-write path.
- Do not expose unresolved legacy bookings to Area Managers; reconcile ambiguous records explicitly.

### Phase D — Walker and Supervisor scope
- Inventory existing walker location fields and assignment data.
- Introduce reviewed, server-owned canonical Area assignments; do not infer permission from free-text location fields.
- Define Supervisor's exact task permissions and assigned scope.
- Dry-run backfills, report ambiguous records, manually reconcile uncertain assignments, and audit migration batches.

### Phase E — Release gates
- Emulator tests pass for Rules and Functions on the exact commit.
- Admin, Customer, Partner and Firebase contracts are compatible.
- Staged deployment and post-deploy checks are documented.
- Founder/CEO approves high-risk role/policy changes and first service-area launch.
- Only then request explicit approval to merge/deploy. Never delete branches containing unmerged work.

## 6. Acceptance checklist

- [ ] Existing production Admin login and Firestore behavior remain unchanged until approved cutover.
- [ ] Founder/CEO can perform Founder-reserved actions; lower roles cannot.
- [ ] Central Admin has operational access without Founder authority.
- [ ] Area Manager sees only assigned Areas and permitted descendants.
- [ ] Supervisor is limited to explicitly assigned work and scope.
- [ ] Walker/Partner and Customer data remain tenant/owner-scoped.
- [ ] No self-grant or client-controlled role/Area assignment.
- [ ] Booking Area is derived from trusted verified location data.
- [ ] Ambiguous legacy bookings/walker assignments are quarantined for reconciliation, not guessed.
- [ ] Rules + callable emulator tests, build, and integration tests pass on the exact release candidate.
- [ ] Production deploy/merge is separately approved and verified.

## 7. Current status

This file records the target flow and dependency order only. It does **not** mean the role system, Supervisor permissions, trusted booking callable, Area Manager scope, production Rules, or migration are implemented. Continue with review-branch documentation and source checks while preserving the current production setup.


## 8. Verified source-review findings — 2026-10-24

These findings are source-review evidence, not production deployment verification:

1. **Legacy Admin identity gate remains:** `lib/core/auth/admin_identity.dart` currently allows entry only when `isActive == true` and `role == 'super_admin'`. This is a UI gate, not a replacement for Firestore Rules or callable authorization. Do not switch it to target roles until membership schema, role grants, scope checks, compatibility, and emulator tests are ready together.
2. **Service Location writes use trusted callable:** the reviewed Add Location save path routes named-location saves through `saveServiceLocationWithNameIndex`; new locations are intended to remain inactive until their required review/verified-boundary conditions are satisfied. Boundary drafts and import metadata have separate paths and need their own rules/permission review.
3. **Hierarchy mismatch remains a blocker:** the current Admin/Firebase location model has historically represented City directly under State (with District/City not yet separated into the target canonical chain). The requested State → District → City → Area → Locality model needs a coordinated Admin + callable + Rules + import contract; a UI-only dropdown change is insufficient.
4. **Booking authorization migration is not ready:** the Customer app's reviewed confirmation screen writes booking documents directly to Firestore and supplies a pickup address ID/map. The canonical saved-address schema and verified Locality linkage are not yet confirmed. Do not change production Rules to require a server-derived Area until a trusted booking-creation path and coordinated Customer migration are tested.
5. **Live Operations is not yet a verified live feed:** Dashboard embeds the Live Operations screen, and the UI has a My Location affordance. Walker-nearby/live-feed information must remain explicitly unknown or pending until trusted location feeds, consent, freshness, scope checks, and backend actions are verified.

### Review-commit CI evidence

For permission-matrix commit `78f085663656b250bfee797a423557f7763abbac`, the following GitHub Actions checks completed successfully:

- Service Location Geometry Tests — run `40102760422` (#694).
- Admin Web Build Check (No Deploy) — run `40102760408` (#856).
- Admin Main Full Validation (No Deploy) — run `40102760396` (#177).

These results validate that commit's CI checks only; they do not prove production deployment, complete role authorization, or that later commits have passed CI.


## 9. District schema cross-repository review — 2026-10-24

Reviewed the Admin review branch and Firebase review branch `security/first-area-founder-approval-2026-10-24` source. This is a static source finding; no callable, Rules, data, or deployment was changed.

### What is already present

- Admin has a `ServiceDistrict` model and `service_districts` collection contract.
- Admin's name-index parent helper supports `district` and supports optional `districtId` for City while preserving legacy City records without it.
- Admin's CSV planner explicitly builds State → District → City → Area nodes in parent-first order. Import is capped and uses the trusted location-save service; it does not activate locations or create boundaries.
- The inspected Firebase review branch's `location_name_index.ts` allowlists `district`, and its `saveServiceLocationWithNameIndex` callable includes District and supports both legacy two-parent and District-linked three-parent City index tuples. Therefore, saying “District is entirely absent from the current Firebase review branch” would be inaccurate. Production deployment parity is still unverified.

### Status-callable descendant guard review — follow-up in progress

The initial source finding has been rechecked against the current Firebase PR #34 head. The State deactivation guard is now present in the review branch: it checks active `service_districts` by `stateId` and also retains the active direct-City/Area checks. This is review-branch source evidence only; it is not proof of deployed behavior.

A separate District descendant gap remained: the previous guard queried `service_areas.districtId`, but the authoritative Area schema does not persist `districtId`. A review-branch-only fix has now been committed to resolve District → City → Area → Locality through canonical parent links. It scans District-linked Cities, then Areas by `cityId`, then active Localities by `areaId`. The scan is deliberately bounded and fails closed for unusually large descendant sets that require manual review.

Regression coverage was updated to exercise:
- active District-linked City blocks District deactivation;
- an active Area blocks deactivation even when its parent City is inactive and the Area has no unsupported `districtId` field;
- an active Locality blocks deactivation even when its Area is inactive;
- deactivation succeeds after these descendants are inactive.

Firebase head `57f63573ac8665baedb64b1c0bfa9be54cf2a789` completed GitHub Actions run #518 (`40103509770`) successfully. The run completed the Functions build and Firestore Emulator Rules/Functions test step successfully, and the linked Admin checks on Admin commit `13314444a8d9560f6ee5c673bf601eb00730b937` also completed successfully: full analyze/test/web build run `40103547253`, geometry tests run `40103547255`, and web build check run `40103547363`. These are review-branch CI results, not production verification.

A further District/State race regression test was added in Firebase commit `ebcacde14f7b97cc99519cc6e223236c4aa1a59c`. GitHub Actions run #519 (`40103781681`) has now completed **SUCCESS** on that commit. The `Build, geometry and callable integration tests` job (`120901138556`) completed the Functions build and the Firestore Emulator Rules/Functions test step successfully. This confirms the regression test passed in the configured CI environment on that commit; it does not prove production deployment parity.

The next Firebase run #520 (`40104453597`) built Functions successfully but **failed the emulator integration test step**: an existing District-descendant test expected a rejection while the District had been left inactive by the preceding legacy-State test. The two newly added State guards themselves passed in that run, as did the State/District concurrency test; the failure was test sequencing/state setup, not a production deployment result. The test now explicitly reactivates the District before exercising its active-child guard in Firebase commit `779346119a9f8de2a0d4288e48b5a8e58ef4a804`. CI for that fix is pending and must pass before closing this gate.

Remaining release tests/reviews:
1. Confirm State deactivation rejects active Districts even with no active Cities/Areas, and rejects active legacy Cities directly under State.
2. Confirm District → City → Area → Locality descendant regression tests pass on the exact latest head.
3. Confirm District-linked City and legacy City-without-District saves preserve canonical name-index uniqueness and ancestry checks.

### Import and hierarchy release gates

- Keep CSV import disabled for production use until the exact Admin commit and Firebase callable/Rules commit pass together.
- Verify the 300-node import limit, stable IDs, immutable run marker, interrupted-run reconciliation, duplicate parent/name paths, and partial failure handling with tests.
- Keep all imported records inactive. City/Area activation must still require the trusted verified-boundary lifecycle and containment checks.
- Do not migrate legacy records or deploy these branch changes without explicit release approval.

## 10. Latest CI and District name-index audit — 2026-10-24

### Exact-head CI results

The following checks completed successfully on the Admin review head fb5e474908cd454eaa1517036aab83437d564979:

- Admin Main Full Validation (No Deploy), run 40105057085 (#184): Flutter analysis, complete Admin test suite, and web build succeeded.
- Admin Web Build Check (No Deploy), run 40105057087 (#863): analysis, tests, and web build succeeded.
- Service Location Geometry Tests, run 40105057166 (#701): geometry and CSV import planner unit tests succeeded.

Firebase review head 779346119a9f8de2a0d4288e48b5a8e58ef4a804 completed run 40105037875 (#521) with SUCCESS. This includes the previously failing District descendant integration test after its setup explicitly reactivates the District. These results are review-branch CI only; they do not prove production deployment parity or launch readiness.

### Name-index and ancestry review

Static review of the Firebase review branch found:

- The District-aware tuple contract has unit tests for District → City → Area → Locality parent ordering, unsafe/missing IDs, and distinct legacy vs District-aware index IDs.
- Trusted ancestry helper tests reject mismatched State/District/City/Area links and return no invented District tuple for legacy City records.
- Legacy City → District preflight is intentionally read-only: missing/ambiguous candidates do not auto-map; even a reviewed manifest still requires a separately approved write implementation.
- Existing hierarchy integration tests cover legacy parent-scoped name uniqueness, idempotent saves, rename/index replacement, and ancestry mismatch rejection.
- The callable ancestry test rejects an Area save when a City has a districtId that points to a missing District and verifies no Area/name-index write occurs.

**Important remaining blocker:** the District-aware index contract and trusted tuple helper explicitly are not yet wired into the callable write path; this is deliberate until Admin and Firebase agree on the same tuple and migration protocol. The current review did not find an end-to-end callable test proving atomic dual-index preservation for both District-linked Cities and legacy Cities without District. Pure helper tests alone are not enough to close this release gate.

### Next review steps

1. Add/verify callable-level emulator tests for District-linked City name uniqueness under a District and legacy City uniqueness under State, including attempted duplicate names and index ownership.
2. Add/verify safe rename/idempotent behavior for District-linked City, Area and Locality with consistent canonical ancestry; legacy records must retain their existing index until a reviewed dual-index migration is approved.
3. Verify the exact latest Firebase head and rerun the exact Admin head checks after any code changes. Do not merge, deploy, backfill production data, or delete unmerged branches as part of this review.


## 11. Latest callable tests and exact-head CI — 2026-10-24

### Verified review-branch results

- Firebase commit `f36c7d08f88a3011ee41f93bccac230df27f28ad` added `functions/test/district_city_callable_name_index.test.cjs`.
- Firebase Actions run #523 (`40108087619`) completed **SUCCESS** on that exact commit. The workflow completed the Functions build and Firestore Emulator Rules/Functions integration-test step, including the new callable-level cases for District-linked City duplicate scope, legacy City two-parent indexing, and District-linked City rename/index replacement.
- Admin commit `efd0e039684748484ac393541cf19fdc9a9078ee` has now been verified by all three exact-head workflows:
  - Admin Main Full Validation (No Deploy), run #185 (`40105611329`): SUCCESS.
  - Admin Web Build Check (No Deploy), run #864 (`40105611382`): SUCCESS.
  - Service Location Geometry Tests, run #702 (`40105611378`): SUCCESS.

These are review-branch checks only. They do not mean either PR is merged, production Functions/Rules match the branch, or the product is launch-ready.

### Remaining gates

1. Extend callable-level rename/idempotency and dual-index preservation coverage to District-linked Areas and Localities; verify conflicting index ownership is rejected without partial writes.
2. Review the test fixture cleanup and CI logs for unexpected emulator residue before treating the suite as release evidence.
3. Keep the production CSV import disabled until Admin and Firebase commits are jointly reviewed against the deployed schema and Rules.
4. Complete the Admin UI dependency/legacy-file audit and verify the real login + Add Location flow against emulator-backed trusted callables.
5. Keep Founder/CEO provisioning, canonical role model, Area Manager scope enforcement, deployed Rules/Functions parity, and authorized launch sign-off as explicit blockers.

No merge, deployment, production data migration, or branch deletion was performed.


## 12. Cross-repository verification checkpoint — 24 Oct 2026

### Exact reviewed heads and CI

- Admin PR #37 head: `606637059f23c64f954be2e1e05a85688fde2361` (draft/open, not merged).
  - Admin Main Full Validation run #186 (`40110437108`): SUCCESS.
  - Admin Web Build Check run #865 (`40110437589`): SUCCESS.
  - Service Location Geometry Tests run #703 (`40110437115`): SUCCESS.
- Firebase PR #34 head: `290c80be2e205dacff1bb826ce772003bcc833b0` (draft/open, not merged).
  - Trusted Location Geometry and Callable Tests run #526 (`40111078112`): SUCCESS.
  - The run built Functions and completed the root Firestore Rules/Functions emulator test step successfully.

### Important distinction

CI success confirms the checked code and tests for these commits. It does NOT establish that deployed Firebase Rules/Functions match these branches, that production credentials are provisioned, or that the complete Admin UI has passed an authenticated end-to-end emulator session.

### Remaining release blockers — do not mark complete

1. Admin: add authenticated Firebase Emulator integration coverage for live `admin_users/{uid}` revocation (active → inactive/role change/missing document) and verify the real repository signs out.
2. Admin: exercise the complete Add Location flow against Firebase Auth + Firestore + Functions emulators: allowed active admin, denied inactive/missing admin, duplicate-name rejection, callable save, read-back and inactive status.
3. Firebase: district-aware index contract is not yet confirmed wired through all callable write paths. Tests for District-linked Area/Locality rename now assert both legacy and District-aware index replacement; inspect test results and source path before treating the dual-index contract as implemented.
4. Firebase: verify conflicting index ownership is rejected without partial writes, including all supported location types and legacy records.
5. Company authorization: Founder/CEO, Central Admin and Area Manager canonical membership/assigned-Area enforcement is not implemented end-to-end. Current Admin UI and legacy Rules still depend on `admin_users/{uid}.role == super_admin`; do not silently map that role to a new role.
6. Live Operations: live booking/walker feeds and actionable state transitions remain unconnected/unverified. “Possible Walker Nearby” must remain “Not checked” until a trusted, fresh and authorized location feed exists.
7. Legacy file migration: keep legacy screens/services until a complete import/reference scan, tests and rollback review justify any deletion.

### Safe next action

Inspect the exact-head Firebase #526 test output and the callable write path for District-aware Area/Locality indexes. Then add the authenticated Admin emulator tests above. Keep PR #37 and #34 draft/open; no merge, deployment, production backfill or authority provisioning without explicit release approval.


## 11. Exact-head verification update — 2026-10-24

### Admin review head

Admin branch `feature/admin-fresh-architecture-2026-10-24`, commit `27e73a1b4ffbca2f57c5a926cc3651a9557a19b8`, completed all three checks successfully:

- Admin Main Full Validation (No Deploy), run `40111350986` (#187).
- Admin Web Build Check (No Deploy), run `40111350900` (#866).
- Service Location Geometry Tests, run `40111350910` (#704).

These checks validate the review commit's analysis/tests/build and geometry test suite. They do not prove that all Admin workflows are production-ready or deployed.

### Firebase name-index regression update

Firebase review head `eb2fc43b971f46dfb77a8585f808cd36ec60e285` completed Actions run `40112768985` (#527) successfully. The Functions build and Firestore Emulator Rules/Functions integration test step passed. The Firebase review branch added callable-level tests for District-linked City idempotent same-ID saves and rename-to-existing-sibling conflict preservation, alongside existing District-scoped duplicate, cross-District same-name, legacy City, and rename/index replacement tests.

This is Firebase review-branch CI only; it does not establish deployed Rules/Functions parity.

### Remaining gates — do not mark complete

- Admin's legacy UI identity gate still requires active `super_admin`; canonical Founder/Central Admin/Area Manager roles and server-enforced Area scope are not implemented as a coordinated migration.
- Dashboard counts and Live Operations remain pending trusted live feeds. “Possible Walker Nearby” is not verified live location evidence, and operational actions must remain disabled until backend permission/state transitions are tested.
- Confirm callable-level Area and Locality rename/idempotency coverage and legacy index compatibility.
- Confirm Customer saved-address schema and migrate direct booking writes to a trusted booking callable before enforcing canonical Area requirements in production Rules.
- Keep both PRs in draft review. No merge, deployment, production migration, role provisioning, or service-area launch approval is authorized by these CI results.
