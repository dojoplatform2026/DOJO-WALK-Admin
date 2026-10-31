import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Server-authoritative client for the DOJO WALK Zone lifecycle.
///
/// Collection writes that affect approval, verification or service status
/// must go through the Firebase callable functions. This class intentionally
/// does not write Zone workflow fields directly to Firestore.
class ServiceZoneWorkflowService {
  ServiceZoneWorkflowService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _zones =>
      _firestore.collection('service_zones');

  /// Live Zone records. Reference hierarchy is loaded separately.
  Stream<List<ServiceZoneRecord>> watchZones({
    String? stateId,
    String? districtId,
    String? cityId,
  }) {
    Query<Map<String, dynamic>> query = _zones;
    if (stateId != null && stateId.isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateId);
    }
    if (districtId != null && districtId.isNotEmpty) {
      query = query.where('districtId', isEqualTo: districtId);
    }
    if (cityId != null && cityId.isNotEmpty) {
      query = query.where('cityId', isEqualTo: cityId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ServiceZoneRecord.fromMap(doc.id, doc.data()))
        .toList(growable: false));
  }

  /// Save or update a draft through the server-owned name-index transaction.
  Future<String> saveDraft({
    String? zoneId,
    required String stateId,
    required String districtId,
    required String cityId,
    required String name,
  }) async {
    final result = await _call('saveServiceLocationWithNameIndex', {
      'locationType': 'zone',
      if (zoneId != null && zoneId.isNotEmpty) 'locationId': zoneId,
      'payload': {
        'stateId': _required(stateId, 'State'),
        'districtId': _required(districtId, 'District'),
        'cityId': _required(cityId, 'City'),
        'name': _required(name, 'Zone name'),
      },
    });
    final id = result['locationId'] ?? result['id'];
    if (id is String && id.isNotEmpty) return id;
    // The callable currently returns the created document ID in its response;
    // fail closed if a future backend contract stops returning it.
    throw StateError('Zone save response did not contain a location ID.');
  }

  Future<Map<String, dynamic>> submitForFounderReview(
    String zoneId,
  ) =>
      _call('submitServiceZoneForFounderReview', {'zoneId': _required(zoneId, 'Zone ID')});

  Future<Map<String, dynamic>> reviewBoundary({
    required String boundaryId,
    required bool verified,
    required String notes,
  }) =>
      _call('reviewServiceLocationBoundary', {
        'boundaryId': _required(boundaryId, 'Boundary ID'),
        'decision': verified ? 'verified' : 'rejected',
        'notes': _required(notes, 'Review notes'),
      });

  Future<Map<String, dynamic>> decideFounderApproval({
    required String zoneId,
    required String decision,
    required String notes,
  }) {
    const decisions = {
      'approve',
      'reject',
      'changes_required',
      'deactivate',
      'reactivate',
    };
    if (!decisions.contains(decision)) {
      throw ArgumentError.value(decision, 'decision', 'Unsupported Founder decision.');
    }
    return _call('decideServiceZoneFounderApproval', {
      'zoneId': _required(zoneId, 'Zone ID'),
      'decision': decision,
      'notes': notes.trim(),
    });
  }

  Future<Map<String, dynamic>> activate(String zoneId) =>
      _call('activateServiceZone', {'zoneId': _required(zoneId, 'Zone ID')});

  Future<Map<String, dynamic>> requestDeactivation({
    required String zoneId,
    required String reason,
  }) =>
      _call('requestServiceZoneDeactivation', {
        'zoneId': _required(zoneId, 'Zone ID'),
        'notes': _required(reason, 'Deactivation reason'),
      });

  Future<Map<String, dynamic>> deactivate(String zoneId) =>
      _call('setServiceLocationStatus', {
        'locationType': 'zone',
        'locationId': _required(zoneId, 'Zone ID'),
        'isActive': false,
      });

  Future<Map<String, dynamic>> emergencySuspend({
    required String zoneId,
    required String reason,
    required String severity,
  }) {
    const severities = {'SEV-1', 'SEV-2', 'SEV-3', 'SEV-4'};
    if (!severities.contains(severity)) {
      throw ArgumentError.value(severity, 'severity', 'Unsupported severity.');
    }
    return _call('suspendServiceZoneForEmergency', {
      'zoneId': _required(zoneId, 'Zone ID'),
      'reason': _required(reason, 'Emergency reason'),
      'severity': severity,
    });
  }

  Future<Map<String, dynamic>> requestReactivation({
    required String zoneId,
    required String reason,
  }) =>
      _call('requestServiceZoneReactivation', {
        'zoneId': _required(zoneId, 'Zone ID'),
        'reason': _required(reason, 'Reactivation reason'),
      });

  String _required(String value, String label) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError('$label is required.');
    return normalized;
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final response = await _functions.httpsCallable(name).call(payload);
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'result': data};
  }
}

/// Read model for a Zone document. It exposes backend workflow fields without
/// granting the UI permission to mutate them directly.
class ServiceZoneRecord {
  const ServiceZoneRecord({
    required this.id,
    required this.name,
    required this.stateId,
    required this.districtId,
    required this.cityId,
    required this.isServiceActive,
    required this.workflowStatus,
    required this.revision,
    required this.verifiedBoundaryId,
    required this.approvedRevision,
    required this.approvedBoundaryHash,
    required this.submittedBoundaryHash,
  });

  final String id;
  final String name;
  final String stateId;
  final String districtId;
  final String cityId;
  final bool isServiceActive;
  final String workflowStatus;
  final int revision;
  final String? verifiedBoundaryId;
  final int? approvedRevision;
  final String? approvedBoundaryHash;
  final String? submittedBoundaryHash;

  factory ServiceZoneRecord.fromMap(
    String id,
    Map<String, dynamic> data,
  ) =>
      ServiceZoneRecord(
        id: id,
        name: data['name']?.toString() ?? '',
        stateId: data['stateId']?.toString() ?? '',
        districtId: data['districtId']?.toString() ?? '',
        cityId: data['cityId']?.toString() ?? '',
        isServiceActive: data['isServiceActive'] == true,
        workflowStatus: data['workflowStatus']?.toString() ?? 'draft',
        revision: (data['revision'] as num?)?.toInt() ?? 1,
        verifiedBoundaryId: data['verifiedBoundaryId']?.toString(),
        approvedRevision: (data['approvedRevision'] as num?)?.toInt(),
        approvedBoundaryHash: data['approvedBoundaryHash']?.toString(),
        submittedBoundaryHash: data['submittedBoundaryHash']?.toString(),
      );
}
