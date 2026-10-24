import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/data/admin_boundary_review_repository.dart';

void main() {
  group('AdminBoundaryReviewItem.fromMap', () {
    test('parses GeoPoint coordinates', () {
      final item = AdminBoundaryReviewItem.fromMap('boundary-1', {
        'locationId': 'city-1',
        'locationType': 'City',
        'points': [const GeoPoint(28.6139, 77.2090)],
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 24)),
      });

      expect(item.locationId, 'city-1');
      expect(item.locationType, 'city');
      expect(item.points, ['28.613900, 77.209000']);
      expect(item.updatedAt.toUtc(), DateTime.utc(2026, 10, 24));
    });

    test('parses latitude/longitude maps', () {
      final item = AdminBoundaryReviewItem.fromMap('boundary-2', {
        'locationId': 'area-1',
        'locationType': 'area',
        'points': [
          {'latitude': 28.6, 'longitude': 77.2},
        ],
      });

      expect(item.points, ['28.600000, 77.200000']);
    });

    test('parses legacy lat/lng maps', () {
      final item = AdminBoundaryReviewItem.fromMap('boundary-3', {
        'locationId': 'area-2',
        'locationType': 'area',
        'points': [
          {'lat': 28.6, 'lng': 77.2},
        ],
      });

      expect(item.points, ['28.600000, 77.200000']);
    });

    test('ignores malformed and out-of-range coordinates; defaults timestamp', () {
      final item = AdminBoundaryReviewItem.fromMap('boundary-4', {
        'locationId': 'city-2',
        'locationType': 'city',
        'points': [
          {'latitude': 'not-a-number', 'longitude': 77.2},
          {'lat': 91, 'lng': 181},
          {'lat': double.infinity, 'lng': 77.2},
          'unexpected',
        ],
      });

      expect(item.points, isEmpty);
      expect(item.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
