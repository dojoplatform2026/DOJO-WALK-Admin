# DOJO WALK — Admin Customer & Pet Management / Data Privacy Audit
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Admin
Branch: ui/notion-brand-foundation-2026-10-28
Scope: read-only source review of Admin Customer/Pet screens and tests, navigation, and Notion policy alignment.

## Executive result
Customer Management and Pet Management are both **UI-only prototypes using hard-coded example records**. They are not connected to Firestore or a live customer/pet service. No customer account lifecycle, dog profile editing, booking-linked pet detail, privacy request, or safety-status mutation is implemented in these screens.

The prototype correctly labels sample data and disables sensitive actions. It is not a production customer/pet administration capability.

**Release assessment: NO-GO for live customer/pet administration or personal-data disclosure from these screens.** No code was changed and no customer data was accessed.

## Source inspected
- `lib/features/customers/screens/customer_management_screen.dart`
- `lib/features/pets/screens/pet_management_screen.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `test/features/customers/customer_management_screen_test.dart`
- `test/features/pets/pet_management_screen_test.dart`
- Expected service/model files `customer_admin_service.dart`, `customer_admin_model.dart`, `pet_admin_service.dart`, `pet_admin_model.dart` were not found at the inspected paths.

## Verified implementation facts
### Customer Management
1. The screen owns three hard-coded `CUS-EX-001..003` examples in memory. No Firestore/service stream or repository is used.
2. Search and status chips filter only the local examples; the dialog explicitly says no live customer data was accessed.
3. Example fields include masked phone, example.invalid email, status, age-eligibility placeholder, terms version, marketing-consent placeholder and example update time.
4. Contact details are masked in sample data; UI warns staff never to request passwords, OTPs, PINs or payment authentication secrets.
5. Restrict and Close Account actions are disabled. The screen warns that real actions require authorized scope, reason, audit logging and safe handling of active bookings/walks.
6. No real profile verification, consent capture, access/correction/export/deletion request, account restriction, closure, or audit action is implemented.

### Pet Management
1. The screen owns three hard-coded `DOG-EX-001..003` examples in memory; no live pet/customer records are loaded.
2. Search and filters operate only on local examples. Example dialog explicitly states health status is not verified in preview.
3. Fields are placeholders for customer reference, breed/size, health/vaccination, handling and care notes.
4. Edit and Safety Action controls are disabled.
5. No live pet-to-customer relationship lookup, booking linkage, verified vaccination record, care-note authorization, safety-flag lifecycle, or edit history is implemented.

### Navigation and tests
- AdminShell exposes Customers and Pets as separate menu entries and routes to these two prototype screens.
- Customer tests cover masked examples, privacy warning, local search/status filtering, example-only dialog and 360px viewport.
- Pet tests cover sample records/safety warning, local search, example-only dialog and 360px viewport.
- These tests assert prototype presentation only. They do not establish backend ownership, Rules enforcement, access scope, consent correctness, data retention, booking links or production behavior.
- No tests were executed as part of this audit; source files were inspected.

## Notion policy alignment
- **POL-014 — Privacy & Data Access Policy:** Draft, not approved/implemented. Requires least-privilege access, customer access only to own account/dogs/bookings, Support case-limited access, geography-limited operations, server-side/Rules authorization, and restricted dog/safety/location information.
- **POL-020 — Data Privacy, Retention & Deletion Policy:** Draft, not approved/implemented/tested. Requires data inventory, purpose/notice, controlled access/correction/export/deletion requests, approved retention schedule, backup/vendor deletion and verification. It explicitly says not to invent retention durations or claim deletion without evidence.
- **POL-031 — Customer Account, Profile, Consent & Account Lifecycle Policy:** Draft, not approved/implemented/tested. Defines proposed lifecycle states and requires authorized, traceable transitions, verified age/consent and safe closure handling. UI labels alone do not prove backend state.
- **POL-006 — Customer Booking & Eligibility Policy:** Draft policy reference for customer eligibility and booking constraints; the Admin customer/pet screens do not demonstrate enforcement.
- **POL-027 — Dog Safety, Welfare, Walk Handling & Emergency Response Policy:** draft policy reference for dog handling/safety. The Admin pet prototype does not establish verified health or safe-to-walk status.

## Material gaps / risks
1. **No live data contract:** no canonical customer/pet read model, query boundaries, pagination, ownership references or error states.
2. **No customer ownership proof:** UI does not verify `customerId` ownership or enforce it server-side. Sample customer IDs are illustrative.
3. **No canonical pet-to-booking link:** Admin cannot establish which dog(s) belong to a booking, whether a dog is active, or whether the booking snapshot preserves the care instructions valid at booking time.
4. **Safety-data integrity:** missing/unverified health and handling details must remain unknown, never silently treated as safe. No verified evidence/status lifecycle exists.
5. **Sensitive notes exposure:** dog care/behavior/safety notes need booking- and role-scoped access, especially for walkers, support and managers.
6. **Consent evidence:** terms and marketing consent are placeholders; no notice version, purpose, timestamp, source, revocation or consent history is wired.
7. **Account lifecycle:** no verified age eligibility, restriction reason, review date, appeal, closure request, legal hold, deletion workflow or active-booking safety gate.
8. **Privacy request operations:** no access/correction/export/deletion intake, identity verification, decision log, backup/vendor handling or completion evidence.
9. **Authorization:** UI masking and disabled controls do not replace Firestore Rules/Functions enforcement. No Rules or Storage tests were reviewed/run.
10. **Test coverage:** widget tests are prototype-only; no integration/security tests or data-retention tests were executed.

## Required cross-team contracts before implementation
- Team 01: versioned Customer and Dog read/write contracts, canonical IDs and ownership, approved field allowlists, server timestamps, status enums and query/index design.
- Team 01: enforce customer ownership, Admin capability and city/zone scope in trusted backend/Rules; deny by default; test direct document reads and collection queries.
- Team 01 + Team 04: canonical dog profile schema, customer-to-dog ownership, active/inactive lifecycle, booking-time snapshot of relevant handling instructions, and multi-dog booking constraints.
- Safety/Operations: define evidence-backed vaccination/health/handling status and who may verify or change it; distinguish unknown, expired, not supplied and verified states.
- Privacy owner: approve notices, age/eligibility verification, consent evidence, access/correction/export/deletion workflow, retention schedule and legal holds.
- Admin: build read-only least-privilege customer/pet views first; mask contact details by default; reveal only with explicit capability and reason/audit; never expose unrelated records.
- QA: test customer ownership isolation, city/zone scope, sensitive-note restrictions, consent history, active-booking closure guard, deletion/hold handling, stale/unknown safety status and responsive states.

## Safe Admin-only next steps
- Keep both screens clearly labelled as prototypes; do not present sample records as live counts or customers.
- Preserve disabled account restriction/closure, pet edit and safety mutation controls.
- Do not create a new service/model based on guessed Firestore fields.
- Once Team 01 and Team 04 approve the contract, implement read-only views with injected data sources and explicit loading/empty/error/permission-denied states.
- Do not change Firebase schema, Rules, indexes, Functions, Storage, Customer/Partner repositories or production records from this Admin repository.

## Verification boundary
Static source and Notion policy inspection only. Customer and Pet widget test files were read but not executed. No emulator, Rules/Functions, live account, booking/pet linkage, privacy request, retention/deletion, or safety workflow test was performed. No application code was changed.

## Decision
**NO-GO for production customer/pet administration** until approved policies, canonical Team 01/Team 04 contracts, server-enforced ownership/scope, sensitive-note controls, consent/retention workflows and automated integration/security tests are complete and independently evidenced. Keep PR #51 open/draft; do not merge or deploy based on this audit.
