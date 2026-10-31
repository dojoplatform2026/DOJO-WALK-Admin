# AdminShell Live Operations Navigation Correction — 2026-10-31

## Scope
Repository: `DOJOWALK/DOJO-WALK-Admin`  
Branch: `ui/notion-brand-foundation-2026-10-28`  
PR: #51 (Draft; no merge/deploy)  
Source file: `lib/screens/dashboard/admin_shell.dart`

## Change made
- Removed the standalone **Live Operations** item from the Admin sidebar menu.
- Preserved the Dashboard's **Open Live Operations** callback, which pushes the existing `LiveOperationsScreen` route.
- Removed the now-obsolete Live Operations menu destination from the shell's index switch.
- Re-numbered the remaining switch destinations to match the menu list.
- Updated the Dashboard **Add / Manage Locations** callback from index 13 to index 12, which is the Service Locations menu destination after removing Live Operations.

## Source-level verification
The latest inspected source shows the following menu order:
1. Dashboard
2. Bookings
3. Walker Management
4. Customers
5. Pets
6. Notifications
7. Support
8. Admin Users & Roles
9. Audit Logs
10. Reports & Analytics
11. Finance Operations
12. Settings
13. Service Locations

The switch maps indices 0–12 to those destinations in the same order. Dashboard's Live Operations action still opens `LiveOperationsScreen` through `MaterialPageRoute`.

## Validation status
- Source-level menu/switch inspection: **PASS** (verified after the update).
- Flutter formatter/analyzer/widget tests: **NOT RUN** in this task.
- GitHub Actions exact-head lookup for commit `87d959451ac268264311b9a78abd9bbfdcdb9e4`: no workflow runs were returned. This is **not a CI PASS**.
- No Firebase repository, Firestore schema/rules/functions, production data, or deployment was changed.

## Remaining validation
- Add behavioral AdminShell widget tests for sidebar destinations, Dashboard Live Operations navigation, Service Locations shortcut, and mobile drawer selection.
- Run `dart format --output=none --set-exit-if-changed`, `flutter analyze`, `flutter test`, and `flutter build web --release` on the exact final branch head.
- Keep PR #51 Draft and do not merge/deploy until owner approval.
