import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/screens/bookings/booking_data_source.dart';
import 'package:dojo_admin/screens/bookings/bookings_screen.dart';

class _FakeBookingsDataSource implements BookingsDataSource {
  _FakeBookingsDataSource(this.stream);

  final Stream<List<BookingRecord>> stream;

  @override
  Stream<List<BookingRecord>> watchBookings() => stream;
}

Widget _screen(BookingsDataSource source) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 800,
        child: BookingsScreen(dataSource: source),
      ),
    ),
  );
}

void main() {
  testWidgets('shows loading while the booking stream is waiting',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await controller.close();
  });

  testWidgets('renders booking data and canonical lifecycle status',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(
        id: 'DW-1001',
        data: {
          'status': 'picked_up',
          'customerName': 'Asha',
          'walkerName': 'Ravi',
          'createdAt': '2026-10-31T08:00:00Z',
          'walkDateTime': '2026-10-31T09:00:00Z',
          'amount': 149,
        },
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Booking DW-1001'), findsOneWidget);
    expect(find.text('Picked Up'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('₹149'), findsOneWidget);
    await controller.close();
  });

  testWidgets('shows empty Firestore state when stream has no records',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const []);
    await tester.pump();
    await tester.pump();

    expect(find.text('No bookings found in Firestore.'), findsOneWidget);
    await controller.close();
  });

  testWidgets('shows permission denied state without mutating data',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Permission denied'), findsOneWidget);
    await controller.close();
  });

  testWidgets('search filters by booking ID and customer name', (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(id: 'DW-1001', data: {'status': 'pending', 'customerName': 'Asha'}),
      BookingRecord(id: 'DW-1002', data: {'status': 'completed', 'customerName': 'Rohan'}),
    ]);
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'asha');
    await tester.pump();

    expect(find.text('Booking DW-1001'), findsOneWidget);
    expect(find.text('Booking DW-1002'), findsNothing);
    await controller.close();
  });

  testWidgets('booking list does not overflow at a 320px viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(
        id: 'DW-VERY-LONG-BOOKING-REFERENCE-001',
        data: {
          'status': 'walk_in_progress',
          'customerName': 'A customer with a very long display name',
          'walkerName': 'A walker with a very long display name',
          'createdAt': '2026-10-31T08:00:00Z',
          'walkDateTime': '2026-10-31T09:00:00Z',
          'amount': 149,
        },
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await controller.close();
  });

  testWidgets('renders the Customer App booking document field contract',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(
        id: 'DW-CUSTOMER-001',
        data: {
          'customerId': 'customer-uid-001',
          'petName': 'Bruno',
          'petDetails': {'name': 'Bruno', 'breed': 'Labrador'},
          'serviceName': 'One-Time Walk',
          'bookingPlan': 'one_time',
          'scheduledAt': '2026-11-01T04:30:00Z',
          'preferredTime': '10:00 AM',
          'duration': '30 minutes',
          'status': 'pending',
          'walkerId': null,
          'createdAt': '2026-10-31T08:00:00Z',
        },
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('One-Time Walk'), findsOneWidget);
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('Not finalized'), findsOneWidget);
    expect(find.text('customer-uid-001'), findsOneWidget);
    await controller.close();
  });

  testWidgets('shows customer cancellation request state and requester',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(
        id: 'DW-CANCEL-001',
        data: {
          'status': 'pending',
          'customerId': 'customer-uid-001',
          'cancelRequest': {
            'status': 'pending',
            'requestedBy': 'customer',
          },
        },
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Cancellation'), findsOneWidget);
    expect(find.textContaining('pending • customer'), findsOneWidget);
    await controller.close();
  });

  testWidgets('search can find a booking by pet name', (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(
        id: 'DW-PET-001',
        data: {'status': 'pending', 'petName': 'Bruno'},
      ),
      BookingRecord(
        id: 'DW-PET-002',
        data: {'status': 'pending', 'petName': 'Milo'},
      ),
    ]);
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'bruno');
    await tester.pump();

    expect(find.text('Booking DW-PET-001'), findsOneWidget);
    expect(find.text('Booking DW-PET-002'), findsNothing);
    await controller.close();
  });
  testWidgets('shows approved and rejected cancellation request outcomes',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const [
      BookingRecord(
        id: 'DW-CANCEL-APPROVED',
        data: {
          'status': 'pending',
          'cancelRequest': {
            'status': 'approved',
            'requestedBy': 'customer',
            'requestedAt': '2026-10-31T08:00:00Z',
          },
        },
      ),
      BookingRecord(
        id: 'DW-CANCEL-REJECTED',
        data: {
          'status': 'pending',
          'cancelRequest': {
            'status': 'rejected',
            'requestedBy': 'customer',
          },
        },
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('approved • customer'), findsOneWidget);
    expect(find.textContaining('31/10/2026 13:30 IST'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.textContaining('rejected • customer'), findsOneWidget);
    await controller.close();
  });

}
