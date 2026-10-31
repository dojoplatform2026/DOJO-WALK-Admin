import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/screens/bookings/booking_status_helper.dart';

void main() {
  group('bookingFilterStatuses', () {
    test('includes every supported booking lifecycle filter', () {
      expect(
        bookingFilterStatuses,
        equals([
          'All',
          'Pending',
          'Finding Walker',
          'Walker Assigned',
          'Walker Arriving',
          'Walker Accepted',
          'Confirmed',
          'Picked Up',
          'Walk In Progress',
          'Completed',
          'Cancelled',
        ]),
      );
      for (final status in bookingFilterStatuses.skip(1)) {
        expect(
          displayBookingStatus(status),
          status,
          reason: 'Filter status "$status" must be a canonical lifecycle label',
        );
      }
    });
  });

  group('displayBookingStatus', () {
    test('normalizes underscore and hyphen lifecycle values', () {
      expect(displayBookingStatus('finding_walker'), 'Finding Walker');
      expect(displayBookingStatus('walker_arriving'), 'Walker Arriving');
      expect(displayBookingStatus('confirmed'), 'Confirmed');
      expect(displayBookingStatus('walker_assigned'), 'Walker Assigned');
      expect(displayBookingStatus('walker-accepted'), 'Walker Accepted');
      expect(displayBookingStatus('in_progress'), 'Walk In Progress');
      expect(displayBookingStatus('walk_started'), 'Walk In Progress');
      expect(displayBookingStatus('picked_up'), 'Picked Up');
      expect(displayBookingStatus('active-walk'), 'Walk In Progress');
      expect(displayBookingStatus('canceled'), 'Cancelled');
    });

    test('preserves unknown status values for investigation', () {
      expect(displayBookingStatus('needs_manual_review'), 'needs_manual_review');
      expect(displayBookingStatus(null), 'Unknown');
      expect(displayBookingStatus('  '), 'Unknown');
    });
  });
  group('bookingEmptyStateMessage', () {
    test('distinguishes empty data from filtered results', () {
      expect(
        bookingEmptyStateMessage(
          totalRecords: 0,
          search: '',
          selectedStatus: 'All',
        ),
        'No bookings found in Firestore.',
      );
      expect(
        bookingEmptyStateMessage(
          totalRecords: 8,
          search: '',
          selectedStatus: 'Completed',
        ),
        'No bookings with status "Completed".',
      );
      expect(
        bookingEmptyStateMessage(
          totalRecords: 8,
          search: 'zone-12',
          selectedStatus: 'All',
        ),
        'No bookings match your search.',
      );
      expect(
        bookingEmptyStateMessage(
          totalRecords: 8,
          search: 'zone-12',
          selectedStatus: 'Completed',
        ),
        'No bookings match your search and selected status.',
      );
    });
  });

  group('bookingStatusQueryAliases', () {
    test('every queried alias normalizes to its canonical lifecycle label', () {
      const expected = {
        'Pending': 'Pending',
        'Finding Walker': 'Finding Walker',
        'Walker Assigned': 'Walker Assigned',
        'Walker Arriving': 'Walker Arriving',
        'Picked Up': 'Picked Up',
        'Walker Accepted': 'Walker Accepted',
        'Confirmed': 'Confirmed',
        'Walk In Progress': 'Walk In Progress',
        'Completed': 'Completed',
        'Cancelled': 'Cancelled',
      };

      for (final entry in expected.entries) {
        for (final raw in bookingStatusQueryAliases(entry.key)) {
          expect(
            displayBookingStatus(raw),
            entry.value,
            reason: 'Raw status "$raw" must map to the canonical label',
          );
        }
      }
    });

    test('covers legacy capitalization and separators for canonical states', () {
      expect(
        bookingStatusQueryAliases('Pending'),
        containsAll(['pending', 'Pending']),
      );
      expect(
        bookingStatusQueryAliases('Walker Assigned'),
        containsAll(['assigned', 'walker_assigned', 'walker-assigned', 'walker assigned', 'Walker Assigned']),
      );
      expect(
        bookingStatusQueryAliases('Picked Up'),
        containsAll(['picked_up', 'picked-up', 'picked up', 'Picked Up', 'pickup_complete', 'pickup-complete']),
      );
      expect(
        bookingStatusQueryAliases('Walker Accepted'),
        containsAll(['accepted', 'walker_accepted', 'walker-accepted', 'walker accepted', 'Walker Accepted']),
      );
      expect(
        bookingStatusQueryAliases('Walk In Progress'),
        containsAll([
          'walking',
          'in_progress',
          'in-progress',
          'walk in progress',
          'Walk In Progress',
          'walk_started',
          'walk-started',
          'walk started',
          'active_walk',
          'active-walk',
          'active walk',
        ]),
      );
      expect(
        bookingStatusQueryAliases('Completed'),
        containsAll(['completed', 'Completed', 'complete', 'Complete']),
      );
      expect(bookingStatusQueryAliases('Unknown'), isEmpty);
    });
  });

}
