# Archived Branch Consolidation — 2026-10-31

Status: selective review and safe port completed; no archived PR was merged wholesale.

## Canonical development line

- Active branch: `ui/notion-brand-foundation-2026-10-28`
- Active PR: #51 → `main`
- Automatic validation: `.github/workflows/admin-main-full-validation.yml`
- Closed PRs #44, #45, #46, #47, #49 and #50 remain closed/unmerged as recovery references.
- Archived source branches have not been deleted.

## Ported safely

### PR #45 — Admin membership verification hardening

Ported to the canonical branch:
- `AuthGate` now fails closed if the Admin membership document cannot be read or is invalid.
- `AuthService.signInAdmin` signs out if the Admin membership record is missing, inactive, or cannot be verified.
- Active Admin membership remains the app-entry condition. Feature/action authorization must continue to use role-specific UI gates and trusted Firebase callables.

Important deliberate deviation from PR #45:
- Did NOT require `role == super_admin` at the app gate. The approved Admin governance includes Founder, Central Admin, technical Super Admin and operational roles; restricting the entire app to technical Super Admin would lock out legitimate roles. The Firebase callable/Firestore security boundary must enforce each privileged action.
- PR #45's browser test edits depend on PR #44's E2E harness, so they were not copied independently.

## Reviewed but not ported

### PR #47 and PR #49 — Zone workflow implementation

Not copied wholesale because:
- Their `service_location_screen.dart` targets the older Countries/States/Districts/Cities/Zones tab UI. The canonical branch already has a newer Zone-first navigation and dedicated prototype screens. Replacing the canonical screen would regress current UI work and recreate duplicate flows.
- The Firebase dependency, PR #39 in `DOJOWALK/DOJO-WALK-Firebase`, is still Draft/Open at the reviewed head. The Admin callable wrapper must not be treated as integrated until the matching backend contract is merged/reviewed and verified.
- PR #49 browser E2E script assumes old tab labels and controls (Countries → Zones → Create Zone Draft), so it is not compatible with the canonical screens.
- PR #49's contract verifier depends on a Zone service file absent from the canonical branch; copying only its test would create a permanently failing/incomplete check.
- The zone model, callable service, role gates and lifecycle widgets remain useful source material, but require a fresh adapter into the current screens and exact Firebase callable contract before porting.

### PR #50 — Remove legacy status handlers

Not copied wholesale because it deletes substantial legacy validation and service methods, including parent ancestry and verified-boundary checks. The canonical UI already hides legacy service activation controls. Retain service-layer compatibility until all references, Firestore schema migration requirements, and tests are audited; remove obsolete methods in a dedicated, reference-checked change rather than deleting protections blindly.

### PR #44 — Browser E2E

Not ported because it was built against an older UI and uses a specific Firebase backend revision. Rework it against the current Zone-first screen flow only after the Firebase callable contract is available. Emulator-only safety guards must remain mandatory.

### PR #46 — Documentation audit

Documentation-only branch. Its useful findings are superseded by the canonical Notion-aligned UI and this consolidation record; do not merge it as a second documentation source.

## Required next integration gates

1. Review/merge the Firebase Zone callable contract independently; no Admin live integration before that.
2. Adapt Zone model/service/role gates to the canonical screen prototypes, with exact field/callable names.
3. Add service/model/widget tests before enabling any Zone action.
4. Rewrite browser E2E for the canonical UI and emulator-only project.
5. Audit all call sites before deleting legacy service methods.
6. Run the single automatic CI gate and manual device acceptance. A green CI run does not equal production readiness.

## Safety

No PR was merged, no archived branch was deleted, no Firebase production data was changed, and no deployment or emulator integration was run as part of this consolidation.
