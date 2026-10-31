import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/service_zone_workflow_service.dart';

void main() {
  group('ServiceZoneRecord', () {
    test('parses the canonical Zone fields from Firebase', () {
      final zone = ServiceZoneRecord.fromMap('zone-123', {
        'name': 'Crossings Republik North',
        'stateId': 'up',
        'districtId': 'gbn',
        'cityId': 'ghaziabad',
        'isServiceActive': true,
        'workflowStatus': 'active',
        'revision': 4,
        'verifiedBoundaryId': 'boundary-123',
        'approvedRevision': 4,
        'approvedBoundaryHash': 'approved-hash',
        'submittedBoundaryHash': 'approved-hash',
      });

      expect(zone.id, 'zone-123');
      expect(zone.name, 'Crossings Republik North');
      expect(zone.stateId, 'up');
      expect(zone.districtId, 'gbn');
      expect(zone.cityId, 'ghaziabad');
      expect(zone.isServiceActive, isTrue);
      expect(zone.workflowStatus, 'active');
      expect(zone.revision, 4);
      expect(zone.verifiedBoundaryId, 'boundary-123');
      expect(zone.approvedRevision, 4);
      expect(zone.approvedBoundaryHash, 'approved-hash');
      expect(zone.submittedBoundaryHash, 'approved-hash');
    });

    test('uses safe defaults for incomplete legacy documents', () {
      final zone = ServiceZoneRecord.fromMap('draft-zone', const {});

      expect(zone.id, 'draft-zone');
      expect(zone.name, isEmpty);
      expect(zone.isServiceActive, isFalse);
      expect(zone.workflowStatus, 'draft');
      expect(zone.revision, 1);
      expect(zone.verifiedBoundaryId, isNull);
      expect(zone.approvedRevision, isNull);
      expect(zone.approvedBoundaryHash, isNull);
      expect(zone.submittedBoundaryHash, isNull);
    });
  });
}
