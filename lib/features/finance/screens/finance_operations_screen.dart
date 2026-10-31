import 'package:flutter/material.dart';

/// UI-only finance operations prototype aligned with POL-012 and POL-033.
class FinanceOperationsScreen extends StatefulWidget {
  const FinanceOperationsScreen({super.key});

  @override
  State<FinanceOperationsScreen> createState() => _FinanceOperationsScreenState();
}

class _FinanceOperationsScreenState extends State<FinanceOperationsScreen> {
  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);
  String tab = 'Payments';

  final payments = const [
    _FinanceRow('PAY-EX-001', 'BOOKING-EX-001', '₹1,499', 'PAYMENT_PENDING',
        'Provider confirmation not connected', '2026-10-28 09:15 IST'),
    _FinanceRow('PAY-EX-002', 'BOOKING-EX-002', '₹3,499', 'PAID_VERIFIED (example)',
        'Example status only; not a real payment', '2026-10-27 16:40 IST'),
    _FinanceRow('PAY-EX-003', 'BOOKING-EX-003', '₹649', 'DISPUTED',
        'Example reconciliation exception', '2026-10-26 12:05 IST'),
  ];

  final refunds = const [
    _FinanceRow('REF-EX-001', 'PAY-EX-003', '₹1,200', 'Pending review',
        'Central Admin review route (example)', '2026-10-28 09:20 IST'),
    _FinanceRow('REF-EX-002', 'PAY-EX-004', '₹2,500', 'Founder/CEO review',
        'Above ₹2,000 threshold; example routing only', '2026-10-27 15:10 IST'),
    _FinanceRow('REF-EX-003', 'PAY-EX-005', 'Amount withheld', 'Suspicious — escalate',
        'No refund decision until fraud/suspicion checks complete', '2026-10-26 10:00 IST'),
  ];

  final payouts = const [
    _FinanceRow('PAYOUT-EX-001', 'WALKER-EX-001', '₹2,860', 'Payable (example)',
        'Eligible completed walks require backend verification', '2026-10-28 08:00 IST'),
    _FinanceRow('PAYOUT-EX-002', 'WALKER-EX-002', '₹1,540', 'Payout failed',
        'Failure reason and retry provider not connected', '2026-10-27 12:00 IST'),
  ];

  final reconciliation = const [
    _FinanceRow('RECON-EX-001', 'GATEWAY-SETTLEMENT-EX-001', '₹4,998', 'Matched (example)',
        'Illustrative only; no provider settlement file was loaded', '2026-10-28 10:00 IST'),
    _FinanceRow('RECON-EX-002', 'GATEWAY-SETTLEMENT-EX-002', '₹1,200', 'Mismatch (example)',
        'Needs evidence review; do not mark paid or refunded from this preview', '2026-10-27 14:30 IST'),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = tab == 'Payments'
        ? payments
        : tab == 'Refunds'
            ? refunds
            : tab == 'Walker payouts'
                ? payouts
                : reconciliation;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Finance Operations'),
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
                const Text('Payments, Refunds & Payouts',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 8),
                const Text(
                  'UI prototype only. No payment gateway, bank settlement, refund API or payout provider is connected. Example amounts and statuses are not transactions.',
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
                      Icon(Icons.account_balance_wallet_outlined, color: orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cash is not accepted. Never mark a booking paid from a client-side event or walker report. Use trusted provider confirmation/reconciliation; never store gateway secrets, OTPs, UPI PINs or payment credentials in the app.',
                          style: TextStyle(color: ink, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in ['Payments', 'Refunds', 'Walker payouts', 'Reconciliation'])
                      ChoiceChip(
                        label: Text(value),
                        selected: tab == value,
                        selectedColor: orange.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() => tab = value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final row in rows) _rowCard(row),
                const SizedBox(height: 8),
                const Text(
                  'Verify, refund, adjust, approve, pay and reconcile actions are disabled until role authority, provider confirmation, idempotency, audit evidence and reconciliation controls are approved and tested.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowCard(_FinanceRow row) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.receipt_long_outlined, color: orange),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.id, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    Text('Related: ${row.related}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                )),
                Text(row.amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
              ]),
              const Divider(height: 24),
              _detail('Status', row.status),
              _detail('Control / note', row.note),
              _detail('Updated at', row.updatedAt),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verify disabled'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Approve disabled'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.sync_outlined),
                  label: const Text('Reconcile disabled'),
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
            SizedBox(width: 135, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _FinanceRow {
  const _FinanceRow(this.id, this.related, this.amount, this.status, this.note, this.updatedAt);
  final String id;
  final String related;
  final String amount;
  final String status;
  final String note;
  final String updatedAt;
}
