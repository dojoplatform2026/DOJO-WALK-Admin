import 'package:flutter/material.dart';

/// UI-only prototype. Sample rows are not live audit_logs records.
class ZoneAuditHistoryScreen extends StatefulWidget {
  const ZoneAuditHistoryScreen({super.key});

  @override
  State<ZoneAuditHistoryScreen> createState() => _ZoneAuditHistoryScreenState();
}

class _ZoneAuditHistoryScreenState extends State<ZoneAuditHistoryScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _background = Color(0xFFFFFAF5);
  final _search = TextEditingController();
  String _query = '';

  final _entries = const <_AuditEntry>[
    _AuditEntry('Zone readiness submitted', 'Illustrative Zone A', 'Central Admin', 'Submitted', 'Example · 28 Oct 2026, 10:15 IST', Icons.upload_file_outlined),
    _AuditEntry('Boundary revision requested', 'Illustrative Zone B', 'Founder / CEO', 'Needs changes', 'Example · 28 Oct 2026, 09:42 IST', Icons.edit_location_alt_outlined),
    _AuditEntry('Zone suspended for safety review', 'Illustrative Zone C', 'Central Admin', 'Suspended', 'Example · 27 Oct 2026, 18:30 IST', Icons.pause_circle_outline),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final visible = _entries.where((e) =>
      '${e.event} ${e.zone} ${e.actor} ${e.status}'.toLowerCase().contains(_query.trim().toLowerCase())).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Zone Audit History'), backgroundColor: Colors.white, foregroundColor: const Color(0xFF252525)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade200), borderRadius: BorderRadius.circular(14)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Colors.brown),
              SizedBox(width: 10),
              Expanded(child: Text('UI preview only. These sample entries are not real audit records. Live audit_logs connection and server-side pagination are not connected yet.')),
            ]),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search event, zone, actor or status',
              prefixIcon: const Icon(Icons.search, color: _orange),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('Recent events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            Text('${visible.length} examples', style: const TextStyle(color: Colors.black54)),
          ]),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const Card(color: Colors.white, child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No matching example events'))))
          else
            ...visible.map((e) => Card(
              color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFECE5DE))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: _orange.withValues(alpha: 0.12),
                          child: Icon(e.icon, color: _orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.event,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      e.zone,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Actor: ${e.actor}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(e.time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e.status,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _AuditEntry {
  const _AuditEntry(this.event, this.zone, this.actor, this.status, this.time, this.icon);
  final String event, zone, actor, status, time;
  final IconData icon;
}
