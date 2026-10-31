import 'package:flutter/material.dart';

import '../services/walker_admin_service.dart';
import '../utils/walker_admin_helpers.dart';

const Color _activityOrange = Color(0xFFFF7900);
const Color _activityText = Color(0xFF292524);
const Color _activityMuted = Color(0xFF78716C);
const Color _activityBorder = Color(0xFFE7E5E4);
const Color _activityBackground = Color(0xFFFFFAF5);

Future<void> showWalkerActivityHistoryDialog({
  required BuildContext context,
  required WalkerAdminService service,
  required String walkerId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => WalkerActivityHistoryDialog(
      service: service,
      walkerId: walkerId,
    ),
  );
}

class WalkerActivityHistoryDialog extends StatelessWidget {
  const WalkerActivityHistoryDialog({
    super.key,
    required this.service,
    required this.walkerId,
  });

  final WalkerAdminService service;
  final String walkerId;

  String _text(dynamic value, {String fallback = '—'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _date(dynamic value) {
    final date = WalkerAdminHelpers.toDateTime(value);

    if (date == null) return 'Date unavailable';

    return WalkerAdminHelpers.formatDateTime(date);
  }

  String _actionLabel(dynamic value) {
    var action = WalkerAdminHelpers.normalizeStatus(value);

    if (action.isEmpty) return 'Activity';
    if (action.startsWith('walker_')) {
      action = action.substring('walker_'.length);
    }

    return WalkerAdminHelpers.displayStatus(action);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 650,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: _activityBorder),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.watchWalkerAuditLogs(
                  walkerId,
                  limit: 50,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _message(
                      icon: Icons.error_outline,
                      title: 'Unable to load activity',
                      subtitle:
                          'Please check the connection and try again.',
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _activityOrange,
                      ),
                    );
                  }

                  final logs =
                      snapshot.data ?? <Map<String, dynamic>>[];

                  if (logs.isEmpty) {
                    return _message(
                      icon: Icons.history,
                      title: 'No activity found',
                      subtitle:
                          'Admin activity for this walker will appear here.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(
                      height: 12,
                    ),
                    itemBuilder: (context, index) {
                      final log = logs[index];

                      final action = _text(
                        log['action'],
                        fallback: 'activity',
                      );

                      final reason = _text(
                        log['reason'],
                        fallback: '',
                      );

                      final actor = _text(
                        log['actorUid'] ?? log['adminUid'],
                        fallback: 'Unknown admin',
                      );

                      final beforeStatus = _text(
                        log['beforeStatus'],
                        fallback: '',
                      );

                      final afterStatus = _text(
                        log['afterStatus'],
                        fallback: '',
                      );

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _activityBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _activityBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _activityOrange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: _activityOrange,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _actionLabel(action),
                                        style: const TextStyle(
                                          color: _activityText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _date(log['createdAt']),
                                        style: const TextStyle(
                                          color: _activityMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _detail('Admin', actor),
                            if (beforeStatus.isNotEmpty)
                              _detail('Previous status', beforeStatus),
                            if (afterStatus.isNotEmpty)
                              _detail('New status', afterStatus),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Reason',
                                style: TextStyle(
                                  color: _activityMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reason,
                                style: const TextStyle(
                                  color: _activityText,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity History',
                  style: TextStyle(
                    color: _activityText,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Recent administrative actions for this walker',
                  style: TextStyle(
                    color: _activityMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: _activityMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _activityText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: _activityMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _activityText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _activityMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
