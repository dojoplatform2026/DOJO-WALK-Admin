import 'package:dojo_admin/screens/dashboard/dashboard_data_source.dart';
import 'package:dojo_admin/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardDataSource implements DashboardDataSource {
  final bool empty;
  final bool failRecentBookings;
  final bool failRecentActivity;
  final bool failCounts;
  final bool failRevenue;
  final bool permissionDenied;
  final bool holdLoading;
  final bool longText;
  int subscriptionCount = 0;

  _FakeDashboardDataSource({
    this.empty = false,
    this.failRecentBookings = false,
    this.failRecentActivity = false,
    this.failCounts = false,
    this.failRevenue = false,
    this.permissionDenied = false,
    this.holdLoading = false,
    this.longText = false,
  });
  @override
  Stream<int> countAll(String collection) {
    subscriptionCount++;
    if (holdLoading) return _pending<int>();
    if (failCounts) return _countFailure();
    return Stream<int>.value(
        switch (collection) {
          'bookings' => 12,
          'users' => 8,
          'walkers' => 5,
          _ => 0,
        },
      );
  }

  @override
  Stream<int> countWhere(String collection, String field, dynamic value) =>
      holdLoading ? _pending<int>() : failCounts ? _countFailure() : Stream<int>.value(2);

  @override
  Stream<int> countBookingStatus(String canonicalLabel) => holdLoading
      ? _pending<int>()
      : failCounts
      ? _countFailure()
      : Stream<int>.value(
        switch (canonicalLabel) {
          'Pending' => 3,
          'Completed' => 4,
          'Walk In Progress' => 1,
          _ => 0,
        },
      );

  @override
  Stream<double> totalPaidAmount() => holdLoading
      ? _pending<double>()
      : failRevenue
      ? Stream<double>.error(_failure)
      : Stream<double>.value(1499);

  Object get _failure => permissionDenied
      ? StateError('cloud_firestore permission-denied')
      : StateError('temporary query failure');

  Stream<int> _countFailure() => Stream<int>.error(_failure);

  Stream<T> _pending<T>() => Stream<T>.multi((_) {});

  @override
  Stream<List<DashboardBooking>> recentBookings() {
    if (holdLoading) return _pending<List<DashboardBooking>>();
    if (failRecentBookings) {
      return Stream<List<DashboardBooking>>.error(Exception('test stream failure'));
    }
    return Stream<List<DashboardBooking>>.value(empty ? const [] : [
        DashboardBooking(
          id: longText ? 'booking-with-a-very-long-reference-identifier-2026' : 'booking-001',
          petId: longText ? 'pet-reference-with-a-very-long-display-value' : 'pet-001',
          status: longText ? 'Walker Accepted - Awaiting Customer Confirmation' : 'Completed',
        ),
      ]);
  }

  @override
  Stream<List<DashboardActivity>> recentActivity() {
    if (holdLoading) return _pending<List<DashboardActivity>>();
    if (failRecentActivity) {
      return Stream<List<DashboardActivity>>.error(Exception('activity failure'));
    }
    return Stream<List<DashboardActivity>>.value(empty ? const [] : [
        DashboardActivity(
          action: longText ? 'A very long audit action description to verify responsive wrapping on small devices' : 'Created booking',
          actorRole: longText ? 'Central Administrator with extended operational role' : 'Central Admin',
        ),
      ]);
  }
}

void main() {
  group('DashboardScreen', () {
    testWidgets('renders dashboard sections from injected streams',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DOJO WALK Command Center'), findsOneWidget);
      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Walkers'), findsOneWidget);
      expect(find.text('Paid Payments (All Time)'), findsOneWidget);
      expect(find.text('Gross paid amount; refunds and fees not deducted'), findsOneWidget);
      expect(find.text('₹1499'), findsOneWidget,
          reason: 'Dashboard must display the injected paid amount, not a fabricated KPI');
      expect(find.text('Live Operations'), findsOneWidget);
      expect(find.text('Booking Status'), findsOneWidget);
      expect(find.text('Recent Bookings'), findsOneWidget);
      expect(find.text('Booking #booking-001'), findsOneWidget);
      expect(find.text('Operations Alerts'), findsOneWidget);
      expect(find.text('System Activity'), findsOneWidget);
      expect(find.text('Created booking'), findsOneWidget);
      expect(find.text('Performed by Central Admin'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows explicit empty states when streams return no records',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(empty: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No bookings yet.'), findsOneWidget);
      expect(find.text('No audit activity available yet.'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows an error instead of an empty booking state on failure',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(failRecentBookings: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load recent bookings.'), findsOneWidget);
      expect(find.text('No bookings yet.'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows an activity error when the audit stream fails',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(failRecentActivity: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load activity.'), findsOneWidget);
      expect(find.text('No audit activity available yet.'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });


    testWidgets('keeps dashboard sections in loading state until streams emit',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(holdLoading: true),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('No bookings yet.'), findsNothing);
      expect(find.text('No audit activity available yet.'), findsNothing);
      expect(find.text('0'), findsNothing);
      expect(find.text('Access denied'), findsNothing);
      expect(find.text('Unable to load'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows visible permission errors for metrics, live counts, statuses and alerts',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(
                failCounts: true,
                failRevenue: true,
                permissionDenied: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access denied'), findsWidgets);
      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('Paid Payments (All Time)'), findsOneWidget);
      expect(find.text('Online Walkers'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Unassigned bookings'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows general query errors without displaying false zero counts',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(
                failCounts: true,
                failRevenue: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load'), findsWidgets);
      expect(find.text('0'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('refresh action resubscribes to dashboard data streams',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      final source = _FakeDashboardDataSource();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(dataSource: source),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialSubscriptions = source.subscriptionCount;
      expect(initialSubscriptions, 3);

      await tester.tap(find.byKey(const ValueKey('dashboard-refresh')));
      await tester.pumpAndSettle();

      expect(source.subscriptionCount, greaterThan(initialSubscriptions));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });


    testWidgets('dashboard renders without layout overflow on mobile tablet and desktop',
        (tester) async {
      final source = _FakeDashboardDataSource();
      for (final width in [320.0, 360.0, 768.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardScreen(dataSource: source),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DOJO WALK Command Center'), findsOneWidget);
        expect(find.byKey(const ValueKey('dashboard-refresh')), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Dashboard should not overflow at width $width');

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets('long booking and activity text does not overflow on narrow mobile', (tester) async {
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: DashboardScreen(dataSource: _FakeDashboardDataSource(longText: true)))));
      await tester.pumpAndSettle();
      expect(find.textContaining('booking-with-a-very-long-reference'), findsOneWidget);
      expect(find.textContaining('A very long audit action description'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Long dashboard content should not overflow at 320 px');
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('header actions call the supplied navigation callbacks',
        (tester) async {
      var liveOperationsOpened = false;
      var serviceLocationsOpened = false;

      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(),
              onOpenLiveOperations: () => liveOperationsOpened = true,
              onOpenServiceLocations: () => serviceLocationsOpened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Live Operations'));
      await tester.tap(find.text('Add / Manage Locations'));

      expect(liveOperationsOpened, isTrue);
      expect(serviceLocationsOpened, isTrue);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('recent bookings failure does not hide healthy activity', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(failRecentBookings: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Activity'), findsOneWidget);
      expect(find.text('Created booking'), findsOneWidget);
      expect(find.text('Recent Bookings'), findsOneWidget);
      expect(find.text('Created booking'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('activity failure does not hide healthy recent bookings', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(failRecentActivity: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Bookings'), findsOneWidget);
      expect(find.text('Booking #booking-001'), findsOneWidget);
      expect(find.text('System Activity'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('revenue failure does not hide healthy dashboard counts', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(failRevenue: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Walkers'), findsOneWidget);
      expect(find.text('Paid Payments (All Time)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    test('dashboard greeting respects all time boundaries', () {
      expect(
        dashboardGreetingFor(DateTime(2026, 10, 30, 11, 59)),
        'Good morning, Admin 👋',
      );
      expect(
        dashboardGreetingFor(DateTime(2026, 10, 30, 12, 0)),
        'Good afternoon, Admin 👋',
      );
      expect(
        dashboardGreetingFor(DateTime(2026, 10, 30, 16, 59)),
        'Good afternoon, Admin 👋',
      );
      expect(
        dashboardGreetingFor(DateTime(2026, 10, 30, 17, 0)),
        'Good evening, Admin 👋',
      );
    });

    testWidgets('uses injected clock for the dashboard date', (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(),
              clock: () => DateTime(2026, 10, 30, 17, 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good evening, Admin 👋'), findsOneWidget);
      expect(find.text('Friday, 30 October 2026'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
