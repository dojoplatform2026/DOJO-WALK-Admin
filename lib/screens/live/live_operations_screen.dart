import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/admin_error_classifier.dart';
import 'live_booking_details_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'live_map_widget.dart';

class LiveOperationsScreen extends StatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  State<LiveOperationsScreen> createState() =>
      _LiveOperationsScreenState();
}

class _LiveOperationsScreenState
    extends State<LiveOperationsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkerSubscription;

  final Map<String, Map<String, dynamic>> _walkers = {};

  String? _selectedWalkerId;
  bool _isLoadingWalkers = true;
  String? _walkerLoadError;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const LatLng _defaultLocation =
      LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _listenToWalkers();
  }

  @override
  void dispose() {
    _walkerSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // LIVE WALKER LISTENER
  // ============================================================

  void _listenToWalkers() {
    _walkerSubscription?.cancel();
    _walkerSubscription = _firestore
        .collection('walkers')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final updated = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        updated[doc.id] = {
          'id': doc.id,
          ...doc.data(),
        };
      }

      if (!mounted) return;

      setState(() {
        _isLoadingWalkers = false;
        _walkerLoadError = null;
        _walkers
          ..clear()
          ..addAll(updated);

        if (_selectedWalkerId != null &&
            !updated.containsKey(_selectedWalkerId)) {
          _selectedWalkerId = null;
          _polylines = {};
        }

        _buildMarkers();
      });
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('Live walker listener failed: $error');
      if (!mounted) return;
      final permissionDenied = isPermissionDeniedError(error);
      setState(() {
        _isLoadingWalkers = false;
        _walkerLoadError = permissionDenied
            ? 'Permission denied for live walker data. Ask an authorized administrator to review scope.'
            : 'Live walker data could not be refreshed. Check the connection and retry.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permissionDenied
                ? 'Permission denied for live walker data. Ask an authorized administrator to review scope.'
                : 'Unable to refresh live walkers. Check the connection; the listener will retry.',
          ),
        ),
      );
    });
  }

  void _retryLiveWalkers() {
    setState(() {
      _isLoadingWalkers = true;
      _walkerLoadError = null;
    });
    _listenToWalkers();
  }

  // ============================================================
  // BUILD WALKER MARKERS
  // ============================================================

  void _buildMarkers() {
    final markers = <Marker>{};

    for (final entry in _walkers.entries) {
      final walkerId = entry.key;
      final data = entry.value;

      final location =
          _readLocation(data['currentLocation']);

      if (location == null) {
        continue;
      }

      final name =
          data['name']?.toString() ?? 'Walker';

      final selected =
          walkerId == _selectedWalkerId;

      markers.add(
        Marker(
          markerId: MarkerId(
            'walker_$walkerId',
          ),
          position: location,
          infoWindow: InfoWindow(
            title: name,
            snippet: selected
                ? 'Selected Walker'
                : 'Online',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: () {
            _selectWalker(walkerId);
          },
        ),
      );
    }

    _markers = markers;
  }

  // ============================================================
  // LOCATION PARSER
  // ============================================================

  LatLng? _readLocation(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    if (value is Map) {
      final lat = value['latitude'];
      final lng = value['longitude'];

      if (lat is num && lng is num) {
        return LatLng(
          lat.toDouble(),
          lng.toDouble(),
        );
      }
    }

    return null;
  }

  // ============================================================
  // SELECT WALKER
  // ============================================================

  void _selectWalker(String walkerId) {
    setState(() {
      _selectedWalkerId = walkerId;
    });

    _loadWalkerRoute(walkerId);
  }

  // ============================================================
  // LOAD LIVE ROUTE
  // ============================================================

  Future<void> _loadWalkerRoute(
    String walkerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('walk_locations')
          .where(
            'walkerId',
            isEqualTo: walkerId,
          )
          .orderBy(
            'timestamp',
            descending: false,
          )
          .limit(300)
          .get();

      final points = <LatLng>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final lat = data['latitude'];
        final lng = data['longitude'];

        if (lat is num && lng is num) {
          points.add(
            LatLng(
              lat.toDouble(),
              lng.toDouble(),
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        if (points.length >= 2) {
          _polylines = {
            Polyline(
              polylineId:
                  const PolylineId('live_route'),
              points: points,
              width: 5,
              color: const Color(0xFFFF7900),
            ),
          };
        } else {
          _polylines = {};
        }
      });

      if (points.length < 2 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No route points are available for this walker yet.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Unable to load walker route: $e');
      if (!mounted) return;
      final permissionDenied = isPermissionDeniedError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permissionDenied
                ? 'Permission denied for this walker route.'
                : 'Unable to load walker route. Please retry.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SELECTED WALKER
  // ============================================================

  Map<String, dynamic>? get _selectedWalker {
    if (_selectedWalkerId == null) {
      return null;
    }

    return _walkers[_selectedWalkerId!];
  }

  Future<void> _showBookingDetails(String? bookingId) async {
    if (bookingId == null || bookingId.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active booking is linked to this walker.')),
      );
      return;
    }
    try {
      final booking = await _firestore.collection('bookings').doc(bookingId).get();
      if (!mounted) return;
      if (!booking.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking ' + bookingId + ' was not found.')),
        );
        return;
      }
      final data = booking.data() ?? <String, dynamic>{};
      final details = safeLiveBookingSummary(data);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Booking summary · $bookingId'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.isEmpty)
                  const Text('No approved operational summary fields are available.')
                else
                  for (final entry in details.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${entry.key}: ${entry.value}'),
                    ),
                const SizedBox(height: 8),
                const Text(
                  'Sensitive fields are intentionally omitted from this operational summary.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final permissionDenied = isPermissionDeniedError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permissionDenied
                ? 'Permission denied for booking details.'
                : 'Unable to load booking details. Please retry.',
          ),
        ),
      );
    }
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selected = _selectedWalker;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFFFAF5),
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================

          Positioned.fill(
            child: LiveMapWidget(
              markers: _markers,
              polylines: _polylines,
              initialLocation:
                  _defaultLocation,
            ),
          ),

          // ======================================================
          // TOP SEARCH / STATUS
          // ======================================================

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 15,
                        color: Colors.black
                            .withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color:
                            Color(0xFFFF7900),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingWalkers
                            ? 'Loading live walkers…'
                            : _walkerLoadError != null
                                ? 'Live data unavailable'
                                : '${_walkers.length} walkers online',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _walkerLoadError != null
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF292524),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_walkerLoadError != null)
            Positioned(
              top: 82,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFB91C1C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _walkerLoadError!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _retryLiveWalkers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ======================================================
          // SELECTED WALKER PANEL
          // ======================================================

          if (selected != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.48,
                ),
                child: SingleChildScrollView(
                  child: _WalkerDetailsCard(
                    data: selected,
                    onViewBooking: () => _showBookingDetails(
                      selected['currentBookingId']?.toString(),
                    ),
                    onViewRoute: () => _loadWalkerRoute(
                      selected['id']?.toString() ?? _selectedWalkerId!,
                    ),
                    onClose: () {
                      setState(() {
                        _selectedWalkerId = null;
                        _polylines = {};
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================================================================
// WALKER DETAILS CARD
// ==================================================================

class _WalkerDetailsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;
  final VoidCallback onViewBooking;
  final VoidCallback onViewRoute;

  const _WalkerDetailsCard({
    required this.data,
    required this.onClose,
    required this.onViewBooking,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        data['name']?.toString() ?? 'Walker';

    final status =
        data['status']?.toString() ?? 'online';

    final bookingId =
        data['currentBookingId']
            ?.toString();

    final rating =
        data['rating']?.toString() ?? '—';

    final isOnline =
        data['isOnline'] == true;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 25,
              offset: const Offset(0, -4),
              color: Colors.black.withValues(
                alpha: 0.15,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      const Color(0xFFFF7900),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.red,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            isOnline
                                ? 'LIVE'
                                : 'OFFLINE',
                            style:
                                TextStyle(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  icon: Icons.directions_walk,
                  label: status,
                ),
                _InfoChip(
                  icon: Icons.star,
                  label: rating,
                ),
                if (bookingId != null &&
                    bookingId.isNotEmpty)
                  _InfoChip(
                    icon: Icons.receipt_long,
                    label: bookingId,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewBooking,
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                    ),
                    label: const Text(
                      'VIEW BOOKING',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewRoute,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFFF7900,
                      ),
                      foregroundColor:
                          Colors.white,
                    ),
                    icon: const Icon(
                      Icons.route,
                    ),
                    label: const Text(
                      'VIEW ROUTE',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// INFO CHIP
// ==================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(
              0xFFFF7900,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
