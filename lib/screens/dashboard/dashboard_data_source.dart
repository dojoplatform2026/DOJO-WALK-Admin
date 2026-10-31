import 'package:cloud_firestore/cloud_firestore.dart';

import '../bookings/booking_status_helper.dart';

/// Small read-only contract for the Admin dashboard.
///
/// The UI depends on this contract rather than opening Firestore queries
/// directly. Tests can provide deterministic streams without initializing
/// or connecting to Firebase.
abstract class DashboardDataSource {
  Stream<int> countAll(String collection);

  Stream<int> countWhere(
    String collection,
    String field,
    dynamic value,
  );

  Stream<int> countBookingStatus(String canonicalLabel);

  Stream<double> totalPaidAmount();

  Stream<List<DashboardBooking>> recentBookings();

  Stream<List<DashboardActivity>> recentActivity();
}

class DashboardBooking {
  final String id;
  final String petId;
  final String status;

  const DashboardBooking({
    required this.id,
    required this.petId,
    required this.status,
  });
}

class DashboardActivity {
  final String action;
  final String actorRole;

  const DashboardActivity({
    required this.action,
    required this.actorRole,
  });
}

/// Production implementation. Query shapes and collection names intentionally
/// match the existing dashboard behavior; this is an extraction, not a
/// Firestore contract migration.
class FirestoreDashboardDataSource implements DashboardDataSource {
  final FirebaseFirestore firestore;

  const FirestoreDashboardDataSource(this.firestore);

  @override
  Stream<int> countAll(String collection) {
    return firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<int> countWhere(
    String collection,
    String field,
    dynamic value,
  ) {
    return firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<int> countBookingStatus(String canonicalLabel) {
    final aliases = bookingStatusQueryAliases(canonicalLabel);
    if (aliases.isEmpty) return Stream<int>.value(0);

    return firestore
        .collection('bookings')
        .where('status', whereIn: aliases)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<double> totalPaidAmount() {
    return firestore
        .collection('payments')
        .where('status', isEqualTo: 'paid')
        .snapshots()
        .map((snapshot) {
      var total = 0.0;
      for (final doc in snapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount is num) total += amount.toDouble();
      }
      return total;
    });
  }

  @override
  Stream<List<DashboardBooking>> recentBookings() {
    return firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(8)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return DashboardBooking(
                id: doc.id,
                petId: data['petId']?.toString() ?? '',
                status: displayBookingStatus(data['status'] ?? 'Pending'),
              );
            }).toList(growable: false));
  }

  @override
  Stream<List<DashboardActivity>> recentActivity() {
    return firestore
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return DashboardActivity(
                action: data['action']?.toString() ?? 'System activity',
                actorRole: data['actorRole']?.toString() ?? 'Admin',
              );
            }).toList(growable: false));
  }
}
