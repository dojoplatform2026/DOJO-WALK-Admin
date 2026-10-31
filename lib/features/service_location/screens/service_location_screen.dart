/// DOJO WALK Admin — Service Locations UI.
///
/// State/UT, District and City are hierarchy/reference records only.
/// Zone is the sole service activation unit under the current Notion rules.
///
/// The Zone-specific boundary preview and approval screens are UI prototypes
/// until their approved data contract is implemented. This screen must not
/// present legacy City/Area boundaries or status flags as active service Zones.
/// Existing data services are retained for the hierarchy/import tabs; this
/// UI-only work does not add or change Firebase lifecycle operations.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/service_location_models.dart';
import '../services/location_csv_preview_parser.dart';
import '../services/location_csv_import_fingerprint.dart';
import '../services/location_csv_import_service.dart';
import '../services/location_csv_lgd_validator.dart';
import '../services/service_location_service.dart';
import '../utils/boundary_preview_status.dart';
import 'add_zone_screen.dart';
import 'audit_history_screen.dart';
import 'boundary_review_screen.dart';
import 'zone_directory_screen.dart';
import 'zone_approval_queue_screen.dart';
import 'suspended_zones_screen.dart';
import 'zone_audit_history_screen.dart';

const Color _locationOrange = Color(0xFFFF7900);
const Color _locationBackground = Color(0xFFFFFAF5);

const LatLng _defaultMapCenter = LatLng(28.4744, 77.5040);

class ServiceLocationScreen extends StatefulWidget {
  const ServiceLocationScreen({super.key});

  @override
  State<ServiceLocationScreen> createState() =>
      _ServiceLocationScreenState();
}

class _ServiceLocationScreenState
    extends State<ServiceLocationScreen> {
  final ServiceLocationService _service =
      ServiceLocationService();

  final TextEditingController _searchController =
      TextEditingController();

  int _selectedTab = 0;
  String _search = '';

  GoogleMapController? _mapController;
  late Future<Set<Polygon>> _activeBoundaryPolygonsFuture;
  Set<Polygon> _loadedActiveBoundaryPolygons = <Polygon>{};
  String? _lastFittedPolygonSignature;

  // India-only navigation aligned to the Notion location hierarchy.
  // Zone workflow screens are being added separately; legacy Area/Locality
  // management is intentionally not exposed as a primary navigation tab.
  static const List<String> _tabNames = [
    'State / UT',
    'Districts',
    'Cities',
    'Import & Reconciliation',
  ];

  @override
  void initState() {
    super.initState();
    _activeBoundaryPolygonsFuture = _loadActiveBoundaryPolygons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _openLocationAction(String action) {
    final Widget screen;
    switch (action) {
      case 'directory':
        screen = const ZoneDirectoryScreen();
      case 'boundary':
        screen = const BoundaryReviewScreen();
      case 'approval':
        screen = const ZoneApprovalQueueScreen();
      case 'location-audit':
        screen = const LocationAuditHistoryScreen();
      case 'zone-audit':
        screen = const ZoneAuditHistoryScreen();
      case 'suspended':
        screen = const SuspendedZonesScreen();
      default:
        return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showError(Object error) async {
    if (!mounted) return;

    // Keep raw exception details out of the UI; backend/provider messages can
    // contain implementation details. Show a useful, non-sensitive next step.
    final errorText = error.toString().toLowerCase();
    final isPermissionError = errorText.contains('permission-denied') ||
        errorText.contains('permission denied') ||
        errorText.contains('unauthorized');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isPermissionError ? 'Access not available' : 'Action could not be completed',
        ),
        content: Text(
          isPermissionError
              ? 'Your account may not have permission for this action. Check your assigned role or contact Central Admin.'
              : 'No changes were confirmed. Please try again. If the problem continues, contact Central Admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _matches(String value) {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return true;

    return value.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: _locationBackground,
      appBar: AppBar(
        toolbarHeight: isMobile ? 68 : 76,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF242424),
        surfaceTintColor: Colors.transparent,
        shadowColor: _locationOrange.withValues(alpha: 0.12),
        elevation: 3,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFA64D), _locationOrange, Color(0xFFE85F00)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _locationOrange.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: _locationOrange,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Service Locations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Coverage & boundary management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isMobile)
            PopupMenuButton<String>(
              tooltip: 'More location actions',
              onSelected: _openLocationAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'directory', child: Text('Zone Directory')),
                PopupMenuItem(value: 'boundary', child: Text('Boundary Review')),
                PopupMenuItem(value: 'approval', child: Text('Founder Approval Queue')),
                PopupMenuItem(value: 'suspended', child: Text('Suspended / Deactivated Zones')),
                PopupMenuItem(value: 'location-audit', child: Text('Location Audit History')),
                PopupMenuItem(value: 'zone-audit', child: Text('Zone Audit History')),
              ],
            ),
          if (!isMobile) ...[
            IconButton(
              tooltip: 'Zone Directory',
              onPressed: () => _openLocationAction('directory'),
              icon: const Icon(Icons.list_alt_outlined),
            ),
            IconButton(
              tooltip: 'Boundary Review',
              onPressed: () => _openLocationAction('boundary'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
            IconButton(
              tooltip: 'Founder Approval Queue',
              onPressed: () => _openLocationAction('approval'),
              icon: const Icon(Icons.verified_user_outlined),
            ),
            IconButton(
              tooltip: 'Location Audit History',
              onPressed: () => _openLocationAction('location-audit'),
              icon: const Icon(Icons.history_rounded),
            ),
            IconButton(
              tooltip: 'Zone Audit History',
              onPressed: () => _openLocationAction('zone-audit'),
              icon: const Icon(Icons.history_rounded),
            ),
            IconButton(
              tooltip: 'Suspended / Deactivated Zones',
              onPressed: () => _openLocationAction('suspended'),
              icon: const Icon(Icons.pause_circle_outline),
            ),
          ],
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 20),
            child: Center(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddZoneScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(isMobile ? 'Add Zone' : 'Add Service Zone'),
                style: FilledButton.styleFrom(
                  backgroundColor: _locationOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 20, 12, isMobile ? 12 : 20, 0,
            ),
            child: SizedBox(
              width: double.infinity,
              height: isMobile ? 172 : 228,
              child: _buildMapPreview(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 20, 12, isMobile ? 12 : 20, 8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search state, district, city or zone code',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                prefixIcon: const Icon(Icons.search_rounded, color: _locationOrange),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFECE5DE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _locationOrange, width: 1.5),
                ),
              ),
            ),
          ),
          _buildTabs(),
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 4, isMobile ? 12 : 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _locationOrange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _locationOrange.withValues(alpha: 0.22)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: _locationOrange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reference hierarchy only: State / UT, District and City do not activate service. Only a verified Zone can be considered for service activation after the approved review workflow.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF4A3525)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECE5DE)),
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildSelectedList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 14, isMobile ? 12 : 20, 0),
      padding: EdgeInsets.all(isMobile ? 13 : 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF8F0)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD2AC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B5B25).withValues(alpha: 0.10),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Coverage overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _locationOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: _locationOrange),
                    SizedBox(width: 5),
                    Text(
                      'Verification required',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _locationOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            runSpacing: 6,
            children: [
              _hierarchyChip('State / UT'),
              _hierarchyArrow(),
              _hierarchyChip('District'),
              _hierarchyArrow(),
              _hierarchyChip('City'),
              _hierarchyArrow(),
              _hierarchyChip('Zone'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Colors.black54),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'नई boundaries Pending Review में सेव होती हैं। Verified boundary भी service को अपने आप active नहीं करती।',
                  style: TextStyle(fontSize: 11, height: 1.35, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hierarchyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFE3D8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _hierarchyArrow() => const Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: _locationOrange,
      );

  // ============================================================
  // MAP PREVIEW
  // ============================================================

  Future<Set<Polygon>> _loadActiveBoundaryPolygons() async {
    // Do not display legacy City/Area polygons as active service Zones.
    // The Zone-specific boundary data contract will be connected after the
    // UI and Notion screen workflow are finalized.
    return <Polygon>{};
  }

  Future<void> _fitMapToActiveBoundaries(Set<Polygon> polygons) async {
    final controller = _mapController;
    if (controller == null || polygons.isEmpty) return;

    final ids = polygons.map((polygon) => polygon.polygonId.value).toList()
      ..sort();
    final signature = ids.join('|');
    if (signature == _lastFittedPolygonSignature) return;
    _lastFittedPolygonSignature = signature;

    final points = polygons.expand((polygon) => polygon.points).toList();
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          24,
        ),
      );
    } catch (_) {
      // A map can still be usable even if the camera cannot fit its bounds.
    }
  }

  Widget _buildMapPreview() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF4E9)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _locationOrange.withValues(alpha: 0.34),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _locationOrange.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: FutureBuilder<Set<Polygon>>(
        future: _activeBoundaryPolygonsFuture,
        builder: (context, snapshot) {
          final polygons = snapshot.data ?? <Polygon>{};
          _loadedActiveBoundaryPolygons = polygons;
          if (snapshot.hasData && polygons.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMapToActiveBoundaries(polygons);
            });
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultMapCenter,
                  zoom: 11,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_loadedActiveBoundaryPolygons.isNotEmpty) {
                    _fitMapToActiveBoundaries(_loadedActiveBoundaryPolygons);
                  }
                },
                polygons: polygons,
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: _locationOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        boundaryPreviewStatusLabel(
                          isLoading: snapshot.connectionState == ConnectionState.waiting,
                          hasError: snapshot.hasError,
                          polygonCount: polygons.length,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Refresh boundary preview',
                    onPressed: () {
                      setState(() {
                        _lastFittedPolygonSignature = null;
                        _activeBoundaryPolygonsFuture =
                            _loadActiveBoundaryPolygons();
                      });
                    },
                    icon: const Icon(Icons.refresh, color: _locationOrange),
                  ),
                ),
              ),
              if (snapshot.hasError)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 54,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Unable to load active boundaries. Check your access or try again later.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Verified Zone polygons will appear here when the Zone-specific boundary source is connected. '
                    'State/UT, District and City are hierarchy records, not service activation units.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _tabNames.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedTab == index;
          return ChoiceChip(
            label: Text(_tabNames[index]),
            selected: selected,
            selectedColor: _locationOrange,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5D5148),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected ? _locationOrange : const Color(0xFFE9D9CB),
              width: 1,
            ),
            elevation: selected ? 5 : 1,
            pressElevation: 7,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            onSelected: (_) {
              setState(() => _selectedTab = index);
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedList() {
    switch (_selectedTab) {
      case 0:
        return _buildStates();
      case 1:
        return _buildDistricts();
      case 2:
        return _buildCities();
      case 3:
        return _buildImports();
      default:
        return _buildStates();
    }
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_searching,
              size: 44,
              color: _locationOrange,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: _locationOrange,
      ),
    );
  }

  // ============================================================
  // COUNTRIES
  // ============================================================

  
  // ============================================================
  // STATES
  // ============================================================

  Widget _buildStates() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('Unable to load location data. Check your access or try again later.');
        }

        if (!countrySnapshot.hasData) {
          return _loadingState();
        }

        final countries = countrySnapshot.data!;

        if (countries.isEmpty) {
          return _emptyState('Add a country first.');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final country in countries)
              StreamBuilder<List<ServiceState>>(
                stream: _service.watchStates(
                  countryId: country.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        'Unable to load states for ${country.name}. Check your access or try again later.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _locationOrange,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Loading states…'),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data!
                      .where(
                        (item) => _matches(
                          '${item.id} ${item.name} '
                          '${country.id} ${country.name}',
                        ),
                      )
                      .toList();

                  if (items.isEmpty) {
                    if (_search.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'No States match your search in ${country.name}.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(country.name),
                      for (final item in items)
                        _locationCard(
                          title: item.name,
                          subtitle:
                              'ID: ${item.id} · Country: ${country.name}',
                          icon: Icons.map_outlined,
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISTRICTS
  // ============================================================

  Widget _buildDistricts() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('Unable to load location data. Check your access or try again later.');
        }
        if (!countrySnapshot.hasData) return _loadingState();

        return StreamBuilder<List<ServiceState>>(
          stream: _service.watchStates(),
          builder: (context, stateSnapshot) {
            if (stateSnapshot.hasError) {
              return _emptyState('Unable to load location data. Check your access or try again later.');
            }
            if (!stateSnapshot.hasData) return _loadingState();

            return StreamBuilder<List<ServiceDistrict>>(
              stream: _service.watchDistricts(),
              builder: (context, districtSnapshot) {
                if (districtSnapshot.hasError) {
                  return _emptyState(
                    'Unable to load location data. Check your access or try again later.',
                  );
                }
                if (!districtSnapshot.hasData) return _loadingState();

                final countriesById = {
                  for (final country in countrySnapshot.data!) country.id: country,
                };
                final statesById = {
                  for (final state in stateSnapshot.data!) state.id: state,
                };
                final districts = districtSnapshot.data!.where((district) {
                  final state = statesById[district.stateId];
                  final country = countriesById[district.countryId];
                  return _matches(
                    '${district.id} ${district.name} '
                    '${district.stateId} ${state?.name ?? ""} '
                    '${district.countryId} ${country?.name ?? ""}',
                  );
                }).toList();

                if (districts.isEmpty) {
                  return _emptyState(
                    _search.isEmpty
                        ? 'No Districts yet. Use Add Location to create a District under a State.'
                        : 'No Districts match your search.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _sectionTitle('Districts · ${districts.length}'),
                    for (final district in districts)
                      _locationCard(
                        title: district.name,
                        subtitle: 'State: ${statesById[district.stateId]?.name ?? "Unknown State"}\n'
                            'Country: ${countriesById[district.countryId]?.name ?? "Unknown Country"}',
                        icon: Icons.map_outlined,
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CITIES / DISTRICTS
  // ============================================================

  Widget _buildCities() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('Unable to load location data. Check your access or try again later.');
        }
        if (!countrySnapshot.hasData) return _loadingState();

        return StreamBuilder<List<ServiceState>>(
          stream: _service.watchStates(),
          builder: (context, stateSnapshot) {
            if (stateSnapshot.hasError) {
              return _emptyState('Unable to load location data. Check your access or try again later.');
            }
            if (!stateSnapshot.hasData) return _loadingState();

            return StreamBuilder<List<ServiceDistrict>>(
              stream: _service.watchDistricts(),
              builder: (context, districtSnapshot) {
                if (districtSnapshot.hasError) {
                  return _emptyState('Unable to load location data. Check your access or try again later.');
                }
                if (!districtSnapshot.hasData) return _loadingState();

                final districtsById = {
                  for (final district in districtSnapshot.data!)
                    district.id: district,
                };

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final country in countrySnapshot.data!)
                      for (final state in stateSnapshot.data!.where(
                        (item) => item.countryId == country.id,
                      ))
                        StreamBuilder<List<ServiceCity>>(
                          stream: _service.watchCities(
                            countryId: country.id,
                            stateId: state.id,
                          ),
                          builder: (context, citySnapshot) {
                            if (citySnapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Unable to load cities for ${state.name}. Check your access or try again later.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }

                            if (!citySnapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _locationOrange,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Loading cities…'),
                                  ],
                                ),
                              );
                            }

                            final cities = citySnapshot.data!.where((item) {
                              final district = districtsById[item.districtId];
                              return _matches(
                                '${item.id} ${item.name} '
                                '${state.id} ${state.name} '
                                '${country.id} ${country.name} '
                                '${item.districtId} ${district?.name ?? "Legacy City"}',
                              );
                            }).toList();

                            if (cities.isEmpty) {
                              if (_search.trim().isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No Cities match your search under ${state.name}.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('${state.name} · ${country.name}'),
                                for (final item in cities)
                                  _locationCard(
                                    title: item.name,
                                    subtitle:
                                        'ID: ${item.id}\n'
                                        'District: ${districtsById[item.districtId]?.name ?? (item.districtId.isEmpty ? "Not linked (legacy City)" : "Unknown District")}',
                                    icon: Icons.location_city,
                                  ),
                              ],
                            );
                          },
                        ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // AREAS / SUB-DISTRICTS
  // ============================================================

  
  // ============================================================
  // LOCALITIES / VILLAGES
  // ============================================================

  
  Future<void> _confirmAndRunCsvImport({
    required LocationCsvPreview preview,
    required String fileName,
  }) async {
    if (!preview.isSyntacticallyValid || preview.rows.isEmpty) {
      _showMessage('Validate a non-empty CSV before importing.');
      return;
    }

    late final List<ServiceCountry> activeCountries;
    try {
      activeCountries = (await _service.watchCountries().first)
          .where((country) => country.isActive && country.id.trim().isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      await _showError(error);
      return;
    }
    if (!mounted) return;
    if (activeCountries.isEmpty) {
      await _showError(StateError(
        'No active Service Country is available. Activate/configure the country before importing.',
      ));
      return;
    }

    final runIdController = TextEditingController(
      text: 'csv-${DateTime.now().millisecondsSinceEpoch}',
    );
    String? selectedCountryId = activeCountries.first.id;
    bool confirmed = false;
    bool importing = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Confirm location CSV import'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Source: $fileName'),
                    const SizedBox(height: 6),
                    Text('CSV rows: ${preview.rows.length}'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCountryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Parent country',
                        border: OutlineInputBorder(),
                      ),
                      items: activeCountries
                          .map((country) => DropdownMenuItem<String>(
                                value: country.id,
                                child: Text('${country.name} (${country.code})'),
                              ))
                          .toList(growable: false),
                      onChanged: importing
                          ? null
                          : (value) => setDialogState(
                                () => selectedCountryId = value,
                              ),
                    ),
                    if (selectedCountryId != null) ...[
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final fingerprint = locationCsvImportFingerprint(
                          countryId: selectedCountryId!,
                          preview: preview,
                        );
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE6E0DA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Import fingerprint · save this for reconciliation',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              const SizedBox(height: 5),
                              SelectableText(fingerprint, style: const TextStyle(fontSize: 11)),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: fingerprint));
                                    _showMessage('Import fingerprint copied. Keep it with the Run ID.');
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Copy fingerprint'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: runIdController,
                      enabled: !importing,
                      decoration: const InputDecoration(
                        labelText: 'Import Run ID',
                        helperText: 'Save this ID if the import needs reconciliation.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD1A8)),
                      ),
                      child: const Text(
                        'Import creates inactive State → District → City → Area records only. It does not create boundaries or activate service. A network timeout can leave a partial run; do not retry with a new Run ID until the original run is reconciled.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: confirmed,
                      onChanged: importing
                          ? null
                          : (value) => setDialogState(
                                () => confirmed = value == true,
                              ),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I reviewed the CSV and confirm these location records should be imported.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    if (importing) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: importing
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: importing || !confirmed || selectedCountryId == null
                    ? null
                    : () async {
                        final runId = runIdController.text.trim();
                        try {
                          validateLocationCsvImportRunId(runId);
                        } catch (error) {
                          await _showError(error);
                          return;
                        }
                        setDialogState(() => importing = true);
                        try {
                          final result = await LocationCsvImportService(
                            locations: _service,
                          ).importPreview(
                            preview: preview,
                            countryId: selectedCountryId!,
                            fileName: fileName,
                            importRunId: runId,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          _showMessage(
                            'Import completed · Planned ${result.plannedRecords} · '
                            'Created ${result.createdRecords} · Reused ${result.reusedRecords}.',
                          );
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() => importing = false);
                          }
                          await _showError(error);
                        }
                      },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(importing ? 'Importing…' : 'Import locations'),
              ),
            ],
          ),
        ),
      );
    } finally {
      runIdController.dispose();
    }
  }

  // ============================================================
  // READ-ONLY CSV PREVIEW
  // ============================================================

  Future<void> _showCsvPreviewDialog() async {
    final controller = TextEditingController();
    final parser = LocationCsvPreviewParser();
    LocationCsvPreview? preview;
    List<String> mappingReport = [];
    bool checkingParents = false;
    String sourceName = 'Pasted CSV';

    String normalizeLocationName(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    List<String> optionalSourceHeaders(LocationCsvPreview value) =>
        value.headers.where((header) {
          final normalized = header
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'[ _-]+'), '');
          return !const {'state', 'district', 'city', 'area'}
              .contains(normalized);
        }).toList();

    String rowPreviewSubtitle(LocationCsvRow row) {
      final validation = row.errors.isEmpty
          ? 'Validation passed'
          : row.errors.join('\n');
      final metadata = row.sourceValues.entries
          .where((entry) {
            final normalized = entry.key
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[ _-]+'), '');
            return !const {'state', 'district', 'city', 'area'}
                    .contains(normalized) &&
                entry.value.isNotEmpty;
          })
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' · ');
      return metadata.isEmpty
          ? validation
          : '$validation\nSource metadata: $metadata';
    }

    Future<void> checkParentMapping(StateSetter setDialogState) async {
      final currentPreview = preview;
      if (currentPreview == null || !currentPreview.isSyntacticallyValid) {
        setDialogState(() {
          mappingReport = ['Run a clean CSV validation before checking parents.'];
        });
        return;
      }

      setDialogState(() {
        checkingParents = true;
        mappingReport = [];
      });

      try {
        final states = await _service.watchStates().first;
        final districts = await _service.watchDistricts().first;
        final cities = await _service.watchCities().first;
        final areas = await _service.watchAreas().first;
        final report = <String>[];
        var matched = 0;
        var lgdMatched = 0;

        for (final row in currentPreview.rows) {
          final lgdMatch = matchCsvStateDistrictToLgd(row);
          if (lgdMatch.isMatched) {
            lgdMatched++;
          } else {
            report.add('Line ${row.lineNumber}: LGD check — ${lgdMatch.message}');
          }

          final stateName = row.values['state'] ?? '';
          final cityName = row.values['city'] ?? '';
          final areaName = row.values['area'] ?? '';

          final stateMatches = states.where(
            (item) => normalizeLocationName(item.name) ==
                normalizeLocationName(stateName),
          ).toList();

          if (stateMatches.length != 1) {
            report.add(
              'Line ${row.lineNumber}: State "$stateName" '
              '${stateMatches.isEmpty ? 'not found' : 'is ambiguous'} '
              'in existing Service Locations.',
            );
            continue;
          }

          final state = stateMatches.single;
          final districtName = row.values['district'] ?? '';
          final districtMatches = districts.where(
            (item) =>
                item.stateId == state.id &&
                normalizeLocationName(item.name) ==
                    normalizeLocationName(districtName),
          ).toList();

          if (districtMatches.length != 1) {
            report.add(
              'Line ${row.lineNumber}: District "$districtName" under '
              '$stateName ${districtMatches.isEmpty ? 'not found' : 'is ambiguous'} '
              'in existing Service Locations.',
            );
            continue;
          }

          final district = districtMatches.single;
          final sameNameCities = cities.where(
            (item) =>
                item.stateId == state.id &&
                normalizeLocationName(item.name) ==
                    normalizeLocationName(cityName),
          ).toList();
          final cityMatches = sameNameCities.where(
            (item) => item.districtId == district.id,
          ).toList();

          if (cityMatches.length != 1) {
            final legacyUnlinked = sameNameCities.any(
              (item) => item.districtId.trim().isEmpty,
            );
            final detail = cityMatches.isEmpty
                ? (legacyUnlinked
                    ? 'exists but is not linked to District "$districtName"'
                    : 'not found under District "$districtName"')
                : 'is ambiguous under District "$districtName"';
            report.add(
              'Line ${row.lineNumber}: City "$cityName" $detail.',
            );
            continue;
          }

          final city = cityMatches.single;
          final areaMatches = areas.where(
            (item) =>
                item.cityId == city.id &&
                normalizeLocationName(item.name) ==
                    normalizeLocationName(areaName),
          ).toList();

          if (areaMatches.length != 1) {
            report.add(
              'Line ${row.lineNumber}: Area "$areaName" under '
              '$cityName ${areaMatches.isEmpty ? 'not found' : 'is ambiguous'}.',
            );
            continue;
          }

          matched++;
        }

        report.insert(
          0,
          'LGD State/District reference matches: $lgdMatched / ${currentPreview.rows.length} rows. This uses the bundled reference snapshot only.',
        );
        report.insert(
          1,
          'Existing Service State/City/Area name matches: $matched / ${currentPreview.rows.length} rows.',
        );
        report.insert(
          2,
          'District mapping uses existing Service District records and requires each matched City to carry the matching districtId. Legacy unlinked Cities are reported, not guessed. This check never writes data.',
        );

        setDialogState(() {
          mappingReport = report;
        });
      } catch (error) {
        setDialogState(() {
          mappingReport = ['Could not read existing parent records: $error'];
        });
      } finally {
        setDialogState(() {
          checkingParents = false;
        });
      }
    }

    Future<void> pickCsvFile(StateSetter setDialogState) async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['csv'],
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;

        final file = result.files.single;
        final bytes = file.bytes;
        if (bytes == null) {
          throw const FormatException(
            'CSV file bytes are unavailable. Please try another file.',
          );
        }

        final contents = utf8.decode(bytes, allowMalformed: false);
        controller.text = contents;
        setDialogState(() {
          sourceName = file.name;
          preview = parser.parse(contents);
          // A new file invalidates any parent-mapping report from the old preview.
          mappingReport = [];
        });
      } catch (error) {
        setDialogState(() {
          preview = LocationCsvPreview(
            headers: const [],
            rows: const [],
            fileErrors: ['Could not read selected CSV: $error'],
          );
          // Do not leave stale mapping results visible after a file-read error.
          mappingReport = [];
        });
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Preview location CSV'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paste CSV text below. Required columns: State, District, City, Area. '
                    'This preview does not save or activate any locations.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => pickCsvFile(setDialogState),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Choose CSV file'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    onChanged: (_) {
                      setDialogState(() {
                        sourceName = 'Pasted CSV';
                        preview = null;
                        mappingReport = [];
                      });
                    },
                    minLines: 6,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'State,District,City,Area\n'
                          'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (preview != null) ...[
                    SelectableText('Source: $sourceName'),
                    SelectableText(
                      'SHA-256: ${sha256.convert(utf8.encode(controller.text))}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Rows: ${preview!.rows.length}')),
                        Chip(label: Text('Valid: ${preview!.validRowCount}')),
                        Chip(label: Text('Invalid: ${preview!.invalidRowCount}')),
                      ],
                    ),
                    if (optionalSourceHeaders(preview!).isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Optional source metadata · preview only',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: optionalSourceHeaders(preview!)
                                  .map((header) => Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(header),
                                      ))
                                  .toList(),
                            ),
                            const Text(
                              'Source codes and versions are displayed as provided; they are not verified against an authoritative source.',
                            ),
                          ],
                        ),
                      ),
                    for (final error in preview!.fileErrors)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    for (final row in preview!.rows.take(20))
                      Card(
                        margin: const EdgeInsets.only(top: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            row.isValid ? Icons.check_circle_outline : Icons.error_outline,
                            color: row.isValid ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            'Line ${row.lineNumber}: ${row.values['state']} · '
                            '${row.values['district']} · ${row.values['city']} · '
                            '${row.values['area']}',
                          ),
                          subtitle: Text(rowPreviewSubtitle(row)),
                        ),
                      ),
                    if (preview!.rows.length > 20)
                      Text('Showing first 20 of ${preview!.rows.length} rows.'),
                    if (preview!.isSyntacticallyValid)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _locationOrange.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CSV syntax validation passed — NOT import approval.',
                              style: TextStyle(
                                color: _locationOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Preview itself never writes location records. After validation, use Import locations to choose an active parent country, enter a stable Run ID, and explicitly confirm the import. The trusted backend enforces super_admin access and records the bounded plan before hierarchy writes. If a run fails or times out, do not retry with a new Run ID; use Import History → Reconcile to inspect the original run. Import creates inactive records only and never creates boundaries or activates service.',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: checkingParents
                          ? null
                          : () => checkParentMapping(setDialogState),
                      icon: checkingParents
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.account_tree_outlined),
                      label: Text(
                        checkingParents
                            ? 'Checking existing parents…'
                            : 'Check Existing Parent Mapping',
                      ),
                    ),
                    for (final line in mappingReport)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: line.startsWith('Existing State/City/Area name matches')
                                ? Colors.green.shade800
                                : Colors.deepOrange.shade800,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() {
                controller.clear();
                preview = null;
                mappingReport = [];
                sourceName = 'Pasted CSV';
              }),
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: preview == null || !preview!.isSyntacticallyValid
                  ? null
                  : () => _confirmAndRunCsvImport(
                        preview: preview!,
                        fileName: sourceName,
                      ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Import locations'),
            ),
            FilledButton.icon(
              onPressed: () => setDialogState(() {
                preview = parser.parse(controller.text);
                mappingReport = [];
              }),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate CSV'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  // Read-only reconciliation never resumes, repairs, activates, or replays writes.
  Future<void> _reconcileImportById() async {
    final runIdController = TextEditingController();
    final fingerprintController = TextEditingController();
    var checking = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Reconcile import run'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Enter the original Run ID and exact SHA-256 fingerprint. This check is read-only and never resumes or repairs an import.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: runIdController,
                      enabled: !checking,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Import Run ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fingerprintController,
                      enabled: !checking,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Input fingerprint (sha256:...)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: checking ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: checking ? null : () async {
                  final runId = runIdController.text.trim();
                  final fingerprint = fingerprintController.text.trim();
                  if (!RegExp(r'^[A-Za-z0-9_-]{1,150}$').hasMatch(runId)) {
                    _showMessage('Enter a valid Run ID.');
                    return;
                  }
                  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(fingerprint)) {
                    _showMessage('Enter the complete lowercase SHA-256 fingerprint.');
                    return;
                  }
                  setDialogState(() => checking = true);
                  try {
                    final inspection = await _service.inspectImportRun(runId: runId, inputFingerprint: fingerprint);
                    final result = await _service.reconcileImportPlan(runId: runId, inputFingerprint: fingerprint);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    await showDialog<void>(
                      context: this.context,
                      builder: (resultContext) => AlertDialog(
                        title: const Text('Read-only reconciliation result'),
                        content: SizedBox(
                          width: 560,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              'Run: ' + runId + '\n' +
                              'Server status: ' + (inspection['status']?.toString() ?? 'unknown') + '\n' +
                              'Reconciliation: ' + (result['status']?.toString() ?? 'unknown') + '\n' +
                              'Read-only: ' + (result['readOnly'] == true ? 'Yes' : 'No') + '\n' +
                              'Planned records: ' + (result['plannedRecords'] ?? inspection['plannedRecords'] ?? '—').toString() + '\n' +
                              'Matching records: ' + (result['matchingRecords'] ?? 0).toString() + '\n' +
                              'Missing IDs: ' + ((result['missingIds'] as List? ?? const []).join(', ')) + '\n' +
                              'Mismatch IDs: ' + ((result['mismatchIds'] as List? ?? const []).join(', ')) + '\n' +
                              'Truncated: ' + (result['truncated'] == true ? 'Yes' : 'No') + '\n\n' +
                              'No location was created, changed, activated, resumed or repaired.',
                            ),
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.of(resultContext).pop(), child: const Text('Close'))],
                      ),
                    );
                  } catch (error) {
                    if (dialogContext.mounted) setDialogState(() => checking = false);
                    await _showError(error);
                  }
                },
                child: Text(checking ? 'Checking...' : 'Inspect & Reconcile'),
              ),
            ],
          ),
        ),
      );
    } finally {
      runIdController.dispose();
      fingerprintController.dispose();
    }
  }

  Future<void> _reconcileImportRecord(ServiceLocationImport item) async {
    final fingerprint = item.inputFingerprint.trim();
    if (item.id.trim().isEmpty || fingerprint.isEmpty) {
      _showMessage('This legacy import has no fingerprint; reconciliation is unavailable.');
      return;
    }
    try {
      final inspection = await _service.inspectImportRun(
        runId: item.id,
        inputFingerprint: fingerprint,
      );
      final reconciliation = await _service.reconcileImportPlan(
        runId: item.id,
        inputFingerprint: fingerprint,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Read-only import reconciliation'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(
                'Run: ${item.id}\n'
                'Audit status: ${item.status}\n'
                'Server status: ${inspection['status'] ?? 'unknown'}\n'
                'Reconciliation: ${reconciliation['status'] ?? 'unknown'}\n'
                'Read-only: ${reconciliation['readOnly'] == true ? 'Yes' : 'No'}\n'
                'Plan records: ${reconciliation['plannedRecords'] ?? inspection['plannedRecords'] ?? '—'}\n'
                'Matching records: ${reconciliation['matchingRecords'] ?? 0}\n'
                'Missing records: ${reconciliation['missingCount'] ?? (reconciliation['missingIds'] as List? ?? const []).length}\n'
                'Mismatched records: ${reconciliation['mismatchCount'] ?? (reconciliation['mismatchIds'] as List? ?? const []).length}\n'
                'Missing IDs (first 50): ${(reconciliation['missingIds'] as List? ?? const []).join(', ')}\n'
                'Mismatched IDs (first 50): ${(reconciliation['mismatchIds'] as List? ?? const []).join(', ')}\n'
                'Results truncated: ${reconciliation['truncated'] == true ? 'Yes — more records need investigation' : 'No'}\n\n'
                'This check does not write, repair, resume, or activate any location.',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      await _showError(error);
    }
  }

  // ============================================================
  // IMPORT HISTORY
  // ============================================================

  Widget _buildImports() {
    return StreamBuilder<List<ServiceLocationImport>>(
      stream: _service.watchImports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load import history. Check your access or try again later.',
          );
        }

        if (!snapshot.hasData) {
          return _loadingState();
        }

        final items = snapshot.data!
            .where(
              (item) => _matches(
                '${item.id} ${item.fileName} ${item.source} '
                '${item.status} ${item.verificationStatus}',
              ),
            )
            .toList();

        if (items.isEmpty) {
          return _emptyState(
            _search.trim().isEmpty
                ? 'No import history yet. Preview and validate a CSV before starting an authorized import.'
                : 'No import records match your search.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSV Import Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Legacy reference-data import only: preview State, District, City and Area rows. This is not the Create Zone flow and does not create or activate a service Zone. '
                      'Import is restricted to active super_admin accounts. New records stay inactive; '
                      'service activation still requires separate boundary verification.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _showCsvPreviewDialog,
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text('Paste CSV and Preview'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _locationOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _reconcileImportById,
                          icon: const Icon(Icons.manage_search_outlined),
                          label: const Text('Reconcile by Run ID'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No import history records found yet.'),
              ),
            for (final item in items)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.file_present, color: _locationOrange),
                        title: Text(item.fileName),
                        subtitle: Text(
                          'ID: ${item.id}\n'
                          'Source: ${item.source}\n'
                          'Status: ${item.status}\n'
                          'Verification: ${item.verificationStatus}',
                        ),
                        isThreeLine: true,
                      ),
                      if (item.inputFingerprint.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: OutlinedButton.icon(
                            onPressed: () => _reconcileImportRecord(item),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Inspect & Reconcile (Read-only)'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );

      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _locationOrange,
          ),
        ),
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      color: Colors.white,
      shadowColor: _locationOrange.withValues(alpha: 0.12),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: _locationOrange.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFFFD7B5), _locationOrange.withValues(alpha: 0.14)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _locationOrange.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: _locationOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: subtitle.contains('\n'),
      ),
    );
  }

  // ============================================================
  // ADD LOCATION
  // ============================================================

  }