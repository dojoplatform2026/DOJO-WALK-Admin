import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_admin/screens/dashboard/dashboard_data_source.dart';

void main() {
  group('FirestoreDashboardDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreDashboardDataSource source;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      source = FirestoreDashboardDataSource(firestore);
    });

    test('countAll emits the number of documents in a collection', () async {
      await firestore.collection('walkers').doc('w1').set({'isOnline': true});
      await firestore.collection('walkers').doc('w2').set({'isOnline': false});

      expect(await source.countAll('walkers').first, 2);
    });

    test('countWhere applies the requested equality filter', () async {
      await firestore.collection('walkers').doc('w1').set({'isOnline': true});
      await firestore.collection('walkers').doc('w2').set({'isOnline': false});
      await firestore.collection('walkers').doc('w3').set({'isOnline': true});

      expect(await source.countWhere('walkers', 'isOnline', true).first, 2);
    });

    test('countBookingStatus includes the declared legacy aliases', () async {
      await firestore.collection('bookings').doc('b1').set({'status': 'pending'});
      await firestore.collection('bookings').doc('b2').set({'status': 'Pending'});
      await firestore.collection('bookings').doc('b3').set({'status': 'completed'});

      expect(await source.countBookingStatus('Pending').first, 2);
    });

    test('unknown booking status label emits zero without querying', () async {
      await firestore.collection('bookings').doc('b1').set({'status': 'pending'});

      expect(await source.countBookingStatus('Not A State').first, 0);
    });

    test('totalPaidAmount sums numeric amounts and skips non-numeric values', () async {
      final payments = firestore.collection('payments');
      await payments.doc('p1').set({'status': 'paid', 'amount': 100});
      await payments.doc('p2').set({'status': 'paid', 'amount': 25.5});
      await payments.doc('p3').set({'status': 'paid', 'amount': '40'});
      await payments.doc('p4').set({'status': 'paid'});
      await payments.doc('p5').set({'status': 'failed', 'amount': 900});

      expect(await source.totalPaidAmount().first, 125.5);
    });

    test('recentBookings returns at most eight newest records with normalized status', () async {
      final bookings = firestore.collection('bookings');
      for (var i = 0; i < 10; i++) {
        await bookings.doc('b$i').set({
          'createdAt': DateTime(2026, 10, 1 + i),
          'petId': 'pet-$i',
          'status': i.isEven ? 'completed' : 'walker_accepted',
        });
      }

      final result = await source.recentBookings().first;
      expect(result, hasLength(8));
      expect(result.first.id, 'b9');
      expect(result.first.status, 'Walker Accepted');
      expect(result.last.id, 'b2');
    });

    test('recentActivity maps missing fields to safe display defaults', () async {
      await firestore.collection('audit_logs').doc('a1').set({
        'createdAt': DateTime(2026, 10, 30),
      });

      final result = await source.recentActivity().first;
      expect(result, hasLength(1));
      expect(result.single.action, 'System activity');
      expect(result.single.actorRole, 'Admin');
    });

    test('recentActivity orders records by createdAt newest first', () async {
      final logs = firestore.collection('audit_logs');
      await logs.doc('older').set({
        'createdAt': DateTime(2026, 10, 29),
        'action': 'walker_approved',
      });
      await logs.doc('newer').set({
        'createdAt': DateTime(2026, 10, 30),
        'action': 'walker_reactivated',
      });

      final result = await source.recentActivity().first;
      expect(result, hasLength(2));
      expect(result.first.action, 'walker_reactivated');
      expect(result.last.action, 'walker_approved');
    });
  });
}
