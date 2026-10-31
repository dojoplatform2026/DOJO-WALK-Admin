import 'package:flutter/material.dart';

/// UI-only report catalog. No KPI values are fabricated or queried here.
class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);
  String period = 'Last 7 days';

  final reports = const [
    _Report('Booking lifecycle', 'Created, assigned, completed, cancelled and rescheduled counts', 'POL-026 / POL-029'),
    _Report('Walker performance', 'Verified completed walks, availability and quality review', 'POL-004 / POL-026'),
    _Report('Zone readiness', 'Zone capacity, polygon verification, approval and activation state', 'POL-038 / POL-040'),
    _Report('Safety & incidents', 'Severity, response trail, safe handover and closure review', 'POL-016 / POL-008'),
    _Report('Payments & refunds', 'Paid transactions, reconciliation exceptions and refund approvals', 'POL-030 / POL-029'),
    _Report('Support resolution', 'Case severity, owner, escalation and resolution trail', 'POL-009 / POL-024'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFFFAF5),
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
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
                  const Text('Operational Reporting',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 8),
                  const Text(
                    'Report catalog only. KPI values, totals and trends are intentionally not fabricated; each report needs an approved data definition and authorized source.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Reporting period', style: TextStyle(fontWeight: FontWeight.w700)),
                      for (final value in ['Last 7 days', 'Last 30 days', 'Custom range'])
                        ChoiceChip(
                          label: Text(value),
                          selected: period == value,
                          selectedColor: orange.withValues(alpha: 0.16),
                          onSelected: (_) => setState(() => period = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final report in reports) _reportCard(report),
                  const SizedBox(height: 8),
                  const Text(
                    'Export, scheduled reports and data refresh are disabled until source definitions, permissions, retention and audit requirements are approved.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _reportCard(_Report report) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Chip(label: Text('Not connected')),
                ],
              ),
              const SizedBox(height: 10),
              Text(report.description, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 6),
              Text('Policy source: ${report.policy}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Open report disabled'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export disabled'),
                ),
              ]),
            ],
          ),
        ),
      );
}

class _Report {
  const _Report(this.title, this.description, this.policy);
  final String title;
  final String description;
  final String policy;
}
