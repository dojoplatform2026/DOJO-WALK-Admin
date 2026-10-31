# Admin Zone UI ↔ Callable Contract Audit

- Date: 2026-11-01
- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch: `ui/notion-brand-foundation-2026-10-28`
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`
- Firebase branch inspected: `fix/disable-legacy-location-activation-2026-10-28`
- Scope: read-only contract comparison. No API wiring, Firebase writes, schema/rules/functions changes, merge or deployment.

## Sources inspected

- Notion POL-040 — Admin Service Location UI: screen-by-screen design and developer checklist.
- Notion POL-041 — India Service Location API & Backend Workflow Specification.
- Admin `lib/features/service_location/screens/add_zone_screen.dart`.
- Admin `lib/features/service_location/services/service_zone_workflow_service.dart`.
- Admin `test/features/service_location/add_zone_screen_test.dart`.
- Firebase `functions/src/index.ts` on the branch above.
- Admin PR #51 and Firebase PR #40 metadata.

POL-041 explicitly labels its operation names and request envelopes as proposed logical contracts, not deployed endpoint names. Therefore the concrete callable names below are a source-level mapping observed in the Firebase Draft branch, not an approval to integrate them.

## Observed Admin service-to-Firebase callable mapping

| Admin service method | Callable and payload observed in source | Notes |
|---|---|---|
| `saveDraft` | `saveServiceLocationWithNameIndex` with `locationType: zone`, optional `locationId`, and `payload: {stateId, districtId, cityId, name}` | Server-owned name-index save; creation is inactive and does not accept boundary/activation fields. |
| `submitForFounderReview` | `submitServiceZoneForFounderReview({zoneId})` | Submission is bound to the verified boundary hash in the Firebase implementation. |
| `reviewBoundary` | `reviewServiceLocationBoundary({boundaryId, decision, notes})` | Decision is `verified` or `rejected`; requires an existing boundary record. |
| `decideFounderApproval` | `decideServiceZoneFounderApproval({zoneId, decision, notes})` | Supported decisions in both inspected sources: approve, reject, changes_required, deactivate, reactivate. |
| `activate` | `activateServiceZone({zoneId})` | Dedicated activation path; generic status callable rejects activation. |
| `requestDeactivation` | `requestServiceZoneDeactivation({zoneId, notes})` | Central Admin request; Founder decision is a separate step. |
| `deactivate` | `setServiceLocationStatus({locationType: zone, locationId, isActive: false})` | Firebase implementation requires Founder-approved current revision and boundary hash before Central Admin can execute. |
| `emergencySuspend` | `suspendServiceZoneForEmergency({zoneId, reason, severity})` | Safety-only suspension path; not activation/reactivation authority. |
| `requestReactivation` | `requestServiceZoneReactivation({zoneId, reason})` | Submits a fresh Founder reactivation decision. |

## Confirmed UI boundary

- `AddZoneScreen` is explicitly UI-only.
- State/UT → District → City → Zone is exactly four dependent selectors; no Locality selector.
- The hierarchy catalog is hard-coded example data, and existing Zone options are labelled mock.
- Boundary points are held in local widget state only; they are not uploaded or independently verified.
- Save Draft and Submit for Review are disabled.
- Boundary Review preview navigation does not submit a Zone.
- Focused widget tests cover the four selectors, parent reset behavior, mock Zone handling, disabled save/submit, preview-only navigation, narrow mobile layout, and missing boundary evidence.

These are prototype protections, not live workflow integration or production readiness.

## Integration blockers and safeguards

1. **Do not wire AddZoneScreen yet.** Its current mock hierarchy and local-only polygon cannot safely supply authoritative parent IDs, boundary IDs, revision or canonical hash.
2. **Resolve the canonical API contract before UI wiring.** POL-041 names logical operations; the Firebase branch exposes concrete callable names. Record the approved mapping and response/error envelope in Notion before connecting screens.
3. **Keep lifecycle sequencing explicit.** Zone draft save → boundary draft/upload → independent boundary verification → Founder submission/decision bound to revision + boundary hash → Central Admin activation. Approval alone must not activate.
4. **Deactivation is a two-step approval/execution flow.** Request deactivation, obtain Founder decision for the exact current revision/hash, then Central Admin executes the status change. Do not call the generic status method as a shortcut.
5. **Keep the emergency path separate.** Emergency suspension is a narrowly scoped safety stop with reason/severity and audit/notification; it cannot be reused for reactivation.
6. **Check all read operations and data sources.** The current Create Zone hierarchy options are not live. Do not silently replace them with a collection until the authoritative India hierarchy/catalog and IDs are confirmed.
7. **Validate exact Firebase head before integration.** At audit time Firebase PR #40 is Draft/open/unmerged. Its source branch is not production/deployed evidence. Recheck PR state, exact head, Rules/Functions emulator CI and cross-app compatibility at the time integration is authorized.
8. **Preserve disabled UI actions.** No privileged button should be enabled merely because a client service method exists. Backend authorization and audit behavior must be tested first.

## Status

- Source-level method-name/payload comparison: **completed for the methods listed above**.
- UI-to-callable integration: **not started by this audit**.
- Canonical contract approval: **pending**.
- Firebase production/deployed parity: **not established**.
- Admin/Firebase emulator end-to-end flow: **not established**.
- Admin PR #51: Draft/open/unmerged; keep Draft.
- Firebase PR #40: Draft/open/unmerged at time checked.
- No code changes to Dart, Firebase Functions, Firestore Rules, indexes or data were made by this audit.
- No merge or deployment was performed.

## Next safe step

Before any API wiring, obtain approval of the final operation map and role/state matrix in Notion, then run a read-only cross-repository schema and response-shape reconciliation against the exact Firebase PR head. Keep Create Zone save, boundary upload, review and lifecycle controls disabled until the contract and emulator-backed acceptance tests are ready.
