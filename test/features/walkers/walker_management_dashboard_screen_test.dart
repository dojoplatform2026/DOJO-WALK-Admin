import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/walkers/models/walker_admin_model.dart';
import 'package:dojo_admin/features/walkers/screens/walker_management_dashboard_screen.dart';

WalkerAdminModel _walker({
  required String uid,
  required String name,
  String phone = '9876543210',
  String email = 'walker@example.com',
  String status = 'approved',
  String verificationStatus = 'verified',
  bool isApproved = true,
  bool isActive = true,
  bool applicationSubmitted = false,
  String area = 'Crossings Republik',
}) {
  final data = <String, dynamic>{
    'name': name,
    'phoneNumber': phone,
    'email': email,
    'status': status,
    'verificationStatus': verificationStatus,
    'isApproved': isApproved,
    'isActive': isActive,
    'applicationSubmitted': applicationSubmitted,
    'area': area,
    'city': 'Ghaziabad',
    'state': 'Uttar Pradesh',
  };
  return WalkerAdminModel.fromMap(uid: uid, data: data);
}

Widget _screen({
  required List<WalkerAdminModel> walkers,
  Set<String> runningIds = const <String>{},
}) {
  return MaterialApp(
    home: WalkerManagementDashboardScreen(
      walkersStream: Stream<List<WalkerAdminModel>>.value(walkers),
      runningWalkerIdsStream: Stream<Set<String>>.value(runningIds),
    ),
  );
}

void main() {
  group('WalkerManagementDashboardScreen', () {
    testWidgets('renders walker cards and filtered count', (tester) async {
      await tester.pumpWidget(_screen(
        walkers: [
          _walker(uid: 'w-2', name: 'Zoya Walker'),
          _walker(uid: 'w-1', name: 'Aman Walker'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Walker Management'), findsOneWidget);
      expect(find.text('Aman Walker'), findsOneWidget);
      expect(find.text('Zoya Walker'), findsOneWidget);
      expect(find.text('2 walkers'), findsOneWidget);
    });

    testWidgets('search matches email and location fields', (tester) async {
      await tester.pumpWidget(_screen(
        walkers: [
          _walker(uid: 'w-1', name: 'Aman Walker', email: 'aman@example.com', area: 'Indirapuram'),
          _walker(uid: 'w-2', name: 'Riya Walker', area: 'Crossings Republik'),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'aman@example.com');
      await tester.pumpAndSettle();
      expect(find.text('Aman Walker'), findsOneWidget);
      expect(find.text('Riya Walker'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Crossings Republik');
      await tester.pumpAndSettle();
      expect(find.text('Riya Walker'), findsOneWidget);
      expect(find.text('Aman Walker'), findsNothing);
    });

    testWidgets('running tab includes only walker IDs in running set',
        (tester) async {
      await tester.pumpWidget(_screen(
        walkers: [
          _walker(uid: 'w-1', name: 'Aman Walker'),
          _walker(uid: 'w-2', name: 'Riya Walker'),
        ],
        runningIds: const {'w-2'},
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Running'));
      await tester.tap(find.text('Running'));
      await tester.pumpAndSettle();

      expect(find.text('Riya Walker'), findsOneWidget);
      expect(find.text('Aman Walker'), findsNothing);
      expect(find.text('1 walkers'), findsOneWidget);
    });

    testWidgets('available tab excludes running and ineligible accounts',
        (tester) async {
      await tester.pumpWidget(_screen(
        walkers: [
          _walker(uid: 'w-1', name: 'Available Walker'),
          _walker(uid: 'w-2', name: 'Running Walker'),
          _walker(uid: 'w-3', name: 'Inactive Walker', isActive: false),
        ],
        runningIds: const {'w-2'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Available Walker'), findsOneWidget);
      expect(find.text('Running Walker'), findsNothing);
      expect(find.text('Inactive Walker'), findsNothing);
    });

    testWidgets('verification and training tabs remain distinct', (tester) async {
      await tester.pumpWidget(_screen(
        walkers: [
          _walker(
            uid: 'w-review',
            name: 'Review Walker',
            status: 'under_review',
            verificationStatus: 'pending',
            isApproved: false,
            isActive: false,
            applicationSubmitted: true,
          ),
          _walker(
            uid: 'w-training',
            name: 'Training Walker',
            status: 'training_required',
            verificationStatus: 'pending',
            isApproved: false,
            isActive: false,
            applicationSubmitted: true,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Verification'));
      await tester.tap(find.text('Verification'));
      await tester.pumpAndSettle();
      expect(find.text('Review Walker'), findsOneWidget);
      expect(find.text('Training Walker'), findsNothing);

      await tester.ensureVisible(find.text('Training Required'));
      await tester.tap(find.text('Training Required'));
      await tester.pumpAndSettle();
      expect(find.text('Training Walker'), findsOneWidget);
      expect(find.text('Review Walker'), findsNothing);
    });

    testWidgets('shows no-results state when search has no match',
        (tester) async {
      await tester.pumpWidget(_screen(
        walkers: [_walker(uid: 'w-1', name: 'Aman Walker')],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'not-a-real-walker');
      await tester.pumpAndSettle();

      expect(find.text('No walkers match your search'), findsOneWidget);
    });

    testWidgets('shows loading while walker stream is pending',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WalkerManagementDashboardScreen(
          walkersStream: Stream<List<WalkerAdminModel>>.multi((_) {}),
          runningWalkerIdsStream: Stream<Set<String>>.multi((_) {}),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows retry action after walker stream error',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WalkerManagementDashboardScreen(
          walkersStream: Stream<List<WalkerAdminModel>>.error(
            Exception('network unavailable'),
          ),
          runningWalkerIdsStream: Stream<Set<String>>.value(const {}),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Walker data load नहीं हुआ'), findsOneWidget);
      expect(find.byKey(const ValueKey('walker-management-retry')),
          findsOneWidget);
    });

    testWidgets('does not overflow at mobile tablet and desktop widths',
        (tester) async {
      for (final width in [320.0, 360.0, 390.0, 768.0, 1280.0]) {
        await tester.binding.setSurfaceSize(Size(width, 1200));
        await tester.pumpWidget(_screen(
          walkers: [
            _walker(
              uid: 'w-1',
              name: 'A very long walker display name for responsive layout',
              area: 'A very long location name for narrow screens',
            ),
          ],
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'width: $width');
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}
