# DOJO WALK Admin — Branch and CI Policy

Status: adopted for the current Admin consolidation work (2026-10-31).

## One active development line

- `main` is the protected-intent release baseline; do not push feature work directly to it.
- Until the current Admin consolidation PR is reviewed and merged, the only active development branch is:
  `ui/notion-brand-foundation-2026-10-28`
- Do not create a second branch for the same Admin UI, Service Location, authentication, or test work.
- Continue related changes on the one active branch and keep one draft PR against `main`.
- If a genuinely independent release line is ever needed, document the reason and obtain explicit owner approval before creating it.

## Before adding code

1. Search the repository and open PRs for an existing implementation.
2. Reuse or extend the existing file, test, and workflow where appropriate.
3. Do not create a parallel screen, service, model, or test for an existing responsibility.
4. Update the relevant Notion-aligned contract and acceptance checklist.
5. Add regression tests for the changed behavior.

## Single automatic CI gate

`.github/workflows/admin-main-full-validation.yml` is the sole automatic Admin CI gate for the canonical branch and PRs targeting `main`. It runs:

1. Dart formatting check
2. Git whitespace check
3. Flutter static analysis
4. Full Flutter test suite
5. Flutter Web release build (no deployment)

The old full-suite and geometry workflows remain available only through manual `workflow_dispatch`; they must not create duplicate automatic runs.

## Deployment and Firebase safety

- CI must never deploy.
- Live Hosting deployment remains a separate manually dispatched workflow with explicit confirmation and production environment controls.
- Do not run production Firebase writes, emulator integration, or deployment as part of ordinary UI validation.
- A green CI run is not the same as manual device acceptance or owner approval.

## Completion gate

Do not mark the Admin UI complete until the full CI gate is green, manual acceptance checklist items are verified, and the owner approves the result.
