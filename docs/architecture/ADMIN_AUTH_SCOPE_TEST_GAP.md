# DOJO WALK Admin — Auth and Scope Test Gap

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Reviewed HEAD: `4eb80e74bd6a8097e2095976ae6d69da57613c04`

## Evidence reviewed

- `lib/core/auth/admin_auth_repository.dart`: watches `admin_users/{uid}` live, requires `isActive == true` and `role == 'super_admin'`, and signs out when the live identity becomes unauthorized.
- `test/core/auth/admin_identity_test.dart`: tests active super_admin allowed; inactive super_admin, active admin, and unknown area_manager role denied. These are identity-policy tests.
- `test/core/auth/admin_identity_revocation_guard_test.dart`: newly added unit tests cover an active identity followed by inactive identity, role change, or missing identity; each expects null emission and one sign-out callback. These test the extracted revocation guard using a controlled stream, not Firebase Auth/Firestore itself.
- `test/core/auth/fresh_admin_auth_gate_test.dart`: widget tests cover retry after an auth-status stream error and the no-identity/login state.
- `lib/core/auth/fresh_admin_auth_gate.dart`: accepts an optional repository for deterministic widget tests.
- `lib/features/service_location/data/admin_service_location_repository.dart`: uses trusted callable `saveServiceLocationWithNameIndex`; after callable success, it reads the created document back and verifies the status field is explicitly false before returning success.
- Prior reviewed code HEAD `0f0be991a9e0541beaa850fbc973d19c5384d0a3` had passing CI:
  - Admin Web Build Check run `40068200291`: SUCCESS.
  - Service Location Geometry Tests run `40068200255`: SUCCESS.
  - Admin Main Full Validation run `40068200208`: SUCCESS.
- Latest prior validation at HEAD `3526810f999af277d5327654fb1d433f2f9d321a` also passed:
  - Admin Main Full Validation run `40068436623`: SUCCESS (analysis, complete Dart test suite, and Flutter Web build).
  - Admin Web Build Check run `40068437402`: SUCCESS.
  - Service Location Geometry Tests run `40068436735`: SUCCESS.
- The new commits `c10b112` and `4eb80e7` were added after those CI runs. Their CI results must be checked separately before claiming the latest HEAD passes.

## Current classification

- UI super_admin gate: IMPLEMENTED and covered by focused identity policy tests.
- Auth-gate error/retry and no-identity UI states: IMPLEMENTED and covered by widget tests in the previously passing full-validation run.
- Revocation guard behavior: IMPLEMENTED with new controlled-stream unit tests. A Firebase Emulator/integration test proving real `admin_users/{uid}` document changes trigger sign-out is STILL MISSING.
- Add Location save/read-back: IMPLEMENTED in source. An authenticated Admin-client-to-Firebase-Emulator test for the full callable + Firestore Rules read-back path is still required before production readiness.
- Backend authorization: must remain authoritative; UI gating alone is insufficient.
- Area Manager assigned-area scoping: NOT IMPLEMENTED in the fresh identity/shell reviewed here.
- Founder/CEO-only company-wide approval controls: NOT IMPLEMENTED in the fresh shell reviewed here.
- Live Operations is not yet connected to verified live walker/booking data.
- Boundary Review displays a polygon-shape preview, not a geographic map. Human source/reference verification and trusted backend checks remain necessary.

## Remaining tests before role/scope claims

1. Add/run a Firebase Emulator integration test proving a real `admin_users/{uid}` document change from active super_admin to inactive/another role revokes access and signs out.
2. Run authenticated emulator coverage for the complete fresh Add Location flow: active super_admin save, duplicate-name rejection, inactive/missing admin rejection, and client read-back of the newly created inactive record.
3. Verify server-side callable and Firestore Rules reject unauthorized roles regardless of client UI.
4. Before adding Area Manager UI, tests must prove an Area Manager can only query/view assigned Area IDs and descendants; client-controlled IDs must not widen access.
5. Founder/CEO-only actions must require approved server-side capabilities and leave an audit record before they are implemented.

## Company alignment

The approved management structure is Founder / CEO → Central Admin → Area Manager → Walker / Partner. Geographic hierarchy is separate: India → State/UT → District → City → Area → Locality. The app must not treat a geographic selection as a substitute for a role's authorized scope.

Do not add new role screens, assume Area Manager access, or loosen the super_admin gate until the Company Master / Owner Control Center policy and server-side authorization contract are verified together.

## Safe next action

Check CI for the new HEAD. If it passes, add authenticated Firebase Emulator coverage for actual document-change revocation and the Add Location save/read-back path. Keep PR #37 draft; do not merge or deploy until these gates and company-alignment review are complete.


## Fresh verification checkpoint — 24 Oct 2026, HEAD e4a9cc70942ef15c21a2381b6bc4acaba325c0d3

- Admin Main Full Validation (No Deploy), run 40095608794: **SUCCESS**. The job completed dependency install, full-project analysis, complete test suite, and Flutter Web build.
- Admin Web Build Check (No Deploy), run 40095608810: **SUCCESS**. The job completed analysis, full test suite, and Web build.
- Service Location Geometry Tests, run 40095608860: **SUCCESS**.
- Current source now includes a geographic polygon map widget in Boundary Review and a save → Firestore read-back → inactive-status confirmation in the Add Location repository. These are source/build/test evidence only; they do not establish that the production Google Maps key/configuration works or that a real authenticated Firebase Emulator scenario has passed.
- The current focused tests include dashboard/live-operation UI assertions, identity/revocation-guard unit tests, auth-gate retry behavior, and boundary-coordinate parsing. They are not substitutes for the still-missing authenticated Firebase Emulator tests for live admin-document revocation and the complete Add Location callable/Rules/read-back path.
- PR #37 remains **open and draft**. No merge, deployment, production data write, or branch deletion was performed.
- Remaining release blockers: verify live map/API configuration; run authenticated Emulator coverage for admin revocation and Add Location save/duplicate/inactive-admin/read-back; implement and test the canonical Founder/CEO → Central Admin → Area Manager scope model with server-enforced assigned-area restrictions; verify deployed Firebase revision parity and complete the required release review.


## Latest verified CI checkpoint — PR #37 HEAD f6dae0c20ca8408ce7e7125133716cc56a56a2d0

Checked the GitHub Actions runs associated with this exact PR head on 24 Oct 2026:

- Admin Main Full Validation (No Deploy), run 40096969588: **SUCCESS** — dependency install, complete-project analysis, full test suite, and Flutter Web build all completed.
- Admin Web Build Check (No Deploy), run 40096969626: **SUCCESS** — analysis, full test suite, and Flutter Web build all completed.
- Service Location Geometry Tests, run 40096969602: **SUCCESS** — formatting/whitespace checks, targeted analysis, and geometry/CSV planner unit tests completed.

The current branch source includes a Google Maps polygon preview in Boundary Review and Add Location save/read-back with explicit inactive-status confirmation. CI does not prove a valid production Maps API key, correct map rendering in the deployed browser, authenticated real Admin behavior against Firebase Emulator, or deployed Firebase revision parity.

**Status unchanged:** PR #37 remains open/draft. No merge, deployment, production data write, or branch deletion. The remaining authenticated Emulator tests, Founder/CEO → Central Admin → Area Manager authorization/scope implementation, live operations data connection, and release review remain blockers.
