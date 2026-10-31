import 'package:flutter/material.dart';

import '../models/walker_admin_model.dart';
import '../utils/walker_admin_helpers.dart';
import 'walker_admin_widgets.dart';

/// UI sections used by WalkerDetailsScreen.
///
/// This widget only displays walker information.
/// Administrative actions remain in WalkerAdminService.
class WalkerDetailsSections extends StatelessWidget {
  const WalkerDetailsSections({
    super.key,
    required this.walker,
    required this.onOpenDocument,
  });

  final WalkerAdminModel walker;

  /// Opens a KYC document using the existing document viewer.
  final void Function(String title, dynamic document) onOpenDocument;

  static const Color _orange = Color(0xFFFF7900);
  static const Color _text = Color(0xFF292524);
  static const Color _muted = Color(0xFF78716C);
  static const Color _border = Color(0xFFE7E5E4);
  static const Color _background = Color(0xFFFFFAF5);
  static const Color _green = Color(0xFF15803D);
  static const Color _blue = Color(0xFF1D4ED8);
  static const Color _red = Color(0xFFB91C1C);

  Map<String, dynamic> get _data => walker.rawData;

  Map<String, dynamic> get _kyc {
    return WalkerAdminHelpers.asMap(_data['kyc']);
  }

  Map<String, dynamic> get _documents {
    return WalkerAdminHelpers.asMap(_kyc['documents']);
  }

  String _value(
    List<String> keys, {
    String fallback = 'Not provided',
  }) {
    for (final key in keys) {
      final value = _data[key];

      if (value == null) continue;

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      if (value is Map || value is List) continue;

      return value.toString();
    }

    return fallback;
  }

  String _nestedValue(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = 'Not provided',
  }) {
    for (final key in keys) {
      final value = source[key];

      if (value == null) continue;

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      if (value is Map || value is List) continue;

      return value.toString();
    }

    return fallback;
  }

  String _dateValue(dynamic value) {
    return WalkerAdminHelpers.formatDate(value);
  }

  String _dateTimeValue(dynamic value) {
    return WalkerAdminHelpers.formatDateTime(value);
  }

  String _displayDate(List<String> keys) {
    for (final key in keys) {
      final value = _data[key];

      if (value != null) {
        return _dateValue(value);
      }
    }

    return 'Not provided';
  }

  String _displayDateTime(List<String> keys) {
    for (final key in keys) {
      final value = _data[key];

      if (value != null) {
        return _dateTimeValue(value);
      }
    }

    return 'Not provided';
  }

  String _listValue(dynamic value) {
    if (value is List) {
      final items = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      return items.isEmpty ? 'Not provided' : items.join(', ');
    }

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return 'Not provided';
  }

  String _addressValue() {
    final address = WalkerAdminHelpers.asMap(
      _data['currentAddress'] ?? _data['address'],
    );

    final parts = <String>[
      _nestedValue(
        address,
        ['flatHouse', 'houseNumber', 'flat'],
      ),
      _nestedValue(
        address,
        ['area', 'locality', 'street'],
      ),
      _nestedValue(address, ['landmark']),
      _nestedValue(address, ['city']),
      _nestedValue(address, ['state']),
      _nestedValue(address, ['pincode', 'postalCode']),
    ].where((part) => part != 'Not provided').toList();

    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String _documentReference(String key) {
    final document = _documents[key];

    if (document == null) {
      return '';
    }

    return WalkerAdminHelpers.documentReference(document) ?? '';
  }

  bool _hasDocument(String key) {
    final reference = _documentReference(key).trim();

    return reference.isNotEmpty;
  }

  String _documentSubtitle(String key) {
    final document = _documents[key];

    if (document == null) {
      return 'Document not uploaded';
    }

    if (document is Map) {
      final map = Map<String, dynamic>.from(document);

      final fileName = _nestedValue(
        map,
        ['fileName', 'filename', 'name', 'originalName'],
        fallback: '',
      );

      if (fileName.isNotEmpty) {
        return fileName;
      }
    }

    return _hasDocument(key)
        ? 'Document available — tap to view'
        : 'Document reference unavailable';
  }

  Color _statusColor(String status) {
    switch (WalkerAdminHelpers.normalizeStatus(status)) {
      case 'approved':
      case 'verified':
      case 'active':
      case 'completed':
        return _green;

      case 'rejected':
      case 'suspended':
      case 'inactive':
        return _red;

      case 'under_review':
      case 'pending':
      case 'correction_required':
        return _orange;

      default:
        return _blue;
    }
  }

  Widget _statusBadge(String status) {
    final normalized = WalkerAdminHelpers.normalizeStatus(status);
    final color = _statusColor(normalized);
    final label = WalkerAdminHelpers.displayStatus(normalized);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        softWrap: true,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return WalkerAdminSection(
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _info({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return WalkerAdminInfoRow(
      label: label,
      value: value,
      icon: icon,
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;

        return GridView.count(
          crossAxisCount: isWide ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 16,
          childAspectRatio: isWide ? 3.6 : 2.8,
          children: children,
        );
      },
    );
  }

  /// Displays a KYC document.
  ///
  /// The callback is always non-null because WalkerAdminKycDocumentTile
  /// requires a VoidCallback. The tile itself disables View when the
  /// document is unavailable.
  Widget _document({
    required String title,
    required String key,
  }) {
    final available = _hasDocument(key);

    return WalkerAdminKycDocumentTile(
      title: title,
      subtitle: _documentSubtitle(key),
      isAvailable: available,
      onView: () {
        if (!available) return;

        onOpenDocument(
          title,
          _documents[key],
        );
      },
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceSnapshot() {
    final totalWalks = _value(
      ['totalWalks', 'totalBookings', 'completedWalksCount'],
      fallback: 'Not available',
    );

    final completedWalks = _value(
      ['completedWalks', 'completedBookings'],
      fallback: 'Not available',
    );

    final rating = _value(
      ['averageRating', 'rating', 'average_rating'],
      fallback: 'Not available',
    );

    final cancellations = _value(
      ['cancelledWalks', 'cancelledBookings'],
      fallback: 'Not available',
    );

    return _section(
      title: 'Performance Snapshot',
      icon: Icons.insights_outlined,
      children: [
        _grid([
          _metric(
            label: 'Total Walks',
            value: totalWalks,
            icon: Icons.directions_walk_outlined,
          ),
          _metric(
            label: 'Completed Walks',
            value: completedWalks,
            icon: Icons.check_circle_outline,
          ),
          _metric(
            label: 'Average Rating',
            value: rating,
            icon: Icons.star_outline,
          ),
          _metric(
            label: 'Cancelled Walks',
            value: cancellations,
            icon: Icons.event_busy_outlined,
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          title: 'Personal Details',
          icon: Icons.person_outline,
          children: [
            _grid([
              _info(
                label: 'Full Name',
                value: walker.name,
                icon: Icons.badge_outlined,
              ),
              _info(
                label: 'Phone Number',
                value: walker.phoneNumber?.trim().isNotEmpty == true
                    ? walker.phoneNumber!.trim()
                    : 'Not provided',
                icon: Icons.phone_outlined,
              ),
              _info(
                label: 'Email',
                value: walker.email?.trim().isNotEmpty == true
                    ? walker.email!.trim()
                    : 'Not provided',
                icon: Icons.email_outlined,
              ),
              _info(
                label: 'Gender',
                value: _value(['gender']),
                icon: Icons.person_outline,
              ),
              _info(
                label: 'Date of Birth',
                value: _displayDate([
                  'dateOfBirth',
                  'dob',
                ]),
                icon: Icons.cake_outlined,
              ),
              _info(
                label: 'Account Created',
                value: _displayDate([
                  'createdAt',
                ]),
                icon: Icons.calendar_today_outlined,
              ),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        _section(
          title: 'Current Address',
          icon: Icons.home_outlined,
          children: [
            _info(
              label: 'Full Address',
              value: _addressValue(),
              icon: Icons.location_on_outlined,
            ),
            _grid([
              _info(
                label: 'City',
                value: _value(['city']),
                icon: Icons.location_city_outlined,
              ),
              _info(
                label: 'State',
                value: _value(['state']),
                icon: Icons.map_outlined,
              ),
              _info(
                label: 'Area',
                value: _value(['area', 'locality']),
                icon: Icons.place_outlined,
              ),
              _info(
                label: 'Pincode',
                value: _value(['pincode', 'postalCode']),
                icon: Icons.markunread_mailbox_outlined,
              ),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        _section(
          title: 'Work Location',
          icon: Icons.work_outline,
          children: [
            _grid([
              _info(
                label: 'Work Area',
                value: _value(['workArea', 'area']),
                icon: Icons.place_outlined,
              ),
              _info(
                label: 'Work City',
                value: _value(['workCity', 'city']),
                icon: Icons.location_city_outlined,
              ),
              _info(
                label: 'Work State',
                value: _value(['workState', 'state']),
                icon: Icons.map_outlined,
              ),
              _info(
                label: 'Assigned Zones',
                value: _listValue(_data['zoneIds']),
                icon: Icons.grid_view_outlined,
              ),
              _info(
                label: 'Availability',
                value: _value([
                  'availabilityStatus',
                  'availability',
                ]),
                icon: Icons.schedule_outlined,
              ),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        _section(
          title: 'KYC Documents',
          icon: Icons.verified_user_outlined,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Verification Status',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                ),
                _statusBadge(walker.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            _document(
              title: 'Aadhaar Front',
              key: 'aadhaar_front',
            ),
            _document(
              title: 'Aadhaar Back',
              key: 'aadhaar_back',
            ),
            _document(
              title: 'PAN Card',
              key: 'pan_card',
            ),
          ],
        ),
        const SizedBox(height: 16),

        _performanceSnapshot(),
        const SizedBox(height: 16),

        _section(
          title: 'Account Information',
          icon: Icons.security_outlined,
          children: [
            _grid([
              _info(
                label: 'Account Status',
                value: walker.displayStatus,
                icon: Icons.account_circle_outlined,
              ),
              _info(
                label: 'Application Submitted',
                value: walker.applicationSubmitted ? 'Yes' : 'No',
                icon: Icons.assignment_turned_in_outlined,
              ),
              _info(
                label: 'Approved',
                value: walker.isApproved ? 'Yes' : 'No',
                icon: Icons.verified_outlined,
              ),
              _info(
                label: 'Active',
                value: walker.isActive ? 'Yes' : 'No',
                icon: Icons.toggle_on_outlined,
              ),
              _info(
                label: 'Last Updated',
                value: _displayDateTime([
                  'updatedAt',
                ]),
                icon: Icons.update_outlined,
              ),
              _info(
                label: 'Decision Date',
                value: _displayDateTime([
                  'decisionAt',
                ]),
                icon: Icons.history_outlined,
              ),
            ]),
            _info(
              label: 'Decision By',
              value: _value(['decisionBy']),
              icon: Icons.admin_panel_settings_outlined,
            ),
            _info(
              label: 'Decision Reason',
              value: _value(['decisionReason']),
              icon: Icons.notes_outlined,
            ),
          ],
        ),
      ],
    );
  }
}
