import 'package:cloud_functions/cloud_functions.dart';

/// Typed adapter for trusted service-location callable APIs.
///
/// All callables are deployed in asia-south1 and enforce authorization on the
/// server. Never replace these calls with direct writes to activation/status
/// or boundary-review fields.
class AdminLocationCallables {
  AdminLocationCallables({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  Future<void> setStatus({
    required String locationType,
    required String locationId,
    required bool isActive,
  }) async {
    _requireNonEmpty(locationType, 'Location type');
    _requireNonEmpty(locationId, 'Location ID');

    await _functions.httpsCallable('setServiceLocationStatus').call<void>({
      'locationType': locationType,
      'locationId': locationId,
      'isActive': isActive,
    });
  }

  Future<void> activateBoundaryLocation({
    required String locationType,
    required String locationId,
  }) async {
    if (locationType != 'city' && locationType != 'area') {
      throw ArgumentError.value(
        locationType,
        'locationType',
        'Only city and area can use verified-boundary activation.',
      );
    }
    _requireNonEmpty(locationId, 'Location ID');

    await _functions.httpsCallable('activateServiceLocation').call<void>({
      'locationType': locationType,
      'locationId': locationId,
    });
  }

  Future<void> reviewBoundary({
    required String boundaryId,
    required String decision,
    required String notes,
  }) async {
    _requireNonEmpty(boundaryId, 'Boundary ID');
    if (decision != 'verified' && decision != 'rejected') {
      throw ArgumentError.value(
        decision,
        'decision',
        'Decision must be verified or rejected.',
      );
    }
    final trimmedNotes = notes.trim();
    if (trimmedNotes.isEmpty || trimmedNotes.length > 2000) {
      throw ArgumentError.value(
        notes,
        'notes',
        'Review notes must contain 1 to 2000 characters.',
      );
    }

    await _functions.httpsCallable('reviewServiceLocationBoundary').call<void>({
      'boundaryId': boundaryId,
      'decision': decision,
      'notes': trimmedNotes,
    });
  }

  void _requireNonEmpty(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$field is required.');
    }
  }
}
