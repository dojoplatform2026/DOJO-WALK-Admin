# DOJO WALK Admin — Canonical Target File Structure

**Authority:** Notion is the source of truth. This is the required target layout for Admin. The target layout does not certify that every path already exists or that features are implemented.
**Repository:** `DOJOWALK/DOJO-WALK-Admin`
**Branch:** `ui/notion-brand-foundation-2026-10-28`
**Status:** Target approved by owner on 2026-10-29; implementation and verification remain in progress.
**Guardrails:** Keep PR #51 Draft. No merge, deployment, or Firebase integration in this UI/structure phase.

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

## Implementation rules

1. This exact tree is the target contract. Audit each path as **Existing / Correct**, **Move / Refactor**, **Missing**, or **Not applicable** before changing code.
2. A folder shown above is not proof that it exists. Do not create empty placeholder folders to claim completion.
3. Inspect current imports, routes, dependencies, workflow triggers and tests before moving, renaming or deleting files. Avoid duplicate models, routes and services.
4. Preserve existing files until a path-by-path migration is safe and tested. If current ownership differs from this target, document the migration and complete it in small verified steps; do not treat an earlier hybrid layout as overriding this approved target.
5. `lib/features/coupons/` is included in the requested target drawing for structural reference only; the business rule remains **no coupon-code system**. Do not implement coupon UI, routes, or behavior. Record this explicit exception in the audit.
6. Keep raw/source location data under `data/reference/india_locations/` and generated/runtime Dart reference data under `lib/data/reference/india_locations/`. Keep these separate from live customer address records.
7. Validate source provenance, IDs, counts, parent-child integrity, imports and checksums for the three India Dart datasets before restoration or integration. No production Firebase import.
8. Preserve `firebase_options.dart`; do not change Firebase configuration or start backend integration in this phase.
9. Service Location Create Zone selectors are exactly **State/UT → District → City → Zone**; no Locality selector. Only Zone can be activated, and verified polygon evidence is required.
10. Founder/CEO business approval is separate from Super Admin technical access. Central Admin cannot approve its own submission. Approval binds to the submitted revision and boundary hash. Keep real approval/activation disabled until backend authorization and audit logging are implemented and verified.
11. Run `flutter pub get`, format changed Dart files, `flutter analyze`, `flutter test`, and `flutter build web --release`. Record exact commit SHA and actual CI results. A missing check is **Pending**, not PASS.
12. Keep PR #51 Draft. No merge, deployment, or Firebase integration until the UI/structure phase and its verification gates are complete.

## Current implementation status

The canonical target has been recorded. Full file-tree reconciliation, migration, location-data integrity verification and exact-head CI are **In progress / Pending**. This document update alone does not mean the target has been implemented.
