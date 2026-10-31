import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared helper functions for DOJO WALK Admin Walker Management.
///
/// This class contains formatting and data-reading helpers only.
/// Firestore writes and admin decisions belong in WalkerAdminService.
class WalkerAdminHelpers {
  WalkerAdminHelpers._();

  // ----------------------------------------------------------
  // STATUS
  // ----------------------------------------------------------

  /// Normalizes status values into a consistent format.
  ///
  /// Examples:
  /// "Under Review"      -> "under_review"
  /// "under-review"      -> "under_review"
  /// " CORRECTION_REQUIRED " -> "correction_required"
  static String normalizeStatus(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return 'pending';
    }

    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  /// Returns a human-readable status label.
  static String displayStatus(dynamic value) {
    final status = normalizeStatus(value);

    switch (status) {
      case 'under_review':
        return 'Under Review';

      case 'correction_required':
        return 'Correction Required';

      case 'active_walk':
      case 'walk_started':
      case 'walking':
      case 'running':
        return 'Running';

      case 'verified':
        return 'Verified';

      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'suspended':
        return 'Suspended';

      case 'inactive':
        return 'Inactive';

      case 'left':
      case 'offboarded':
        return 'Offboarded';

      case 'training_required':
        return 'Training Required';

      case 'pending':
        return 'Pending';

      case 'finding_walker':
        return 'Finding Walker';

      case 'walker_assigned':
        return 'Walker Assigned';

      case 'walker_arriving':
        return 'Walker Arriving';

      case 'in_progress':
        return 'In Progress';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      case 'active':
        return 'Active';

      case 'unknown':
        return 'Unknown';

      default:
        return status
            .split('_')
            .where((word) => word.isNotEmpty)
            .map(_capitalize)
            .join(' ');
    }
  }

  /// Checks the verification status.
  static bool isVerified(Map<String, dynamic> data) {
    return normalizeStatus(data['verificationStatus']) == 'verified';
  }

  /// Checks whether the walker has been approved.
  static bool isApproved(Map<String, dynamic> data) {
    return data['isApproved'] == true;
  }

  /// Checks whether the walker account is active.
  static bool isActive(Map<String, dynamic> data) {
    return data['isActive'] == true;
  }

  /// Checks whether the walker is eligible for availability.
  ///
  /// This checks account state only.
  /// It does not check booking conflicts, location, or live GPS.
  static bool isEligibleForAvailability(
    Map<String, dynamic> data,
  ) {
    return normalizeStatus(data['status']) == 'approved' &&
        isVerified(data) &&
        isApproved(data) &&
        isActive(data);
  }

  /// Identifies an application awaiting admin review.
  ///
  /// A submitted application is not automatically approved.
  static bool isApplicationUnderReview(
    Map<String, dynamic> data,
  ) {
    final status = normalizeStatus(data['status']);
    final verificationStatus =
        normalizeStatus(data['verificationStatus']);

    const excludedStatuses = {
      'approved',
      'rejected',
      'suspended',
      'inactive',
      'left',
      'offboarded',
      'training_required',
    };

    if (excludedStatuses.contains(status)) {
      return false;
    }

    if (verificationStatus == 'verified' ||
        verificationStatus == 'rejected') {
      return false;
    }

    return data['applicationSubmitted'] == true ||
        status == 'under_review' ||
        status == 'correction_required' ||
        verificationStatus == 'under_review' ||
        verificationStatus == 'correction_required';
  }

  /// Identifies rejected applications.
  static bool isRejected(Map<String, dynamic> data) {
    return normalizeStatus(data['status']) == 'rejected' ||
        normalizeStatus(data['verificationStatus']) == 'rejected';
  }

  /// Identifies walkers who still require training before matching.
  static bool isTrainingRequired(Map<String, dynamic> data) {
    return normalizeStatus(data['status']) == 'training_required';
  }

  /// Identifies approved walkers who are inactive, plus inactive/offboarded
  /// legacy account states that must not receive new booking offers.
  static bool isInactiveOrOffboarded(Map<String, dynamic> data) {
    final status = normalizeStatus(data['status']);
    return (status == 'approved' && isApproved(data) && !isActive(data)) ||
        status == 'inactive' ||
        status == 'left' ||
        status == 'offboarded';
  }

  /// Identifies suspended walker accounts.
  static bool isSuspended(Map<String, dynamic> data) {
    return normalizeStatus(data['status']) == 'suspended';
  }

  /// Identifies walker accounts that should not be treated as active.
  static bool isUnavailableAccount(Map<String, dynamic> data) {
    final status = normalizeStatus(data['status']);

    return status == 'rejected' ||
        status == 'suspended' ||
        status == 'inactive' ||
        status == 'left' ||
        !isVerified(data) ||
        !isApproved(data) ||
        !isActive(data);
  }

  // ----------------------------------------------------------
  // STRING AND PROFILE DATA
  // ----------------------------------------------------------

  /// Returns a non-empty string from the first matching field.
  static String? firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  /// Returns the first non-empty display value.
  ///
  /// Supports strings and simple numeric values.
  static String? firstDisplayValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      if (value is String) {
        if (value.trim().isNotEmpty) {
          return value.trim();
        }
        continue;
      }

      if (value is num || value is bool) {
        return value.toString();
      }
    }

    return null;
  }

  /// Returns the walker's display name.
  static String walkerName(Map<String, dynamic> data) {
    return firstString(data, [
          'name',
          'fullName',
          'displayName',
        ]) ??
        'Walker';
  }

  /// Returns the walker's phone number.
  static String? phoneNumber(Map<String, dynamic> data) {
    return firstString(data, [
      'phoneNumber',
      'phone',
      'mobile',
    ]);
  }

  /// Returns the walker's profile photo reference.
  static String? photoUrl(Map<String, dynamic> data) {
    return firstString(data, [
      'photoUrl',
      'profilePhotoUrl',
      'profilePhoto',
      'profileImage',
      'profileImageUrl',
    ]);
  }

  /// Returns the walker's email address.
  static String? email(Map<String, dynamic> data) {
    return firstString(data, ['email']);
  }

  // ----------------------------------------------------------
  // MAP AND LOCATION
  // ----------------------------------------------------------

  /// Safely converts a Map to Map<String, dynamic>.
  ///
  /// Returns an empty map for unsupported values.
  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      final result = <String, dynamic>{};

      for (final entry in value.entries) {
        if (entry.key is String) {
          result[entry.key as String] = entry.value;
        }
      }

      return result;
    }

    return <String, dynamic>{};
  }

  /// Reads a nested address field with a fallback.
  static String? nestedString(
    Map<String, dynamic> data, {
    required List<String> mapKeys,
    required List<String> fieldKeys,
  }) {
    for (final mapKey in mapKeys) {
      final nested = asMap(data[mapKey]);
      final value = firstString(nested, fieldKeys);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  /// Builds a readable location from flat or nested fields.
  ///
  /// Supports area, city and state stored directly in the document,
  /// with fallbacks to currentAddress or address maps.
  static String locationLabel(Map<String, dynamic> data) {
    final addressKeys = ['currentAddress', 'address'];

    final area = firstString(data, ['area', 'locality']) ??
        nestedString(
          data,
          mapKeys: addressKeys,
          fieldKeys: ['area', 'locality', 'localityName'],
        );

    final city = firstString(data, ['city']) ??
        nestedString(
          data,
          mapKeys: addressKeys,
          fieldKeys: ['city', 'district'],
        );

    final state = firstString(data, ['state', 'stateName']) ??
        nestedString(
          data,
          mapKeys: addressKeys,
          fieldKeys: ['state', 'stateName'],
        );

    final parts = <String>[];

    for (final value in [area, city, state]) {
      if (value == null || value.trim().isEmpty) continue;

      final cleanValue = value.trim();

      final alreadyExists = parts.any(
        (part) => part.toLowerCase() == cleanValue.toLowerCase(),
      );

      if (!alreadyExists) {
        parts.add(cleanValue);
      }
    }

    return parts.isEmpty
        ? 'Location not provided'
        : parts.join(', ');
  }

  // ----------------------------------------------------------
  // DATE AND TIME
  // ----------------------------------------------------------

  /// Converts supported Firestore and application date values.
  static DateTime? toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }

  /// Formats a date as DD/MM/YYYY.
  static String formatDate(dynamic value) {
    final date = toDateTime(value);

    if (date == null) {
      return 'Not available';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  /// Formats a date and time for admin display.
  static String formatDateTime(dynamic value) {
    final date = toDateTime(value);

    if (date == null) {
      return 'Not available';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // ----------------------------------------------------------
  // DOCUMENTS AND KYC
  // ----------------------------------------------------------

  /// Extracts a direct URL or Firebase Storage path from a document.
  ///
  /// Supported formats:
  /// - URL or Storage path string.
  /// - Map with downloadUrl or url.
  /// - Map with storagePath or path.
  static String? documentReference(dynamic document) {
    if (document is String && document.trim().isNotEmpty) {
      return document.trim();
    }

    if (document is Map) {
      final map = asMap(document);

      final url = firstString(
        map,
        ['downloadUrl', 'url'],
      );

      if (url != null) {
        return url;
      }

      final path = firstString(
        map,
        ['storagePath', 'path'],
      );

      if (path != null) {
        return path;
      }
    }

    return null;
  }

  /// Checks whether a reference is a valid HTTP or HTTPS URL.
  static bool isHttpUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(value.trim());

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Checks whether a document has a non-empty reference.
  ///
  /// This does not prove that the remote file exists or that the
  /// current admin is allowed to read it.
  static bool hasDocumentReference(dynamic document) {
    return documentReference(document) != null;
  }

  // ----------------------------------------------------------
  // INTERNAL
  // ----------------------------------------------------------

  static String _capitalize(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
