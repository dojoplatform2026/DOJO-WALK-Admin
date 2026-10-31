import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveMapWidget extends StatelessWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final LatLng initialLocation;

  const LiveMapWidget({
    super.key,
    required this.markers,
    required this.polylines,
    this.polygons = const <Polygon>{},
    required this.initialLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 12,
      ),

      // Online walker markers
      markers: markers,

      // Walker routes
      polylines: polylines,

      // Service zone boundaries
      polygons: polygons,

      // Admin device location is not required for live walker monitoring.
      // Keep device-location access disabled to avoid unnecessary permission
      // prompts and to prevent showing the admin's own location on this map.
      myLocationEnabled: false,
      myLocationButtonEnabled: false,

      // Map controls
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,

      mapType: MapType.normal,
    );
  }
}
