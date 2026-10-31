# DOJO WALK Live Operations ↔ Partner GPS Contract Audit

**Date:** 2026-10-30  
**Status:** Read-only source audit; proposed contract only  
**Admin branch:** `ui/notion-brand-foundation-2026-10-28`  
**Repositories inspected:** `DOJOWALK/DOJO-WALK-Admin`, `DOJOWALK/DOJO-WALK-Partner`

## 1. Executive finding

The current Admin Live Operations screen and Partner Live Walk implementation do not share a persisted live-location contract.

- Admin listens to `walkers` where `isOnline == true`, then reads `walkers/{walkerId}.currentLocation` as either a Firestore `GeoPoint` or a map containing `latitude` and `longitude`.
- Admin route history reads `walk_locations` filtered by `walkerId`, ordered by `timestamp`, capped at 300 points.
- Partner Live Walk collects GPS positions in memory with Geolocator. The inspected code does not write each position to `walk_locations` and does not update `walkers/{uid}.currentLocation`.
- When a walk ends, Partner writes a completed document to `walks/{generatedWalkDocumentId}`; its `route` is an embedded list of GeoPoints capped/compacted to 500. The document includes `walkerId`, optional `bookingId`, `startedAt`, `endedAt`, `status`, `startLocation`, and `endLocation`.

Therefore Admin's current live marker and route queries are not fed by the inspected Partner Live Walk writer. This is a source-code mismatch, not a live production-data test.

## 2. Admin read contract observed

File: `lib/screens/live/live_operations_screen.dart`

### Online walker listener
- Collection: `walkers`
- Filter: `isOnline == true`
- Marker location field: `currentLocation`
- Accepted marker shapes:
  - Firestore `GeoPoint`
  - map with numeric `latitude` and `longitude`
- Selected walker booking reference: `currentBookingId`
- Walker display/status fields include `name`, `status`, `rating`.

### Route history
- Collection: `walk_locations`
- Filter: `walkerId == selectedWalkerId`
- Sort: `timestamp ASC`
- Limit: 300
- Point fields: numeric `latitude`, `longitude`

Observed gaps:
- No `walkId` or `bookingId` filter in route query.
- No freshness cutoff or stale-location state.
- The marker parser does not inspect a location timestamp.
- The listener has no city/zone scope parameters in this screen.
- Online presence is treated as a proxy for a live walk; these are different concepts.

## 3. Partner write/collection contract observed

Files:
- `lib/features/live_walk/screens/live_walk_screen.dart`
- `lib/features/live_walk/services/location_permission_service.dart`
- `lib/screens/home/navigation_screen.dart`

### GPS acquisition
- Geolocator position stream, high accuracy, distance filter 3 meters.
- Rejects invalid coordinates, accuracy above 35m, and single jumps above 100m.
- Route points and distance are accumulated in memory.
- Stream is cancelled when the walk ends or screen is disposed.
- Permission helper accepts `whileInUse` or `always`; background tracking behavior is not established by this source alone.

### Walk completion write
- Collection: `walks`
- Document ID: generated independently via `walks.doc().id`
- Fields include `walkerId`, optional `bookingId`, `startedAt`, `endedAt`, `duration`, `distance`, `status: completed`, `route: List<GeoPoint>`, optional `startLocation` and `endLocation`.
- Partner also updates `bookings/{bookingId}` to `completed`.

Important: the Partner walk document ID is the walk identifier; the booking ID is stored separately. Keep that distinction in every future contract.

## 4. Confirmed mismatch matrix

| Concern | Admin reads | Partner writes | Result |
|---|---|---|---|
| Current marker | `walkers.currentLocation` | No per-fix walker location write found in inspected live-walk file | Not connected by inspected code |
| Route collection | `walk_locations` | Completed route embedded in `walks/{walkId}.route` | Collection mismatch |
| Route point timestamp | `walk_locations.timestamp` | Embedded GeoPoints have no per-point timestamp | Timestamp mismatch |
| Route identity | `walkerId` only | `walkerId` + optional `bookingId` + generated walk doc ID | Missing walk-level filtering |
| Online/live meaning | `isOnline == true` | Walk lifecycle represented by booking status and completed walk doc | Presence ≠ active walk |
| Freshness | Not checked | Position has device timestamp in memory, but not persisted as point metadata | Stale marker cannot be detected |

## 5. Proposed canonical contract (NOT IMPLEMENTED)

Do not treat this proposal as an existing schema. It requires alignment across Partner, Admin, Firestore rules, and backend.

### A. Walk identity and lifecycle
- `walkId`: immutable ID of `walks/{walkId}`.
- `bookingId`: separate booking reference; never substitute it for `walkId`.
- `walkerId`: authenticated Partner UID.
- Lifecycle events should bind all three IDs and verify the booking-to-walker assignment server-side.

### B. Live location point
Recommended collection: `walk_locations`, with one document per accepted GPS fix:
- `walkId` (required)
- `bookingId` (required)
- `walkerId` (required)
- `latitude`, `longitude` (validated finite numeric coordinates)
- `accuracyMeters`
- `capturedAt` (device capture time)
- `receivedAt` (server timestamp)
- `sequence` (monotonic per walk, if safely maintained)
- `source` (e.g. `partner_gps`)

Use a server-generated or otherwise collision-safe point ID. Do not rely on a mutable array in the walker profile for route history.

### C. Current location / presence
If Admin needs a fast current marker, maintain a separate current-location summary keyed by walker or active walk, containing the same IDs, coordinates, capture/receive times, and explicit freshness. Presence (`isOnline`) must remain separate from walk state.

### D. Query contract
- Admin must select an authorized city/zone scope before reading.
- Active tracking view must be bound to a specific active `walkId` and `bookingId`.
- Route query must filter by `walkId` (and validate `walkerId`/booking linkage), not by walker alone.
- Display a stale/offline state when last accepted point exceeds an agreed threshold; do not continue presenting an old point as live.
- Enforce retention and pagination server-side; do not load unbounded route history.

## 6. Required security and operational controls

Before implementation:
1. Firestore rules or trusted backend must verify the authenticated Partner owns the active assigned walk and booking.
2. Partner must not write arbitrary `walkerId`, `walkId`, `bookingId`, or another walker's location.
3. Only authorized Admin roles may read location data, scoped to assigned city/zone; UI filters are not authorization.
4. Deny client edits/deletes to historical GPS points; corrections should be explicit audited server workflows.
5. Validate coordinate ranges, accuracy, timestamp skew, sequence/replay, and plausible movement.
6. Handle GPS permission loss, network outage, app backgrounding, device restart, and delayed uploads explicitly.
7. Stop accepting live points when the walk is completed/cancelled/otherwise terminal.
8. Define location retention, access audit, customer disclosure/consent, and incident access before launch.

## 7. Implementation order

1. Approve a single contract and event lifecycle in the canonical Notion spec.
2. Implement Partner writer and offline/retry behavior against Firebase Emulator.
3. Add Firestore rules tests for ownership, assignment, city/zone read scope, terminal walk rejection, and immutable history.
4. Implement Admin live marker and route reader using the same IDs and freshness rules.
5. Add cross-repo emulator integration tests and test multi-walker/multi-zone isolation.
6. Only after evidence passes, plan production rules/index deployment separately with explicit approval.

## 8. Scope and evidence limitations

- This is a static source audit of the checked-in files and refs returned by GitHub; no production Firestore data was read or changed.
- The audit does not prove whether another service or background worker writes `walk_locations`; a repository-wide search of the Partner repo returned no matching `walk_locations` or `currentLocation` references in the indexed source.
- No code, Firestore rules, indexes, production data, or deployment configuration was changed by this audit.
- PR #51 remains draft/open; no merge or deployment is authorized by this document.
