import 'package:flutter/material.dart';

/// UI-only admin audit viewer prototype aligned with POL-021 and POL-020.
class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);
  final search = TextEditingController();
  String resultFilter = 'All';

  final entries = const [
    _AuditEntry('AUDIT-EX-001', 'Zone revision submitted', 'Central Operations (example)',
        'Central Admin', 'ZONE-EX-001 / Revision 1', 'Allowed (example)',
        'Submission recorded in prototype; no server write occurred', '2026-10-28 09:15 IST'),
    _AuditEntry('AUDIT-EX-002', 'Founder approval viewed', 'Founder/CEO (example)',
        'Founder / CEO', 'ZONE-EX-001 / Approval Queue', 'Allowed (example)',
        'Read-only UI event example', '2026-10-28 09:18 IST'),
    _AuditEntry('AUDIT-EX-003', 'Out-of-scope access attempt', 'City Manager (example)',
        'City Manager', 'Another City / Customer record', 'Denied (example)',
        'Geographic scope mismatch; example only', '2026-10-27 16:40 IST'),
    _AuditEntry('AUDIT-EX-004', 'Role grant requested', 'Super Admin (example)',
        'Super Admin', 'Admin role matrix', 'Blocked (example)',
        'Role changes are disabled in this prototype', '2026-10-26 12:05 IST'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final rows = entries.where((entry) {
      final matchesQuery = q.isEmpty ||
          '${entry.id} ${entry.action} ${entry.actor} ${entry.role} ${entry.resource} ${entry.reason}'
              .toLowerCase().contains(q);
      final matchesResult = resultFilter == 'All' || entry.result.startsWith(resultFilter);
      return matchesQuery && matchesResult;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Admin Audit Logs'),
        backgroundColor: Colors.white,
        foregroundColor: ink,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security & Activity Audit Trail',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 8),
                const Text(
                  'Prototype only. Example audit entries are illustrative and are not live records. A UI event is not evidence of a server-side action.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Audit integrity: record actor, role, scope, action, resource, result, reason and timestamp. Ordinary administrators must not edit or delete audit entries. Avoid storing passwords, OTPs, secrets or unnecessary sensitive payloads.',
                          style: TextStyle(color: ink, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search actor, action, resource or reason',
                    prefixIcon: const Icon(Icons.search, color: orange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final value in ['All', 'Allowed', 'Denied', 'Blocked'])
                    ChoiceChip(
                      label: Text(value),
                      selected: resultFilter == value,
                      selectedColor: orange.withValues(alpha: 0.16),
                      onSelected: (_) => setState(() => resultFilter = value),
                    ),
                ]),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No example audit entries match these filters. Live audit records are not connected.'),
                  ))
                else
                  for (final entry in rows) _entryCard(entry),
                const SizedBox(height: 8),
                const Text(
                  'Export is disabled until audit access scope, retention, redaction and evidence integrity controls are approved and tested.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _entryCard(_AuditEntry entry) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.history_rounded, color: orange),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.action, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    Text(entry.id, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                )),
                Chip(label: Text(entry.result)),
              ]),
              const Divider(height: 24),
              _detail('Actor', entry.actor),
              _detail('Role', entry.role),
              _detail('Resource', entry.resource),
              _detail('Result', entry.result),
              _detail('Reason / context', entry.reason),
              _detail('Timestamp', entry.timestamp),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export disabled'),
              ),
            ],
          ),
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 145, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _AuditEntry {
  const _AuditEntry(this.id, this.action, this.actor, this.role, this.resource,
      this.result, this.reason, this.timestamp);
  final String id, action, actor, role, resource, result, reason, timestamp;
}
