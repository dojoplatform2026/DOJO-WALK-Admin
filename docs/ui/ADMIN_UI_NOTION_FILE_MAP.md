# DOJO WALK Admin — Notion-to-File UI Map

**Working branch:** `ui/notion-brand-foundation-2026-10-28`  
**Rule:** Notion is the source of truth. This document records the current UI mapping and gaps; it does not approve draft policies. No new Firebase integration, merge, or deployment is performed in this UI phase.

## Shared UI rules

- Brand: orange `#FF7900`, background `#FFFAF5`, text `#252525`.
- Use responsive cards/Wrap on mobile; do not force wide action toolbars on small screens.
- Mark every mock/example record clearly; never present mock data as live.
- Server-backed actions remain disabled until role/scope authorization, state guards and audit logging are implemented.
- UI role hiding is not security; backend must enforce permissions.
- No coupon system; do not re-add Coupons to the menu. The obsolete `lib/screens/coupons/coupons_screen.dart` was removed from this working branch; discount rules remain policy-controlled, not coupon-code based.
- Zone is the only service activation unit. State/UT, District and City are hierarchy/reference records.
- Founder/CEO business approval is distinct from Super Admin technical access.

## Current menu and files

| Admin menu | Current screen/file | Source of truth | Status |
|---|---|---|---|
| Dashboard | `lib/screens/dashboard/dashboard_screen.dart` | Owner Dashboard in India Operating System & Area Launch Master; related operational policies | Existing Firestore streams. Revenue metric is now labelled “Paid Payments (All Time)” with a note that it is gross and does not deduct refunds/fees, avoiding a misleading net-revenue implication. This change passed Analyze, all tests and Web Build in run [40774222923](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40774222923). Continue auditing metric definitions, date windows and loading/error states. |
| Live Operations | `lib/screens/live/live_operations_screen.dart`; `lib/screens/live/live_booking_details_helper.dart` | POL-007 Live Walk & Safe Handover; POL-008 Safety; POL-016 Incident & Emergency; POL-020 Privacy | Live walker listener now distinguishes initial loading, successful zero/nonzero online count, and an explicit visible error state; permission-denied is not shown as “0 walkers online”. The error banner includes a Retry action that re-subscribes to the walker stream; it no longer promises an automatic retry. Route/booking failures use permission-aware messages, and booking summary uses an approved field whitelist. Loading/error UI passed full CI in run [40774153769](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40774153769); the subsequent Retry control also passed Analyze, all tests and Web Build in run [40774427634](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40774427634). Backend authorization still governs actual reads. |
| Bookings | `lib/screens/bookings/bookings_screen.dart`; `lib/screens/bookings/booking_status_helper.dart` | POL-026 assignment; POL-029 cancellation/reschedule/refund; POL-030 payment controls | Existing stream remains; UI normalizes known lifecycle status values, parses timestamp variants for sorting, and distinguishes permission-denied from generic load errors. Dashboard query aliases now include lowercase spaced legacy status variants (for example `walker assigned` and `walk in progress`) as well as underscore/hyphen variants; tests assert each queried alias maps to the expected canonical status. Latest alias/test update is awaiting full CI verification. Full policy audit still required. |
| Walker Management | `lib/features/walkers/screens/walker_management_dashboard_screen.dart` | POL-004 Walker/Partner Management; POL-026 availability/assignment | Existing screen. Requires full Notion parity audit. |
| Customer Management | `lib/features/customers/screens/customer_management_screen.dart` | POL-031 Customer Account/Profile/Consent; POL-021 Access Control | UI prototype with masked example data, lifecycle filters and disabled restriction/closure actions. No customer data connection. |
| Pet Management | `lib/features/pets/screens/pet_management_screen.dart` | POL-008 Dog/Customer/Walker Safety; POL-031 customer/pet context | UI prototype with example records, explicit unverified health/handling fields and disabled edit/safety actions. |
| Notification Center | `lib/features/notifications/screens/notification_center_screen.dart` | POL-032 Notifications/Communication Preferences; POL-020 Privacy | UI prototype with categories, safe message previews and disabled send/retry actions. No channels configured. |
| Support & Complaints | `lib/features/support/screens/support_center_screen.dart` | POL-009 Support & Complaints; POL-024 Support/Refunds/Disputes; POL-016 incidents | UI prototype with S0–S3 example queue, safety-first ordering and disabled transfer/resolve actions. Severity policy is draft. |
| Admin Users & Roles | `lib/features/access_control/screens/admin_access_control_screen.dart` | POL-021 Access Control, Admin Roles & Privileged Account Security | UI prototype role matrix. Explicitly separates Founder/CEO from Super Admin. Grants, scope changes and MFA actions disabled. |
| Audit Logs | `lib/features/audit/screens/admin_audit_logs_screen.dart` | POL-021 Access Control; POL-020 Privacy/retention; India Operating System audit-record standards | UI prototype with actor, role, resource, result, reason and IST timestamp fields; export disabled and no live audit data. |
| Reports & Analytics | `lib/features/reports/screens/reports_analytics_screen.dart` | India Operating System & Area Launch Master reporting standards; POL-004, POL-009, POL-016, POL-026, POL-029, POL-030, POL-038/POL-040 | Policy-mapped report catalog; no fabricated KPI totals. Open/export/schedule actions disabled until data definitions and permissions are approved. |
| Finance Operations | `lib/features/finance/screens/finance_operations_screen.dart` | POL-012 Payment/Refund/Reconciliation; POL-033 Earnings/Payouts; POL-029 cancellations/refunds | Cashless payment, refund and payout UI prototype; example amounts/statuses only. Verify/approve/reconcile actions disabled; no gateway or payout provider connected. |
| Settings | `lib/features/settings/screens/settings_governance_screen.dart` | POL-021 Access Control; POL-032 Notifications; POL-009 Support; POL-020/031 Privacy and account lifecycle | Policy-mapped preview for language, security, notifications, privacy/retention and verified support channels. Unconfigured values are explicit; no settings are saved. |
| Service Locations | `lib/features/service_location/screens/service_location_screen.dart` | POL-040 UI; POL-038 Zone lifecycle; POL-039 Firestore model/rules; POL-041 API; POL-042 test plan | UI work in progress. See `NOTION_POL040_FILE_MAP.md`. State/District/City activation controls removed; legacy City/Area polygons are no longer presented as active Zones. |

## Feature folder layout

- `lib/features/service_location/screens/` — service-location screens and prototypes.
- `lib/features/customers/screens/` — customer account UI.
- `lib/features/pets/screens/` — dog profile/safety UI.
- `lib/features/notifications/screens/` — notification operations UI.
- `lib/features/support/screens/` — support case queue UI.
- `lib/features/access_control/screens/` — admin role matrix UI.
- Tests mirror the domain folder under `test/features/<domain>/`.

## Remaining Admin UI scope

1. Complete role-based visibility and all Loading, Empty, Error, Permission Denied and Success states across every screen.
2. Audit Dashboard, Live Operations, Bookings and Walker Management against their detailed Notion policies; avoid fabricated metrics or status.
3. Confirm all Admin menu destinations and mobile layouts in responsive widget/integration tests.
4. Only after the UI is approved, start the planned Firebase/auth/Firestore integration and server-side authorization work.
5. Run responsive checks and full test suite after UI work; record actual CI evidence.

## Validation discipline

- Latest UI code validation: run `40687163413` passed `flutter analyze`, the complete test suite and `flutter build web --release` at commit `c41a1568bc54d0f2de16112fd1ece3c1ae4af7c7`. This includes Service Location, Customer, Pet, Notification, Support, Admin Users & Roles, Audit Logs, Reports, Finance, Settings, booking status/error UI updates, and privacy-safe Live Operations booking summaries.
- Latest known full CI status is **not green**: runs `40757393216` and `40757415352` failed during the test suite (199 passed, 3 failed); Analyze passed and Web Build was skipped. The initial cause was Founder Approval Queue tests looking for blocked example rows while the default filter is `Awaiting decision`. Tests were updated to select the blocked filters and to assert the default queue excludes blocked examples; mobile viewport setup was also stabilized. Follow-up changes add emergency suspension policy copy/tests, explicit unconnected map-source status plus unit tests, and clearer legacy import wording. These follow-up commits have **not yet been verified by a full CI run**. Do not claim PASS based on the older `40687163413` run.
- No merge or deployment is authorized in this phase.
