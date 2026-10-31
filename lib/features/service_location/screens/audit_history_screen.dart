import 'package:flutter/material.dart';

/// UI-only Service Location audit history preview.
/// Rows are illustrative and are not fetched from Firebase yet.
class LocationAuditHistoryScreen extends StatefulWidget {
  const LocationAuditHistoryScreen({super.key});

  @override
  State<LocationAuditHistoryScreen> createState() =>
      _LocationAuditHistoryScreenState();
}

class _LocationAuditHistoryScreenState extends State<LocationAuditHistoryScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);
  String _filter = 'All events';

  final List<_AuditEntry> _examples = const [
    _AuditEntry(
      event: 'Zone readiness submitted',
      target: 'Example Zone A',
      actor: 'Central Admin',
      outcome: 'Pending review',
      time: 'Illustrative · IST',
      detail: 'Readiness packet submitted for review.',
    ),
    _AuditEntry(
      event: 'Boundary revision updated',
      target: 'Example Zone B',
      actor: 'Central Admin',
      outcome: 'Review required',
      time: 'Illustrative · IST',
      detail: 'A boundary change requires a fresh review and approval.',
    ),
    _AuditEntry(
      event: 'Emergency suspension',
      target: 'Example Zone C',
      actor: 'Central Admin',
      outcome: 'Suspended',
      time: 'Illustrative · IST',
      detail: 'Example only: suspension must be audited and Founder/CEO notified.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _filter == 'All events'
        ? _examples
        : _examples.where((entry) => entry.outcome == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Location Audit History'),
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
                  'Service location audit trail',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track who performed a location workflow action, what changed, '
                  'and the resulting status. Times should be shown in IST. '
                  'This preview is not connected to live audit records.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: _orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Audit records should be append-only. This screen must not '
                          'allow editing or deleting audit events. Example entries below '
                          'are placeholders, not production evidence.',
                          style: TextStyle(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'All events',
                    'Pending review',
                    'Review required',
                    'Suspended',
                  ].map((value) {
                    return ChoiceChip(
                      label: Text(value),
                      selected: _filter == value,
                      selectedColor: _orange.withValues(alpha: 0.16),
                      onSelected: (_) => setState(() => _filter = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No example events match this filter.')),
                    ),
                  )
                else
                  ...entries.map(
                    (entry) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.history_rounded, color: _orange),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.event,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _AuditStatus(entry.outcome),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 20,
                              runSpacing: 10,
                              children: [
                                _AuditDetail('Target', entry.target),
                                _AuditDetail('Actor', entry.actor),
                                _AuditDetail('Time', entry.time),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(entry.detail, style: const TextStyle(height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Integration pending: connect to the approved audit data source, add pagination '
                  'and date/actor filters, and enforce role-based access before release.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditEntry {
  const _AuditEntry({
    required this.event,
    required this.target,
    required this.actor,
    required this.outcome,
    required this.time,
    required this.detail,
  });

  final String event;
  final String target;
  final String actor;
  final String outcome;
  final String time;
  final String detail;
}

class _AuditStatus extends StatelessWidget {
  const _AuditStatus(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E7),
          border: Border.all(color: const Color(0xFFFFD2AC)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A4300),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
}

class _AuditDetail extends StatelessWidget {
  const _AuditDetail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
