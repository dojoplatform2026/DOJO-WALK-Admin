import 'package:flutter/material.dart';

import 'boundary_review_screen.dart';
import 'zone_approval_queue_screen.dart';

/// UI-only Zone details prototype. Values are passed from example directory rows.
class ZoneDetailsScreen extends StatelessWidget {
  const ZoneDetailsScreen({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.parentPath,
    required this.status,
    required this.revision,
    required this.boundaryStatus,
    required this.readinessBlocker,
    required this.updatedAt,
    required this.updatedBy,
  });

  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);

  final String zoneId;
  final String zoneName;
  final String parentPath;
  final String status;
  final String revision;
  final String boundaryStatus;
  final String readinessBlocker;
  final String updatedAt;
  final String updatedBy;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFFFAF5),
        appBar: AppBar(
          title: const Text('Zone Details'),
          backgroundColor: Colors.white,
          foregroundColor: ink,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zoneName,
                      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 6),
                  Text('$zoneId · $revision', style: const TextStyle(color: Colors.black54)),
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
                        Icon(Icons.info_outline, color: orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Example record only. This detail view is not connected to the Zone service and cannot save, approve, activate, suspend or deactivate a Zone.',
                            style: TextStyle(color: ink, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'Hierarchy & lifecycle',
                    [
                      _detail('Parent path', parentPath),
                      _detail('Zone status', status),
                      _detail('Revision', revision),
                    ],
                  ),
                  _section(
                    'Boundary & readiness',
                    [
                      _detail('Boundary status', boundaryStatus),
                      _detail('Readiness blockers', readinessBlocker),
                      _detail('Activation rule', 'Zone only; Founder/CEO approval is separate from activation.'),
                    ],
                  ),
                  _section(
                    'Audit metadata',
                    [
                      _detail('Last updated', updatedAt),
                      _detail('Updated by', updatedBy),
                      _detail('Boundary integrity', 'Live hash not loaded in this prototype.'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => BoundaryReviewScreen(focusZoneId: zoneId)),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Preview boundary review'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => ZoneApprovalQueueScreen(focusZoneId: zoneId)),
                      ),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Preview approval queue'),
                    ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit disabled'),
                    ),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Lifecycle action disabled'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );

  static Widget _section(String title, List<Widget> children) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      );

  static Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelStyle = const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            );
            final valueStyle = const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );

            if (constraints.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: labelStyle),
                  const SizedBox(height: 4),
                  Text(value, style: valueStyle),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 170, child: Text(label, style: labelStyle)),
                Expanded(child: Text(value, style: valueStyle)),
              ],
            );
          },
        ),
      );
}
