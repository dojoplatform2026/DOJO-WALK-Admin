import 'package:flutter/material.dart';

/// UI-only prototype aligned with POL-031 and POL-021. Example records only.
class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);
  final search = TextEditingController();
  String status = 'All';

  final examples = const [
    _Customer('CUS-EX-001', 'Example Customer A', '+91 ••••• ••104',
        'customer-a@example.invalid', 'Active', 'Not verified in preview',
        'Example terms v1', 'Not recorded', '2026-10-28 09:15 IST'),
    _Customer('CUS-EX-002', 'Example Customer B', '+91 ••••• ••287',
        'customer-b@example.invalid', 'Verification pending', 'Review required',
        'Not recorded', 'Not recorded', '2026-10-27 16:40 IST'),
    _Customer('CUS-EX-003', 'Example Customer C', '+91 ••••• ••531',
        'customer-c@example.invalid', 'Under review', 'Not verified in preview',
        'Example terms v1', 'Optional consent not assumed', '2026-10-26 12:05 IST'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final visible = examples.where((c) {
      final matchesQuery = q.isEmpty ||
          '${c.id} ${c.name} ${c.phone} ${c.email}'.toLowerCase().contains(q);
      return matchesQuery && (status == 'All' || c.status == status);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Customer Management'),
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
                const Text('Customer Accounts',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 8),
                const Text(
                  'UI prototype only. Example records are not connected to customer data.',
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
                      Icon(Icons.privacy_tip_outlined, color: orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Privacy guard: contact details are masked. Never request passwords, OTPs, PINs or payment authentication secrets. Optional marketing consent is not assumed.',
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
                    hintText: 'Search customer name, ID or masked contact',
                    prefixIcon: const Icon(Icons.search, color: orange),
                    suffixIcon: search.text.isEmpty ? null : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () { search.clear(); setState(() {}); },
                      icon: const Icon(Icons.close),
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
                  children: [
                    for (final value in ['All', 'Active', 'Verification pending', 'Under review', 'Suspended', 'Closure requested'])
                      ChoiceChip(
                        label: Text(value),
                        selected: status == value,
                        selectedColor: orange.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() => status = value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No example customers match these filters. Live records are not connected.'),
                  ))
                else
                  for (final customer in visible) _customerCard(customer),
                const SizedBox(height: 8),
                const Text(
                  'Account restriction, closure and deletion actions are disabled. Real actions require authorized scope, a reason, audit logging and safe handling of active bookings/walks.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customerCard(_Customer c) => Card(
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
              final identity = Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.person_outline, color: orange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        Text(
                          c.id,
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
              final statusChip = Chip(label: Text(c.status));

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
          Wrap(spacing: 22, runSpacing: 14, children: [
            _detail('Phone (masked)', c.phone),
            _detail('Email (example)', c.email),
            _detail('Age eligibility', c.eligibility),
            _detail('Terms version', c.terms),
            _detail('Marketing consent', c.consent),
            _detail('Last updated', c.updated),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(c.name),
                  content: Text('Example record only.\nCustomer ID: ${c.id}\nPhone: ${c.phone}\nEmail: ${c.email}\nNo live customer data was accessed.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View example profile'),
            ),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Restrict disabled'),
            ),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Close account disabled'),
            ),
          ]),
        ],
      ),
    ),
  );

  Widget _detail(String label, String value) => SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Customer {
  const _Customer(this.id, this.name, this.phone, this.email, this.status,
      this.eligibility, this.terms, this.consent, this.updated);
  final String id, name, phone, email, status, eligibility, terms, consent, updated;
}
