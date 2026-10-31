/// User-facing status for the Service Locations map boundary preview.
///
/// A missing Zone-specific source must not be represented as zero active Zones.
String boundaryPreviewStatusLabel({
  required bool isLoading,
  required bool hasError,
  required int polygonCount,
}) {
  if (isLoading) return 'Loading boundary preview…';
  if (hasError) return 'Boundary source unavailable';
  if (polygonCount == 0) return 'Zone boundary source not connected';
  return 'Active boundaries: $polygonCount';
}
