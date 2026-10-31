import 'package:flutter/material.dart';

/// UI-only support queue prototype aligned with POL-009 / POL-024.
/// All cases are examples; no customer or incident data is loaded.
class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);
  final _search = TextEditingController();
  String _severity = 'All';

  final List<_SupportCase> _examples = const [
    _SupportCase(
      id: 'CASE-EX-001',
      title: 'Example live-walk safety concern',
      category: 'Dog / person safety',
      severity: 'S0 — Critical safety/security',
      status: 'Escalated',
      owner: 'Safety Lead (example)',
      relatedRef: 'WALK-EX-001',
      nextStep: 'Immediate safety triage; preserve safe handover and escalate.',
      updatedAt: '2026-10-28 09:15 IST',
    ),
    _SupportCase(
      id: 'CASE-EX-002',
      title: 'Example walker assignment delay',
      category: 'Walker assignment / no availability',
      severity: 'S1 — Urgent live service',
      status: 'In progress',
      owner: 'Central Support (example)',
      relatedRef: 'BOOKING-EX-002',
      nextStep: 'Confirm assigned owner and update the reporter through an approved channel.',
      updatedAt: '2026-10-27 16:40 IST',
    ),
    _SupportCase(
      id: 'CASE-EX-003',
      title: 'Example payment receipt question',
      category: 'Payment / receipt',
      severity: 'S2 — Time-sensitive service/finance',
      status: 'Awaiting information',
      owner: 'Finance (example)',
      relatedRef: 'PAYMENT-EX-003',
      nextStep: 'Reconcile the transaction before communicating an outcome.',
      updatedAt: '2026-10-26 12:05 IST',
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
    final cases = _examples.where((item) {
      final matchesQuery = query.isEmpty ||
          '${item.id} ${item.title} ${item.category} ${item.relatedRef} ${item.owner}'
              .toLowerCase()
              .contains(query);
      final matchesSeverity = _severity == 'All' || item.severity.startsWith(_severity);
      return matchesQuery && matchesSeverity;
    }).toList()
      ..sort((a, b) => _severityRank(a.severity).compareTo(_severityRank(b.severity)));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Support & Complaints'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Support Case Queue',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 8),
                const Text(
                  'One company-owned support process for customers and walkers. Example records only; the queue is not connected to live cases.',
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
                      Icon(Icons.priority_high_rounded, color: _orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Safety and privacy concerns override ordinary queue priority. Do not promise refunds, compensation, outcomes or response times that are not approved. Never request passwords or authentication codes.',
                          style: TextStyle(color: _ink, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search case ID, category, owner or related reference',
                    prefixIcon: const Icon(Icons.search, color: _orange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final severity in ['All', 'S0', 'S1', 'S2', 'S3'])
                      ChoiceChip(
                        label: Text(severity == 'All' ? 'All severities' : severity),
                        selected: _severity == severity,
                        selectedColor: _orange.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() => _severity = severity),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (cases.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No example cases match these filters. Live support cases are not connected.'),
                    ),
                  )
                else
                  for (final item in cases) _caseCard(item),
                const SizedBox(height: 8),
                const Text(
                  'Case assignment, escalation, transfer and resolution actions are disabled until authorization, evidence storage and audit logging are implemented.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _severityRank(String severity) => severity.startsWith('S0')
      ? 0
      : severity.startsWith('S1')
          ? 1
          : severity.startsWith('S2')
              ? 2
              : 3;

  Widget _caseCard(_SupportCase item) => Card(
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
              Row(
                children: [
                  Icon(
                    item.severity.startsWith('S0') ? Icons.emergency_outlined : Icons.support_agent_outlined,
                    color: item.severity.startsWith('S0') ? Colors.red : _orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                        const SizedBox(height: 3),
                        Text(item.id, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Chip(label: Text(item.severity.split(' — ').first)),
                ],
              ),
              const Divider(height: 24),
              _detail('Category', item.category),
              _detail('Severity (draft)', item.severity),
              _detail('Status', item.status),
              _detail('Primary owner', item.owner),
              _detail('Related reference', item.relatedRef),
              _detail('Last updated', item.updatedAt),
              _detail('Next step', item.nextStep),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _showExampleCase(item),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View example case'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.swap_horiz_outlined),
                  label: const Text('Transfer disabled'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Resolve disabled'),
                ),
              ]),
            ],
          ),
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Future<void> _showExampleCase(_SupportCase item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.id),
        content: Text('Example case only.\nCategory: ${item.category}\nSeverity: ${item.severity}\nOwner: ${item.owner}\nNo live support or incident data was accessed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SupportCase {
  const _SupportCase({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.status,
    required this.owner,
    required this.relatedRef,
    required this.nextStep,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String category;
  final String severity;
  final String status;
  final String owner;
  final String relatedRef;
  final String nextStep;
  final String updatedAt;
}
