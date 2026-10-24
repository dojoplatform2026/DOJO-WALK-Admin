import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/admin_boundary_review_repository.dart';

class BoundaryReviewScreen extends StatefulWidget {
  const BoundaryReviewScreen({super.key});

  @override
  State<BoundaryReviewScreen> createState() => _BoundaryReviewScreenState();
}

class _BoundaryReviewScreenState extends State<BoundaryReviewScreen> {
  final _repository = AdminBoundaryReviewRepository();
  final Set<String> _reviewing = <String>{};

  Future<void> _review(AdminBoundaryReviewItem item, {required bool approve}) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Verify boundary?' : 'Reject boundary?'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approve
                      ? 'Approve only after confirming the polygon source and actual geographic boundary.'
                      : 'Explain what must be corrected before resubmission.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review notes (required)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Review notes are required.';
                    if (text.length > 2000) return 'Maximum 2000 characters.';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(approve ? 'Confirm Verify' : 'Confirm Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !mounted) return;

    setState(() => _reviewing.add(item.id));
    try {
      await _repository.review(
        boundaryId: item.id,
        approve: approve,
        notes: notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Boundary verified by trusted backend. Service is not automatically activated.'
                : 'Boundary rejected. Notes saved by trusted backend.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review failed: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _reviewing.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Boundary Review',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pending City/Area polygons. Review the original source and geographic coverage before deciding. '
            'The backend re-validates polygon geometry and Area-within-City containment.',
          ),
          const SizedBox(height: 14),
          const _ReviewWarning(),
          const SizedBox(height: 18),
          StreamBuilder<List<AdminBoundaryReviewItem>>(
            stream: _repository.watchPending(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageCard(
                  icon: Icons.lock_outline,
                  message:
                      'Boundary list load nahi hui. Active super_admin access, Firestore Rules aur connection check karein. '
                      '${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const _MessageCard(
                  icon: Icons.verified_outlined,
                  message: 'Abhi koi pending City/Area boundary nahi hai.',
                );
              }
              return Column(
                children: items.map((item) => _BoundaryCard(
                  item: item,
                  busy: _reviewing.contains(item.id),
                  onApprove: () => _review(item, approve: true),
                  onReject: () => _review(item, approve: false),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewWarning extends StatelessWidget {
  const _ReviewWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2AD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFB45309)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Map par polygon ka geographic preview dikhaya gaya hai, lekin yeh apne aap mein boundary source ki authenticity ka proof nahi. '
              'Source/reference ko independently check kiye bina Verify na karein. Verification se City/Area active nahi hota.',
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final AdminBoundaryReviewItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.polyline, color: Color(0xFFFF7900), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.locationType.toUpperCase()} • ${item.locationId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text('${item.points.length} points')),
              ],
            ),
            const SizedBox(height: 12),
            Text('Boundary ID: ${item.id}'),
            const SizedBox(height: 6),
            Text('Source type: ${item.sourceType}'),
            Text('Source name: ${item.sourceName.isEmpty ? 'Missing' : item.sourceName}'),
            Text('Source reference: ${item.sourceReference.isEmpty ? 'Missing' : item.sourceReference}'),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: _GeographicBoundaryMap(coordinates: item.points),
              ),
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('View polygon coordinates'),
              children: [
                for (var i = 0; i < item.points.length; i++)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${i + 1}. ${item.points[i]}'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
                FilledButton.icon(
                  onPressed: busy || item.points.length < 3 ||
                          item.sourceName.trim().isEmpty ||
                          item.sourceReference.trim().isEmpty
                      ? null
                      : onApprove,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: const Text('Verify Boundary'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GeographicBoundaryMap extends StatelessWidget {
  const _GeographicBoundaryMap({required this.coordinates});

  final List<String> coordinates;

  List<LatLng> get _points {
    final result = <LatLng>[];
    for (final coordinate in coordinates) {
      final parts = coordinate.split(',');
      if (parts.length != 2) continue;
      final latitude = double.tryParse(parts[0].trim());
      final longitude = double.tryParse(parts[1].trim());
      if (latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }
      result.add(LatLng(latitude, longitude));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    if (points.length < 3) {
      return Container(
        color: const Color(0xFFFFFAF5),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Geographic map unavailable: at least three valid polygon points are required.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final minLatitude = points
        .map((point) => point.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLatitude = points
        .map((point) => point.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLongitude = points
        .map((point) => point.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLongitude = points
        .map((point) => point.longitude)
        .reduce((a, b) => a > b ? a : b);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: points.first, zoom: 12),
          polygons: {
            Polygon(
              polygonId: const PolygonId('review-boundary'),
              points: points,
              fillColor: const Color(0x33FF7900),
              strokeColor: const Color(0xFFFF7900),
              strokeWidth: 3,
              consumeTapEvents: false,
            ),
          },
          mapType: MapType.normal,
          compassEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (controller) {
            // Avoid invalid zero-width/height bounds for malformed or
            // degenerate polygons. The trusted backend remains authoritative.
            if (maxLatitude - minLatitude < 0.000001 ||
                maxLongitude - minLongitude < 0.000001) {
              return;
            }
            controller.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLatitude, minLongitude),
                  northeast: LatLng(maxLatitude, maxLongitude),
                ),
                36,
              ),
            );
          },
        ),
        Positioned(
          left: 10,
          top: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD2AD)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                'Geographic polygon • verify source independently',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFF7900)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
