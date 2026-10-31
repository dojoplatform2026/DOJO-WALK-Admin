import 'package:dojo_admin/screens/dashboard/admin_shell.dart';
import 'package:dojo_admin/screens/dashboard/dashboard_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ShellDashboardDataSource implements DashboardDataSource {
  @override
  Stream<int> countAll(String collection) => Stream<int>.value(0);

  @override
  Stream<int> countWhere(String collection, String field, dynamic value) =>
      Stream<int>.value(0);

  @override
  Stream<int> countBookingStatus(String canonicalLabel) =>
      Stream<int>.value(0);

  @override
  Stream<double> totalPaidAmount() => Stream<double>.value(0);

  @override
  Stream<List<DashboardBooking>> recentBookings() =>
      Stream<List<DashboardBooking>>.value(const []);

  @override
  Stream<List<DashboardActivity>> recentActivity() =>
      Stream<List<DashboardActivity>>.value(const []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setViewport(
    WidgetTester tester,
    Size size, {
    Widget Function(int index)? contentBuilder,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminShell(
          dashboardDataSource: _ShellDashboardDataSource(),
          contentBuilder: contentBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    // Reset the simulated device dimensions between widget tests.
  });

  group('AdminShell navigation', () {
    testWidgets('desktop sidebar omits duplicate Live Operations destination',
        (tester) async {
      await setViewport(tester, const Size(1440, 1000));

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Service Locations'), findsOneWidget);
      expect(
        find.text('Live Operations'),
        findsOneWidget,
        reason: 'Only the Dashboard card heading should be present; the sidebar must not duplicate this destination.',
      );
      expect(find.byTooltip('Logout'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('all sidebar destinations can be selected without Firebase',
        (tester) async {
      const titles = [
        'Dashboard',
        'Bookings',
        'Walker Management',
        'Customers',
        'Pets',
        'Notifications',
        'Support',
        'Admin Users & Roles',
        'Audit Logs',
        'Reports & Analytics',
        'Finance Operations',
        'Settings',
        'Service Locations',
      ];

      await setViewport(
        tester,
        const Size(1440, 1000),
        contentBuilder: (index) => Center(
          child: Text('Test destination $index'),
        ),
      );

      for (var index = 0; index < titles.length; index++) {
        final destination = find.text(titles[index]).first;
        await tester.ensureVisible(destination);
        await tester.tap(destination);
        await tester.pumpAndSettle();

        expect(find.text('Test destination $index'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('mobile drawer navigates to Settings and closes',
        (tester) async {
      await setViewport(tester, const Size(390, 844));

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('DOJO WALK'), findsOneWidget);
      await tester.ensureVisible(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings & Governance'), findsOneWidget);
      expect(find.text('System Settings'), findsOneWidget);
      expect(find.text('DOJO WALK'), findsNothing,
          reason: 'The navigation drawer should close after selection.');
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('logout confirmation can be cancelled safely',
        (tester) async {
      await setViewport(tester, const Size(1440, 1000));

      await tester.tap(find.byTooltip('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of DOJO WALK Admin?'),
          findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of DOJO WALK Admin?'),
          findsNothing);
      expect(find.text('DOJO WALK Command Center'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
