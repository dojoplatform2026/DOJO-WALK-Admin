import 'package:flutter/material.dart';

/// UI-only notification operations prototype aligned with POL-032.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);
  final search = TextEditingController();
  String filter = 'All';

  final examples = const [
    _Notice('NOTICE-EX-001', 'Booking created', 'Booking lifecycle', 'In-app example',
        'Pending (example)', 'BOOKING-EX-001', '2026-10-28 09:15 IST',
        'Booking reference is available. Assignment is not yet confirmed.'),
    _Notice('NOTICE-EX-002', 'Walker assignment confirmed', 'Walker updates', 'Push not configured',
        'Delivery unknown', 'BOOKING-EX-002', '2026-10-27 16:40 IST',
        'Assignment details must only be shown after trusted status confirmation.'),
    _Notice('NOTICE-EX-003', 'Safety case escalation', 'Safety and emergency', 'Operational route',
        'Escalated (example)', 'CASE-EX-003', '2026-10-26 12:05 IST',
        'Urgent safety handling must not depend on push delivery.'),
    _Notice('NOTICE-EX-004', 'Optional campaign', 'Marketing (optional)', 'Not configured',
        'Consent required', 'CAMPAIGN-EX-004', '2026-10-25 11:20 IST',
        'Marketing must remain separate from required service communications.'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final rows = examples.where((item) {
      final matchesQuery = q.isEmpty ||
          '${item.id} ${item.title} ${item.category} ${item.relatedRef}'
              .toLowerCase().contains(q);
      final matchesFilter = filter == 'All' || item.category == filter;
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Notification Center'),
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
                const Text('Notification & Messaging Operations',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 8),
                const Text(
                  'Prototype only. Delivery channels are not connected and no notification will be sent from this screen.',
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
                      Icon(Icons.verified_user_outlined, color: orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Never claim assignment, arrival, live location, payment or refund completion unless trusted backend status confirms it. Delivery receipts do not prove a message was read. Optional marketing requires separate consent.',
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
                    hintText: 'Search notification ID, category or reference',
                    prefixIcon: const Icon(Icons.search, color: orange),
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
                    for (final value in [
                      'All', 'Booking lifecycle', 'Walker updates',
                      'Safety and emergency', 'Marketing (optional)',
                    ])
                      ChoiceChip(
                        label: Text(value),
                        selected: filter == value,
                        selectedColor: orange.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() => filter = value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No example notifications match these filters. Live delivery records are not connected.'),
                  ))
                else
                  for (final item in rows) _noticeCard(item),
                const SizedBox(height: 8),
                const Text(
                  'Send, retry, cancel and preference-change actions are disabled until channel configuration, consent rules, delivery retries and audit logging are approved and implemented.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noticeCard(_Notice item) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final identity = Row(
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            Text(
                              item.id,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final statusChip = Chip(label: Text(item.status));

                  if (constraints.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        const SizedBox(height: 8),
                        statusChip,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 8),
                      statusChip,
                    ],
                  );
                },
              ),
              const Divider(height: 24),
              _detail('Category', item.category),
              _detail('Channel', item.channel),
              _detail('Status', item.status),
              _detail('Related reference', item.relatedRef),
              _detail('Updated at', item.updatedAt),
              _detail('Safe message preview', item.preview),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(item.title),
                      content: Text('Example only.\nCategory: ${item.category}\nChannel: ${item.channel}\nStatus: ${item.status}\nNo message was sent.'),
                      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View example'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send disabled'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Retry disabled'),
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
            SizedBox(width: 145, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _Notice {
  const _Notice(this.id, this.title, this.category, this.channel, this.status,
      this.relatedRef, this.updatedAt, this.preview);
  final String id, title, category, channel, status, relatedRef, updatedAt, preview;
}
