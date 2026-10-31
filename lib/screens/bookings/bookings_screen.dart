import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'booking_status_helper.dart';
import 'booking_data_source.dart';
import '../../utils/admin_error_classifier.dart';

class BookingsScreen extends StatefulWidget {
  final BookingsDataSource? dataSource;

  const BookingsScreen({super.key, this.dataSource});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late final BookingsDataSource _dataSource = widget.dataSource ??
      FirestoreBookingsDataSource(FirebaseFirestore.instance);

  String _selectedStatus = 'All';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _statuses = bookingFilterStatuses;

  String _text(dynamic value, [String fallback = '—']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'finding walker':
      case 'walker arriving':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'picked up':
      case 'walk in progress':
        return Colors.blue;
      case 'confirmed':
      case 'walker accepted':
      case 'walker assigned':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _date(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Date unavailable';

    // Operational timestamps must display in India Standard Time (IST),
    // independent of the browser/device timezone.
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    final day = ist.day.toString().padLeft(2, '0');
    final month = ist.month.toString().padLeft(2, '0');

    return '$day/$month/${ist.year} '
        '${ist.hour.toString().padLeft(2, '0')}:'
        '${ist.minute.toString().padLeft(2, '0')} IST';
  }

  int _timestampMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFAF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bookings Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'View and monitor customer bookings',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _search = value.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: 'Search booking, customer or status',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFFE1C8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Filter by status',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: _statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BookingRecord>>(
              stream: _dataSource.watchBookings(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final permissionDenied =
                      isPermissionDeniedError(snapshot.error);
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            permissionDenied
                                ? Icons.lock_outline
                                : Icons.error_outline,
                            size: 42,
                            color: permissionDenied
                                ? Colors.orange
                                : Colors.redAccent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            permissionDenied
                                ? 'Permission denied'
                                : 'Could not load bookings',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            permissionDenied
                                ? 'Your current Admin role or assigned scope may not allow access to these bookings. Ask an authorized administrator to review access.'
                                : 'Check the connection and data access configuration. No booking status has been changed.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF7900),
                    ),
                  );
                }

                final docs = snapshot.data ?? const <BookingRecord>[];

                final filtered = docs.where((doc) {
                  final data = doc.data;
                  final status = displayBookingStatus(data['status']);

                  if (_selectedStatus != 'All' &&
                      status.toLowerCase() !=
                          _selectedStatus.toLowerCase()) {
                    return false;
                  }

                  final searchable = [
                    doc.id,
                    _text(data['customerName'], ''),
                    _text(data['customerId'], ''),
                    _text(data['walkerName'] ?? data['walkerId'], ''),
                    _text(data['petName'], ''),
                    _text((data['petDetails'] is Map)
                        ? (data['petDetails'] as Map)['name']
                        : null, ''),
                    _text(data['serviceName'] ?? data['bookingPlan'], ''),
                    _text(data['preferredTime'], ''),
                    status,
                  ].join(' ').toLowerCase();

                  return searchable.contains(_search);
                }).toList();

                filtered.sort((a, b) {
                  final aTime = _timestampMillis(a.data['createdAt']);
                  final bTime = _timestampMillis(b.data['createdAt']);
                  return bTime.compareTo(aTime);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 54,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bookingEmptyStateMessage(
                              totalRecords: docs.length,
                              search: _search,
                              selectedStatus: _selectedStatus,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total records: ${docs.length}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data;
                    final status = displayBookingStatus(data['status']);
                    final color = _statusColor(status);

                    final customerName = _text(
                      data['customerName'] ?? data['customerId'],
                      'Customer',
                    );

                    final walkerName = _text(
                      data['walkerName'] ?? data['walkerId'],
                      'Not assigned',
                    );

                    final petDetails = data['petDetails'] is Map
                        ? Map<String, dynamic>.from(data['petDetails'] as Map)
                        : <String, dynamic>{};
                    final dogName = _text(
                      data['petName'] ?? petDetails['name'],
                      'Not provided',
                    );
                    final serviceName = _text(
                      data['serviceName'] ?? data['bookingPlan'],
                      'Not provided',
                    );
                    final preferredTime = _text(data['preferredTime'], '');
                    final cancelRequest = data['cancelRequest'] is Map
                        ? Map<String, dynamic>.from(data['cancelRequest'] as Map)
                        : <String, dynamic>{};
                    final cancelStatus = _text(
                      cancelRequest['status'],
                      data['cancelRequest'] == null ? 'None' : 'Pending',
                    );
                    final cancelRequestedBy = _text(
                      cancelRequest['requestedBy'],
                      'Unknown',
                    );
                    final amount = data['amount'] ??
                        data['totalAmount'] ??
                        data['price'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  color: Color(0xFFFF7900),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Booking ${doc.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _detailRow(
                              Icons.person_outline,
                              'Customer',
                              customerName,
                            ),
                            _detailRow(
                              Icons.directions_walk_outlined,
                              'Walker',
                              walkerName,
                            ),
                            _detailRow(
                              Icons.pets_outlined,
                              'Dog',
                              dogName,
                            ),
                            _detailRow(
                              Icons.miscellaneous_services_outlined,
                              'Service',
                              serviceName,
                            ),
                            if (preferredTime.isNotEmpty)
                              _detailRow(
                                Icons.schedule_outlined,
                                'Preferred time',
                                preferredTime,
                              ),
                            _detailRow(
                              Icons.access_time,
                              'Created',
                              _date(data['createdAt']),
                            ),
                            _detailRow(
                              Icons.calendar_month_outlined,
                              'Walk time',
                              _date(
                                data['walkDateTime'] ??
                                    data['scheduledAt'] ??
                                    data['bookingDate'],
                              ),
                            ),
                            _detailRow(
                              Icons.currency_rupee,
                              'Amount',
                              amount == null ? 'Not finalized' : '₹$amount',
                            ),
                            if (data['cancelRequest'] != null)
                              _detailRow(
                                Icons.cancel_outlined,
                                'Cancellation',
                                '$cancelStatus • $cancelRequestedBy'
                                    ' • ${cancelRequest['requestedAt'] == null ? 'Time unavailable' : _date(cancelRequest['requestedAt'])}',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
