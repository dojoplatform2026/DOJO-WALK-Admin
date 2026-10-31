import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'service_location_geometry.dart';

/// Client-side feedback for a boundary drawing preview.
///
/// This is intentionally limited to basic polygon geometry. It does not
/// establish geographic accuracy, serviceability, GIS verification or approval.
class ServiceBoundaryPreviewValidator {
  ServiceBoundaryPreviewValidator._();

  static const validFeedback =
      'Basic polygon geometry looks valid locally. Not GIS-verified.';

  /// Validates raw coordinate values before any GeoPoint conversion.
  ///
  /// Kept public so coordinate bounds can be unit-tested independently from
  /// Google Maps LatLng construction/normalization behavior.
  static bool isCoordinateInRange({
    required double latitude,
    required double longitude,
  }) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static String feedback(List<LatLng> points) {
    if (points.length < 3) {
      return 'Add at least 3 points (${points.length}/3).';
    }

    if (!points.every((point) => isCoordinateInRange(
          latitude: point.latitude,
          longitude: point.longitude,
        ))) {
      return 'Invalid preview: one or more coordinates are out of range.';
    }

    final distinctPoints = points
        .map((point) => '${point.latitude.toStringAsFixed(7)},'
            '${point.longitude.toStringAsFixed(7)}')
        .toSet();
    if (distinctPoints.length < 3) {
      return 'Invalid preview: at least 3 distinct points are required.';
    }

    final geoPoints = points
        .map((point) => GeoPoint(point.latitude, point.longitude))
        .toList(growable: false);
    if (!ServiceLocationGeometry.isValidPolygon(geoPoints)) {
      return 'Invalid preview: polygon crosses itself or encloses no area.';
    }

    return validFeedback;
  }

  static bool isValid(List<LatLng> points) =>
      feedback(points) == validFeedback;
}
