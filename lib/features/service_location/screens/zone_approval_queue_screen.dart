import 'package:flutter/material.dart';

/// UI-only Founder approval queue prototype.
/// Example rows are illustrative; no live requests can be approved here.
class ZoneApprovalQueueScreen extends StatefulWidget {
  const ZoneApprovalQueueScreen({super.key, this.focusZoneId});

  final String? focusZoneId;

  @override
  State<ZoneApprovalQueueScreen> createState() => _ZoneApprovalQueueScreenState();
}

class _ZoneApprovalQueueScreenState extends State<ZoneApprovalQueueScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);
  late String _filter;

  @override
  void initState() {
    super.initState();
    // A deep-linked Zone must be visible even when its example status is blocked.
    _filter = widget.focusZoneId == null ? 'Awaiting decision' : 'All';
  }

  final List<_ApprovalItem> _examples = const [
    _ApprovalItem(
      zoneId: 'ZONE-EX-001',
      name: 'Example Zone A',
      city: 'Example City',
      request: 'Initial launch',
      zoneType: 'Service Zone',
      parentPath: 'Example State/UT → Example District → Example City',
      submittedBy: 'Central Admin (example)',
      submittedAt: '2026-10-28 09:15 IST',
      revision: 'Revision 1',
      boundaryStatus: 'Not verified',
      boundaryHash: 'Not generated',
      blockers: 'Polygon evidence and verification pending; Founder decision must wait',
      status: 'Blocked — boundary pending',
    ),
    _ApprovalItem(
      zoneId: 'ZONE-EX-003',
      name: 'Example Zone C',
      city: 'Example City',
      request: 'Initial launch',
      zoneType: 'Service Zone',
      parentPath: 'Example State/UT → Example District → Example City',
      submittedBy: 'Central Admin (example)',
      submittedAt: '2026-10-29 08:30 IST',
      revision: 'Revision 3',
      boundaryStatus: 'Verified (example)',
      boundaryHash: 'EXAMPLE-SHA256-VERIFIED-003',
      blockers: 'None shown in this illustrative record; live readiness checks are not connected',
      status: 'Awaiting decision',
    ),
    _ApprovalItem(
      zoneId: 'ZONE-EX-002',
      name: 'Example Zone B',
      city: 'Example City',
      request: 'Boundary change',
      zoneType: 'Service Zone',
      parentPath: 'Example State/UT → Example District → Example City',
      submittedBy: 'Central Admin (example)',
      submittedAt: '2026-10-27 16:40 IST',
      revision: 'Revision 2',
      boundaryStatus: 'Hash changed',
      boundaryHash: 'EXAMPLE-HASH-CHANGED',
      blockers: 'Re-review required; prior approval must not be reused',
      status: 'Blocked — re-review',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = _examples.where((item) {
      final matchesZone = widget.focusZoneId == null || item.zoneId == widget.focusZoneId;
      final matchesStatus = _filter == 'All' || item.status == _filter;
      return matchesZone && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        toolbarHeight: widget.focusZoneId == null ? kToolbarHeight : 80,
        title: Text(
          widget.focusZoneId == null
              ? 'Founder Approval Queue'
              : 'Founder Approval Queue · ${widget.focusZoneId}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD2AC)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Business approval gate',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
                SizedBox(height: 8),
                Text(
                  'Founder/CEO makes the final business decision for Zone launch, activation, material boundary changes, deactivation and reactivation. Central Admin prepares the request; Super Admin does not inherit Founder approval authority.',
                  style: TextStyle(height: 1.45, color: Color(0xFF5D5148)),
                ),
                SizedBox(height: 8),
                Text(
                  'Prototype only · Example records · No server actions enabled',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9A4D00)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in ['Awaiting decision', 'Blocked — boundary pending', 'Blocked — re-review', 'All'])
                ChoiceChip(
                  label: Text(label),
                  selected: _filter == label,
                  selectedColor: _orange,
                  labelStyle: TextStyle(
                    color: _filter == label ? Colors.white : _ink,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _filter = label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.focusZoneId == null
                      ? 'No example requests match this filter. Live queue is not connected.'
                      : 'No example approval request exists for ${widget.focusZoneId} in this sample. Live queue is not connected.',
                ),
              ),
            )
          else
            for (final item in rows) _approvalCard(item),
        ],
      ),
    );
  }

  Widget _approvalCard(_ApprovalItem item) {
    final blocked = item.status.startsWith('Blocked');
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFECE5DE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final statusChip = Chip(
                  label: Text(item.status, style: const TextStyle(fontSize: 11)),
                  backgroundColor:
                      blocked ? const Color(0xFFFFE8E3) : const Color(0xFFFFF0DF),
                  side: BorderSide.none,
                );
                final titleRow = Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: _orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 6),
                      statusChip,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: titleRow),
                    const SizedBox(width: 8),
                    statusChip,
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            _detail('Zone ID', item.zoneId),
            _detail('Type', item.zoneType),
            _detail('City', item.city),
            _detail('Parent path', item.parentPath),
            _detail('Request', item.request),
            _detail('Submitted by', item.submittedBy),
            _detail('Submitted at', item.submittedAt),
            _detail('Zone revision', item.revision),
            _detail('Boundary status', item.boundaryStatus),
            _detail('Boundary integrity', item.boundaryHash),
            _detail('Readiness blockers', item.blockers),
            const SizedBox(height: 10),
            const Text(
              'Before a real decision: verify Zone ID, exact revision, boundary polygon and boundary hash. Any mismatch must invalidate the approval.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6D625A)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_outline, size: 17),
                label: const Text('Decision disabled — not connected'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const labelStyle = TextStyle(
              color: Color(0xFF756960),
              fontSize: 12,
            );
            const valueStyle = TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );

            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: labelStyle),
                  const SizedBox(height: 3),
                  Text(value, style: valueStyle),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 132, child: Text(label, style: labelStyle)),
                Expanded(child: Text(value, style: valueStyle)),
              ],
            );
          },
        ),
      );
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.zoneId,
    required this.name,
    required this.city,
    required this.request,
    required this.zoneType,
    required this.parentPath,
    required this.submittedBy,
    required this.submittedAt,
    required this.revision,
    required this.boundaryStatus,
    required this.boundaryHash,
    required this.blockers,
    required this.status,
  });

  final String zoneId;
  final String name;
  final String city;
  final String request;
  final String zoneType;
  final String parentPath;
  final String submittedBy;
  final String submittedAt;
  final String revision;
  final String boundaryStatus;
  final String boundaryHash;
  final String blockers;
  final String status;
}
