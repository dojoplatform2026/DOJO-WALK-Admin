# DOJO WALK — Company Project File Structure

Last updated: 2026-10-16

This document defines the intended, maintainable file structure for the DOJO WALK repositories. It distinguishes existing paths from planned paths; a documented target folder is not proof that the folder already exists in GitHub.

## 1. Repository boundaries

- `dojo-admin`: Admin web portal, service-location operations, boundary review, administrative workflows.
- `dojo-walk-customer`: Customer app, profile, dogs, addresses, booking and walk tracking views.
- `dojo-partner`: Walker/partner onboarding, availability, assigned walks and active walk operations.

Keep app-specific UI and logic in its own repository. Shared data contracts should be documented and versioned; do not copy whole app folders across repositories.

## 2. Admin repository — target structure

```text
dojo-admin/
├── .github/
│   └── workflows/
│       └── build_web.yml
├── docs/
│   ├── PROJECT_FILE_STRUCTURE.md
│   ├── LOCATION_MASTER_STATUS.md
│   ├── architecture/
│   ├── data_dictionary/
│   ├── runbooks/
│   └── decisions/
├── data/
│   └── reference/
│       └── india_locations/
│           ├── source_manifest.md
│           └── README.md
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── routing/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── reference/
│   │   │   └── india_locations/
│   │   │       ├── india_states.dart
│   │   │       ├── india_districts.dart
│   │   │       └── india_sub_districts.dart
│   │   └── repositories/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── bookings/
│   │   ├── walkers/
│   │   ├── live_operations/
│   │   ├── service_location/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   └── widgets/
│   │   ├── coupons/
│   │   └── settings/
│   ├── shared/
│   │   ├── widgets/
│   │   └── services/
│   └── firebase_options.dart
├── test/
│   ├── core/
│   ├── features/
│   └── data/
├── web/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### Current known paths confirmed on the repository default branch

- `lib/main.dart`
- `lib/app/app.dart` (imported by `main.dart`)
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/widgets/service_boundary_dialog.dart`
- `.github/workflows/build_web.yml`
- `pubspec.yaml`
- `docs/LOCATION_MASTER_STATUS.md`

The three `lib/data/reference/india_locations/*.dart` files were checked and were not present at the expected paths at the time of this update. Matching generated data files exist in the ChatGPT Library and are pending a safe restore and compatibility check. Some folders in the target tree are architectural targets and may not yet exist.

## 3. Reference data rules

- Keep raw government source files, generated Dart, staging outputs and audit reports separated.
- Record source URL/name, retrieval date, publication/update date if available, licence/terms, checksum and generation command in a source manifest.
- Preserve official codes as strings whenever leading zeros or non-numeric identifiers matter. Do not silently replace blank or placeholder codes.
- Keep generated Dart deterministic and do not manually patch individual generated records without updating the source/staging data and audit.
- Do not mix reference data with live customer address records.
- Validate unique IDs, parent-child relationships, record counts and source differences before integration.
- Never import reference records into production Firebase until source validation, schema review and import dry-run pass.

## 4. Service-location domain

Expected hierarchy:
`Country -> State/UT -> City/District -> Area/Sub-district -> Locality/Village`

Expected responsibilities:
- `models/`: typed models and serialization only.
- `services/`: Firestore access, validation, unique-name indexes and state transitions.
- `screens/`: page-level UI and navigation.
- `widgets/`: reusable UI components such as boundary editor/dialog.
- Boundary draft saving, boundary verification and service activation are separate operations.
- City/Area activation requires a verified polygon and valid parent state. A radius-only circle is not a substitute for a verified area polygon.
- Customer pickup/drop-off addresses remain separate from the service-area reference hierarchy.

## 5. Customer repository — target feature grouping

```text
dojo-walk-customer/
├── docs/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   ├── data/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── dogs/
│   │   ├── addresses/
│   │   ├── booking/
│   │   ├── bookings/
│   │   ├── live_walk/
│   │   ├── support/
│   │   └── profile/
│   ├── l10n/
│   └── shared/
├── test/
├── web/
└── pubspec.yaml
```

## 6. Partner repository — target feature grouping

```text
dojo-partner/
├── docs/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   ├── data/
│   ├── features/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── documents/
│   │   ├── work_zone/
│   │   ├── assigned_walks/
│   │   ├── live_walk/
│   │   ├── earnings/
│   │   └── profile/
│   └── shared/
├── test/
├── web/
└── pubspec.yaml
```

These Customer and Partner trees are target groupings, not an audit of every existing file in those repositories.

## Company-wide flow and ownership

The company-level workflow, repository ownership, shared contract rules, Service Location lifecycle, and recommended folder placement are maintained in
[`docs/architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md`](architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md).

Canonical business flow:
`Company/System Management → Operations → India Location Master → Customer → Partner/Walker → Booking/Live Walk → Support → Reports/Audits`.

This is a cross-repository flow, not a reason to duplicate app folders. Keep each feature in its owning repository, preserve existing paths until migration tests pass, and use canonical shared IDs/contracts for entities used by multiple apps. The architecture guide distinguishes intended organization from implementation that has actually been verified.

## Dashboard-first navigation structure

The Admin shell is defined in `lib/screens/dashboard/admin_shell.dart`. Keep **Dashboard** as the main company command center. Live Operations is launched from the Dashboard's prominent action and retains its dedicated map screen at `lib/screens/live/live_operations_screen.dart`; it is not a separate sidebar destination. Dashboard UI and metrics live in `lib/screens/dashboard/dashboard_screen.dart`.

Company flow and implementation boundary: `docs/architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md`.

## 7. Engineering and release gates

1. Inspect existing files before moving or renaming anything.
2. Avoid duplicate models, duplicate routes and duplicate sources of truth.
3. Run formatting and static analysis for changed Dart files.
4. Run relevant unit/widget tests.
5. Run `flutter pub get` and `flutter build web --release` for Admin Web.
6. Record the actual CI/build run and commit SHA in `docs/LOCATION_MASTER_STATUS.md`.
7. Do not claim build success based only on a commit or empty status response.
8. Deploy only after the release checks pass; keep production imports and migrations separate from code deployment.

## 8. Immediate next actions

- Restore the three generated Dart reference files from the Library after checking declarations, IDs and import usage.
- Inspect the current feature tree and ensure files are placed under the existing architecture rather than creating duplicate model/service layers.
- Add focused tests for reference-data counts, key uniqueness and parent-child integrity.
- Run the actual web build and record the result.


## 9. Fresh Admin branch — actual paths and migration boundary (24 Oct 2026)

This section is specific to draft PR #37 on branch `feature/admin-fresh-architecture-2026-10-24`. The default `main` branch still has the legacy `lib/screens/**` architecture; do not confuse the draft branch with a merged replacement.

### Paths present in the fresh branch

```text
lib/
├── main.dart
├── app/
│   └── app.dart
├── core/
│   ├── auth/
│   └── theme/
└── features/
    ├── dashboard/
    │   └── presentation/
    ├── live_operations/
    │   └── presentation/
    └── service_location/
        ├── data/
        └── presentation/
```

The actual fresh UI paths include:
- `lib/app/app.dart`
- `lib/core/auth/` — identity, auth repository and auth gate
- `lib/core/theme/admin_theme.dart`
- `lib/features/dashboard/presentation/admin_dashboard_screen.dart`
- `lib/features/live_operations/presentation/live_operations_screen.dart`
- `lib/features/service_location/data/` — typed location and boundary-review repositories/models
- `lib/features/service_location/presentation/` — Add Location and Boundary Review
- `test/core/auth/`, `test/features/dashboard/`, and `test/features/service_location/`

Use the branch's established `presentation/` and `data/` names consistently for new work. Do not create a second parallel `screens/` or `services/` layer inside these same fresh features. If a feature later grows, add a `domain/` layer only when there is a real domain abstraction and tests to justify it.

### Legacy paths — preserve, inventory, then migrate

The default branch contains established paths including `lib/screens/dashboard/**`, `lib/screens/live/**`, `lib/screens/bookings/**`, `lib/services/**`, and existing `lib/features/walkers/**`. PR #37 has intentionally not deleted these paths. Some documentation and older tests refer to them; that alone is not proof that a source file is still imported, and a search excerpt alone is not a complete dependency scan.

Before moving any legacy file, generate a complete inventory from the exact branch and classify each candidate:
- **KEEP** — still used, or needed for rollback / functionality not yet ported.
- **MIGRATE** — active functionality with a tested replacement destination.
- **REMOVE** — proven unreferenced after source, tests, routes, generated files, workflow scripts and documentation-link review.

For every migration, update imports and tests in the same change, run formatter/analyzer/full tests/web build, and compare behavior with the legacy implementation. Do not bulk-move the whole tree or remove legacy booking/walker functions as a visual cleanup.

### Current-head validation evidence

Inspected PR #37 head: `43898dfd74c874e6718e4d040e8932abd8d64801`.

- Service Location Geometry Tests: run `40092368844`, job `geometry-unit-tests` — success.
- Admin Web Build Check (No Deploy): run `40092368877`, job `build-web` — success.
- Admin Main Full Validation (No Deploy): run `40092368847`, job `Analyze, test and build Admin Web` — success.

These three CI runs are on the exact head listed above. They validate the repository's configured CI scope only; they do not prove production deployment parity, real Firebase Auth/Firestore Emulator integration, live operational data, map-based boundary review, Founder/CEO approval UI, or complete role/scope enforcement. PR #37 remains draft and unmerged.
