# Fresh Admin Backend/API Inventory — 2026-10-24

Branch: `feature/admin-fresh-architecture-2026-10-24`
Scope: source inspection only. No production data changed; no deployment or merge performed.

## Verified existing backend contract

Source checked on the current `main` branch of `dojoplatform2026/DOJO-WALK-Firebase`:

- `functions/src/index.ts` (blob `2b13994aff949f38e626e1929422e5de84755312`)
- `firestore.rules` (blob `104467bab5dcc66c01a1f0f70df321ac0b193249`)
- `firebase.json` and `functions/package.json`

### Trusted callable Functions

| Callable | Region | Fresh Admin integration contract | Security boundary |
|---|---|---|---|
| `setServiceLocationStatus` | `asia-south1` | `{ locationType, locationId, isActive }` | Requires signed-in active `admin_users/{uid}` with `role == super_admin`; City/Area activation is rejected here. |
| `activateServiceLocation` | `asia-south1` | `{ locationType: city/area, locationId }` | Separate activation path; requires a verified, matching boundary and validates hierarchy/geometry. |
| `reviewServiceLocationBoundary` | `asia-south1` | `{ boundaryId, decision: verified/rejected, notes }` | Requires active super_admin; server validates boundary and records review. |

Do not write activation/status/review fields directly from the new UI. Invoke the trusted callable and then refresh/read server state.

### Service-location collections seen in the existing client/backend contract

- `service_countries`
- `service_states`
- `service_districts`
- `service_cities`
- `service_areas`
- `service_localities`
- `service_location_name_indexes`
- `service_location_boundaries`
- `service_location_imports`

The client service also uses Firestore reads/streams and trusted unique-name save/index logic. Reuse is allowed only behind a fresh repository/service layer; do not copy old screens/widgets.

## Important compatibility findings

1. The Firebase `main` source now recognizes `service_districts` and optional `districtId` on City records. This is newer than some historical Admin audit documents that described District as unsupported. Do not rely on the older notes alone; check current callable payload validation, Firestore Rules allowlists, and CI together before enabling the full hierarchy.
2. Legacy City records can omit `districtId`; the new app must not silently reinterpret them or send an empty `districtId`.
3. Country/State status fields use `isActive`; District/City/Area/Locality use `isServiceActive` in the trusted status path. Read models must preserve this distinction.
4. City and Area must not be activated until a matching verified polygon is present and the trusted activation callable succeeds. Locality does not require its own polygon.
5. The current Admin `AuthService` and `AuthGate` check only `isActive == true`, but Firebase Rules and the reviewed callables require `role == super_admin`. The fresh auth layer must enforce both for UI access. Server-side rules/callables remain authoritative.
6. `firestore.rules` on Firebase `main` was read from source, but this does not prove that this exact revision is deployed to production.
7. Existing CSV parsing/preview is not proof of a safe end-to-end importer. Keep imports read-only in the fresh UI until the trusted importer contract and recovery/idempotency tests are verified.

## Fresh implementation decisions

- Keep the fresh screens separate from legacy `lib/screens/**` and old feature UI.
- Reuse Firebase initialization/configuration and verified backend contracts, not legacy presentation widgets.
- Build a new auth repository, typed service-location repository, and explicit callable adapter.
- Do not wire Add Location save/activation actions until payload allowlists and current Firebase CI are checked.
- Do not claim tests/build/deployment passed until current branch CI has actually run and been inspected.
- No legacy files deleted; no changes to `main`; no PR or merge in this step.

## Next verification gates

1. Check the complete `validateServiceLocationPayload` and Rules field allowlists for every location type against the Admin request payload.
2. Check current Firebase Actions/emulator tests for the callable contracts above.
3. Add fresh typed read/write repository methods and contract tests.
4. Wire fresh auth gate and screens only after these checks; run Flutter analyze/tests/build.


## Callable payload audit — 24 Oct 2026

Compared the fresh Dart repository against Firebase `main` source for `saveServiceLocationWithNameIndex` and its schema validator.

| Type | Fresh Admin payload | Backend contract | Result |
|---|---|---|---|
| Country | `name, code` | `name, code` | Match |
| State | `countryId, name` | `countryId, name` | Match |
| District | `countryId, stateId, name` | `countryId, stateId, name` | Match |
| City | `countryId, stateId, districtId, name` | District is optional for legacy compatibility | Safe for new records, but stricter than the backend |
| Area | `countryId, stateId, cityId, name` | Same | Match |
| Locality | `countryId, stateId, cityId, areaId, name, optional pincode` | Same allowed fields | Match |

The callable creates new records inactive by default and protects activation/boundary fields from client writes. The client checks the returned location ID. City/Area must use the separate trusted boundary-review/activation flow; Locality has no own-polygon requirement.

### Follow-up items before declaring Add Location production-ready

1. **Legacy City compatibility:** fresh dropdown flow requires District for City, Area and Locality selection, but the backend supports existing Cities without `districtId`. This is not a payload vulnerability; it is a UI/legacy-data compatibility gap. Keep legacy records unmodified. Decide whether to show an explicitly labelled legacy/no-District option or migrate those records through a separately reviewed migration before production.
2. **Parent selection state:** dropdowns clear descendants when an ancestor changes; add widget tests for every parent change and for a selected option disappearing from a live stream.
3. **Save verification:** after callable success, refresh/re-read the created record and show its server-confirmed inactive status; the current success message is based on callable response plus generated ID and does not itself re-read the record.
4. **Authorization contract:** `saveServiceLocationWithNameIndex` allows active roles `super_admin` and `admin`, while the fresh UI intentionally allows only active `super_admin`. Keep the stricter UI gate; verify this role split is intentional and test that server-side privileged operations remain super_admin-only.
5. **Authenticated emulator test gap:** branch CI build/geometry success is not evidence of a real signed-in admin save, duplicate-name rejection, inactive-admin rejection, or the UI refresh path. Add/verify emulator integration tests for these paths before marking Add Location verified.

No production call was made, no Firestore records were changed, and no deployment or merge was performed by this audit.
