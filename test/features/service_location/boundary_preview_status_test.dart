import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/utils/boundary_preview_status.dart';

void main() {
  group('boundaryPreviewStatusLabel', () {
    test('shows loading state while the source is loading', () {
      expect(
        boundaryPreviewStatusLabel(
          isLoading: true,
          hasError: false,
          polygonCount: 0,
        ),
        'Loading boundary preview…',
      );
    });

    test('shows an error state when the source fails', () {
      expect(
        boundaryPreviewStatusLabel(
          isLoading: false,
          hasError: true,
          polygonCount: 0,
        ),
        'Boundary source unavailable',
      );
    });

    test('does not misrepresent an unconnected source as zero active Zones', () {
      expect(
        boundaryPreviewStatusLabel(
          isLoading: false,
          hasError: false,
          polygonCount: 0,
        ),
        'Zone boundary source not connected',
      );
    });

    test('shows a count only when polygons are actually present', () {
      expect(
        boundaryPreviewStatusLabel(
          isLoading: false,
          hasError: false,
          polygonCount: 3,
        ),
        'Active boundaries: 3',
      );
    });
  });
}
