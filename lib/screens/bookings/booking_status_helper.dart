/// Normalizes Firestore booking status values for the Admin UI.
String displayBookingStatus(dynamic rawValue) {
  final raw = rawValue?.toString().trim() ?? '';
  if (raw.isEmpty) return 'Unknown';

  final normalized = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  switch (normalized) {
    case 'pending':
      return 'Pending';
    case 'finding walker':
      return 'Finding Walker';
    case 'walker arriving':
      return 'Walker Arriving';
    case 'walker assigned':
    case 'assigned':
      return 'Walker Assigned';
    case 'picked up':
    case 'pickup complete':
      return 'Picked Up';
    case 'walker accepted':
    case 'accepted':
      return 'Walker Accepted';
    case 'confirmed':
      return 'Confirmed';
    case 'in progress':
    case 'walk in progress':
    case 'active walk':
    case 'walking':
    case 'walk started':
      return 'Walk In Progress';
    case 'completed':
    case 'complete':
      return 'Completed';
    case 'cancelled':
    case 'canceled':
      return 'Cancelled';
    default:
      // Preserve unknown statuses for investigation instead of silently
      // mapping them to an unrelated lifecycle state.
      return raw;
  }
}

/// Returns an empty-state message that reflects both search and status filters.
String bookingEmptyStateMessage({
  required int totalRecords,
  required String search,
  required String selectedStatus,
}) {
  if (totalRecords == 0) return 'No bookings found in Firestore.';

  final hasSearch = search.trim().isNotEmpty;
  final hasStatus = selectedStatus != 'All';

  if (hasSearch && hasStatus) {
    return 'No bookings match your search and selected status.';
  }
  if (hasSearch) return 'No bookings match your search.';
  if (hasStatus) return 'No bookings with status "$selectedStatus".';
  return 'No bookings match the current filters.';
}

/// Known raw Firestore values for each canonical booking lifecycle label.
/// Keep this list in sync with [displayBookingStatus] so Dashboard counts
/// do not silently miss legacy capitalization/underscore variants.
List<String> bookingStatusQueryAliases(String canonicalLabel) {
  switch (canonicalLabel) {
    case 'Pending':
      return const ['pending', 'Pending'];
    case 'Finding Walker':
      return const ['finding_walker', 'finding-walker', 'finding walker'];
    case 'Walker Arriving':
      return const ['walker_arriving', 'walker-arriving', 'walker arriving'];
    case 'Walker Assigned':
      return const ['assigned', 'walker_assigned', 'walker-assigned', 'walker assigned', 'Walker Assigned'];
    case 'Walker Accepted':
      return const ['accepted', 'walker_accepted', 'walker-accepted', 'walker accepted', 'Walker Accepted'];
    case 'Confirmed':
      return const ['confirmed', 'Confirmed'];
    case 'Picked Up':
      return const ['picked_up', 'picked-up', 'picked up', 'Picked Up', 'pickup_complete', 'pickup-complete'];
    case 'Walk In Progress':
      return const [
        'walking',
        'in_progress',
        'in-progress',
        'walk in progress',
        'Walk In Progress',
        'walk_started',
        'walk-started',
        'walk started',
        'active_walk',
        'active-walk',
        'active walk',
      ];
    case 'Completed':
      return const ['completed', 'Completed', 'complete', 'Complete'];
    case 'Cancelled':
      return const ['cancelled', 'canceled', 'Cancelled', 'Canceled'];
    default:
      return const [];
  }
}

/// Status options exposed by the Admin booking filter.
/// Keep this list aligned with the canonical lifecycle labels above.
const List<String> bookingFilterStatuses = [
  'All',
  'Pending',
  'Finding Walker',
  'Walker Assigned',
  'Walker Arriving',
  'Walker Accepted',
  'Confirmed',
  'Picked Up',
  'Walk In Progress',
  'Completed',
  'Cancelled',
];
