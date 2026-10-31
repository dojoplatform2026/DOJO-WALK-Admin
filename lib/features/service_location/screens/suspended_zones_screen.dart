import 'package:flutter/material.dart';

/// UI-only prototype for suspended/deactivated service Zones.
/// Example data is intentionally local; no Firebase reads or state changes occur.
class SuspendedZonesScreen extends StatefulWidget {
  const SuspendedZonesScreen({super.key});

  @override
  State<SuspendedZonesScreen> createState() => _SuspendedZonesScreenState();
}

class _SuspendedZonesScreenState extends State<SuspendedZonesScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);
  static const _paper = Color(0xFFFFFAF5);

  String _statusFilter = 'All';
  String _impactFilter = 'All';

  final List<_ZoneRecord> _examples = const [
    _ZoneRecord(
      zoneName: 'Example Zone North',
      zoneId: 'ZONE-EX-001',
      city: 'Example City',
      state: 'Example State/UT',
      status: 'Suspended',
      reason: 'Boundary integrity review required',
      reasonCode: 'BOUNDARY_REVIEW',
      effectiveAt: '2026-10-27 16:20 IST',
      changedBy: 'Central Admin (example)',
      activeBookings: 4,
      runningWalks: 1,
      revision: 'Revision 3',
      boundaryHash: 'Needs re-verification',
      events: [
        _AuditEvent('Suspension requested', 'Central Admin (example)', '2026-10-27 16:15 IST'),
        _AuditEvent('Zone suspended', 'System event (example)', '2026-10-27 16:20 IST'),
        _AuditEvent('Boundary re-review required', 'System event (example)', '2026-10-27 16:20 IST'),
      ],
    ),
    _ZoneRecord(
      zoneName: 'Example Zone South',
      zoneId: 'ZONE-EX-002',
      city: 'Example City',
      state: 'Example State/UT',
      status: 'Deactivated',
      reason: 'Temporary service closure',
      reasonCode: 'SERVICE_CLOSURE',
      effectiveAt: '2026-10-25 11:00 IST',
      changedBy: 'Central Admin (example)',
      activeBookings: 0,
      runningWalks: 0,
      revision: 'Revision 2',
      boundaryHash: 'Not rechecked',
      events: [
        _AuditEvent('Deactivation requested', 'Central Admin (example)', '2026-10-25 10:42 IST'),
        _AuditEvent('Founder decision recorded (example)', 'Founder/CEO (example)', '2026-10-25 10:58 IST'),
        _AuditEvent('Zone deactivated', 'System event (example)', '2026-10-25 11:00 IST'),
      ],
    ),
    _ZoneRecord(
      zoneName: 'Example Zone Central',
      zoneId: 'ZONE-EX-003',
      city: 'Example City',
      state: 'Example State/UT',
      status: 'Suspended',
      reason: 'Safety incident under investigation',
      reasonCode: 'SAFETY_REVIEW',
      effectiveAt: '2026-10-28 08:30 IST',
      changedBy: 'Central Admin (example)',
      activeBookings: 2,
      runningWalks: 0,
      revision: 'Revision 1',
      boundaryHash: 'Unchanged in example',
      events: [
        _AuditEvent('Safety hold requested', 'Central Admin (example)', '2026-10-28 08:22 IST'),
        _AuditEvent('Zone suspension recorded', 'System event (example)', '2026-10-28 08:30 IST'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _examples.where((zone) {
      final statusMatch = _statusFilter == 'All' || zone.status == _statusFilter;
      final impactMatch = _impactFilter == 'All' ||
          (_impactFilter == 'Has active bookings' && zone.activeBookings > 0) ||
          (_impactFilter == 'Has running walks' && zone.runningWalks > 0) ||
          (_impactFilter == 'No current impact' &&
              zone.activeBookings == 0 && zone.runningWalks == 0);
      return statusMatch && impactMatch;
    }).toList();

    final suspended = _examples.where((z) => z.status == 'Suspended').length;
    final deactivated = _examples.where((z) => z.status == 'Deactivated').length;
    final bookings = _examples.fold<int>(0, (sum, z) => sum + z.activeBookings);
    final walks = _examples.fold<int>(0, (sum, z) => sum + z.runningWalks);

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Suspended / Deactivated Zones',
            maxLines: 1,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
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
                Text('Zone service-status control',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink)),
                SizedBox(height: 8),
                Text(
                  'Only a Zone can be Active, Suspended or Deactivated. State/UT, District and City are hierarchy records, not service activation controls. Central Admin prepares and manages the case; Founder/CEO approval is required for business activation/deactivation decisions. A narrowly scoped emergency safety suspension may be applied only to prevent immediate harm, with an append-only audit record and prompt Founder/CEO notification; it is not a substitute for the normal approval gate. Super Admin does not automatically inherit Founder authority.',
                  style: TextStyle(height: 1.45, color: Color(0xFF5D5148)),
                ),
                SizedBox(height: 10),
                Text(
                  'PROTOTYPE ONLY · Example records · No live status changes',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF9A4D00)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metric('Suspended zones', '$suspended', Icons.pause_circle_outline, width),
                _metric('Deactivated zones', '$deactivated', Icons.block_outlined, width),
                _metric('Affected bookings', '$bookings', Icons.event_note_outlined, width),
                _metric('Running walks', '$walks', Icons.directions_walk_outlined, width),
              ],
            );
          }),
          const SizedBox(height: 18),
          _sectionTitle('Find a Zone'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in ['All', 'Suspended', 'Deactivated'])
                ChoiceChip(
                  label: Text(status),
                  selected: _statusFilter == status,
                  selectedColor: _orange,
                  labelStyle: TextStyle(
                    color: _statusFilter == status ? Colors.white : _ink,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _statusFilter = status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _impactFilter,
            decoration: InputDecoration(
              labelText: 'Operational impact',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All impact levels')),
              DropdownMenuItem(value: 'Has active bookings', child: Text('Has active bookings')),
              DropdownMenuItem(value: 'Has running walks', child: Text('Has running walks')),
              DropdownMenuItem(value: 'No current impact', child: Text('No current impact')),
            ],
            onChanged: (value) => setState(() => _impactFilter = value ?? 'All'),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No example Zones match these filters. Live records are not connected.'),
            ))
          else
            for (final zone in visible) _zoneCard(zone),
          const SizedBox(height: 8),
          _sectionTitle('Required safeguards'),
          const SizedBox(height: 8),
          const _Safeguard(
            icon: Icons.event_busy_outlined,
            title: 'Existing bookings',
            body: 'Show affected upcoming bookings, prevent new bookings in a non-active Zone, and route rescheduling/refund handling through the approved policy. Do not silently delete bookings.',
          ),
          const _Safeguard(
            icon: Icons.emergency_outlined,
            title: 'Walk already in progress',
            body: 'A Zone status change must not silently cancel or terminate a running walk. Keep safety, handover and incident escalation available until the walk is safely closed.',
          ),
          const _Safeguard(
            icon: Icons.verified_user_outlined,
            title: 'Reactivation is a new approval gate',
            body: 'Recheck Zone ID, boundary polygon, revision and boundary hash. Any material revision/hash mismatch invalidates the old approval. Central Admin prepares a new request; Founder/CEO decides.',
          ),
          const _Safeguard(
            icon: Icons.history_outlined,
            title: 'Append-only audit trail',
            body: 'Record who requested and decided, reason code and notes, timestamps, previous/new status, Zone revision, boundary hash, affected booking/walk counts and decision reference.',
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFECE5DE)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _orange),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF756960))),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
      );

  Widget _zoneCard(_ZoneRecord zone) {
    final isSuspended = zone.status == 'Suspended';
    final statusColor = isSuspended ? const Color(0xFF9A4D00) : const Color(0xFF8B3030);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFECE5DE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.zoneName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${zone.zoneId} · ${zone.city}, ${zone.state}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF756960)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSuspended ? const Color(0xFFFFF0DF) : const Color(0xFFFFE8E3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  zone.status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _detail('Reason', zone.reason),
          _detail('Reason code', zone.reasonCode),
          _detail('Effective at', zone.effectiveAt),
          _detail('Changed by', zone.changedBy),
          _detail('Zone revision', zone.revision),
          _detail('Boundary integrity', zone.boundaryHash),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _impactPill(Icons.event_note_outlined, '${zone.activeBookings} active bookings',
                zone.activeBookings > 0),
            _impactPill(Icons.directions_walk_outlined, '${zone.runningWalks} running walks',
                zone.runningWalks > 0),
          ]),
          const SizedBox(height: 12),
          Text(
            'Audit history',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            '${zone.events.length} example events · not live audit data',
            style: const TextStyle(fontSize: 12, color: Color(0xFF756960)),
          ),
          const SizedBox(height: 8),
          for (final event in zone.events)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.action,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${event.actor}\n${event.at}',
                    style: const TextStyle(height: 1.5, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Actions are disabled in this prototype. Reactivation must go through a fresh Founder approval; no direct status toggle is provided.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6D625A)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: null,
                child: const Text('View case'),
              ),
              OutlinedButton(
                onPressed: null,
                child: const Text('Request reactivation'),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(builder: (context, constraints) {
          const labelStyle = TextStyle(
            fontSize: 12,
            color: Color(0xFF756960),
          );
          const valueStyle = TextStyle(fontSize: 13, color: _ink);

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 2),
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
        }),
      );

  Widget _impactPill(IconData icon, String label, bool alert) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: alert ? const Color(0xFFFFE8E3) : const Color(0xFFF4F0EC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: alert ? const Color(0xFF8B3030) : const Color(0xFF756960),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              softWrap: true,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: alert ? const Color(0xFF8B3030) : _ink,
              ),
            ),
          ],
        ),
      );
}

class _ZoneRecord {
  const _ZoneRecord({
    required this.zoneName,
    required this.zoneId,
    required this.city,
    required this.state,
    required this.status,
    required this.reason,
    required this.reasonCode,
    required this.effectiveAt,
    required this.changedBy,
    required this.activeBookings,
    required this.runningWalks,
    required this.revision,
    required this.boundaryHash,
    required this.events,
  });

  final String zoneName;
  final String zoneId;
  final String city;
  final String state;
  final String status;
  final String reason;
  final String reasonCode;
  final String effectiveAt;
  final String changedBy;
  final int activeBookings;
  final int runningWalks;
  final String revision;
  final String boundaryHash;
  final List<_AuditEvent> events;
}

class _AuditEvent {
  const _AuditEvent(this.action, this.actor, this.at);
  final String action;
  final String actor;
  final String at;
}

class _Safeguard extends StatelessWidget {
  const _Safeguard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECE5DE)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFFFF7900)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF252525))),
            const SizedBox(height: 5),
            Text(body, style: const TextStyle(height: 1.4, color: Color(0xFF5D5148))),
          ])),
        ]),
      );
}
