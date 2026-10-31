import 'package:cloud_firestore/cloud_firestore.dart';

/// Builds a minimal operational summary for Live Operations.
/// Never dump arbitrary booking document fields into an Admin dialog.
Map<String, String> safeLiveBookingSummary(Map<String, dynamic> data) {
  const labels = <String, String>{
    'status': 'Status',
    'customerId': 'Customer ID',
    'walkerId': 'Walker ID',
    'walkId': 'Walk ID',
    'zoneId': 'Zone ID',
    'scheduledAt': 'Scheduled at',
    'startAt': 'Walk started at',
    'completedAt': 'Walk completed at',
    'durationMinutes': 'Duration (minutes)',
    'serviceDurationMinutes': 'Service duration (minutes)',
    'dogCount': 'Dog count',
  };

  final summary = <String, String>{};
  for (final entry in labels.entries) {
    final value = data[entry.key];
    if (value == null) continue;
    if (value is Timestamp) {
      summary[entry.value] = value.toDate().toLocal().toString();
    } else if (value is DateTime) {
      summary[entry.value] = value.toLocal().toString();
    } else {
      summary[entry.value] = value.toString();
    }
  }
  return summary;
}
