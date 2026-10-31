import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/screens/live/live_booking_details_helper.dart';

void main() {
  test('includes only approved operational booking fields', () {
    final summary = safeLiveBookingSummary({
      'status': 'in_progress',
      'customerId': 'CUS-EX-001',
      'walkerId': 'WALKER-EX-001',
      'walkId': 'WALK-EX-001',
      'zoneId': 'ZONE-EX-001',
      'durationMinutes': 30,
      'pickupAddress': 'Sensitive address must not be displayed',
      'customerPhone': '+91 9999999999',
      'paymentToken': 'secret-token',
      'internalNotes': 'private notes',
    });

    expect(summary['Status'], 'in_progress');
    expect(summary['Customer ID'], 'CUS-EX-001');
    expect(summary['Walk ID'], 'WALK-EX-001');
    expect(summary['Duration (minutes)'], '30');
    expect(summary.containsKey('pickupAddress'), isFalse);
    expect(summary.values.any((value) => value.contains('9999999999')), isFalse);
    expect(summary.values.any((value) => value.contains('secret-token')), isFalse);
    expect(summary.values.any((value) => value.contains('private notes')), isFalse);
  });

  test('returns an empty summary when no approved fields exist', () {
    expect(safeLiveBookingSummary({'pickupAddress': 'private'}), isEmpty);
  });
}
