# Walker Management — Service/Testability Follow-up (2026-10-30)

## Verified source facts
Reviewed:
- `lib/features/walkers/screens/walker_management_dashboard_screen.dart`
- `lib/features/walkers/services/walker_admin_service.dart`
- `lib/features/walkers/widgets/walker_admin_widgets.dart`
- `test/features/walkers/walker_lifecycle_filter_helpers_test.dart`

## Confirmed implementation details
1. The dashboard constructs `WalkerAdminService()` internally; it cannot currently receive a fake/read-only service from a widget test.
2. `WalkerAdminService.watchWalkers()` subscribes to the complete `walkers` collection and maps every document to a model.
3. `WalkerAdminService.watchBookings()` subscribes to the complete `bookings` collection; the dashboard only needs booking status and walkerId to calculate Running.
4. The bookings StreamBuilder is nested inside the walkers StreamBuilder, and `watchBookings()` is invoked in the nested builder path. Search/tab setState rebuilds can therefore recreate the stream subscription unless the stream is cached.
5. `WalkerAdminTabs` uses a horizontal SingleChildScrollView and each tab has Semantics(button:true, selected:..., label:...). Therefore eight tabs do not automatically imply horizontal overflow; test swipe/keyboard accessibility and selected semantics instead of asserting a known overflow defect.
6. Search implementation checks name, phone, email, UID, area, city, state, status and verification status. Current hint only advertises name, phone and Walker ID, so the hint is inaccurate.
7. Search uses lowercase substring matching. Phone formatting normalization is not implemented.
8. Running detection recognizes only `in_progress`, `active_walk`, `walking`, and `walk_started`, then reads `walkerId`. The canonical booking status contract must be reconciled before changing this list.
9. Walker cards open Walker Details with the UID and raw profile data. No dedicated dashboard widget test exists in the inspected test directory.
10. The screen's error state distinguishes permission denied but currently provides no retry control.

## Risk assessment
- **High: data scope / privacy review.** Full-collection walkers and bookings subscriptions rely on Firestore Rules for strict access control. Do not assume client filtering is authorization. Confirm city/zone scope and least-privilege read rules before expanding usage.
- **High: booking stream cost/performance.** The dashboard downloads the full bookings collection merely to derive running walker IDs. Design a scoped query or server-maintained operational projection only after confirming the canonical booking schema, indexes, and rules.
- **Medium: stream lifecycle.** Cache streams in State or inject them so UI-only rebuilds do not repeatedly resubscribe.
- **Medium: testability.** Introduce a read-only abstraction that exposes typed walker and booking streams; production Firestore implementation remains the default.
- **Low: search discoverability.** Correct hint to reflect actual searchable fields, or intentionally constrain the search contract.
- **Accessibility validation needed.** Preserve horizontal scrolling; test semantics, focus traversal, and keyboard interaction.

## Next implementation order
1. Inspect Firestore Rules and canonical booking status contract; do not broaden any data access.
2. Define a read-only interface for walker and booking streams, implemented by current Firestore service.
3. Inject that interface into the screen with production default behavior.
4. Cache the two streams in State and verify resubscription behavior.
5. Add deterministic widget tests with fake streams: loading, data, empty, permission error, generic error, search, all eight filters, running aliases, profile navigation, retry (after implemented), and 320/360/390/768/1280 px layouts.
6. Correct search hint and add phone normalization only after expected search behavior is agreed in the product contract.
7. Run targeted tests, full Flutter tests, analyze, and web build on the exact commit; record actual workflow IDs/results.

## Not done / not claimed
- No application source code changed in this follow-up.
- No widget tests executed.
- No Firestore Rules or booking schema changed.
- No production Firebase data accessed or modified.
- No merge or deployment.
