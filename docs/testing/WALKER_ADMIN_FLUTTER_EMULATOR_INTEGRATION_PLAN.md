# Walker Admin — Flutter-to-Firestore Emulator Integration Plan

- Date: 2026-10-30
- Status: design spike; implementation and execution are not yet complete.
- Scope: exercise the real FlutterFire `WalkerAdminService.runAdminAction()` against Firebase Authentication and Firestore emulators, with the repository's actual Firestore Security Rules.

## Why the existing tests are not enough

- `walker_admin_service_test.dart` injects FakeFirestore and mocked Auth. It is useful service logic coverage, but it does not execute FlutterFire platform channels or Firestore Security Rules.
- Firebase repository tests use the Node Firestore SDK and emulator. They verify Rules and transaction rollback semantics, but do not call the Dart service.
- The target integration must combine the real Dart service, Firebase Auth emulator, Firestore emulator, and the exact rules file.

## Confirmed setup constraints

1. Admin `main.dart` initializes Firebase using `DefaultFirebaseOptions.currentPlatform`; the current options identify the production project. An integration harness must initialize a separate named Firebase app with a dedicated demo project ID, not reuse the production project configuration.
2. The Admin repository currently has no `integration_test/` directory and no `integration_test` dev dependency.
3. Firestore rules explicitly deny client creation and deletion of `admin_users` documents. Therefore an authenticated test user cannot self-promote to `super_admin` through normal client SDK writes. The harness needs a test-only emulator fixture seeding path with emulator-owner privileges; it must never target a live Firebase endpoint.
4. The walker update and audit creation must be performed by the real `WalkerAdminService` using the authenticated emulator user. Seed data may use the emulator's privileged fixture path, but assertions must read the final records through the authenticated FlutterFire client so the rules are exercised.
5. A web integration target is a reasonable first candidate because the checked-in Firebase options currently support Web only. Before adding CI, verify the selected Flutter integration-test browser/driver invocation on the pinned stable Flutter SDK and ensure the emulator host is reachable from the browser process.

## Required test scenarios

### Successful transaction
- Start Auth and Firestore emulators under a dedicated `demo-` project ID.
- Create a test user in the Auth emulator.
- Seed `admin_users/{uid}` as active `super_admin` and seed a valid submitted walker using emulator-only privileged fixtures.
- Initialize a named Firebase app with demo options; point Auth and Firestore at emulator endpoints.
- Call the actual `WalkerAdminService.runAdminAction(action: approve)`.
- Read the walker and audit documents using the authenticated FlutterFire client.
- Assert approved/verified/active state, actor UID, `walker_approved` event, target ID and matching after-state.

### Rules-denied transaction / rollback
- Use a separate emulator fixture or a test-only rule condition that denies the audit write without changing production rules.
- Call the actual Dart service transaction.
- Assert the transaction fails and the walker state remains unchanged; assert no audit document was created.
- Do not weaken or patch production Rules merely to manufacture a failure. Prefer a dedicated emulator-only rules fixture if needed, and clearly identify which rules file is being tested.

### Authorization denial
- Sign in as an ordinary emulator user with no admin record, seed a walker fixture, call the service and assert denial with no walker/audit mutation.
- Also retain FakeFirestore tests for inactive and non-Super-Admin admin records; the actual rules emulator suite already tests those rule conditions.

## CI acceptance gates

- Use a dedicated workflow with read-only repository permissions.
- Pin a dedicated demo project ID beginning with `demo-`.
- Start only Auth + Firestore emulators; never deploy or connect to the production project.
- Run the integration against the checked-in Firebase Rules from the Firebase repository (or a version-pinned copy whose source commit is recorded).
- Require the successful Dart service transaction and denied/no-partial-write scenario to pass.
- Capture exact Admin SHA, Firebase Rules SHA, workflow run ID, emulator logs and test results.
- Keep the existing FakeFirestore unit tests and Node Rules tests; this integration suite complements rather than replaces them.

## Safety boundary

No production credentials, production rules, production data, deployed indexes, merge, or deployment are needed for this test. Do not mark Flutter-to-emulator integration as PASS until the real Dart service has run successfully against the emulators in CI.
