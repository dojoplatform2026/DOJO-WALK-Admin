import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dojo_admin/features/service_location/services/service_boundary_preview_validator.dart';

void main() {
  group('ServiceBoundaryPreviewValidator coordinate bounds', () {
    test('rejects latitude outside the geographic range', () {
      expect(
        ServiceBoundaryPreviewValidator.isCoordinateInRange(
          latitude: 91,
          longitude: 1,
        ),
        isFalse,
      );
    });

    test('rejects longitude outside the geographic range', () {
      expect(
        ServiceBoundaryPreviewValidator.isCoordinateInRange(
          latitude: 1,
          longitude: 181,
        ),
        isFalse,
      );
    });

    test('rejects non-finite coordinate values', () {
      expect(
        ServiceBoundaryPreviewValidator.isCoordinateInRange(
          latitude: double.infinity,
          longitude: 1,
        ),
        isFalse,
      );
      expect(
        ServiceBoundaryPreviewValidator.isCoordinateInRange(
          latitude: 1,
          longitude: double.nan,
        ),
        isFalse,
      );
    });

    test('accepts geographic boundary values', () {
      expect(
        ServiceBoundaryPreviewValidator.isCoordinateInRange(
          latitude: 90,
          longitude: 180,
        ),
        isTrue,
      );
      expect(
        ServiceBoundaryPreviewValidator.isCoordinateInRange(
          latitude: -90,
          longitude: -180,
        ),
        isTrue,
      );
    });
  });

  group('ServiceBoundaryPreviewValidator.feedback', () {
    test('asks for three points when preview is empty', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const []),
        'Add at least 3 points (0/3).',
      );
    });

    test('rejects fewer than three points', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 2),
        ]),
        'Add at least 3 points (2/3).',
      );
    });

    test('rejects repeated vertices', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 0),
          LatLng(2, 2),
        ]),
        'Invalid preview: at least 3 distinct points are required.',
      );
    });

    test('rejects a self-intersecting polygon', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(2, 2),
          LatLng(0, 2),
          LatLng(2, 0),
        ]),
        'Invalid preview: polygon crosses itself or encloses no area.',
      );
    });

    test('rejects a collinear polygon with no enclosed area', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 1),
          LatLng(0, 2),
        ]),
        'Invalid preview: polygon crosses itself or encloses no area.',
      );
    });

    test('accepts basic geometry but explicitly denies GIS verification', () {
      const polygon = [
        LatLng(0, 0),
        LatLng(0, 2),
        LatLng(2, 2),
        LatLng(2, 0),
      ];
      expect(
        ServiceBoundaryPreviewValidator.feedback(polygon),
        ServiceBoundaryPreviewValidator.validFeedback,
      );
      expect(ServiceBoundaryPreviewValidator.isValid(polygon), isTrue);
    });
  });
}
