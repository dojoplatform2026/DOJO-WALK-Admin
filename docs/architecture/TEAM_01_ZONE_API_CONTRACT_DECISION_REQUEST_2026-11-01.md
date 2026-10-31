# Team 01 Decision Request — Zone API Contract
Date: 2026-11-01
Owner: Team 02 — Admin App
Status: BLOCKED — awaiting Team 01 decisions
Related Admin PR: #51 (Draft; do not merge)
Related specifications: POL-040 (Admin Service Location UI), POL-041 (India Service Location API & Backend Workflow)

## Purpose
Team 02 has completed a source-level cross-check of the Admin Zone workflow against the Firebase callable implementation inspected in Team 01's Zone workflow branch. This request records the decisions required before any API wiring is attempted. This document is a handoff request, not evidence that the contract is approved or deployed.

## Decisions required from Team 01

### D01 — Admin role mapping
The inspected Zone lifecycle callables require an active admin record with the exact role `central_admin`; Founder approval requires `founder`. The Admin application has also used `super_admin`.
- Confirm whether `super_admin` is intentionally denied these callables, or provide the approved server-side role/permission mapping.
- Specify which Admin roles can save drafts, review boundaries, submit Founder review, execute activation/deactivation, emergency-suspend, and approve/reactivate.
- Confirm that client-side role labels are not treated as authorization.

**Team 01 answer:** Pending.

### D02 — Boundary upload/create contract
The inspected Admin service has a boundary-review method, but no boundary-create/upload method was found in the inspected Firebase callable exports.
- Confirm the intended boundary ingestion mechanism (callable, authenticated Storage upload + server validation, or another documented flow).
- Provide exact callable/export or Storage path, request fields, response fields, file/geometry limits, and validation/error behavior.
- Confirm how the uploaded boundary is bound to the Zone revision and immutable boundary hash.

**Team 01 answer:** Pending.

### D03 — Manager and geographic scope enforcement
The inspected callable role checks showed active global roles but did not show city/zone assignment scope checks.
- Confirm whether Area/City Manager and Zone Supervisor are permitted to use any Zone workflow operations.
- If permitted, identify the authoritative assignment documents/claims and server-side scope checks.
- Confirm that out-of-scope city/zone operations are rejected server-side, with the stable error code.

**Team 01 answer:** Pending.

### D04 — Stable error and response contract
The cross-check observed Firebase error codes including `unauthenticated`, `permission-denied`, `invalid-argument`, `not-found`, `already-exists`, `failed-precondition`, `aborted`, and `internal`.
- Confirm the canonical error-code catalogue and whether any domain-specific details are returned in `details`.
- Provide stable success response schemas and error response examples for each Zone callable.
- Confirm retry/idempotency expectations, especially for submit, activation, deactivation, and emergency suspension.

**Team 01 answer:** Pending.

### D05 — Emergency suspension and reactivation lifecycle
The inspected source indicates emergency suspension immediately makes a Zone inactive/suspended and queues a durable Founder inbox item; a later reactivation requires a new request, Founder approval, and the dedicated `activateServiceZone` callable.
- Confirm this is the intended lifecycle and identify who may initiate and execute each step.
- Confirm Founder notification delivery channels and whether push/email are configured or only the durable inbox record is guaranteed.
- Confirm required audit events and operational recovery expectations.

**Team 01 answer:** Pending.

## Evidence requested
For each decision, Team 01 should provide:
1. The source branch and exact commit SHA inspected.
2. Callable/export names and relevant source/test paths.
3. Emulator test evidence covering allowed and denied roles, including out-of-scope access where applicable.
4. Any Notion POL-041 updates, with a link to the updated section/page.
5. Explicit status: implemented and emulator-verified, implemented but unverified, planned, or not supported.

## Team 02 acceptance gate
Team 02 will not wire callable APIs until D01–D05 are answered and the relevant contract is reflected in POL-041. Once confirmed, Team 02 will update the Admin service adapter, normalize callable errors into user-safe UI states, add role/scope-aware UI tests, and run emulator-backed integration tests against the agreed Team 01 branch/commit.

## Guardrails
- No Firebase repository, rules, functions, schema, or production data changes from Team 02.
- No API integration before the acceptance gate.
- Keep Admin PR #51 Draft and unmerged; no deployment.
- A source inspection or planned test is not an emulator PASS.
