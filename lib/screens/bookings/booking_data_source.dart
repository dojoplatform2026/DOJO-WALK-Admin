import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only booking record exposed to the Admin UI.
class BookingRecord {
  final String id;
  final Map<String, dynamic> data;

  const BookingRecord({required this.id, required this.data});
}

/// Small contract that keeps the booking screen testable without Firebase.
abstract class BookingsDataSource {
  Stream<List<BookingRecord>> watchBookings();
}

/// Production adapter. It preserves the existing collection and query shape.
class FirestoreBookingsDataSource implements BookingsDataSource {
  final FirebaseFirestore firestore;

  const FirestoreBookingsDataSource(this.firestore);

  @override
  Stream<List<BookingRecord>> watchBookings() {
    return firestore.collection('bookings').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingRecord(id: doc.id, data: doc.data()))
              .toList(growable: false),
        );
  }
}
