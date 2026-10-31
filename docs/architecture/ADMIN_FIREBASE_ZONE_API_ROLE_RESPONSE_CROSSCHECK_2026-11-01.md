# Admin ↔ Firebase Zone API Contract and Role Cross-Check

- Date: 2026-11-01
- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch: `ui/notion-brand-foundation-2026-10-28`
- Admin PR: #51 (Draft; keep unmerged)
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`
- Firebase PR: #40 (Draft/open/unmerged at inspection)
- Firebase branch inspected: `fix/disable-legacy-location-activation-2026-10-28`
- Firebase source head inspected: `d6f676ccb025c2a43bc86a35fd3127abb5fe5eb8`
- Firebase source file: `functions/src/index.ts`
- Scope: read-only source reconciliation. No API wiring, Firebase changes, emulator execution, merge or deployment.

## 1. Executive result

**Status: SOURCE CROSS-CHECK COMPLETE; CONTRACT APPROVAL AND INTEGRATION BLOCKED.**

The Admin service method names and most request payloads align with callable exports on the inspected Firebase Draft branch. However, this is not yet a safe integration contract.

Critical findings:

1. **Role mismatch risk:** Zone lifecycle callables require an active `admin_users/{uid}` record with exact role `central_admin`; Founder decisions require exact role `founder`. A `super_admin` role alone does not satisfy those checks. The current Admin account configuration has used `super_admin`; confirm a deliberate role/permission mapping before enabling Zone actions.
2. **Boundary upload gap:** Admin has a `reviewBoundary` method but no boundary-create/upload method in `ServiceZoneWorkflowService`. The inspected Firebase `index.ts` exports a boundary review callable, but no boundary upload/create callable. A verified boundary record therefore cannot be safely created by the current Admin service path.
3. **Error handling gap:** Admin `_call` returns map data (or wraps non-map data) but does not normalize `FirebaseFunctionsException.code` into stable UI states. Raw callable errors currently propagate.
4. **Scope gap:** The inspected callable checks active status and global role, but does not check a city/zone assignment or area scope. Do not assume Manager/Area Manager scope enforcement exists.
5. **Reactivation is executable through the dedicated activation path:** after Founder approves the reactivation submission, the same `activateServiceZone({zoneId})` checks the current approved revision/hash and performs activation. No separate reactivation execution callable was found/needed in this inspected implementation.

Do not enable UI actions based on this source comparison alone.

## 2. Exact source-level callable crosswalk

All callable functions inspected use Firebase Functions region `asia-south1`.

| Admin service method | Firebase callable | Request payload | Observed success response | Source-level authorization |
|---|---|---|---|---|
| `saveDraft` | `saveServiceLocationWithNameIndex` | `{locationType:"zone", locationId?, payload:{stateId,districtId,cityId,name}}` | `{ok:true, locationId, locationType:"zone"}` | Active `central_admin` for Zone |
| `reviewBoundary` | `reviewServiceLocationBoundary` | `{boundaryId, decision:"verified"|"rejected", notes}` | `{ok:true,boundaryId,locationId,locationType,decision}` | Active `central_admin` |
| `submitForFounderReview` | `submitServiceZoneForFounderReview` | `{zoneId}` | `{ok:true,zoneId,revision,boundaryHash,workflowStatus:"submitted"}` | Active `central_admin` |
| `decideFounderApproval` | `decideServiceZoneFounderApproval` | `{zoneId,decision,notes}` | `{ok:true,zoneId,revision,workflowStatus}` | Active `founder` |
| `activate` | `activateServiceZone` | `{zoneId}` | `{ok:true,zoneId,locationType:"zone"}` | Active `central_admin` |
| `requestDeactivation` | `requestServiceZoneDeactivation` | `{zoneId,notes}` | `{ok:true,zoneId,revision,workflowStatus:"deactivation_submitted"}` | Active `central_admin` |
| `deactivate` | `setServiceLocationStatus` | `{locationType:"zone",locationId:zoneId,isActive:false}` | `{ok:true,locationId,locationType:"zone",isActive:false}` | Active `central_admin`; exact Founder-approved revision/hash required |
| `emergencySuspend` | `suspendServiceZoneForEmergency` | `{zoneId,reason,severity:"SEV-1"|"SEV-2"|"SEV-3"|"SEV-4"}` | `{ok:true,zoneId,workflowStatus:"suspended",founderNotificationQueued:true}` (repeat may return `alreadySuspended:true`) | Active `central_admin` |
| `requestReactivation` | `requestServiceZoneReactivation` | `{zoneId,reason}` | `{ok:true,zoneId,revision,workflowStatus:"reactivation_submitted"}` | Active `central_admin` |

**Important:** The Admin client currently calls `reviewServiceLocationBoundary` but has no corresponding boundary upload/create method. This table is not proof that the end-to-end boundary lifecycle can be completed from Admin.

## 3. Role authorization findings

Observed in Firebase source:

- `saveServiceLocationWithNameIndex`: general location saves permit active `super_admin` or `admin`, but Zone save/edit is explicitly restricted to active `central_admin`.
- `reviewServiceLocationBoundary`: active `central_admin`.
- `submitServiceZoneForFounderReview`: active `central_admin`.
- `requestServiceZoneDeactivation`: active `central_admin`.
- `suspendServiceZoneForEmergency`: active `central_admin`.
- `requestServiceZoneReactivation`: active `central_admin`.
- `activateServiceZone` and `setServiceLocationStatus` deactivation: active `central_admin`.
- `decideServiceZoneFounderApproval`: active `founder`.

### Required decisions before integration

1. Confirm whether the platform role model will use distinct `central_admin` and `founder` values, or a server-authoritative permission mapping. Do not silently treat `super_admin` as `central_admin`.
2. Define whether Super Admin can perform Central Admin tasks, and if so, implement that delegation explicitly in backend authorization and tests.
3. Define whether Founder is a distinct account role and how the UI identifies the Founder review queue.
4. Define emergency-suspension authority more narrowly if not every Central Admin should be able to suspend any Zone.
5. Add city/zone scope checks if Central/Area/City Manager boundaries are intended to restrict access. Current inspected callables do not demonstrate such scope checks.
6. Manager and Supervisor are not authorized by the inspected Zone callables; UI must not expose privileged lifecycle actions to them.

## 4. Error contract observed

Firebase callable failures use `HttpsError` codes. The following are observed source-level examples, not an exhaustive stable public API:

| Firebase code | Observed conditions | UI handling recommendation |
|---|---|---|
| `unauthenticated` | No Firebase Auth user | Sign-in required; preserve draft form locally |
| `permission-denied` | Missing/inactive admin or role mismatch | Show access denied; do not offer retry as if transient |
| `invalid-argument` | Missing/invalid IDs, unsupported decision, missing reason/notes, protected payload field | Field-level validation where safely identifiable |
| `not-found` | Zone/boundary/parent record missing | Refresh authoritative data; show record unavailable |
| `already-exists` | Duplicate normalized name or already-submitted revision | Show conflict/already submitted; refresh list |
| `failed-precondition` | Missing verification/approval, stale hash/revision, wrong workflow state, parent hierarchy mismatch, attempted generic activation | Explain blocked prerequisite and next permitted step |
| `aborted` | Ancestry/boundary changed during transaction | Safe retry after refreshing current record |
| `internal` / unknown | Unhandled callable/server failure | Generic safe error + correlation ID if available; never claim success |

Recommended client mapping must preserve the Firebase code and message for diagnostics while showing a safe, user-readable message. Avoid relying on exact error message text as a permanent contract; approve stable error identifiers in POL-041.

## 5. Request validation and state-machine details

- Zone save payload accepts only `stateId`, `districtId`, `cityId`, `name`; boundary, activation, approval and revision fields are server-managed.
- Save validates parent records and their Country/State/District ancestry. A Zone is created inactive, workflow status `draft`, and revision is managed by the server.
- Zone name index is updated transactionally. Duplicate name under the selected parent returns `already-exists`.
- Boundary review requires a pending boundary record, source name/reference, valid polygon and review notes (1–2000 characters). Verification binds the boundary to its owning Zone and increments Zone revision.
- Founder submission requires current verified Zone boundary; response contains revision and boundary hash.
- Founder decision choices observed: `approve`, `reject`, `changes_required`, `deactivate`, `reactivate`. Non-approve decisions require notes; the callable validates notes as a string up to 2000 characters.
- Activation checks current Zone hierarchy, verified polygon, Founder approval, exact approved revision and boundary hash. Generic status callable rejects `isActive:true`.
- Deactivation is a two-step flow: Central Admin request → Founder decision `deactivate` → Central Admin executes `setServiceLocationStatus(...isActive:false)` against the approved current revision/hash.
- Emergency suspension requires reason (max 2000 characters) and severity from SEV-1…SEV-4. It immediately sets the Zone inactive/suspended, clears usable approval metadata and queues a durable Founder inbox item. Source comments explicitly say push/email delivery is not configured here.
- Reactivation request increments revision and requires currently verified boundary; Founder `reactivate` decision produces an approved state, then Central Admin can use the dedicated `activateServiceZone` path.

## 6. Admin client gaps

Inspected Admin file: `lib/features/service_location/services/service_zone_workflow_service.dart`.

| Gap | Evidence | Required follow-up |
|---|---|---|
| Boundary upload/create absent | Service exposes `reviewBoundary`, but no upload/create method | Backend to provide/confirm trusted boundary ingestion contract; Admin to implement only after approval |
| Error normalization absent | `_call` directly awaits callable and returns Map; no FirebaseFunctionsException mapping | Add typed error/result layer and unit tests before enabling UI |
| Role mapping unresolved | Backend expects exact `central_admin` and `founder` | Align Admin auth/role claims and backend authorization |
| Scope checks not evident | Callable role checks do not validate city/zone assignments | Backend to specify and test scope enforcement |
| Read contract incomplete for this flow | `watchZones` queries `service_zones`; no hierarchy catalog reader is in this service | Approve authoritative catalog read API/repository |
| UI remains disconnected | Create Zone screen uses sample hierarchy and local geometry; save/review actions disabled | Keep disabled until catalog, upload, contract, role and emulator tests are ready |

## 7. Required cross-team decisions

| Decision | Owner | Status |
|---|---|---|
| Confirm `super_admin` vs `central_admin` authority/delegation | Product governance + Backend | Pending |
| Confirm Founder role/claim and review permissions | Product governance + Backend | Pending |
| Define city/zone scope enforcement for Central/Area/City Manager roles | Backend + Admin | Pending |
| Define boundary create/upload callable, payload, storage location and response | Backend/Firebase | Pending |
| Define stable error identifiers and client-safe messages | Backend + Admin | Pending |
| Confirm emergency suspension role scope and notification delivery | Product governance + Backend | Pending |
| Approve reactivation final state transition and audit behavior | Backend + Product governance | Source path observed; formal approval pending |
| Record approved contract in Notion POL-041 | Team 01 + Team 02 | Pending |

## 8. Evidence and limitations

- Admin service inspected at the Team 02 branch.
- Admin companion UI/callable audit and Zone acceptance matrix inspected.
- Firebase `functions/src/index.ts` and `functions/test/zone_service_location.integration.test.cjs` inspected at Firebase PR #40 head listed above.
- Firebase PR #40 was Draft/open/unmerged at inspection. Its PR description states it is diverged from its target integration branch and requires conflict-aware alignment plus fresh exact-head emulator CI.
- This task did not run emulator tests, Firestore Rules tests, callable tests, or production checks.
- No Firebase source, Rules, indexes, data or deployment were changed.
- No Admin API wiring was performed.
- PR #51 remains Draft; do not merge/deploy.

## 9. Next safe step

Team 01 should answer the pending decisions and approve the canonical API/error/role contract in Notion POL-041. Team 02 should then update the client service and tests against that approved contract, starting with role/error handling and a boundary-ingestion design. Keep all privileged UI actions disabled until emulator-backed acceptance tests pass on the exact aligned Firebase PR head.
