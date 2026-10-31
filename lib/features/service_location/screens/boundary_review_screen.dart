import 'package:flutter/material.dart';

import 'zone_approval_queue_screen.dart';

/// UI-only boundary review queue prototype.
/// No records are loaded, approved, rejected, or changed on the server.
class BoundaryReviewScreen extends StatefulWidget {
  const BoundaryReviewScreen({super.key, this.focusZoneId});

  final String? focusZoneId;

  @override
  State<BoundaryReviewScreen> createState() => _BoundaryReviewScreenState();
}

class _BoundaryReviewScreenState extends State<BoundaryReviewScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);
  String _filter = 'All';

  // Illustrative rows only. IDs and hashes below are not live records.
  final List<_ReviewItem> _examples = const [
    _ReviewItem(
      zoneId: 'ZONE-EX-001',
      zone: 'Example Zone A',
      city: 'Example City',
      owner: 'Central Admin',
      status: 'Pending review',
      revision: 'Revision 1',
      boundaryStatus: 'Not verified',
      polygonStatus: 'Polygon evidence pending',
      boundaryHash: 'Not generated',
    ),
    _ReviewItem(
      zoneId: 'ZONE-EX-002',
      zone: 'Example Zone B',
      city: 'Example City',
      owner: 'Central Admin',
      status: 'Needs changes',
      revision: 'Revision 2',
      boundaryStatus: 'Hash changed',
      polygonStatus: 'Re-verification required',
      boundaryHash: 'EXAMPLE-HASH-CHANGED',
    ),
    _ReviewItem(
      zoneId: 'ZONE-EX-003',
      zone: 'Example Zone C',
      city: 'Example City',
      owner: 'Central Admin',
      status: 'Verified',
      revision: 'Revision 3',
      boundaryStatus: 'Verified (example)',
      polygonStatus: 'Polygon check recorded (example)',
      boundaryHash: 'EXAMPLE-SHA256-VERIFIED-003',
    ),
    _ReviewItem(
      zoneId: 'ZONE-EX-004',
      zone: 'Example Zone D',
      city: 'Example City',
      owner: 'Central Admin',
      status: 'Rejected',
      revision: '1',
      boundaryStatus: 'Rejected',
      polygonStatus: 'Evidence incomplete (example)',
      boundaryHash: 'EXAMPLE-HASH-REJECTED',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final statuses = ['All', 'Pending review', 'Verified', 'Rejected', 'Needs changes'];
    final items = _examples.where((item) {
      final matchesZone = widget.focusZoneId == null || item.zoneId == widget.focusZoneId;
      final matchesStatus = _filter == 'All' || item.status == _filter;
      return matchesZone && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      // Keep the preview heading in the scrollable content rather than the
      // AppBar. This avoids a narrow-viewport toolbar RenderFlex overflow.
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boundary Review',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Zone boundary review',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Central Admin checks zone readiness and evidence. Founder/CEO remains the final business approver for launch. This screen is a UI preview; it is not connected to live records.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ZoneApprovalQueueScreen(focusZoneId: widget.focusZoneId),
                      ),
                    ),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Preview Founder Approval Queue'),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Boundary map preview',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0DF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Not connected',
                              style: TextStyle(
                                color: Color(0xFF9A4D00),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9D9CB)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 42,
                              color: _orange,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Zone polygon overlay will appear here',
                              style: TextStyle(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 6),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'No map or polygon evidence is loaded. This placeholder is not proof of boundary verification.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Required before approval', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      _Requirement('Zone polygon exists and passes geometry validation'),
                      _Requirement('Boundary revision and cryptographic hash are recorded'),
                      _Requirement('State / UT → District → City hierarchy is confirmed'),
                      _Requirement('Readiness evidence and audit trail are available'),
                      _Requirement('Founder/CEO decision is bound to the exact Zone ID, revision and boundary hash'),
                      _Requirement('Any boundary revision/hash mismatch invalidates prior approval'),
                      _Requirement('Radius-only coverage is not sufficient for verification'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statuses.map((value) {
                    final selected = _filter == value;
                    return ChoiceChip(
                      label: Text(value),
                      selected: selected,
                      selectedColor: _orange.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _filter = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          widget.focusZoneId == null
                              ? 'No example items in this filter. Live data is not connected.'
                              : 'No example boundary request exists for ${widget.focusZoneId} in this sample. Live data is not connected.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ...items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.map_outlined, color: _orange),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.zone,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _StatusPill(item.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 18,
                                runSpacing: 12,
                                children: [
                                  _Detail('Zone ID', item.zoneId),
                                  _Detail('City', item.city),
                                  _Detail('Submitted by', item.owner),
                                  _Detail('Boundary revision', item.revision),
                                  _Detail('Boundary status', item.boundaryStatus),
                                  _Detail('Polygon verification', item.polygonStatus),
                                  _Detail('Boundary hash', item.boundaryHash),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFD2AC)),
                                ),
                                child: const Text(
                                  'Boundary verification is a technical evidence check only. A “Verified” boundary does not activate the Zone or grant launch approval. After boundary checks pass, the separate Founder Approval Queue handles the final business decision.',
                                  style: TextStyle(color: _ink, fontSize: 12, height: 1.45),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Example data only. Review and decision actions remain disabled until live records, evidence storage and permission checks are implemented.',
                                style: TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text('Review evidence'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.edit_note_outlined),
                                    label: const Text('Request changes'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.verified_outlined),
                                    label: const Text('Founder decision'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 8),
                const Text(
                  'Important: all rows, IDs and hashes are mock data, not actual pending zones. No approval, rejection, verification or activation can be performed here.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({
    required this.zoneId,
    required this.zone,
    required this.city,
    required this.owner,
    required this.status,
    required this.revision,
    required this.boundaryStatus,
    required this.polygonStatus,
    required this.boundaryHash,
  });

  final String zoneId;
  final String zone;
  final String city;
  final String owner;
  final String status;
  final String revision;
  final String boundaryStatus;
  final String polygonStatus;
  final String boundaryHash;
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, size: 18, color: _orange),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  static const _orange = Color(0xFFFF7900);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (label == 'Verified') {
      background = const Color(0xFFE5F5E9);
      foreground = const Color(0xFF176534);
    } else if (label == 'Rejected') {
      background = const Color(0xFFFFE8E3);
      foreground = const Color(0xFF9A2F20);
    } else if (label == 'Needs changes') {
      background = const Color(0xFFFFF0DF);
      foreground = const Color(0xFF8A4300);
    } else {
      background = const Color(0xFFEAF1FF);
      foreground = const Color(0xFF244A8F);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  static const _ink = Color(0xFF252525);
}
