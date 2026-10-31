# DOJO WALK Admin — Walker Management Service Deep Audit

- Audit date: 2026-10-30
- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch reviewed: `ui/notion-brand-foundation-2026-10-28`
- Firebase rules repository reviewed: `DOJOWALK/DOJO-WALK-Firebase` default branch snapshot
- Scope: source-level review of walker service, model/helpers and current Firestore rules. No production data, emulator execution, merge, or deployment.

## 1. Service behavior confirmed

- `watchWalkers()` subscribes to the entire `walkers` collection and maps every document into a `WalkerAdminModel`.
- `watchBookings()` subscribes to the entire `bookings` collection; the dashboard derives running walker IDs client-side.
- `watchWalkerBookings(walkerId)` filters only by `walkerId`; it has no status/date filter or limit.
- `watchWalkerAuditLogs(walkerId)` filters by `targetType == walker` and `targetId == walkerId`, applies a clamped limit (1–200), then sorts the returned subset locally by `createdAt`.
- `watchWalker(uid)` and `getWalker(uid)` read one walker document.
- `runAdminAction()` checks the signed-in user's `admin_users/{uid}` record and currently accepts only `role == super_admin` plus `isActive == true`.
- The action and audit record are written in one Firestore transaction. The service validates current status and required reasons before writing.
- Supported transitions are approve, reject, suspend, reactivate and request correction.
- Model maps legacy aliases such as `name/fullName/displayName`, phone fields, area/locality and state/stateName; raw profile and KYC maps are retained for detail views.

## 2. Confirmed risks and required decisions

| Priority | Finding | Impact / required follow-up |
|---|---|---|
| P0 | Walker and booking streams read entire collections. | Read cost and data exposure scale with national growth. Replace with approved paginated/filtered query contracts and server-enforced city/zone scope before broad rollout. |
| P0 | Client service has no city/zone scope parameters. | UI tabs/search are not authorization. Confirm canonical walker zone/city fields and manager/supervisor visibility contract; enforce in trusted backend/rules, not client-only filters. |
| P0 | Client-side transaction checks only `super_admin`. | This does not implement the agreed Founder → Central → City Manager → Zone Supervisor hierarchy. Keep lifecycle controls disabled until POL-004 defines action-level authority and the backend/rules enforce it. |
| P1 | Audit query limits before local sorting and has no `orderBy(createdAt)`. | It can return an arbitrary subset rather than the newest 50 records. Add a deterministic descending timestamp query with an appropriate composite index and stable tie-breaker, after checking index ownership. |
| P1 | Walker booking stream has no status/date constraint or limit. | A walker with long history can cause growing reads; the dashboard's separate all-bookings stream is even broader. Define whether running detection should query only active statuses and use a bounded/maintained assignment index. |
| P1 | Running detection currently recognizes only `in_progress`, `active_walk`, `walking`, `walk_started` in the UI adapter. | Status drift or a canonical status change can misclassify walkers. Reconcile with the booking lifecycle contract and shared canonical status helper before adding aliases. |
| P1 | `runAdminAction` is client-callable and trusts a client-side transition implementation. | Transactions prevent partial writes but do not replace trusted authorization/business validation. Verify the exact deployed Firestore update rules and consider callable/server-side decisions with immutable audit creation. |
| P1 | Service writes `decisionBy`, `decisionAt`, `decisionReason`, and audit actorRole as hard-coded `super_admin`. | This is incompatible with future action-level roles and may overwrite decision metadata; align field names and actor role with POL-004 and audit schema. |
| P2 | `watchWalkerAuditLogs` treats missing/invalid timestamps as oldest only after fetching. | Missing timestamps remain possible and sorting is not deterministic for ties. Validate audit schema and timestamp requirements. |
| P2 | `watchWalkerBookings` has no dedicated service tests in the inspected tree. | Add fake/emulator tests for query constraints, errors, status transitions, transaction atomicity and audit payloads. |
| P2 | Model stores full raw data and KYC map in memory. | Keep sensitive KYC access least-privilege; avoid logging raw model/maps and verify Storage rules independently. |

## 3. Firestore rules cross-check (Firebase repository snapshot)

- The inspected rules define `isAdmin()` as an active `admin_users` document with role exactly `super_admin`.
- `walkers` collection listing is restricted to `isAdmin()`; therefore the Admin full-collection walker stream depends on Super Admin access in the inspected rules.
- The rules contain explicit walker status/verification validation and separate owner update paths. The admin service's lifecycle transaction must be checked against the exact walker `allow update` clauses and current deployed rules before any action is enabled.
- The rules reviewed are a repository snapshot, not proof of what is deployed to Firebase. No production rules state was queried.
- No zone/city manager read-scope implementation was established by this source review.

## 4. Safe implementation direction

1. Keep all lifecycle actions disabled in the UI; do not loosen the `super_admin` check or add manager roles speculatively.
2. Treat this as a cross-repository contract task: Notion POL-004/POL-026 → Admin service → Firebase rules/functions → emulator tests.
3. Agree the canonical fields for `cityId`, `zoneId`, active booking status, and audit actor role before changing queries.
4. Introduce bounded query APIs only after those fields and indexes are confirmed. Avoid silently filtering by display names such as city/area.
5. Add service tests using injected Firestore/Auth or emulator fixtures; include denied-role, inactive-admin, missing-walker, invalid transition, required reason, transaction/audit atomicity and query-bound cases.
6. Run targeted tests, full Flutter tests, analyze, web build and Firebase rules emulator tests on exact resulting commits.

## 5. Validation status

- Admin service/model/helper source review: DONE.
- Firebase rules source cross-check: PARTIAL; repository snapshot only, exact deployed rules and full transition-rule compatibility not verified.
- Service-level tests: NOT FOUND in inspected Admin test tree.
- Flutter Analyze / Flutter Test: NOT RUN.
- Firestore emulator/rules tests: NOT RUN.
- Production Firebase read/rules verification: NOT performed.
- Merge/deployment: NOT performed.

This report records source-level findings only. It does not claim runtime tests, security approval, or production readiness.

## 6. Lifecycle policy test seam added — 2026-10-30

- Extracted deterministic state-transition validation into `lib/features/walkers/services/walker_admin_transition_policy.dart`.
- Moved the shared action enum and safe service exception into `walker_admin_contracts.dart` to avoid a circular import.
- `WalkerAdminService` delegates its existing transition validation to the pure policy; this is a structural refactor intended to preserve the existing transition rules.
- Added `test/features/walkers/walker_admin_transition_policy_test.dart` covering approval, rejection, suspension, reactivation, correction requests and terminal-state guards.
- These are authored tests, not executed test results. No Firestore/Auth transaction, audit write, query shape, rules emulator or role authorization is tested by this pure policy suite.
- Exact-head CI has not yet appeared. Flutter Analyze/Test remain unverified.

## 7. Additional pure-policy coverage — 2026-10-30

- Centralized the "reason required" rule for Reject, Suspend and Request Correction in `WalkerAdminTransitionPolicy.requiresReason`.
- Centralized stable audit event names for all five lifecycle actions in `WalkerAdminTransitionPolicy.auditActionName`.
- Updated `WalkerAdminService` to consume these shared policy methods and removed unused transition method parameters.
- Added tests for exact reason-required action set and audit event mapping.
- This still does **not** test Firestore transaction atomicity, Firebase Auth state, admin role authorization, rules enforcement or audit persistence. Those require emulator-backed service tests and are not claimed complete.
- Exact PR head checked: `465d48df0bab5da602205fb1ba8e5ec4d09af25d`.
- PR #51 remains open and draft; latest queried workflow run list was empty. GitHub reported mergeable=false at the time of the check; conflict/status details need a fresh PR review before merge.


## 8. Firebase rules and emulator setup cross-check — 2026-10-30

- Re-read the exact current `DOJOWALK/DOJO-WALK-Firebase` `main` rules snapshot, rather than relying on the earlier partial note.
- The walker admin update allow-list includes `walkerId`, `status`, `isActive`, `isApproved`, `verificationStatus`, `updatedAt`, `decisionReason`, `decisionBy` and `decisionAt`. The Admin service writes only the applicable lifecycle fields from this list, so the field-name contract is aligned at source level.
- The rules independently require an active `super_admin` admin record and validate the resulting walker status/verification/approval/active combination. They also constrain `decisionBy` to the authenticated UID and validate the optional reason/timestamp.
- The audit log create allow-list includes all fields currently emitted by the service, and its action allow-list contains all five lifecycle event names emitted by `WalkerAdminTransitionPolicy`. This confirms source-level schema compatibility, not runtime success.
- The Firebase repository has an existing Rules Unit Testing harness: `firebase.json` configures Auth and Firestore emulators; `package.json` includes `@firebase/rules-unit-testing` and `firebase-tools`; tests live under `test/*.test.mjs`. The Admin repository itself has no `firestore.rules` or `firebase.json` emulator configuration, and its `pubspec.yaml` currently has no Firebase mock/emulator test dependency.
- The inspected Firebase Rules test file contains no walker lifecycle-specific cases. Therefore the next meaningful validation should add rule tests in the Firebase repository for the five lifecycle transitions, invalid state combinations, inactive/non-super-admin denial, actor UID mismatch, and audit event allow-list. Flutter service transaction tests remain a separate follow-up; the Node rules suite alone cannot prove the Flutter transaction's persisted audit payload.

### Updated validation matrix

| Check | Result |
|---|---|
| Walker update field allow-list vs service writes | SOURCE-LEVEL ALIGNED |
| Walker state validation vs transition policy outputs | SOURCE-LEVEL CONTRACT CHECKED; emulator not run |
| Audit event names vs Firestore audit allow-list | SOURCE-LEVEL ALIGNED |
| Firestore rules emulator harness in Firebase repo | EXISTS; not executed in this audit |
| Walker lifecycle rules tests | NOT FOUND in inspected test file |
| Flutter service transaction tests | NOT IMPLEMENTED / NOT RUN |
| Exact PR-head CI | NOT VERIFIED |

This cross-check does not change production rules, enable UI actions, or approve the current security model. Keep the PR Draft and keep lifecycle actions gated until emulator and service-level tests are added and run.


## 9. Walker lifecycle Firestore Rules test suite added — 2026-10-30

- Added `test/walker_lifecycle.rules.test.mjs` to `DOJOWALK/DOJO-WALK-Firebase` on `main`.
- The suite covers the five allowed lifecycle state outcomes (approve, reject, request correction, suspend, reactivate), inactive/non-super-admin denial, actor UID mismatch, invalid state combinations, unknown walker fields, reason length validation, the five audit event names, audit actor mismatch, and audit immutability.
- Firebase test commits: initial suite `cbc9587c966f1b2fe534e4a7cfeeff6971921ea4`; assertion correction `dcb4e1ce68054b661c4a9ac03747e0af1a980e09`.
- The test file uses the existing `firebase.json` emulator configuration and `npm test` script (`node --test test/*.test.mjs`).
- Exact commit workflow runs and combined statuses were queried for `dcb4e1ce68054b661c4a9ac03747e0af1a980e09`; both returned empty. The test suite has **not been executed** in this environment. Do not mark it PASS.
- This is Rules-level coverage only. It does not execute `WalkerAdminService.runAdminAction`, prove transaction atomicity, or verify Flutter client behavior. Those remain separate service/emulator tests.

### Next validation gates

1. Run `npm install` and `npm test` in `DOJOWALK/DOJO-WALK-Firebase` with the Firestore emulator available; fix any test or rules failures before treating this suite as validated.
2. Add a Firebase CI job that runs the rules suite on changes to `firestore.rules`, `firebase.json`, package manifests and `test/**` (only after inspecting the existing workflow structure to avoid duplicate pipelines).
3. Add Flutter service transaction tests with injected Auth/Firestore emulator instances. These should assert the persisted walker state and audit record after success, and no partial writes after every denied/invalid path.

No production rules were changed and no emulator or production deployment was run.


## 10. Firebase Rules CI workflow added — 2026-10-30

- Added `.github/workflows/firestore-rules-tests.yml` to `DOJOWALK/DOJO-WALK-Firebase` on `main`.
- Workflow triggers on pushes to `main` and pull requests when Firestore rules, Firebase config, package manifest/lockfile, tests, or this workflow change; it also supports manual `workflow_dispatch`.
- CI provisions Node.js 22 and Temurin Java 21, installs npm dependencies, and runs `npm test` inside `firebase-tools emulators:exec --only firestore` using the dedicated demo project ID.
- Workflow file commit: `fa4ce0f182daac071ca0c8604e15f37f7376fa5d`; fetched the committed file back and verified its contents.
- The available commit-run lookup only reports pull-request-triggered runs; it returned no PR-triggered run for this commit. It cannot establish whether the push-triggered run completed. Therefore workflow execution and test result remain **UNVERIFIED**, not PASS.
- No lockfile exists in the repository snapshot; workflow currently uses `npm install`. Consider committing a lockfile in a separate controlled change for reproducible dependency resolution.
- No production rules or data changed. No deployment, merge, or Admin PR state change occurred.

### Revised next validation gates

1. Inspect the actual GitHub Actions run for commit `fa4ce0f182daac071ca0c8604e15f37f7376fa5d` in the repository Actions UI; capture job logs and resolve failures before marking Rules tests PASS.
2. Add/commit a package lockfile after confirming the project's intended dependency versions, then change CI to `npm ci`.
3. Add Flutter service transaction tests with injected Auth/Firestore emulator instances. Assert persisted walker state and audit record after success, and no partial writes after denied/invalid paths.


- Follow-up workflow review found and corrected the CLI invocation: the job now uses `npx firebase emulators:exec` (the executable exposed by the `firebase-tools` package), not `npx firebase-tools`. Correction commit on Firebase `main`: `2f5eb81ac2409c0177ffd373e275054b34ce613d`. The corrected workflow has been fetched back and inspected; runtime execution is still unverified.


## 11. Walker audit history ordering fix — 2026-10-30

- Updated `WalkerAdminService.watchWalkerAuditLogs` to apply server-side `orderBy('createdAt', descending: true)` before the bounded limit. This removes the prior correctness defect where an arbitrary limited subset was locally sorted and could omit newer records.
- Admin service commit: `6981fcd4bbed0102ddbbaf706e4bba9660b1ce72`.
- Added Firestore composite index `audit_logs(targetType ASC, targetId ASC, createdAt DESC)` in `firestore.indexes.json` and registered it in `firebase.json`.
- Firebase index/config commits: `5f6d1c8b4e3360b0d23ce11ed4fc857fc9680aff`, `928dd8cc45e3a394e94b7492b4dfaee2fca51833`.
- Updated Rules CI path filters to include `firestore.indexes.json` for push and pull request events; workflow path-filter commits: `d9eb9a00e63adecbbdaad6ad73dd70e5c5122525`, `9a0960438141e63bbf06195e116c98403fce405b`.
- Source files were fetched back for review. No Flutter test, emulator index build, live index deployment, or CI execution was performed. The index is defined in source but is **not deployed** to the Firebase project.
- Before enabling this query in a deployed environment, deploy the index through the approved Firebase release process and wait for index build completion. Do not assume it is available merely because it exists in Git.


## 12. Walker decision reason contract alignment — 2026-10-30

- Cross-checked the Admin decision-reason input against the current Firebase repository rules: decisionReason is optional on the walker record and, when supplied, must be a string no longer than 1,000 characters. Reject, Suspend and Request Correction require a non-empty reason in the Admin service.
- Added WalkerAdminTransitionPolicy.normalizeReason() to trim input, enforce the required-reason rule, and reject values longer than 1,000 characters before a Firestore transaction starts.
- Updated WalkerAdminService.runAdminAction() to use this shared validation.
- Added pure-policy tests for whitespace trimming, optional reasons on Approve, required reasons on the three guarded actions, and the 1,000 / 1,001 character boundary.
- Commits on the Admin feature branch: policy 3350f2fc4972a36e96efaf2a04bf9cfab9fed84e; service 1b7901493770f9ec1ceb00109c1daf49bf76ad1f; tests ec023543bfc654e4eddd779086148f63051fad60.
- The changed files were fetched back and the expected validation code/test markers were confirmed. Flutter tests and analysis were not run, so this is source-reviewed, runtime-unverified.
- This does not replace the still-missing Firestore/Auth transaction tests. The transaction remains untested for persisted audit payload, authorization denial, and no-partial-write behavior. No Firebase rules, production data, merge, or deployment changed.


## 13. Non-deploying Flutter validation CI — 2026-10-30

- Added `.github/workflows/flutter-validation.yml` on the Admin feature branch. It runs on relevant pull requests, pushes to `ui/**`, and manual dispatch.
- The job provisions stable Flutter, resolves dependencies, runs `flutter analyze --no-pub`, runs `flutter test --no-pub`, and builds Flutter Web in release mode.
- This workflow is validation-only: it has read-only repository permissions and contains no Firebase Hosting deployment step or production secrets.
- Commit: `3546d11e11ca8095ad61f3a5bd854b6ba7f34fcc`. The committed workflow was fetched back and its expected commands/triggers were verified.
- The workflow run has not yet been observed; therefore analyzer, test and build results remain **PENDING / UNVERIFIED**. This does not establish that service transaction tests pass. No merge or deployment occurred.


## 14. Flutter validation CI failure triage — 2026-10-30

- Inspected GitHub Actions run `41000460752` for workflow commit `3546d11e11ca8095ad61f3a5bd854b6ba7f34fcc`.
- Result: **FAILED** during Static analysis; Flutter tests and Web build were skipped. Dependency installation succeeded.
- The analyzer reported 62 issues. The first source-level issue was that `walker_details_screen.dart` referenced `WalkerAdminAction` and `WalkerAdminServiceException` without importing the shared contracts file. Added the missing import in commit `ca8bb1a302b3b94fbf2719c8cf40a2becfe8bb83`.
- Remaining analyzer errors are predominantly outdated widget-test viewport APIs: `TestFlutterView.setPhysicalSize` / `setDevicePixelRatio` are not available in the pinned stable Flutter SDK, and dashboard tests also await reset methods that return void. Affected files include `walker_details_screen_test.dart`, `walker_details_sections_test.dart` and `dashboard_screen_test.dart`.
- The workflow therefore correctly exposed pre-existing test-suite/API drift. The import correction is committed but has not yet been re-run; it must not be described as a passing fix.
- Next action: migrate the affected tests to the current `tester.view.physicalSize` / `tester.view.devicePixelRatio` setter API and synchronous reset calls, then rerun the full validation workflow. Recheck remaining analyzer diagnostics after this migration; do not suppress the test suite or narrow CI merely to obtain a green result.
- No merge, Firebase deployment, production data change or production rules change occurred.


## 15. Flutter test viewport API migration — 2026-10-30

- Replaced obsolete `TestFlutterView.setPhysicalSize()` and `setDevicePixelRatio()` calls in the Walker Details and Dashboard widget tests with the current `physicalSize` and `devicePixelRatio` setters.
- Removed `await` from synchronous `resetPhysicalSize()` and `resetDevicePixelRatio()` calls in Dashboard tests; retained teardown registration for Walker Details tests.
- Commits: `2697a77b358eda03d41116812c52190464de1f18` (Walker Details screen tests), `e43dccc6617032a9c4a1acee470c830ef161d204` (Walker Details sections tests), `8e711cb5459c02a330b2c983a1bcf9f15d36d01c` (Dashboard tests).
- A new Admin Web Build Check run `41000965841` was observed for this update and was still in progress at the time of this note. The separate Flutter Validation run `41000965808` was cancelled as the subsequent push-triggered workflow took over; no test/analyze/build result is claimed yet.
- The previous analyzer log showed the missing contracts import and old viewport API calls as the reported errors; the contracts import was added in commit `ca8bb1a302b3b94fbf2719c8cf40a2becfe8bb83`. The new workflow run must confirm whether any further analyzer/test issues remain.
- No merge, deploy, production rules or data changes occurred.


## 16. Follow-up CI syntax correction — 2026-10-30

- The next analyzer run exposed a syntax error introduced by the mechanical viewport migration: the new property assignments retained the closing parenthesis from the old method calls (for example `physicalSize = const Size(...));`).
- Corrected the assignment terminators in all three affected test files.
- Commits: `bac45dd4773c4c9475bdc3b71f8bdd9505ff2b04` (Walker Details screen), `1daa2c29e0784197516fdf0f48ca6a69b87f31fe` (Walker Details sections), `ce7f5ff0b35bdfb09c6f9d6b5d3d3499e23654f0` (Dashboard).
- CI run `41000969583` failed at static analysis; test and web build steps were skipped. The follow-up runs for commit `ce7f5ff0b35bdfb09c6f9d6b5d3d3499e23654f0` were queued when checked (`41001138011` Admin Web Build Check; `41001138095` Flutter Validation). No passing result is claimed.
- No merge, deployment, production rules or data changes occurred.


## 17. Widget test failure triage and responsive fixes — 2026-10-30

- Run `41001138011` reached static analysis successfully; the full test suite then failed. Web build was skipped because tests failed.
- Failures identified from runner logs included: walker details metric-card vertical overflow (3.8 px), document-button assertions that assumed only one visible View label / no disabled View labels, repeated walker identity/status labels in the details screen, lifecycle audit action label showing the raw event prefix, WalkerAdminTabs semantics test without semantics enabled, and dashboard header/card-title horizontal overflows on narrow viewports.
- Fixes committed:
  - `74ccdce3c5f75368bb03d54d4134791dc6e3ebb4`: increase narrow walker metric tile height via responsive grid aspect ratio.
  - `2864d663d08439ad57d454d930c92b1f84575e6f`: assert all KYC View controls exist and are disabled/enabled according to document availability; tap the available control.
  - `a28fac209cf58d4d835f8aeedcec0bd9bcb262f9`: render lifecycle audit labels without the redundant `walker_` prefix.
  - `9b1e8878352a97652271a7b3e1d8cca79025e18d`: allow repeated identity/status text where the page intentionally shows it in multiple sections.
  - `bc60cf7e41b1fdd8a689b04295ac90432153f43d`: make compact dashboard header actions vertical and allow dashboard card titles to wrap.
  - `9b2d1241d493b34ee84b51f7d663308001ca3f74`: enable semantics in the WalkerAdminTabs accessibility test.
- Run `41001138011` had Analyzer = success, Tests = failure, Web build = skipped. Follow-up workflow for the latest test changes was queued/pending at last inspection; no passing test or build result is claimed yet.
- No merge, deployment, production rules or data changes occurred.


## 18. Second widget-test run triage — 2026-10-30

- Run `41001622974`: dependency install PASS; static analysis PASS; test suite FAIL; web build skipped.
- Test log showed four remaining issues:
  1. KYC View button was below the viewport; the test tapped without scrolling it into view.
  2. Walker info-grid tiles had vertical overflow at narrow widths due to insufficient grid height.
  3. WalkerAdminTabs semantics assertion used a semantics-node finder that did not match the explicit Semantics widget in this test environment.
  4. The lifecycle screen correctly displayed a disabled Suspend action for an approved walker, while the test incorrectly expected the action to be absent.
- Corrections committed:
  - `b8ba4124d779fd486806088bbf864a637e0b60b7`: scroll KYC View control into view before tapping.
  - `caad877c6d1a7790b7dd47b5db3ee5f93922cf5d`: increase responsive info-grid tile height by adjusting aspect ratios.
  - `d7f2240a32f6fa6c3407cd331c1ed3290ecce2e8`: assert the explicit tab Semantics widget label.
  - `3b91143c902a3480a43db03f44b2a67c258b2801`: assert Suspend is present but disabled, matching POL-004 UI behavior.
- These fixes are not yet validated by a completed follow-up CI run. No tests/build are claimed PASS beyond the observed analyzer result for the previous run.
- No merge, deployment, production rules or data changes occurred.



## 19. Latest full Admin validation result — 2026-10-30

- Inspected Flutter Validation run `41002331483` for commit `35a015289af1d88c51bbb7691756df6ce2923c7d`.
- All workflow steps completed successfully: dependency install, `flutter analyze`, complete `flutter test` suite, and Flutter Web release build.
- The same commit passed the separate Admin Web Build Check run `41002331493`, including dependency install, project analysis, full test suite and web build.
- The prior run `41002085935` had 280 tests pass and one failure: the WalkerAdminTabs semantics test left a `SemanticsHandle` active. Updated the test to dispose the handle explicitly in commit `35a015289af1d88c51bbb7691756df6ce2923c7d`.
- This establishes CI validation for that exact Admin commit only. It does not establish Firebase Rules emulator success, Flutter service transaction coverage, production index deployment, role-scope authorization, or production readiness.
- PR #51 remains unmerged and deployment has not been performed.


## 20. Firebase lifecycle Rules CI verified — 2026-10-30

- Verified Firebase repository commit `a1f2c4830f6c54b7a00b54142f4779c0f9ebf9cd` after upgrading GitHub Actions to supported major versions.
- Workflow run `41002942139` (Firestore Rules Tests) completed **SUCCESS**. Emulator job `123891286539` passed dependency installation and the Firestore Rules emulator test command.
- Workflow run `41002942103` (Test Firestore Security Rules) completed **SUCCESS**. Emulator job `123891286079` passed, and workflow-lint job `123891286384` passed the Actionlint validation step.
- This confirms the Firebase lifecycle Rules test suite and workflow YAML lint passed in CI for the exact Firebase commit above. It does not prove the Admin Flutter service transaction is exercised, production Rules/index deployment, or city/zone role authorization.
- The Admin service still has no dedicated transaction-level tests. The next test seam must verify the persisted walker update and audit event together, denied/inactive admin paths, missing walker, invalid transitions, required reason validation, and query constraints. Prefer an emulator-backed test harness and make CI provision the Firestore emulator; do not add guessed mock dependencies or weaken the existing full Flutter validation.
- No production rules/data, deployed indexes, merge state, or hosting deployment were changed.


## 21. Walker Admin service tests and exact-head CI — 2026-10-30

- Added `fake_cloud_firestore` and `firebase_auth_mocks` as development dependencies and created `test/features/walkers/walker_admin_service_test.dart`.
- The new service suite covers eight cases: successful approval with persisted walker state and audit event; no signed-in user; inactive admin; active non-Super-Admin; missing walker; invalid lifecycle transition; missing required rejection reason; and normalized reason persistence on both walker and audit records.
- Exact Admin commit: `1a2687dc220b4c45132fe52fb20c171952856e7d`.
- Flutter Validation run `41004355178` completed **SUCCESS**. Its dependency installation, static analysis, complete Flutter test suite (including the new service tests), and Flutter Web release build all passed.
- Separate Admin Web Build Check run `41004355086` completed **SUCCESS**, including full project analysis, full tests and web build.
- The service tests use FakeFirestore. They verify service-level outcomes against the fake implementation, but they do **not** prove real Firestore Emulator transaction atomicity or Firestore Security Rules behavior. The Firebase Rules emulator suite is separately validated as recorded in section 20.
- Next gate: add a deliberate emulator-backed integration test for the actual Admin service transaction, including successful dual-write and rollback/no-partial-write behavior. Do not describe transaction atomicity as emulator-verified until that test runs successfully.
- No production rules/data, deployed indexes, merge state, or hosting deployment changed.


## 22. Firestore Emulator transaction contract tests — 2026-10-30

- Added two Firestore Emulator transaction contract tests in `DOJOWALK/DOJO-WALK-Firebase/test/walker_lifecycle.rules.test.mjs` on Firebase `main`.
- Exact Firebase commit: `42923ecabedb60c158cdec91a5397f9925b3e07a`.
- Test 1 runs a signed-in Super Admin transaction that updates a walker lifecycle state and creates the matching audit event, then verifies both persisted documents.
- Test 2 attempts the walker update and an audit write with a disallowed event name in the same transaction; it expects a Rules denial and verifies the walker remains unchanged and the audit document is absent.
- Exact-head workflow results:
  - Firestore Rules Tests run `41005367911`: **COMPLETED / SUCCESS**; emulator job `Firestore Security Rules Emulator Tests` completed successfully.
  - Test Firestore Security Rules run `41005367828`: **COMPLETED / SUCCESS**; emulator job `Firestore Rules Emulator Tests` and workflow YAML validation / Actionlint job both completed successfully.
- These results verify the Node Firestore SDK transaction contract against the Firestore Emulator and the repository's Rules. They do **not** execute the Flutter `WalkerAdminService.runAdminAction()` implementation, so they are not proof of the Dart service's real-client integration.
- The separate FakeFirestore-backed Admin service tests and exact-head Flutter CI remain as recorded in section 21. A true Flutter service-to-emulator integration harness remains a separate validation gate.
- No production rules/data changed; no index deployment, merge, or hosting deployment occurred.


## 23. Flutter-to-Emulator integration feasibility spike — 2026-10-30

- Inspected the actual Admin Firebase initialization, Firebase options, service constructor, existing FakeFirestore tests, and Firebase Rules governing admin bootstrap.
- Confirmed the Admin app's checked-in Firebase options are Web-only and currently identify the production project. A safe integration harness must initialize a separate named Firebase app with a dedicated `demo-` project ID and explicitly connect both Auth and Firestore to local emulators.
- Confirmed Firestore Rules deny client creation/deletion of `admin_users` documents. A normal authenticated test client cannot bootstrap its own `super_admin` fixture. The test therefore requires a privileged fixture seeding path restricted to the emulator; all service actions and final assertions must still use the authenticated FlutterFire client.
- Added `docs/testing/WALKER_ADMIN_FLUTTER_EMULATOR_INTEGRATION_PLAN.md` (commit `1f8d92faec34470f13e71abda86bc7cd60ab787d`) with the proposed named-app setup, emulator-only fixture boundary, success/denial/rollback scenarios, CI gates and acceptance criteria.
- This is a design/feasibility result only. No integration test code or CI job has been added yet, and no Flutter-to-emulator test has run. Do not mark this gate PASS.
- Next implementation gate: prove the Flutter Web integration-test driver and emulator-owner fixture seeding against a dedicated demo project, then add the test and non-deploying CI workflow. Keep production Firebase options and rules untouched.
- No production data/rules, deployed indexes, merge, or hosting deployment changed.


## 24. First real FlutterFire Emulator integration harness added — 2026-10-30

- Added the Flutter `integration_test` SDK dependency in commit `547ab69e882af504f594c5e97e197c84b746ac9d`.
- Added `integration_test/walker_admin_service_emulator_test.dart` in commits `0706d458d4e8cb75bce2dd6eb968f54a5e4b6ce6` and `204a346e913bc06a111d58310c5656735a438f91`. It initializes a separate named Firebase app with a dedicated demo project ID, connects real FlutterFire Auth and Firestore clients to local emulators, creates an ordinary Auth emulator user, and calls the actual `WalkerAdminService.runAdminAction()`. It expects the missing admin record to deny the action and verifies the caller's walker document remains absent.
- Added `.github/workflows/walker-admin-emulator-integration.yml` in commit `6f7a0642daa86ed7d7950c6b4e8b9b99345bc169`. It checks out the Firebase Rules repository, starts only Auth + Firestore emulators under `demo-dojo-admin-integration`, and runs the Flutter integration test in Chrome. Permissions are read-only; no deploy step or production credentials are configured.
- Workflow run `41006504289` was observed as **QUEUED** at audit time. No test result is claimed yet. The existing full Flutter validation and Admin Web Build Check runs for preceding commits were still in progress when checked.
- Scope limitation: this first real-client integration test validates the denied/no-admin path only. It does not yet validate a successful Super Admin Dart transaction or a Dart-side rollback after an audit write denial. The Node Firestore SDK emulator transaction tests remain separate evidence for Rules/transaction rollback behavior.
- Next gate: inspect run `41006504289` and the full Flutter validation results; fix any driver/emulator issues, then add a successful authorized Dart transaction test using an emulator-only fixture mechanism. Never seed or mutate production admin records.
- No production rules/data, deployed indexes, merge, or hosting deployment changed.


## 25. FlutterFire integration runner correction — 2026-10-30

- First integration workflow run: `41006504289` on Admin commit `6f7a0642daa86ed7d7950c6b4e8b9b99345bc169` failed before executing the test.
- Exact failure from job `123902492084`: Flutter reported **“Web devices are not supported for integration tests yet.”** The Auth and Firestore emulators themselves started successfully and their ports were accepting connections.
- Root cause: the harness used `flutter test integration_test/... -d chrome`, but Flutter's integration_test runner does not support the web target.
- Corrective workflow commit: `a6c71ba8337f0e06c93e05e935f1de4fbe733b21`. Replaced Chrome setup with Linux desktop build dependencies, enabled the Linux desktop target, and switched the integration test device to `-d linux`.
- The revised workflow run `41006832987` is in progress at the time of this update. No integration test PASS is claimed yet.
- Earlier Admin Web Build Check runs `41006488337` (commit `204a346e...`) and `41006409894` (commit `0706d458...`) completed successfully. Flutter Validation run `41006388234` (commit `547ab69e...`) also completed successfully; these are not exact-head results for the workflow-only correction commit.
- No production rules/data, deployed indexes, merge, or hosting deployment changed.


## 26. Linux integration runner scaffold follow-up — 2026-10-30

- Corrected workflow run `41006832987` also failed before test execution. Linux dependencies and both Firebase emulators started successfully, but Flutter reported: **“No Linux desktop project configured.”**
- Root cause: this Admin Flutter repo does not check in a `linux/` desktop runner scaffold. Enabling the Linux target alone does not generate the platform project.
- Follow-up workflow commit: `fe95f55526fc4c0cf40ae8b456f0a93580d7bb5f`. Added a CI-only `flutter create --platforms=linux --project-name dojo_admin .` step before running the integration test. This generates the Linux runner in the ephemeral CI checkout; it does not commit platform scaffolding to the repository or alter production.
- New workflow result is pending at the time of this report update. No FlutterFire integration test PASS is claimed.
- The integration test remains a denied/no-admin scenario only. A successful Super Admin transaction still requires a safe emulator fixture approach that does not bypass or weaken production Firestore rules.


## 27. Headless Linux integration test launch correction — 2026-10-30

- Inspected the complete job log for failed workflow run `41007237200` (Admin commit `fe95f55526fc4c0cf40ae8b456f0a93580d7bb5f`).
- The CI-only Linux runner scaffold generated successfully, Firebase Auth and Firestore emulators both became ready, and Flutter dependencies installed successfully.
- The test did not execute: Flutter built the Linux app, then reported `Error waiting for a debug connection: The log reader stopped unexpectedly, or never started` and `Unable to start the app on the device`. The runner is headless; the workflow had no virtual display server.
- Corrective workflow commit: `7df259f7bd27cb71091c13e49fcb9dd230f18538`. Added the `xvfb` package and wrapped the Linux integration test command in `xvfb-run -a` so the desktop test app has a virtual display in GitHub Actions.
- This is a targeted environment correction based on the observed launch failure. The next workflow run must confirm whether the app starts and the FlutterFire test reaches its assertions. No integration PASS is claimed yet.
- The integration test still covers only the ordinary authenticated user / missing-admin denial path. Successful Super Admin Dart transaction and Dart-side rollback remain untested; no privileged fixture bypass was added.
- No production Firebase rules/data, deployed indexes, merge, or hosting deployment changed.


## 28. FlutterFire Linux desktop platform mismatch and Android runner migration — 2026-10-30

- Inspected workflow run `41008249858` on Admin commit `7df259f7bd27cb71091c13e49fcb9dd230f18538`, job `123907978490`.
- The CI-only Linux runner was generated, the desktop application built, and Auth + Firestore emulators started. The integration test then failed during `Firebase.initializeApp()` with `PlatformException(channel-error, Unable to establish connection ... FirebaseCoreHostApi.initializeCore)`; **0 tests passed**. The failure occurred before Auth/Firestore client calls or service assertions.
- Diagnosis: the generated Linux desktop runner did not provide a functioning FlutterFire Firebase Core platform channel for this test. This is not evidence of a service authorization failure, and the run is not a PASS.
- Corrective workflow commit: `0f6d83d50bd822af438b1bc2ad2ca60c99c34535`. Replaced the Linux desktop/Xvfb path with a CI-only Android runner scaffold and an Android emulator (API 35 / Google APIs / x86_64). Android is the supported native target for the Firebase Auth and Cloud Firestore Flutter plugins used by this service. The test still uses the dedicated `demo-dojo-admin-integration` project and local Auth/Firestore emulators.
- The workflow has read-only repository permissions and no deploy step. The generated Android scaffold exists only in the ephemeral CI checkout. Production Firebase configuration, rules, and data remain untouched.
- The next Android workflow result must be inspected before claiming the FlutterFire integration gate passed. The test still covers only the ordinary authenticated user / missing-admin denial path; a successful Super Admin Dart transaction and Dart-side rollback remain untested. No privileged fixture bypass was added.
- No merge, production deployment, index deployment, or production data/rules change occurred.


## 29. Android Emulator host routing correction — 2026-10-30

- Reviewed the Android migration from section 28 before treating it as ready for validation.
- Identified a platform networking issue in the integration test: `127.0.0.1` from inside an Android Emulator refers to the Android guest, not the GitHub Actions host where Firebase Auth and Firestore emulators are listening.
- Corrective test commit: `5db2280fa71772cd2b8c8e2a525d2cd33e2412f8`. The test now selects `10.0.2.2` on Android (Android Emulator host bridge) and retains `127.0.0.1` for non-Android local targets. Both Auth and Firestore emulator clients use the selected host.
- This is a source-level correction based on Android Emulator networking behavior; it is not a test result. No new Android integration workflow result has been verified in this audit entry.
- The integration test remains limited to the ordinary authenticated user / missing-admin denial path. Successful Super Admin Dart transaction and Dart-side rollback remain untested.
- No production Firebase configuration, rules, or data changed. No merge, deploy, or index deployment occurred.
