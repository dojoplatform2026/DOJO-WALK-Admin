# DOJO WALK — Admin Live Operations GPS & Privacy Audit
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Scope: read-only source review of Live Operations, route rendering, booking summary and Notion incident requirements.

## Executive result
The Live Operations screen is a map-based viewer for online walker profiles and route points. It is **not yet a verified safety-grade live-walk command system**. It does not establish location freshness, walk-occurrence identity, GPS accuracy, route completeness, incident acknowledgement or trusted active-walk state. An online marker alone is not proof of an active walk.

## Source inspected
- `lib/screens/live/live_operations_screen.dart`
- `lib/screens/live/live_booking_details_helper.dart`
- `lib/screens/live/live_map_widget.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- Expected `test/screens/live/live_operations_screen_test.dart` was not found at that path on this branch.

## Verified source facts
1. Screen subscribes to `walkers.where('isOnline', isEqualTo: true).snapshots()`; count and markers represent online walker documents, not verified active walks.
2. Marker location accepts GeoPoint or numeric latitude/longitude map. No timestamp, accuracy, source, freshness or coordinate-range validation is applied.
3. Initial camera is fixed at Delhi coordinates `28.6139, 77.2090`; it is not derived from active service zone or selected walker.
4. Selecting a walker queries `walk_locations` by `walkerId`, orders `timestamp` ascending and limits to 300 points. It is not scoped to booking ID or walk ID and has no bounded active-occurrence window.
5. Route points are accepted when latitude/longitude are numeric. The UI does not show point timestamps, GPS accuracy, stale gaps, missing intervals or route completeness.
6. Booking summary fetches one booking by ID and uses an allowlist: status, customer/walker/walk/zone IDs, scheduled/start/completed timestamps, duration and dog count. Arbitrary booking fields are not dumped into the dialog.
7. Listener error state and Retry exist; listener is cancelled on dispose and before retry.
8. Map widget disables Admin device-location access.
9. Dashboard Operations Alerts are derived from booking status counts, not a dedicated incident feed with severity, owner, acknowledgement, escalation and resolution.

## Risks / gaps
- **Critical — freshness ambiguity:** online status/currentLocation have no visible last-updated or accuracy indicators. Stale coordinates may look live.
- **High — route ambiguity:** walkerId-only query can mix multiple walks/dates; 300 oldest-first points may omit latest points. It does not prove a particular booking's complete route.
- **High — missing occurrence contract:** recurring/multiple-walk booking model needs a canonical walk-occurrence ID. Live Operations cannot safely infer current walk from walkerId alone.
- **High — authorization/scope:** client filters do not prove Rules enforce city/zone scope or least privilege. No Rules trace/test was run.
- **High — incident response gap:** no severity/acknowledgement/on-call handoff/escalation workflow is evidenced in this screen.
- **Medium — fixed map center:** Delhi initial camera can mislead for another operating zone.
- **Medium — route integrity:** coordinates are not range-checked; timestamp gaps and accuracy are not represented.
- **Test gap:** expected dedicated Live Operations widget test file was not found at the inspected path. This does not prove no other tests exist.

## Required Team 01 / Backend & Firebase contract
1. Canonical active walk occurrence with immutable `walkId`, `bookingId`, `walkerId`, zone/city scope, lifecycle state and server timestamps.
2. Location samples linked to that walk occurrence, with capturedAt/serverReceivedAt, accuracy, source metadata and retention policy.
3. Server-enforced role/city/zone access to presence, active occurrence and route samples; least-privilege projections and Rules tests.
4. Explicit freshness thresholds and trustworthy online/presence semantics; distinguish online session from active walk and GPS freshness.
5. Bounded route query by walkId/time window, with pagination/order and latest-point behavior defined.
6. Incident queue contract: severity, case ID, owner, acknowledgement, escalation/handoff, status, evidence references and audit events.
7. Retention/deletion and access logging for sensitive location history.

## Safe Admin-only next steps
- Keep screen read-only; do not add assign/reassign/stop-walk or incident-closure mutations.
- Add parsing/presentation tests only after canonical contracts are documented.
- Display last update, accuracy and stale/unknown state only when backend supplies authoritative values.
- Scope route display to canonical walkId; do not guess using walkerId.
- Do not treat missing GPS as proof of misconduct or service failure.
- Do not modify Firebase schemas, Rules, indexes, Functions, Storage or production records from this repository.

## Verification boundary
Static source and policy audit only. No Flutter test, emulator, Rules test, GPS simulation, Google Maps runtime, device permission test or production monitoring was executed. No application code was changed.

## Decision
**NO-GO for safety-critical reliance on the map as a complete live-walk record** until freshness, occurrence identity, scoped access, route integrity and incident escalation are implemented and tested. Continue read-only monitoring and clearly communicate stale/unknown data when authoritative fields become available.
