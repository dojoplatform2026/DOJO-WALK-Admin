# DOJO WALK Admin — GitHub File Structure Audit

**Audit date:** 2026-10-29  
**Repository:** `DOJOWALK/DOJO-WALK-Admin`  
**Audited ref:** PR #51 head `df5562f2166d864f3817d06caff0a480076a3c91`  
**Working branch:** `ui/notion-brand-foundation-2026-10-28`  
**Status:** Inventory only; no source files moved or deleted by this audit.

## 1. Scope and safety

The repository tree was read from the exact PR-head commit. The tree contains 394 entries and GitHub reported `truncated: false`. This is a path inventory, not a claim that every feature is complete or that the application was built during this audit.

Notion remains the source of truth. The user-provided target tree is a desired logical organization, but the current implementation has established legacy paths and a Notion-aligned hybrid layout. Do not move or delete code solely to make the tree visually identical. Each migration needs an import/reference audit, tests, and exact-head CI.

## 2. Observed current layout

| Area | Paths observed at audited PR head | Finding / next action |
|---|---|---|
| App entry and composition | `lib/main.dart`, `lib/app/app.dart`, `lib/app/theme.dart` | Existing. Keep stable while organizing features. |
| Shared/core | `lib/utils/`, `lib/app/`, `lib/services/` | No top-level `lib/core/` directory observed in this tree. Introduce core subfolders only when moving a real shared responsibility with tests; avoid duplicate utility/theme sources. |
| Dashboard | `lib/screens/dashboard/admin_shell.dart`, `lib/screens/dashboard/dashboard_screen.dart` | Established path. Keep as the company command center per UI map. |
| Bookings | `lib/screens/bookings/bookings_screen.dart`, `booking_status_helper.dart` | Established path, not yet `lib/features/bookings/`. Do not move without a tested migration plan. |
| Live Operations | `lib/screens/live/` | Established path, including booking detail helper and map widget. Keep until a Notion-backed migration is approved. |
| Authentication | `lib/screens/auth/`, `lib/services/auth_service.dart` | Established legacy ownership; inspect before any consolidation. |
| Service Location | `lib/features/service_location/{models,screens,services,utils,widgets}/` | Already organized by responsibility; preserve. Create Zone remains State/UT → District → City → Zone, with no Locality selector. |
| Walker Management | `lib/features/walkers/{models,screens,services,utils,widgets}/` | Existing feature-grouped domain. Preserve. |
| Other Admin domains | `lib/features/access_control`, `audit`, `customers`, `finance`, `notifications`, `pets`, `reports`, `settings`, `support` | Feature-grouped domains exist. Verify each against the UI map; do not create parallel screens. |
| India reference data | `lib/data/reference/india_locations/india_states.dart`, `india_districts.dart`, `india_sub_districts.dart`, `india_location_filters.dart` | Files exist at the audited head. Source provenance, determinism, IDs, counts, and parent-child integrity must be verified before production import. |
| Tests | `test/screens/`, `test/features/`, `test/data/`, `test/reference_data_integrity_test.dart` | Mixed legacy and feature-aligned test paths. Keep tests near the existing domain convention; move only with imports and CI verified. |
| CI | `.github/workflows/admin-main-full-validation.yml`, `admin-web-build-check.yml`, `build_web.yml`, `service-location-geometry-tests.yml` | Four workflows exist. Do not delete or consolidate workflows until triggers, required checks, and duplicate coverage are audited. |
| Data templates | `data/templates/service_location_import_template.csv` | Existing template. This is distinct from generated/reference data and production imports. |
| Documentation | `docs/PROJECT_FILE_STRUCTURE.md`, `docs/LOCATION_MASTER_STATUS.md`, `docs/architecture/`, `docs/ui/`, and many dated `STEP_*.md` reports | Documentation is extensive and historical. Do not bulk-delete or relocate historical evidence; update the canonical index and links instead. |
| Coupons | No `lib/features/coupons/` implementation is part of the Notion-aligned target. | Do not recreate a coupon feature/menu. DOJO WALK uses no coupon-code system. |

## 3. Comparison against the requested target tree

- **Already present or functionally represented:** `.github/workflows/`, `docs/`, `data/`, `lib/main.dart`, `lib/app/app.dart`, `lib/data/reference/india_locations/`, `lib/features/service_location/`, `lib/features/walkers/`, `lib/firebase_options.dart`, `test/`, `web/`, and Flutter project configuration.
- **Different from the simplified target tree:** Dashboard, Bookings, Live Operations and Auth use existing `lib/screens/` paths; shared authentication is under `lib/services/`; multiple additional feature domains exist under `lib/features/`.
- **Not observed as a top-level folder at this head:** `lib/core/`, `lib/data/repositories/`, and a complete generic `lib/shared/` layer. Do not create empty placeholders. Add these only when there is a concrete shared implementation to place there.
- **Target-only/obsolete item:** `lib/features/coupons/` must not be added.
- **Workflow naming:** The target mentions `build_web.yml`, which exists, but it is not the only workflow. Keep all workflows until their roles and required-check dependencies are verified.

## 4. Safe migration order

1. Keep the current hybrid layout and map each domain to its canonical path in `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md` and `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`.
2. Audit all imports and route references before moving any file.
3. For each proposed move, make a small isolated change; update imports and tests in the same commit.
4. Run formatter, `flutter analyze`, relevant tests, full `flutter test`, and `flutter build web --release`.
5. Record the exact commit SHA and actual workflow run. A missing/empty status response is not a pass.
6. Do not merge, deploy, or expand Firebase integration during the UI-first phase.

## 5. Current-head recheck — 2026-10-29

Rechecked directly against PR #51 head `df5562f2166d864f3817d06caff0a480076a3c91`; GitHub returned a complete recursive tree (`truncated: false`, 394 entries).

- `lib/core/`, `lib/data/repositories/`, and `lib/shared/` are not present as tracked paths. They remain target architecture folders only; do not create empty placeholders.
- Existing dashboard/auth/bookings/live screens remain under `lib/screens/`; do not create duplicate feature copies.
- All four India reference Dart files are present: `india_states.dart`, `india_districts.dart`, `india_sub_districts.dart`, `india_location_filters.dart`.
- The branch has a successful Admin Web Build Check at earlier commit `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a` (run `40777254854`). The current PR head is `df5562f2166d864f3817d06caff0a480076a3c91`, so that earlier success is **not** proof that the current head passed. Current-head status response was empty; CI needs a new run or explicit workflow evidence before calling it green.

## 6. Audit result

**Inventory completed; structural migration not yet performed.** The repository already contains a working mixed layout and a more detailed Notion-driven file map. The next implementation task is to reconcile the user's desired logical tree with that canonical map, then select one low-risk migration only if the mapping proves a real maintenance benefit. No production data or Firebase state was changed.

## 7. Follow-up recheck — 2026-10-29

The repository was rechecked at PR #51 head `97e3fadab6cf51897c4c1389dcecfe750db5c0cc` using GitHub's recursive Git tree API:

- Tree response: `truncated: false`, 394 entries.
- The four India location Dart files are tracked. The sub-district source blob is 1,830,733 bytes; a content-preview response returned no text for this large file, so that preview must not be interpreted as an empty source file.
- `lib/core/`, `lib/data/repositories/`, and `lib/shared/` remain absent as tracked paths. Do not create empty directories solely to match the diagram.
- The four workflows remain present: `admin-main-full-validation.yml`, `admin-web-build-check.yml`, `build_web.yml`, and `service-location-geometry-tests.yml`.
- Reference data provenance remains **unverified**: the Dart comments identify a user-supplied LGD CSV, but the corresponding raw source file, source URL, retrieval date, licence/terms, checksum and reproducible generation command were not found under `data/reference/india_locations/`. Do not import this data into production Firebase until that evidence and integrity review are complete.
- Current PR head has no reported commit statuses and no workflow run associated with that exact SHA in the inspected API responses. The latest successful Admin Web Build Check returned by the branch run list is run `40777254854` for older code commit `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a`; it is not proof of a pass on the current head.
- No source files were moved or deleted during this follow-up. PR #51 remains Draft; no merge, deploy, or backend expansion.

### Follow-up result and remaining blocker

- Added `data/reference/india_locations/README.md` in documentation commit `2ceb58f1849fbff8cbc491421f2d34cacd909cd9`. It documents the separation between source artifacts, staging, audits and generated Dart, plus the validation gates before production import.
- `data/reference/india_locations/source_manifest.md` is intentionally **not created yet** because the raw source artifact and its provenance fields are not available in the repository. Creating a manifest with guessed URLs, dates, licences or checksums would be misleading.
- The README-only commit does not change Dart code. Exact-head CI status is still unreported; historical CI success remains limited to the earlier code commit noted above.
- Next safe task: obtain the actual LGD CSV/source artifact and verify its provenance, then populate the manifest and audit the generated dataset. Until then, do not regenerate or import reference data.


## 8. Latest exact-head recheck — 2026-10-29

This section supersedes earlier head-specific counts and CI observations above where they conflict.

- Pull request: #51, still **open and Draft**; base `main`; working branch `ui/notion-brand-foundation-2026-10-28`.
- Exact PR head inspected: `9b9724796d69620e6dac1ec87946df1b2689d744`.
- Recursive Git tree inspection returned **397 paths**. The current tree includes `.github/workflows/build_web.yml`, the other existing validation workflows, `docs/ui/` maps/contracts, the established `lib/screens/` and `lib/features/` hybrid layout, and the four India reference Dart files.
- Current canonical file ownership remains documented in `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md` and `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`. The user's simplified tree is a logical target, not permission to move files mechanically.
- `lib/core/`, `lib/data/repositories/`, and a generic `lib/shared/` layer are not present as tracked paths. Do not add empty placeholders. Introduce them only alongside a real responsibility and a tested migration.
- Do **not** create `lib/features/coupons/`; coupon-code functionality is excluded by the product decision.
- Exact-head CI recheck for `9b9724796d69620e6dac1ec87946df1b2689d744` returned no commit statuses and no associated PR workflow runs in the inspected responses. Therefore, current-head CI is **unverified**, not passed. The older successful run does not establish a pass for this SHA.
- No production files were moved or deleted during this audit. No Firebase/backend expansion, merge, or deployment was performed.

### Next action

Continue with a path-by-path Notion mapping audit. Prefer documenting the canonical location and gaps over cosmetic moves. Before any code move, check imports, routes, tests, workflow triggers and release gates; then make one isolated change and verify CI against its exact resulting SHA.


## 9. Continued path-to-target mapping — 2026-10-29

**Rechecked PR metadata:** #51 is open and Draft; current reported head at this check is `ecadffeaf13c129e65b4f4140642238478520282`. The recursive tree response for that SHA was complete (`truncated: false`). No source files were moved or deleted in this pass.

| User's target path | Current GitHub reality at the inspected tree | Decision |
|---|---|---|
| `.github/workflows/build_web.yml` | Exists; three additional Admin validation workflows also exist | Keep all four until triggers and required-check overlap are reviewed. |
| `docs/PROJECT_FILE_STRUCTURE.md` | Exists | Keep as the broad project structure document; use the more specific UI contract/map for current implementation ownership. |
| `docs/LOCATION_MASTER_STATUS.md` | Exists | Keep; update only with evidence tied to the exact commit/run. |
| `docs/architecture/` | Exists, including company flow/file structure guide | Keep canonical architecture decisions here. |
| `docs/data_dictionary/`, `docs/runbooks/`, `docs/decisions/` | Not established as tracked top-level subfolders in the inspected inventory | Do not create empty folders. Add when there is approved, concrete content to place there. |
| `data/reference/india_locations/source_manifest.md` | Not present in the inspected inventory; README exists | Do not fabricate source URL, licence, retrieval date or checksum. Add the manifest only after source evidence is available. |
| `lib/app/` | Exists: app composition and theme | Keep; avoid a second app/theme source. |
| `lib/core/{constants,errors,routing,theme,utils}/` | No tracked top-level `lib/core/` folder observed | Treat as a future target only. Introduce a subfolder when moving a real shared responsibility with import and test coverage. |
| `lib/data/reference/india_locations/` | States, districts, sub-districts and location-filter Dart files exist | Keep current paths; separately verify data provenance, stable IDs, counts and parent-child integrity. |
| `lib/data/repositories/` | No tracked folder observed | Do not add a placeholder or duplicate existing service/repository ownership. |
| `lib/features/dashboard/`, `bookings/`, `live_operations/` | Dashboard is under `lib/screens/dashboard/`; bookings under `lib/screens/bookings/`; Live Operations under `lib/screens/live/` | Preserve established paths. No duplicate feature copies. Migrate only if Notion requires it and a separate import/route/test plan passes. |
| `lib/features/service_location/{models,screens,services,widgets}/` | Exists, with an additional `utils/` folder | This already matches the domain-responsibility split; keep it. |
| `lib/features/coupons/` | Excluded from the target implementation by the product decision | Must not be created; no coupon-code system. |
| `lib/shared/{widgets,services}/` | No generic tracked shared layer observed; existing `lib/utils/`, `lib/services/` and app-level files are in use | Do not create parallel shared implementations. Consolidate only after dependency/use-site analysis. |
| `test/{core,features,data}/` | Existing mixed test layout: `test/features/`, `test/screens/`, `test/data/`, plus root-level integrity test | Keep current convention and add tests beside the owning domain. No bulk moves just to mirror the diagram. |
| `web/`, `pubspec.yaml`, `analysis_options.yaml`, `README.md` | Web and pubspec are present; confirm each root config individually before treating it as complete | Presence is not a build-pass claim. Exact-head CI remains required. |

### Migration order — structure work

1. Keep this branch as the UI/file-organization workstream; no merge or deployment.
2. Reconcile the canonical mapping in `NOTION_FILE_STRUCTURE_CONTRACT.md` and `ADMIN_UI_NOTION_FILE_MAP.md` before each file move.
3. The first migration candidate, if still required after import review, should be one small shared utility/theme move—not a mass migration of Dashboard, Bookings, Auth or Live Operations.
4. Before any move, search all Dart imports, route registrations, tests and workflow references; move/update code and tests in the same isolated commit.
5. Run formatter, `flutter analyze`, relevant tests, full `flutter test`, and `flutter build web --release` on the resulting exact SHA.
6. Current reported head `ecadffeaf13c129e65b4f4140642238478520282` has not been established as passing by the previously observed successful workflow run, which belongs to older SHA `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a`. Do not label current-head CI PASS until a run for the exact head (or a later commit containing it) completes successfully.

**Result:** path-to-target mapping updated in this audit. This is not a claim that the whole target tree has been migrated; no application source paths were changed in this pass.

## 10. Live GitHub recheck — 2026-10-29 (latest inspected PR head)

- Pull request #51 remains open and Draft; branch `ui/notion-brand-foundation-2026-10-28`, base `main`.
- Exact inspected head: `213482bb6cd275ba1888f183dc52f82c9e41a773`.
- Recursive tree: 397 paths, `truncated: false`.
- Current tracked structure includes `.github/workflows/build_web.yml` plus three additional validation workflows; `docs/PROJECT_FILE_STRUCTURE.md`; `docs/architecture/`; `data/reference/india_locations/README.md`; existing `lib/screens/{auth,bookings,dashboard,live}/`; feature-grouped Admin domains; `lib/data/reference/india_locations/{india_states,india_districts,india_sub_districts,india_location_filters}.dart`; `lib/firebase_options.dart`; `test/features/`, `test/screens/`, `test/data/`; and `web/`.
- The simplified target tree is **not yet the literal on-disk tree**. In particular, `lib/core/`, `lib/data/repositories/`, `lib/shared/`, `docs/data_dictionary/`, `docs/runbooks/`, and `docs/decisions/` are not present as tracked directories in the inspected tree. Do not add empty placeholders just to make the tree look identical.
- Preserve the established `lib/screens/` ownership for Dashboard, Bookings, Live Operations and Auth until a Notion-backed, import/route/test-verified migration is ready. Do not create duplicate `lib/features/dashboard/`, `lib/features/bookings/`, or `lib/features/live_operations/` copies.
- The current tree does **not** contain `lib/features/coupons/`; keep coupon-code functionality excluded.
- Current-head combined status returned no statuses, and the commit-specific PR workflow query returned no associated runs. Latest successful workflow visible in the branch run list is run `40777254854`, whose workflow head commit is `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a`; it is older than the inspected head. Therefore, current-head CI is **UNVERIFIED**, not PASS.
- No source paths were moved or deleted in this recheck. This is an inventory update, not a claim that the target tree has been fully migrated.

### Next safe implementation gate

1. Run an exact-branch usage/import search for one low-risk shared responsibility before proposing any move.
2. Update this contract and the Notion-to-file map before changing paths.
3. Move one responsibility at a time with its imports and tests, then obtain exact resulting-head CI evidence.
4. Keep PR #51 Draft. No merge, deployment, production import or new Firebase integration in this UI/file-structure phase.


## 11. Continued implementation audit — 2026-10-29

**Live PR metadata rechecked:** PR #51 remains open, unmerged and Draft. Current PR head at this check is `55bc74c5676b45d31e048f3bfd0ca3dca8d43597`. The canonical target tree is documented in `docs/PROJECT_FILE_STRUCTURE.md`; it remains a target, not a claim that every path has been migrated.

### Direct path checks on the working branch

| Path | Live result | Action / interpretation |
|---|---|---|
| `.github/workflows/build_web.yml` | Present | It is a manually triggered live-deployment workflow, not a PR validation workflow. It requires the main branch and explicit confirmation. Do not invoke it during this phase. |
| `lib/main.dart`, `lib/app/app.dart`, `pubspec.yaml` | Present | Existing app bootstrapping, theme and dependencies remain in their current locations; do not duplicate these in new folders. |
| `lib/data/reference/india_locations/india_states.dart` | Present | File comments describe a user-provided LGD CSV; provenance is not independently established. |
| `lib/data/reference/india_locations/india_districts.dart` | Present | Preserve pending source and integrity audit. |
| `lib/data/reference/india_locations/india_sub_districts.dart` | Tracked path is present; direct text-fetch returned no content in the connector response | **Do not interpret the empty fetch response as an empty file.** Repository search and historical integrity documentation refer to 7,151 records and a 1,830,733-byte source blob. Need a byte-level/blob integrity check before asserting current file contents. |
| `data/reference/india_locations/README.md` | Present | Correctly documents source/generated/audit separation and the no-production-import gate. |
| `data/reference/india_locations/source_manifest.md` | Not found | Provenance is still a blocker. Do not fabricate source URL, retrieval date, licence, checksum or generation command. |
| `docs/LOCATION_MASTER_STATUS.md` | Present, large historical status document | Review/update only with current evidence; older counts and historical CI references must not be treated as current-head proof. |

### Exact-head CI check

For commit `55bc74c5676b45d31e048f3bfd0ca3dca8d43597`, the inspected combined-status response contained no statuses and the commit-specific PR workflow query returned no workflow runs. Therefore, exact-head CI is **UNVERIFIED**. Historical successful runs on older code commits are not a pass for this documentation head.

### Decision for the next code step

No source files were moved, deleted or rewritten during this pass. Do not do a cosmetic bulk move yet. First verify the location-data blob integrity and search imports/routes for a concrete, low-risk migration. Keep the deployment workflow untriggered, PR #51 Draft, and Firebase integration/deployment deferred.


## Follow-up contract audit — legacy Service Location lifecycle conflict (30 Oct 2026)

### Finding: BLOCKER for backend/lifecycle integration

Inspection of the current Admin branch found that the legacy service layer and model contracts still describe and support activation for City/Area/Locality, which conflicts with the owner-approved POL-038/POL-040 rule that **Zone is the only service-activatable unit** and State/UT, District and City are hierarchy/reference records only.

Evidence on branch `ui/notion-brand-foundation-2026-10-28`:

- `lib/features/service_location/services/service_location_service.dart` lines 14–20 documents `Country → State → District → Service City → Service Area → optional Locality/Village`, says City and Area activation uses `service_location_boundaries`, and says Locality activation does not require its own polygon.
- The same service has legacy `activateServiceLocation` callable usage and save/activation paths for City/Area. Search hits include `isActive`/`isServiceActive` checks and methods around the City and Area sections.
- `lib/features/service_location/models/service_location_models.dart` still defines `ServiceCity`, `ServiceArea`, and `ServiceLocality` with service-active fields, including fallback from `isServiceActive` to legacy `isActive`.
- The newer UI prototype uses the correct State/UT → District → City → Zone selector hierarchy, but it does not by itself neutralize the legacy service/model lifecycle contract.

### Required resolution before enabling backend writes

1. Keep this as a documented compatibility blocker; do not silently change Firestore schemas or callable behavior in the UI-only PR.
2. Review existing Firestore documents, callable implementations, rules and downstream readers to establish a safe legacy-data migration/compatibility plan.
3. Introduce a dedicated Zone lifecycle contract: draft → submitted revision → boundary verification → authorized approval → activation/suspension, with immutable revision/boundary hash binding and audit events.
4. Ensure only Zone records can carry the service-activation state in the new contract. State/UT, District and City must remain reference hierarchy, not activatable service records. Legacy City/Area fields may need read-only compatibility during migration; they must not authorize new service delivery.
5. Add tests proving non-Zone activation is rejected, unverified/missing polygons cannot activate, stale revision/hash approvals fail, Central Admin cannot approve own submissions, and every privileged transition is server-authorized and audited.
6. Update POL-038, POL-039, POL-040, POL-041 and POL-042 before implementing the lifecycle backend.

### Phase status

- Finding: **Confirmed by source inspection**.
- Fix: **Not applied** — intentionally outside this UI/structure-only change because backend/callable and production data compatibility must be reviewed first.
- Firebase writes, schema migration, merge and deployment: **Not performed**.
- PR #51 remains Draft. This blocker must be resolved in the approved backend phase before Zone activation can be considered production-ready.


## Cross-repository follow-up — mitigation already exists in Firebase draft PR (30 Oct 2026)

This follow-up qualifies the blocker above: the Firebase repository already has a mitigation under review, so the finding is **not an unaddressed design idea**. It is still unresolved for the current mainline/release because the mitigation is not merged and the Admin caller remains in this branch.

- Firebase draft PR #40, `fix/disable-legacy-location-activation-2026-10-28`, head `494d83f4abf3305ca1f1671b7ef52f26dcf227e7`, removes the legacy City/Area activation implementation and leaves a compatibility callable that rejects those activation requests. It is stacked on Firebase PR #39 (`feat/zone-name-index-schema-2026-10-26`), which targets `main`.
- The GitHub Actions check **“Build, geometry and callable integration tests”** completed successfully for PR #40's exact head SHA on 27 Oct 2026 (run `40604834433`). The aggregate commit status API still reports `pending`; therefore this single successful check is not a claim that every required check or the full release gate is complete.
- PR #40 explicitly says Admin UI legacy handlers/callers are not removed in that PR. The current Admin `service_location_service.dart` still has City/Area activation call paths. This caller/backend mismatch must be resolved before a coordinated rollout.
- Firebase PR #40 is Draft/open/unmerged. No Firebase deployment or production data change was performed in this audit.

### Corrected rollout gate

1. Review Firebase PR #39 and #40 together with the Zone workflow / Founder approval / name-index dependencies; preserve their Draft status until reviewed.
2. In a separate Admin change, prevent new UI flows from invoking legacy City/Area activation; retain read-only legacy compatibility where required.
3. Verify the Zone-only callable enforces role separation, boundary verification, submitted revision/hash binding, Founder/CEO approval and audit logging; verify Rules reject direct client status changes.
4. Run exact-head Admin CI and Firebase Functions + Firestore Rules emulator suites, then coordinate reviewed merge/deploy sequencing. Do not treat draft-branch code as production protection.


## Follow-up — clarify reference hierarchy vs service activation (30 Oct 2026)

- Updated `lib/features/service_location/screens/service_location_screen.dart` in commit `f03d0cd0c5235fdda77929aff9e3bdf45ab435cc` to display a clear informational notice: State/UT, District and City are reference hierarchy records; only a verified Zone may be considered for activation after the approved review workflow.
- Audit of this screen found the State/District/City list cards themselves are read-only (no status toggles or activation buttons). This notice reduces confusion; it does not implement Zone activation or backend authorization.
- Exact-head CI was queued at documentation time: [run 40949534432](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40949534432). Analyze, tests and release build are **Pending** until the run concludes. PR #51 remains Draft/open/unmerged; no deployment or production write.


## Cross-repository approval-contract audit — activation dependency blocker (30 Oct 2026)

Inspected Firebase Draft PR #40 (`DOJOWALK/DOJO-WALK-Firebase`, head `494d83f4abf3305ca1f1671b7ef52f26dcf227e7`) without changing or merging it. The callable `activateServiceZone` checks Founder approval against the current Zone revision and canonical Zone boundary hash, rechecks State/District/City ancestry transactionally, and writes an activation audit record. Founder decision callable `decideServiceZoneFounderApproval` requires an active `founder` role and writes a decision audit record; Firestore client rules deny direct create/update/delete of `service_zones` and deny client writes to approval audit records.

**Open policy mismatch to resolve before backend integration:** `activateServiceZone` also requires the parent City to have a `verifiedBoundaryId`, loads a verified City polygon, and checks that the Zone polygon is fully covered by that City polygon (around `functions/src/index.ts` lines 559–571 and 563–610 on the PR branch). The current approved Admin/location policy treats State/UT, District and City as reference hierarchy records and requires verified polygon evidence for the Zone; it does not currently establish that every reference City must have its own verified service boundary. Confirm whether a City boundary is an independent prerequisite or remove that prerequisite in a reviewed backend change. Do not silently weaken geometry validation or invent City boundary data.

Additional review required: the activation transaction guard-writes Country/State/District/City `activationGuardAt` fields to serialize concurrent hierarchy changes; because the parent records are intended to be read-only references, verify this technical guard mechanism is compatible with the canonical data model and rules. No code was changed in Firebase, no backend integration was started, and no production writes/deployment occurred.

Admin exact-head CI for code commit `f03d0cd0c5235fdda77929aff9e3bdf45ab435cc` remains in progress in [run 40949534432](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40949534432): Analyze and tests succeeded; Web release build is still running. PR #51 remains Draft/open/unmerged.
