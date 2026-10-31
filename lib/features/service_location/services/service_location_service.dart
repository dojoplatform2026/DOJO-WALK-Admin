import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_models.dart';
import 'service_location_geometry.dart';
import 'service_location_index_contract.dart';

/// ===========================================================
/// DOJO WALK ADMIN
/// Service Location Service
///
/// Legacy Service Location compatibility service.
///
/// Approved service hierarchy for the new workflow:
/// State/UT -> District -> City -> Zone. Only Zone may be activated
/// or deactivated for customer service. Locality is not a service-status
/// unit. Legacy collections/models remain read-only compatibility until a
/// separately reviewed migration removes them.
///
/// Do not use legacy City/Area/Locality or generic hierarchy status callables
/// to change service availability. Zone activation requires the dedicated
/// Founder-approved Zone workflow; Zone deactivation requires the approved
/// deactivation workflow and server-side audit.
/// ===========================================================

class ServiceLocationService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String? Function() _currentUserIdProvider;

  ServiceLocationService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    String? Function()? currentUserIdProvider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
        _currentUserIdProvider = currentUserIdProvider ??
            (() => FirebaseAuth.instance.currentUser?.uid);

  Future<void> _setTrustedStatus({
    required String locationType,
    required String locationId,
    required bool isActive,
  }) async {
    // Fail closed in the Admin client as well as on the trusted server.
    // Reference hierarchy and legacy Area/Locality records must never carry
    // service activation state. A Zone may only be deactivated through this
    // generic endpoint after the Founder-approved deactivation workflow.
    if (locationType != 'zone') {
      throw StateError(
        'Only Zone can have service status. '
        'State/UT, District, City and legacy Area/Locality are reference records.',
      );
    }
    if (isActive) {
      throw StateError(
        'Zone activation must use the Founder-approved Zone workflow.',
      );
    }

    final callable = _functions.httpsCallable('setServiceLocationStatus');
    await callable.call<void>({
      'locationType': locationType,
      'locationId': locationId,
      'isActive': false,
    });
  }

  Future<void> _activateTrustedBoundaryLocation({
    required String locationType,
    required String locationId,
  }) async {
    // The legacy callable only targets City/Area and is intentionally retired
    // by the Zone-only contract. Do not send obsolete activation requests.
    throw StateError(
      'Legacy $locationType activation is disabled. '
      'Use the Founder-approved Zone workflow.',
    );
  }

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  CollectionReference<Map<String, dynamic>> get _countries =>
      _firestore.collection('service_countries');

  CollectionReference<Map<String, dynamic>> get _states =>
      _firestore.collection('service_states');

  CollectionReference<Map<String, dynamic>> get _districts =>
      _firestore.collection('service_districts');

  CollectionReference<Map<String, dynamic>> get _cities =>
      _firestore.collection('service_cities');

  CollectionReference<Map<String, dynamic>> get _areas =>
      _firestore.collection('service_areas');

  CollectionReference<Map<String, dynamic>> get _localities =>
      _firestore.collection('service_localities');

  CollectionReference<Map<String, dynamic>> get _imports =>
      _firestore.collection('service_location_imports');

  CollectionReference<Map<String, dynamic>> get _boundaries =>
      _firestore.collection('service_location_boundaries');

  // ==========================================================
  // GENERAL HELPERS
  // ==========================================================

  String _required(
    String value,
    String fieldName,
  ) {
    final result = value.trim();

    if (result.isEmpty) {
      throw ArgumentError('$fieldName is required.');
    }

    return result;
  }

  List<GeoPoint> _readPoints(dynamic value) {
    final result = <GeoPoint>[];

    if (value is! List) return result;

    for (final item in value) {
      double? lat;
      double? lng;

      if (item is GeoPoint) {
        lat = item.latitude;
        lng = item.longitude;
      } else if (item is Map) {
        final latitude = item['latitude'];
        final longitude = item['longitude'];

        if (latitude is num && longitude is num) {
          lat = latitude.toDouble();
          lng = longitude.toDouble();
        }
      }

      if (lat == null || lng == null) continue;

      if (!lat.isFinite || !lng.isFinite) continue;

      if (lat < -90 || lat > 90) continue;

      if (lng < -180 || lng > 180) continue;

      result.add(GeoPoint(lat, lng));
    }

    return result;
  }

  bool _hasValidPolygon(dynamic value) {
    final points = _readPoints(value);

    if (points.length < 3) return false;

    final unique = points
        .map(
          (point) =>
              '${point.latitude.toStringAsFixed(7)},'
              '${point.longitude.toStringAsFixed(7)}',
        )
        .toSet();

    return unique.length >= 3;
  }

  // ==========================================================
  // UNIQUE NAME SAVE
  // ==========================================================

  Future<void> _saveUniqueNamedDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String documentId,
    required String name,
    required Map<String, dynamic> data,
  }) async {
    // Name-index writes are now server-owned. Keep this shared method as the
    // single route for Country/State/City/Area/Locality saves.
    final locationTypeByCollection = <String, String>{
      'service_countries': 'country',
      'service_states': 'state',
      'service_districts': 'district',
      'service_cities': 'city',
      'service_areas': 'area',
      'service_localities': 'locality',
    };
    final locationType = locationTypeByCollection[collection.path];
    if (locationType == null) {
      throw StateError('Unsupported service location collection.');
    }

    final allowedFieldsByType = <String, Set<String>>{
      'country': {'name', 'code'},
      'state': {'countryId', 'name'},
      'district': {'countryId', 'stateId', 'name'},
      'city': {'countryId', 'stateId', 'districtId', 'name'},
      'area': {'countryId', 'stateId', 'cityId', 'name'},
      'locality': {
        'countryId', 'stateId', 'cityId', 'areaId', 'name', 'pincode',
      },
    };
    final allowedFields = allowedFieldsByType[locationType]!;
    final payload = <String, dynamic>{};
    for (final entry in data.entries) {
      if (allowedFields.contains(entry.key)) {
        payload[entry.key] = entry.value;
      }
    }
    payload['name'] = _required(name, 'Name');

    // A blank optional District ID means this is a legacy City. Omit the
    // field entirely; sending an empty string makes the trusted callable treat
    // it as a supplied but invalid parent ID.
    final indexPayload =
        normalizeServiceLocationIndexPayload(locationType, payload);
    payload
      ..clear()
      ..addAll(indexPayload);

    // Parent IDs remain explicit in the payload so the server can validate
    // the full hierarchy and recompute the canonical SHA-256 index.
    final parentFields = serviceLocationIndexParentFields(locationType, payload);
    for (final field in parentFields) {
      final parentId = payload[field]?.toString().trim() ?? '';
      if (parentId.isEmpty) {
        throw StateError('The supplied service location hierarchy is invalid: $field is required.');
      }
      payload[field] = parentId;
    }

    final callable = _functions.httpsCallable('saveServiceLocationWithNameIndex');
    final result = await callable.call<Map<String, dynamic>>({
      'locationType': locationType,
      'locationId': documentId,
      'payload': payload,
    });
    final savedId = result.data['locationId']?.toString();
    if (savedId != documentId) {
      throw StateError('The trusted service returned an unexpected location ID.');
    }
  }


  // ==========================================================
  // DOCUMENT / HIERARCHY VALIDATION
  // ==========================================================

  Future<Map<String, dynamic>> _requireDocument(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    String label,
  ) async {
    final documentId = _required(id, '$label ID');

    final snapshot = await collection.doc(documentId).get();

    if (!snapshot.exists) {
      throw StateError('$label not found.');
    }

    return snapshot.data()!;
  }

  Future<void> _requireActiveCountry(
    String countryId,
  ) async {
    final data = await _requireDocument(
      _countries,
      countryId,
      'Country',
    );

    if (data['isActive'] != true) {
      throw StateError(
        'The selected country is not active.',
      );
    }
  }

  Future<void> _requireActiveState(
    String stateId,
    String countryId,
  ) async {
    final data = await _requireDocument(
      _states,
      stateId,
      'State',
    );

    if (data['countryId'] != countryId) {
      throw StateError(
        'The state does not belong to the selected country.',
      );
    }

    if (data['isActive'] != true) {
      throw StateError(
        'The selected state is not active.',
      );
    }
  }

  Future<void> _requireActiveCity(
    String cityId,
    String stateId,
  ) async {
    final data = await _requireDocument(
      _cities,
      cityId,
      'City',
    );

    if (data['stateId'] != stateId) {
      throw StateError(
        'The city does not belong to the selected state.',
      );
    }

    if (data['isServiceActive'] != true) {
      throw StateError(
        'The selected city is not active for service.',
      );
    }
  }

  Future<void> _requireActiveArea(
    String areaId,
    String cityId,
  ) async {
    final data = await _requireDocument(
      _areas,
      areaId,
      'Area',
    );

    if (data['cityId'] != cityId) {
      throw StateError(
        'The area does not belong to the selected city.',
      );
    }

    if (data['isServiceActive'] != true) {
      throw StateError(
        'The selected area is not active for service.',
      );
    }
  }

  Future<bool> _hasActiveChild({
    required String parentCollection,
    required String parentId,
  }) async {
    Query<Map<String, dynamic>> query;

    switch (parentCollection) {
      case 'service_countries':
        query = _states
            .where('countryId', isEqualTo: parentId)
            .where('isActive', isEqualTo: true);
        break;

      case 'service_states':
        // New hierarchy: an active District is also a child of the State.
        // Preserve the legacy direct City lookup for older records that do
        // not yet carry districtId.
        final activeDistricts = await _districts
            .where('stateId', isEqualTo: parentId)
            .where('isServiceActive', isEqualTo: true)
            .limit(1)
            .get();
        if (activeDistricts.docs.isNotEmpty) return true;

        // Backward compatibility: older District records may only have
        // the pre-callable isActive field. Never treat this as the canonical
        // field for newly saved Districts.
        final legacyActiveDistricts = await _districts
            .where('stateId', isEqualTo: parentId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        if (legacyActiveDistricts.docs.isNotEmpty) return true;

        query = _cities
            .where('stateId', isEqualTo: parentId)
            .where('isServiceActive', isEqualTo: true);
        break;

      case 'service_districts':
        query = _cities
            .where('districtId', isEqualTo: parentId)
            .where('isServiceActive', isEqualTo: true);
        break;

      case 'service_cities':
        query = _areas
            .where('cityId', isEqualTo: parentId)
            .where('isServiceActive', isEqualTo: true);
        break;

      case 'service_areas':
        query = _localities
            .where('areaId', isEqualTo: parentId)
            .where('isServiceActive', isEqualTo: true);
        break;

      default:
        return false;
    }

    final result = await query.limit(1).get();

    return result.docs.isNotEmpty;
  }

  Future<void> _ensureNoActiveChildren({
    required String parentCollection,
    required String parentId,
    required String label,
  }) async {
    if (await _hasActiveChild(
      parentCollection: parentCollection,
      parentId: parentId,
    )) {
      throw StateError(
        'Deactivate active child locations before deactivating $label.',
      );
    }
  }

  // ==========================================================
  // VERIFIED BOUNDARY LOOKUP
  // ==========================================================

  Future<String?> _findVerifiedBoundaryId({
    required String locationId,
    required String locationType,
  }) async {
    final id = locationId.trim();

    if (id.isEmpty) return null;

    final normalizedType = locationType.trim().toLowerCase();

    final snapshot = await _boundaries
        .where('locationId', isEqualTo: id)
        .where('locationType', isEqualTo: normalizedType)
        .where(
          'verificationStatus',
          isEqualTo: 'verified',
        )
        .get();

    for (final document in snapshot.docs) {
      final data = document.data();

      final points = _readPoints(data['points']);

      final sourceName =
          data['sourceName']?.toString().trim() ?? '';

      final sourceReference =
          data['sourceReference']?.toString().trim() ?? '';

      final verifiedBy =
          data['verifiedBy']?.toString().trim() ?? '';

      final verifiedAt = data['verifiedAt'];

      if (points.length < 3) continue;

      if (!_hasValidPolygon(points)) continue;

      if (sourceName.isEmpty) continue;

      if (sourceReference.isEmpty) continue;

      if (verifiedBy.isEmpty) continue;

      if (verifiedAt == null) continue;

      if (verifiedAt is! Timestamp &&
          verifiedAt is! DateTime) {
        continue;
      }

      return document.id;
    }

    return null;
  }

  Future<String> _requireVerifiedBoundary({
    required String locationId,
    required String locationType,
  }) async {
    final boundaryId = await _findVerifiedBoundaryId(
      locationId: locationId,
      locationType: locationType,
    );

    if (boundaryId == null) {
      throw StateError(
        'A verified polygon boundary is required before '
        'activating this $locationType.',
      );
    }

    return boundaryId;
  }

  Future<List<GeoPoint>> _requireVerifiedBoundaryPoints({
    required String boundaryId,
    required String locationId,
    required String locationType,
  }) async {
    final id = _required(boundaryId, 'Verified boundary ID');
    final snapshot = await _boundaries.doc(id).get();

    if (!snapshot.exists) {
      throw StateError('The verified $locationType boundary was not found.');
    }

    final data = snapshot.data()!;
    if (data['locationId']?.toString() != locationId ||
        data['locationType']?.toString().toLowerCase() !=
            locationType.toLowerCase() ||
        data['verificationStatus'] != 'verified') {
      throw StateError(
        'The selected boundary is not verified for this $locationType.',
      );
    }

    final points = _readPoints(data['points']);
    if (!_hasValidPolygon(points)) {
      throw StateError('The verified $locationType boundary polygon is invalid.');
    }

    return points;
  }

  // ==========================================================
  // COUNTRIES
  // ==========================================================

  Stream<List<ServiceCountry>> watchCountries() {
    return _countries
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceCountry.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> saveCountry(
    ServiceCountry country,
  ) async {
    final name = _required(country.name, 'Country name');

    if (country.id.trim().isEmpty && country.isActive) {
      throw StateError('Create a Country as inactive, then activate it separately.');
    }

    final code = _required(country.code, 'Country code')
        .toUpperCase();

    if (!RegExp(r'^[A-Z]{2,3}$').hasMatch(code)) {
      throw ArgumentError(
        'Country code must contain 2 or 3 letters.',
      );
    }

    final id = country.id.trim().isEmpty
        ? _countries.doc().id
        : country.id.trim();

    await _saveUniqueNamedDocument(
      collection: _countries,
      documentId: id,
      name: name,
      data: {
        'name': name,
        'code': code,
        'isActive': country.isActive,
      },
    );
  }

  Future<void> setCountryStatus({
    required String countryId,
    required bool isActive,
  }) async {
    final id = _required(countryId, 'Country ID');

    if (!isActive) {
      await _ensureNoActiveChildren(
        parentCollection: 'service_countries',
        parentId: id,
        label: 'country',
      );
    }

    await _setTrustedStatus(
      locationType: 'country',
      locationId: id,
      isActive: isActive,
    );
  }

  // ==========================================================
  // STATES
  // ==========================================================

  Stream<List<ServiceState>> watchStates({
    String? countryId,
  }) {
    Query<Map<String, dynamic>> query = _states;

    if (countryId != null && countryId.trim().isNotEmpty) {
      query = query.where(
        'countryId',
        isEqualTo: countryId.trim(),
      );
    }

    return query.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceState.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> saveState(
    ServiceState state,
  ) async {
    final countryId = _required(
      state.countryId,
      'Country ID',
    );

    final name = _required(state.name, 'State name');

    if (state.id.trim().isEmpty && state.isActive) {
      throw StateError('Create a State as inactive, then activate it separately.');
    }

    await _requireDocument(
      _countries,
      countryId,
      'Country',
    );

    final oldId = state.id.trim();
    final id = oldId.isEmpty ? _states.doc().id : oldId;

    if (oldId.isNotEmpty) {
      final existing = await _states.doc(id).get();
      if (existing.exists &&
          existing.data()?['countryId']?.toString() != countryId) {
        throw StateError('A State parent cannot be changed after creation. Create a new State under the correct Country.');
      }
    }

    await _saveUniqueNamedDocument(
      collection: _states,
      documentId: id,
      name: name,
      data: {
        'countryId': countryId,
        'name': name,
        'isActive': state.isActive,
      },
    );
  }

  Future<void> setStateStatus({
    required String stateId,
    required bool isActive,
  }) async {
    final id = _required(stateId, 'State ID');

    if (isActive) {
      final state = await _requireDocument(
        _states,
        id,
        'State',
      );

      await _requireActiveCountry(
        state['countryId']?.toString() ?? '',
      );
    } else {
      await _ensureNoActiveChildren(
        parentCollection: 'service_states',
        parentId: id,
        label: 'state',
      );
    }

    await _setTrustedStatus(
      locationType: 'state',
      locationId: id,
      isActive: isActive,
    );
  }

  // ==========================================================
  // DISTRICTS
  // ==========================================================

  Stream<List<ServiceDistrict>> watchDistricts({
    String? countryId,
    String? stateId,
    bool? activeOnly,
  }) {
    Query<Map<String, dynamic>> query = _districts;
    if (countryId != null && countryId.trim().isNotEmpty) {
      query = query.where('countryId', isEqualTo: countryId.trim());
    }
    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateId.trim());
    }
    if (activeOnly == true) {
      // Firebase's trusted status callable writes the canonical field.
      query = query.where('isServiceActive', isEqualTo: true);
    }
    return query.orderBy('name').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ServiceDistrict.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<ServiceDistrict?> getDistrict(String districtId) async {
    final id = _required(districtId, 'District ID');
    final snapshot = await _districts.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ServiceDistrict.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<void> saveDistrict(ServiceDistrict district) async {
    final countryId = _required(district.countryId, 'Country ID');
    final stateId = _required(district.stateId, 'State ID');
    final name = _required(district.name, 'District name');
    if (district.id.trim().isEmpty && district.isActive) {
      throw StateError('Create a District as inactive, then activate it separately.');
    }
    await _requireDocument(_countries, countryId, 'Country');
    final state = await _requireDocument(_states, stateId, 'State');
    if (state['countryId']?.toString() != countryId) {
      throw StateError('The State does not belong to the selected Country.');
    }
    final id = district.id.trim().isEmpty
        ? _districts.doc().id
        : district.id.trim();
    if (district.id.trim().isNotEmpty) {
      final old = await _districts.doc(id).get();
      if (old.exists &&
          (old.data()?['countryId']?.toString() != countryId ||
              old.data()?['stateId']?.toString() != stateId)) {
        throw StateError('A District parent cannot be changed after creation.');
      }
    }
    await _saveUniqueNamedDocument(
      collection: _districts,
      documentId: id,
      name: name,
      data: {'countryId': countryId, 'stateId': stateId, 'name': name},
    );
  }

  Future<void> setDistrictStatus({
    required String districtId,
    required bool isActive,
  }) async {
    final id = _required(districtId, 'District ID');
    if (isActive) {
      final district = await _requireDocument(_districts, id, 'District');
      final countryId = district['countryId']?.toString() ?? '';
      final stateId = district['stateId']?.toString() ?? '';
      await _requireActiveCountry(countryId);
      await _requireActiveState(stateId, countryId);
    }
    await _setTrustedStatus(
      locationType: 'district',
      locationId: id,
      isActive: isActive,
    );
  }

  // ==========================================================
  // SINGLE CITY LOOKUP
  // ==========================================================

  Future<ServiceCity?> getCity(String cityId) async {
    final id = _required(cityId, 'City ID');

    final snapshot = await _cities.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return ServiceCity.fromMap(
      snapshot.id,
      data,
    );
  }

  // ==========================================================
  // CITIES / DISTRICTS
  // ==========================================================

  Stream<List<ServiceCity>> watchCities({
    String? countryId,
    String? stateId,
    bool? activeOnly,
  }) {
    Query<Map<String, dynamic>> query = _cities;

    if (countryId != null && countryId.trim().isNotEmpty) {
      query = query.where(
        'countryId',
        isEqualTo: countryId.trim(),
      );
    }

    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where(
        'stateId',
        isEqualTo: stateId.trim(),
      );
    }

    if (activeOnly == true) {
      query = query.where(
        'isServiceActive',
        isEqualTo: true,
      );
    }

    return query.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceCity.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> saveCity(
    ServiceCity city,
  ) async {
    final countryId = _required(
      city.countryId,
      'Country ID',
    );

    final stateId = _required(
      city.stateId,
      'State ID',
    );

    final name = _required(city.name, 'City name');
    final districtId = city.districtId.trim();

    if (districtId.isNotEmpty) {
      final district = await _requireDocument(_districts, districtId, 'District');
      if (district['countryId']?.toString() != countryId ||
          district['stateId']?.toString() != stateId) {
        throw StateError('The District does not belong to the selected Country and State.');
      }
    }

    final oldId = city.id.trim();

    if (oldId.isEmpty && city.isServiceActive) {
      throw StateError('Create a City as inactive; verify its boundary before activation.');
    }

    final id = oldId.isEmpty ? _cities.doc().id : oldId;

    await _requireDocument(
      _countries,
      countryId,
      'Country',
    );

    final stateData = await _requireDocument(
      _states,
      stateId,
      'State',
    );

    if (stateData['countryId'] != countryId) {
      throw StateError(
        'The state does not belong to the selected country.',
      );
    }

    String verifiedBoundaryId = city.verifiedBoundaryId.trim();

    if (city.isServiceActive) {
      await _requireActiveCountry(countryId);

      await _requireActiveState(stateId, countryId);

      verifiedBoundaryId = await _requireVerifiedBoundary(
        locationId: id,
        locationType: 'city',
      );
    }

    final existingSnapshot = await _cities.doc(id).get();

    if (existingSnapshot.exists) {
      final oldData = existingSnapshot.data()!;

      final oldCountryId = oldData['countryId']?.toString() ?? '';
      final oldStateId = oldData['stateId']?.toString() ?? '';
      final oldDistrictId = oldData['districtId']?.toString() ?? '';

      if ((oldDistrictId.isEmpty) != districtId.isEmpty) {
        throw StateError('Adding or removing a City District requires a separate migration.');
      }
      if (oldDistrictId.isNotEmpty && oldDistrictId != districtId) {
        throw StateError('A City District cannot be changed after creation.');
      }

      if (oldCountryId != countryId || oldStateId != stateId) {
        throw StateError('A City parent cannot be changed after creation. Create a new City under the correct State.');
      }
    }

    final savedCity = city.copyWith(
      id: id,
      countryId: countryId,
      stateId: stateId,
      districtId: districtId,
      name: name,
      verifiedBoundaryId: verifiedBoundaryId,
    );

    await _saveUniqueNamedDocument(
      collection: _cities,
      documentId: id,
      name: name,
      data: savedCity.toMap(),
    );
  }

  Future<void> setCityServiceStatus({
    required String cityId,
    required bool isActive,
  }) async {
    final id = _required(cityId, 'City ID');

    final city = await _requireDocument(
      _cities,
      id,
      'City',
    );

    if (isActive) {
      final countryId =
          city['countryId']?.toString() ?? '';

      final stateId =
          city['stateId']?.toString() ?? '';

      await _requireActiveCountry(countryId);

      await _requireActiveState(stateId, countryId);

      await _requireVerifiedBoundary(
        locationId: id,
        locationType: 'city',
      );
    } else {
      await _ensureNoActiveChildren(
        parentCollection: 'service_cities',
        parentId: id,
        label: 'city',
      );
    }

    if (isActive) {
      await _activateTrustedBoundaryLocation(
        locationType: 'city',
        locationId: id,
      );
    } else {
      await _setTrustedStatus(
        locationType: 'city',
        locationId: id,
        isActive: false,
      );
    }
  }

  // ==========================================================
  // AREAS / SUB-DISTRICTS
  // ==========================================================

  Stream<List<ServiceArea>> watchAreas({
    String? countryId,
    String? stateId,
    String? cityId,
    bool? activeOnly,
  }) {
    Query<Map<String, dynamic>> query = _areas;

    if (countryId != null && countryId.trim().isNotEmpty) {
      query = query.where(
        'countryId',
        isEqualTo: countryId.trim(),
      );
    }

    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where(
        'stateId',
        isEqualTo: stateId.trim(),
      );
    }

    if (cityId != null && cityId.trim().isNotEmpty) {
      query = query.where(
        'cityId',
        isEqualTo: cityId.trim(),
      );
    }

    if (activeOnly == true) {
      query = query.where(
        'isServiceActive',
        isEqualTo: true,
      );
    }

    return query.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceArea.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> saveArea(
    ServiceArea area,
  ) async {
    final cityId = _required(area.cityId, 'City ID');

    final name = _required(area.name, 'Area name');

    final oldId = area.id.trim();

    if (oldId.isEmpty && area.isServiceActive) {
      throw StateError('Create an Area as inactive; verify its boundary before activation.');
    }

    final id = oldId.isEmpty ? _areas.doc().id : oldId;

    final cityData = await _requireDocument(
      _cities,
      cityId,
      'City',
    );

    final countryId = area.countryId.trim().isNotEmpty
        ? area.countryId.trim()
        : cityData['countryId']?.toString() ?? '';

    final stateId = area.stateId.trim().isNotEmpty
        ? area.stateId.trim()
        : cityData['stateId']?.toString() ?? '';

    if (cityData['countryId'] != countryId ||
        cityData['stateId'] != stateId) {
      throw StateError(
        'The selected city does not match the country/state.',
      );
    }

    String verifiedBoundaryId = area.verifiedBoundaryId.trim();

    if (area.isServiceActive) {
      await _requireActiveCountry(countryId);

      await _requireActiveState(stateId, countryId);

      await _requireActiveCity(cityId, stateId);

      verifiedBoundaryId = await _requireVerifiedBoundary(
        locationId: id,
        locationType: 'area',
      );

      final city = await _requireDocument(
        _cities,
        cityId,
        'City',
      );
      final cityBoundaryId =
          city['verifiedBoundaryId']?.toString().trim() ?? '';
      final cityBoundaryPoints = await _requireVerifiedBoundaryPoints(
        boundaryId: cityBoundaryId,
        locationId: cityId,
        locationType: 'city',
      );
      final areaBoundaryPoints = await _requireVerifiedBoundaryPoints(
        boundaryId: verifiedBoundaryId,
        locationId: id,
        locationType: 'area',
      );

      if (!ServiceLocationGeometry.isPolygonContained(
        parent: cityBoundaryPoints,
        child: areaBoundaryPoints,
      )) {
        throw StateError(
          'The Area boundary must be fully inside or on the parent City boundary.',
        );
      }
    }

    final existingSnapshot = await _areas.doc(id).get();

    if (existingSnapshot.exists) {
      final oldData = existingSnapshot.data()!;

      final oldCountryId = oldData['countryId']?.toString() ?? '';
      final oldStateId = oldData['stateId']?.toString() ?? '';
      final oldCityId = oldData['cityId']?.toString() ?? '';

      if (oldCountryId != countryId || oldStateId != stateId || oldCityId != cityId) {
        throw StateError('An Area parent cannot be changed after creation. Create a new Area under the correct City.');
      }
    }

    final savedArea = area.copyWith(
      id: id,
      countryId: countryId,
      stateId: stateId,
      cityId: cityId,
      name: name,
      verifiedBoundaryId: verifiedBoundaryId,
    );

    await _saveUniqueNamedDocument(
      collection: _areas,
      documentId: id,
      name: name,
      data: savedArea.toMap(),
    );
  }

  Future<void> setAreaServiceStatus({
    required String areaId,
    required bool isActive,
  }) async {
    final id = _required(areaId, 'Area ID');

    final area = await _requireDocument(
      _areas,
      id,
      'Area',
    );

    if (isActive) {
      final countryId =
          area['countryId']?.toString() ?? '';

      final stateId =
          area['stateId']?.toString() ?? '';

      final cityId =
          area['cityId']?.toString() ?? '';

      await _requireActiveCountry(countryId);

      await _requireActiveState(stateId, countryId);

      await _requireActiveCity(cityId, stateId);

      await _requireVerifiedBoundary(
        locationId: id,
        locationType: 'area',
      );
    } else {
      await _ensureNoActiveChildren(
        parentCollection: 'service_areas',
        parentId: id,
        label: 'area',
      );
    }

    if (isActive) {
      await _activateTrustedBoundaryLocation(
        locationType: 'area',
        locationId: id,
      );
    } else {
      await _setTrustedStatus(
        locationType: 'area',
        locationId: id,
        isActive: false,
      );
    }
  }

  // ==========================================================
  // LOCALITIES / VILLAGES
  //
  // A locality does not need its own polygon.
  // Its parent Area must be active for activation.
  // ==========================================================

  Stream<List<ServiceLocality>> watchLocalities({
    String? countryId,
    String? stateId,
    String? cityId,
    String? areaId,
    bool? activeOnly,
  }) {
    Query<Map<String, dynamic>> query = _localities;

    if (countryId != null && countryId.trim().isNotEmpty) {
      query = query.where(
        'countryId',
        isEqualTo: countryId.trim(),
      );
    }

    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where(
        'stateId',
        isEqualTo: stateId.trim(),
      );
    }

    if (cityId != null && cityId.trim().isNotEmpty) {
      query = query.where(
        'cityId',
        isEqualTo: cityId.trim(),
      );
    }

    if (areaId != null && areaId.trim().isNotEmpty) {
      query = query.where(
        'areaId',
        isEqualTo: areaId.trim(),
      );
    }

    if (activeOnly == true) {
      query = query.where(
        'isServiceActive',
        isEqualTo: true,
      );
    }

    return query.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceLocality.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> saveLocality(
    ServiceLocality locality,
  ) async {
    final areaId = _required(
      locality.areaId,
      'Area ID',
    );

    final name = _required(
      locality.name,
      'Locality name',
    );

    final oldId = locality.id.trim();

    if (oldId.isEmpty && locality.isServiceActive) {
      throw StateError('Create a Locality as inactive, then activate it separately.');
    }

    final id = oldId.isEmpty
        ? _localities.doc().id
        : oldId;

    final areaData = await _requireDocument(
      _areas,
      areaId,
      'Area',
    );

    final cityId = locality.cityId.trim().isNotEmpty
        ? locality.cityId.trim()
        : areaData['cityId']?.toString() ?? '';

    final countryId = locality.countryId.trim().isNotEmpty
        ? locality.countryId.trim()
        : areaData['countryId']?.toString() ?? '';

    final stateId = locality.stateId.trim().isNotEmpty
        ? locality.stateId.trim()
        : areaData['stateId']?.toString() ?? '';

    if (areaData['cityId'] != cityId ||
        areaData['countryId'] != countryId ||
        areaData['stateId'] != stateId) {
      throw StateError(
        'The selected Area does not match the location hierarchy.',
      );
    }

    if (locality.isServiceActive) {
      await _requireActiveCountry(countryId);

      await _requireActiveState(stateId, countryId);

      await _requireActiveCity(cityId, stateId);

      await _requireActiveArea(areaId, cityId);
    }

    // A locality polygon is optional.
    if (locality.boundary.isNotEmpty) {
      final validPoints = _readPoints(locality.boundary);

      if (validPoints.length != locality.boundary.length) {
        throw ArgumentError(
          'The optional locality boundary contains invalid coordinates.',
        );
      }
    }

    final existingSnapshot = await _localities.doc(id).get();

    if (existingSnapshot.exists) {
      final oldData = existingSnapshot.data()!;

      final oldCountryId = oldData['countryId']?.toString() ?? '';
      final oldStateId = oldData['stateId']?.toString() ?? '';
      final oldCityId = oldData['cityId']?.toString() ?? '';
      final oldAreaId = oldData['areaId']?.toString() ?? '';

      if (oldCountryId != countryId || oldStateId != stateId || oldCityId != cityId || oldAreaId != areaId) {
        throw StateError('A Locality parent cannot be changed after creation. Create a new Locality under the correct Area.');
      }
    }

    final savedLocality = locality.copyWith(
      id: id,
      countryId: countryId,
      stateId: stateId,
      cityId: cityId,
      areaId: areaId,
      name: name,
    );

    await _saveUniqueNamedDocument(
      collection: _localities,
      documentId: id,
      name: name,
      data: savedLocality.toMap(),
    );
  }

  Future<void> setLocalityServiceStatus({
    required String localityId,
    required bool isActive,
  }) async {
    final id = _required(localityId, 'Locality ID');

    final locality = await _requireDocument(
      _localities,
      id,
      'Locality',
    );

    if (isActive) {
      final countryId =
          locality['countryId']?.toString() ?? '';

      final stateId =
          locality['stateId']?.toString() ?? '';

      final cityId =
          locality['cityId']?.toString() ?? '';

      final areaId =
          locality['areaId']?.toString() ?? '';

      await _requireActiveCountry(countryId);

      await _requireActiveState(stateId, countryId);

      await _requireActiveCity(cityId, stateId);

      await _requireActiveArea(areaId, cityId);
    }

    // No locality polygon requirement; the server validates ancestry.
    await _setTrustedStatus(
      locationType: 'locality',
      locationId: id,
      isActive: isActive,
    );
  }

  // ==========================================================
  // LOCATION IMPORTS
  // ==========================================================

  Stream<List<ServiceLocationImport>> watchImports() {
    return _imports
        .orderBy('importedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceLocationImport.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// Creates the trusted, durable run marker before any location writes.
  /// The backend rejects reuse of any existing run ID, including matching
  /// fingerprints. Use the read-only reconciliation flow before deciding how
  /// to handle an interrupted run; this method never resumes or repairs it.
  Future<void> beginImportRun({
    required String runId,
    required String countryId,
    required String fileName,
    required String inputFingerprint,
  }) async {
    final callable = _functions.httpsCallable('manageServiceLocationImportRun');
    await callable.call<Map<String, dynamic>>({
      'action': 'begin',
      'runId': runId,
      'countryId': countryId,
      'fileName': fileName,
      'inputFingerprint': inputFingerprint,
    });
  }

  /// Persists the bounded canonical plan on the trusted backend before any
  /// hierarchy writes. Existing runs with a recorded plan are immutable.
  Future<void> recordImportPlan({
    required String runId,
    required String inputFingerprint,
    required List<Map<String, dynamic>> nodes,
  }) async {
    final callable = _functions.httpsCallable('manageServiceLocationImportRun');
    await callable.call<Map<String, dynamic>>({
      'action': 'recordPlan',
      'runId': runId,
      'inputFingerprint': inputFingerprint,
      'nodes': nodes,
    });
  }

  /// Reads the server-owned run marker for reconciliation. This does not
  /// resume or mutate an import; use [reconcileImportPlan] to compare the
  /// immutable recorded plan with the current hierarchy.
  Future<Map<String, dynamic>> inspectImportRun({
    required String runId,
    required String inputFingerprint,
  }) async {
    final callable = _functions.httpsCallable('manageServiceLocationImportRun');
    final result = await callable.call<Map<String, dynamic>>({
      'action': 'inspect',
      'runId': runId,
      'inputFingerprint': inputFingerprint,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Performs a read-only comparison of the recorded import plan against the
  /// current trusted hierarchy documents. This never resumes or repairs writes.
  Future<Map<String, dynamic>> reconcileImportPlan({
    required String runId,
    required String inputFingerprint,
  }) async {
    final callable = _functions.httpsCallable('manageServiceLocationImportRun');
    final result = await callable.call<Map<String, dynamic>>({
      'action': 'reconcilePlan',
      'runId': runId,
      'inputFingerprint': inputFingerprint,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Finalizes a previously started run. The server validates actor ownership,
  /// fingerprint and allowed status transitions.
  Future<void> finishImportRun({
    required String runId,
    required String inputFingerprint,
    required String status,
    required int plannedRecords,
    required int createdRecords,
    required int reusedRecords,
  }) async {
    final callable = _functions.httpsCallable('manageServiceLocationImportRun');
    await callable.call<void>({
      'action': 'finalize',
      'runId': runId,
      'inputFingerprint': inputFingerprint,
      'status': status,
      'plannedRecords': plannedRecords,
      'createdRecords': createdRecords,
      'reusedRecords': reusedRecords,
    });
  }

  Future<String> saveImport(
    ServiceLocationImport importRecord,
  ) async {
    final currentUserId = _currentUserIdProvider();

    if (currentUserId == null || currentUserId.trim().isEmpty) {
      throw StateError('Sign in as an admin before recording an import.');
    }

    if (importRecord.importedBy.trim() != currentUserId) {
      throw StateError('The import actor must match the signed-in admin.');
    }

    final id = importRecord.id.trim().isEmpty
        ? _imports.doc().id
        : importRecord.id.trim();

    final reference = _imports.doc(id);

    final data = <String, dynamic>{
      'source': _required(
        importRecord.source,
        'Import source',
      ),
      'fileName': _required(
        importRecord.fileName,
        'Import file name',
      ),
      'status': _required(
        importRecord.status,
        'Import status',
      ),
      'importedBy': currentUserId,
      'importedAt': FieldValue.serverTimestamp(),
      'verificationStatus': _required(
        importRecord.verificationStatus,
        'Import verification status',
      ),
      if (importRecord.inputFingerprint.trim().isNotEmpty)
        'inputFingerprint': importRecord.inputFingerprint.trim(),
    };

    final snapshot = await reference.get();

    if (snapshot.exists) {
      throw StateError(
        'An import record cannot be overwritten.',
      );
    }

    await reference.set(data);

    return id;
  }
}
