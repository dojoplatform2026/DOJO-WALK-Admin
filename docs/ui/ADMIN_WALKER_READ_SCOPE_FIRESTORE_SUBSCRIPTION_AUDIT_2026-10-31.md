# DOJO WALK Admin — Walker Read Scope & Firestore Subscription Audit

- Date: 2026-10-31
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (Draft / open)
- Scope: Admin source review only. No Firebase repository, Firestore Rules, indexes, deployed data, or backend code changed.

## 1. Source evidence

Reviewed:
- `lib/features/walkers/services/walker_admin_service.dart`
- `lib/features/walkers/screens/walker_management_dashboard_screen.dart`
- `lib/features/walkers/models/walker_admin_model.dart`
- `lib/features/walkers/utils/walker_admin_helpers.dart`

Observed query shapes:
- `watchWalkers()`: `walkers.snapshots()` — unfiltered, unbounded collection listener.
- `watchBookings()`: `bookings.snapshots()` — unfiltered, unbounded collection listener.
- `watchWalkerBookings(walkerId)`: `bookings.where('walkerId', isEqualTo: walkerId).snapshots()` — scoped by walker ID, but still unbounded and not date/status limited.
- `watchWalkerAuditLogs(walkerId, limit)`: filters `targetType == walker`, `targetId == walkerId`, orders by `createdAt desc`, and limits to 1–200 (default 50). This is the only inspected bounded listener.

The dashboard caches the two production streams in `initState`; this prevents rebuild-driven resubscription but does not reduce the number of documents initially read or subsequently listened to.

The dashboard derives running IDs by reading every booking document, then filtering in the client for status in:
- `in_progress`
- `active_walk`
- `walking`
- `walk_started`

It then collects non-empty `walkerId` values. This means the admin dashboard's running-state listener grows with the complete booking collection, even though only a small subset of bookings can be running.

## 2. Risk assessment

| Query | Risk | Why |
|---|---|---|
| All walkers listener | High | Unbounded profile/KYC-related document reads; client filtering is not an authorization boundary. |
| All bookings listener | Critical at scale | Reads customer booking records to derive a small running-ID set; broad data exposure and ongoing listener/read cost. |
| Walker-specific booking listener | Medium | Correctly scopes by walker ID but has no date/status limit and may grow with lifetime history. |
| Walker audit listener | Lower / bounded | Server-side filter, order and limit are present; requires the documented composite index. |

No production read counts, billing metrics, Rules evaluation traces, deployed indexes, or user-level access scopes were available in this Admin-only source review. Actual cost and effective data access remain unverified.

## 3. Why a UI-only query change is blocked

A safe replacement cannot be selected from the current inspected contracts:

1. Walker documents need an approved server-enforced city/zone scope. The current model/source audit does not establish the canonical, immutable scope fields and how a manager's authorized scope is resolved.
2. Running state is derived from parent booking status and `walkerId`. The cross-app audit found no authoritative per-walk occurrence/offer record for recurring and multi-walk-per-day bookings.
3. A query such as `where(status in [...])` would still expose booking fields to every client authorized to read those matching documents; query filters do not replace Firestore Rules.
4. Adding fields such as `zoneId`, `cityId`, `isRunning`, or `activeOccurrenceIds` without a canonical writer would create stale or fabricated state.
5. Adding arbitrary limits would silently omit walkers/bookings and could make the Running tab or counts incorrect. Pagination must have explicit product semantics.

## 4. Required backend/data contract before optimization

Backend/Firebase team must define and approve, without assuming current field names:

- Canonical walker service scope (nation/city/zone) and how Admin role → authorized scope is enforced in Rules or trusted server APIs.
- A minimal Admin walker list projection that excludes KYC document payloads and private fields not needed by list cards.
- Pagination order, stable cursor, page size, search strategy, and whether counts mean page count or total count.
- A canonical live-work/occurrence source with one record per actual scheduled walk, including stable occurrence ID, walker ID, booking ID, authoritative status and timestamps.
- A bounded running-work query or server-maintained projection with a trusted writer and stale-state repair/reconciliation.
- Composite indexes and Rules tests for Central Admin, City Manager, Zone Supervisor, unauthorized zone, inactive admin, and unauthenticated users.
- A documented freshness/latency expectation for the Running tab and a recovery strategy when the projection is delayed or inconsistent.
- Data minimization: do not return customer address, pet/KYC documents, phone or payment fields to a walker list query unless the screen has an approved need and role permission.

Potential design direction (not a claim about current implementation): a trusted backend-maintained, least-privilege Admin list projection plus a per-walk active-occurrence index/query. Do not create either until the canonical data contract, writer ownership, Rules and reconciliation tests are approved.

## 5. Safe Admin-side follow-up after approval

1. Add a typed paginated read interface to the existing Walker Admin service; keep Firestore query details out of widgets.
2. Preserve search/filter behavior with explicit server-supported fields and honest page/total-count labels.
3. Replace the global bookings listener with the approved bounded running-occurrence source.
4. Keep walker detail/history reads scoped to one walker; paginate booking history if the volume requires it.
5. Add emulator Rules tests proving out-of-scope records cannot be read, not merely hidden by UI filters.
6. Add widget tests for pagination, empty next page, cursor reset on filter changes, stale running projection, permission denied and retry.
7. Measure read counts against a representative seeded dataset and record before/after evidence.

## 6. Decision / status

- Source query audit: COMPLETE.
- UI stream caching: already present; does not solve unbounded query size.
- Admin-only safe query replacement: BLOCKED pending canonical backend scope and per-walk occurrence contract.
- Firebase Rules/index/data changes: NOT performed (out of scope).
- Production data/read-cost verification: NOT performed.
- No broadening of access, no guessed fields, no arbitrary limits, no client-only authorization changes.
- PR #51 remains Draft / open; no merge or deployment.
