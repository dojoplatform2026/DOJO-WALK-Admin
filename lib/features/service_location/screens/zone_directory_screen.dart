import 'package:flutter/material.dart';

import 'boundary_review_screen.dart';
import 'zone_approval_queue_screen.dart';
import 'zone_details_screen.dart';

/// UI-only directory preview. The records are illustrative and are not live data.
class ZoneDirectoryScreen extends StatefulWidget {
  const ZoneDirectoryScreen({super.key});

  @override
  State<ZoneDirectoryScreen> createState() => _ZoneDirectoryScreenState();
}

class _ZoneDirectoryScreenState extends State<ZoneDirectoryScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);

  final _search = TextEditingController();
  String _status = 'All';

  final List<_ZoneRow> _examples = const [
    _ZoneRow(
      name: 'Example Zone A',
      city: 'Example City',
      status: 'Pending review',
      revision: 'Revision 1',
      zoneId: 'ZONE-EX-001',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Not verified',
      readinessBlocker: 'Polygon evidence pending',
      updatedAt: '2026-10-28 09:15 IST',
      updatedBy: 'Central Admin (example)',
    ),
    _ZoneRow(
      name: 'Example Zone B',
      city: 'Example City',
      status: 'Needs changes',
      revision: 'Revision 2',
      zoneId: 'ZONE-EX-002',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Hash changed',
      readinessBlocker: 'Boundary re-verification required',
      updatedAt: '2026-10-27 16:40 IST',
      updatedBy: 'Central Admin (example)',
    ),
    _ZoneRow(
      name: 'Example Zone C',
      city: 'Example City',
      status: 'Not activated',
      revision: 'Revision 3',
      zoneId: 'ZONE-EX-003',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Verified (example)',
      readinessBlocker: 'Founder/CEO approval or activation pending',
      updatedAt: '2026-10-26 12:05 IST',
      updatedBy: 'Central Admin (example)',
    ),
    _ZoneRow(
      name: 'Example Zone D',
      city: 'Example City',
      status: 'Draft',
      revision: 'Revision 1',
      zoneId: 'ZONE-EX-004',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Not started',
      readinessBlocker: 'Required details and polygon evidence incomplete',
      updatedAt: '2026-10-25 10:10 IST',
      updatedBy: 'Central Admin (example)',
    ),
    _ZoneRow(
      name: 'Example Zone E',
      city: 'Example City',
      status: 'Active',
      revision: 'Revision 3',
      zoneId: 'ZONE-EX-005',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Verified (example)',
      readinessBlocker: 'None — example only',
      updatedAt: '2026-10-24 13:20 IST',
      updatedBy: 'Central Admin (example)',
    ),
    _ZoneRow(
      name: 'Example Zone F',
      city: 'Example City',
      status: 'Suspended',
      revision: 'Revision 2',
      zoneId: 'ZONE-EX-006',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Verified (example)',
      readinessBlocker: 'Review existing bookings and active walks; never stop a running walk silently',
      updatedAt: '2026-10-23 18:05 IST',
      updatedBy: 'Central Admin (example)',
    ),
    _ZoneRow(
      name: 'Example Zone G',
      city: 'Example City',
      status: 'Deactivated',
      revision: 'Revision 4',
      zoneId: 'ZONE-EX-007',
      parentPath: 'Example State/UT → Example District → Example City',
      boundaryStatus: 'Verified (example)',
      readinessBlocker: 'New bookings blocked; historical records retained',
      updatedAt: '2026-10-22 14:45 IST',
      updatedBy: 'Central Admin (example)',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final rows = _examples.where((row) {
      final matchesQuery =
          query.isEmpty || '${row.name} ${row.city} ${row.zoneId} ${row.parentPath} '
                  '${row.boundaryStatus} ${row.readinessBlocker}'.toLowerCase().contains(query);
      final matchesStatus = _status == 'All' || row.status == _status;
      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Zone Directory'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Zone Directory',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse zone status and revisions. Only Zones can be activated or deactivated. '
                  'This preview uses sample rows; it is not connected to Firestore.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                  ),
                  child: const Text(
                    'Suspended is a temporary emergency stop for safety or material risk, not a normal deactivation shortcut. Central Admin must record the reason and audit event and notify Founder promptly for review. New bookings remain blocked while suspended.',
                    style: TextStyle(color: _ink, fontSize: 12, height: 1.45),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search zone or city',
                    prefixIcon: const Icon(Icons.search, color: _orange),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : Semantics(
                            label: 'Clear search',
                            button: true,
                            child: IconButton(
                              tooltip: 'Clear search',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Draft', 'Pending review', 'Needs changes', 'Not activated', 'Active', 'Suspended', 'Deactivated']
                      .map((status) => ChoiceChip(
                            label: Text(status),
                            selected: _status == status,
                            selectedColor: _orange.withValues(alpha: 0.15),
                            onSelected: (_) => setState(() => _status = status),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_outlined,
                              size: 36,
                              color: _orange,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              query.isNotEmpty
                                  ? 'No example zones match “${_search.text.trim()}”.'
                                  : 'No example zones with status “$_status”.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'These are sample records only. Clear the search or select All to view the examples.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                if (query.isNotEmpty)
                                  OutlinedButton(
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                    child: const Text('Clear search'),
                                  ),
                                if (_status != 'All')
                                  OutlinedButton(
                                    onPressed: () => setState(() => _status = 'All'),
                                    child: const Text('Show all statuses'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...rows.map((row) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final title = Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: _orange),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          row.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                  final status = _StatusLabel(row.status);

                                  if (constraints.maxWidth < 460) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        title,
                                        const SizedBox(height: 8),
                                        status,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: title),
                                      const SizedBox(width: 8),
                                      status,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 18,
                                runSpacing: 8,
                                children: [
                                  _Meta('Zone ID', row.zoneId),
                                  _Meta('Parent path', row.parentPath),
                                  _Meta('Revision', row.revision),
                                  _Meta('Boundary status', row.boundaryStatus),
                                  _Meta('Readiness blockers', row.readinessBlocker),
                                  _Meta('Last updated', row.updatedAt),
                                  _Meta('Updated by', row.updatedBy),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Activation, deactivation and approval actions remain disabled until '
                                'the authoritative Zone service, permissions and audit logging are connected.',
                                style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ZoneDetailsScreen(
                                          zoneId: row.zoneId,
                                          zoneName: row.name,
                                          parentPath: row.parentPath,
                                          status: row.status,
                                          revision: row.revision,
                                          boundaryStatus: row.boundaryStatus,
                                          readinessBlocker: row.readinessBlocker,
                                          updatedAt: row.updatedAt,
                                          updatedBy: row.updatedBy,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('View details'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BoundaryReviewScreen(focusZoneId: row.zoneId),
                                      ),
                                    ),
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('View boundary preview'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ZoneApprovalQueueScreen(focusZoneId: row.zoneId),
                                      ),
                                    ),
                                    icon: const Icon(Icons.verified_user_outlined),
                                    label: const Text('Open approval queue'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.lock_outline),
                                    label: const Text('Lifecycle actions disabled'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 8),
                const Text(
                  'Mock data only — no zone has been created, approved or activated.',
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

class _ZoneRow {
  const _ZoneRow({
    required this.name,
    required this.city,
    required this.status,
    required this.revision,
    required this.zoneId,
    required this.parentPath,
    required this.boundaryStatus,
    required this.readinessBlocker,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String name;
  final String city;
  final String status;
  final String revision;
  final String zoneId;
  final String parentPath;
  final String boundaryStatus;
  final String readinessBlocker;
  final String updatedAt;
  final String updatedBy;
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Pending review'
        ? Colors.orange
        : status == 'Needs changes'
            ? Colors.red
            : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
