import 'package:flutter/material.dart';

import '../data/admin_location_option.dart';
import '../data/admin_service_location_repository.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _repository = AdminServiceLocationRepository();

  static const _types = <String, String>{
    'country': 'Country',
    'state': 'State / Union Territory',
    'district': 'District',
    'city': 'City',
    'area': 'Area',
    'locality': 'Locality / Village',
  };

  String _type = 'state';
  String? _countryId;
  String? _stateId;
  String? _districtId;
  String? _cityId;
  String? _areaId;
  bool _saving = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  bool get _needsCountry => _type != 'country';
  bool get _needsState => const {'district', 'city', 'area', 'locality'}.contains(_type);
  bool get _needsDistrict => const {'city', 'area', 'locality'}.contains(_type);
  bool get _needsCity => const {'area', 'locality'}.contains(_type);
  bool get _needsArea => _type == 'locality';

  void _changeType(String? value) {
    if (value == null) return;
    setState(() {
      _type = value;
      _countryId = null;
      _stateId = null;
      _districtId = null;
      _cityId = null;
      _areaId = null;
      _feedback = null;
      _nameController.clear();
      _codeController.clear();
      _pincodeController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _feedback = null;
    });

    try {
      final parents = <String, String>{
        if (_needsCountry) 'countryId': _countryId ?? '',
        if (_needsState) 'stateId': _stateId ?? '',
        if (_needsDistrict) 'districtId': _districtId ?? '',
        if (_needsCity) 'cityId': _cityId ?? '',
        if (_needsArea) 'areaId': _areaId ?? '',
      };
      final id = await _repository.saveLocation(
        type: _type,
        parentIds: parents,
        name: _nameController.text,
        code: _type == 'country' ? _codeController.text : null,
        pincode: _type == 'locality' ? _pincodeController.text : null,
      );
      if (!mounted) return;
      setState(() {
        _feedback = 'Saved successfully. Record ID: $id. It remains inactive until its required review/activation steps are completed.';
        _feedbackIsError = false;
        _nameController.clear();
        _codeController.clear();
        _pincodeController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _feedback = _friendlyError(error);
        _feedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('already exists') ||
        message.contains('duplicate') ||
        message.contains('name index')) {
      return 'Is parent ke andar ye naam pehle se ho sakta hai. Naam check karke try karein.';
    }
    if (message.contains('permission-denied') ||
        message.contains('Admin access')) {
      return 'Permission nahi mili. Active super_admin login aur Firebase Rules check karein.';
    }
    if (message.contains('failed-precondition')) {
      return 'Parent location ya backend validation match nahi hui. Selected hierarchy check karein.';
    }
    if (message.contains('network')) {
      return 'Network check karke dobara try karein.';
    }
    return 'Location save nahi hui. Input aur backend logs check karein.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 760 ? 16 : 28,
          vertical: 24,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF0E2), Color(0xFFFFFAF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD2AD)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.add_location_alt_outlined,
                    color: Color(0xFFFF7900),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Service Location',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF252525),
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'India → State / UT → District → City → Area → Locality',
                        style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Location records trusted Firebase callable ke through save hote hain. '
                        'Parent hierarchy server par verify hoti hai; client protected collections mein direct write nahi karta.',
                        style: TextStyle(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'What do you want to add?'),
                  items: _types.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: _saving ? null : _changeType,
                ),
                const SizedBox(height: 16),
                if (_needsCountry) ...[
                  _locationDropdown(
                    label: 'Country',
                    type: 'country',
                    value: _countryId,
                    onChanged: (value) => setState(() {
                      _countryId = value;
                      _stateId = null;
                      _districtId = null;
                      _cityId = null;
                      _areaId = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_needsState) ...[
                  _locationDropdown(
                    label: 'State / Union Territory',
                    type: 'state',
                    value: _stateId,
                    countryId: _countryId,
                    enabled: _countryId != null,
                    onChanged: (value) => setState(() {
                      _stateId = value;
                      _districtId = null;
                      _cityId = null;
                      _areaId = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_needsDistrict) ...[
                  _locationDropdown(
                    label: 'District',
                    type: 'district',
                    value: _districtId,
                    countryId: _countryId,
                    stateId: _stateId,
                    enabled: _stateId != null,
                    onChanged: (value) => setState(() {
                      _districtId = value;
                      _cityId = null;
                      _areaId = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_needsCity && _districtId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7EC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD2AD)),
                    ),
                    child: const Text(
                      'Compatibility note: older City records without a District mapping may not appear here. Do not assign a District by guess; review and migrate those records through the approved data process first.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
                if (_needsCity) ...[
                  _locationDropdown(
                    label: 'City',
                    type: 'city',
                    value: _cityId,
                    countryId: _countryId,
                    stateId: _stateId,
                    districtId: _districtId,
                    enabled: _districtId != null,
                    onChanged: (value) => setState(() {
                      _cityId = value;
                      _areaId = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_needsArea) ...[
                  _locationDropdown(
                    label: 'Area',
                    type: 'area',
                    value: _areaId,
                    countryId: _countryId,
                    stateId: _stateId,
                    cityId: _cityId,
                    enabled: _cityId != null,
                    onChanged: (value) => setState(() => _areaId = value),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: '${_types[_type]} name',
                    hintText: 'Enter exact official name',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Name required hai.';
                    if (name.length > 120) return 'Maximum 120 characters.';
                    return null;
                  },
                ),
                if (_type == 'country') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      labelText: 'Country code',
                      hintText: 'IN',
                    ),
                    validator: (value) {
                      if (_type != 'country') return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Country code required hai.';
                      }
                      return null;
                    },
                  ),
                ],
                if (_type == 'locality') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'PIN code (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD2AD)),
                  ),
                  child: Text(
                    _type == 'city' || _type == 'area'
                        ? 'Important: City/Area save hone ke baad bhi inactive rahega. Activation se pehle boundary polygon review/verification zaroori hai. Radius-only coverage allowed nahi hai.'
                        : _type == 'locality'
                            ? 'Locality parent Area ke andar save hogi. Locality ko apna polygon dena zaroori nahi, lekin parent hierarchy valid honi chahiye.'
                            : 'Record inactive/default state mein create hoga. Activation alag trusted action se hi hoga.',
                  ),
                ),
                const SizedBox(height: 18),
                if (_feedback != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _feedbackIsError
                          ? const Color(0xFFFFE9E7)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_feedback!),
                  ),
                  const SizedBox(height: 14),
                ],
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving securely…' : 'Save location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearInvalidSelection(String type, String staleValue) {
    if (!mounted) return;
    setState(() {
      switch (type) {
        case 'country':
          if (_countryId != staleValue) return;
          _countryId = null;
          _stateId = null;
          _districtId = null;
          _cityId = null;
          _areaId = null;
          break;
        case 'state':
          if (_stateId != staleValue) return;
          _stateId = null;
          _districtId = null;
          _cityId = null;
          _areaId = null;
          break;
        case 'district':
          if (_districtId != staleValue) return;
          _districtId = null;
          _cityId = null;
          _areaId = null;
          break;
        case 'city':
          if (_cityId != staleValue) return;
          _cityId = null;
          _areaId = null;
          break;
        case 'area':
          if (_areaId != staleValue) return;
          _areaId = null;
          break;
        default:
          return;
      }
      _feedback = 'Catalog options changed. Please review the parent selections.';
      _feedbackIsError = true;
    });
  }

  Widget _locationDropdown({
    required String label,
    required String type,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? countryId,
    String? stateId,
    String? districtId,
    String? cityId,
    String? areaId,
    bool enabled = true,
  }) {
    if (!enabled) {
      return DropdownButtonFormField<String>(
        initialValue: null,
        decoration: InputDecoration(labelText: label, helperText: 'Pehle parent location select karein.'),
        items: const [],
        onChanged: null,
        validator: (_) => '$label select karein.',
      );
    }
    final stream = _repository.watchOptions(
      type,
      countryId: countryId,
      stateId: stateId,
      districtId: districtId,
      cityId: cityId,
      areaId: areaId,
    );

    return StreamBuilder<List<AdminLocationOption>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: 'Catalog load nahi hua. Access/network check karein.',
            ),
            child: const Text('Unavailable'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return InputDecorator(
            decoration: InputDecoration(labelText: label),
            child: const LinearProgressIndicator(),
          );
        }
        final options = snapshot.data ?? const <AdminLocationOption>[];
        final validValue = options.any((option) => option.id == value)
            ? value
            : null;
        if (value != null && validValue == null) {
          // A live catalog update can remove an option after it was selected.
          // Clear the stale ID (and its descendants) after this frame so the
          // form cannot submit an ID that is no longer offered by the catalog.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _clearInvalidSelection(type, value);
          });
        }
        return DropdownButtonFormField<String>(
          initialValue: validValue,
          decoration: InputDecoration(labelText: label),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option.id,
                    child: Text(option.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: options.isEmpty || _saving ? null : onChanged,
          validator: (selected) =>
              selected == null ? '$label select karein.' : null,
        );
      },
    );
  }
}
