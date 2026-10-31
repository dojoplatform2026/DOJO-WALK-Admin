import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/service_boundary_preview_validator.dart';
import '../widgets/service_boundary_editor.dart';
import 'boundary_review_screen.dart';

/// UI-only Zone creation form based on DOJO WALK POL-040.
/// This screen intentionally does not write to Firebase yet.
class AddZoneScreen extends StatefulWidget {
  const AddZoneScreen({super.key});

  @override
  State<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends State<AddZoneScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);

  final _formKey = GlobalKey<FormState>();
  final _zoneName = TextEditingController();
  String? _state;
  String? _district;
  String? _city;
  String? _zoneSelection;
  String _boundaryStatus = 'Not drawn';
  String _boundaryValidationFeedback = 'Add at least 3 points (0/3).';
  List<LatLng> _boundaryPreviewPoints = const [];
  bool _saving = false;

  // Placeholder catalog values for UI development only; not production data.
  final Map<String, Map<String, List<String>>> _catalog = const {
    'Uttar Pradesh': {
      'Gautam Buddha Nagar': ['Noida', 'Greater Noida'],
      'Ghaziabad': ['Ghaziabad'],
    },
    'Delhi': {
      'New Delhi': ['New Delhi'],
    },
  };

  @override
  void dispose() {
    _zoneName.dispose();
    super.dispose();
  }

  List<String> get _districts =>
      _state == null ? const [] : (_catalog[_state]?.keys.toList() ?? const []);

  List<String> get _cities => _state == null || _district == null
      ? const []
      : (_catalog[_state]?[_district] ?? const []);

  // Clearly labelled example catalog for UI-only development. These are
  // not live Zone records; the approved catalog will replace them after the
  // Notion-defined data contract is connected.
  List<String> get _zoneOptions {
    if (_city == null) return const [];
    return switch (_city) {
      'Noida' => const [
          'Create new Zone…',
          'Example Zone North (mock)',
          'Example Zone Central (mock)',
        ],
      'Greater Noida' => const [
          'Create new Zone…',
          'Example Zone South (mock)',
        ],
      'Ghaziabad' => const [
          'Create new Zone…',
          'Example Zone East (mock)',
        ],
      'New Delhi' => const [
          'Create new Zone…',
          'Example Zone Capital (mock)',
        ],
      _ => const ['Create new Zone…'],
    };
  }

  bool get _creatingZone => _zoneSelection == 'Create new Zone…';

  void _resetBelowState() {
    _district = null;
    _city = null;
    _zoneSelection = null;
    _zoneName.clear();
    _clearBoundaryPreview();
  }

  void _clearBoundaryPreview() {
    _boundaryPreviewPoints = const [];
    _boundaryStatus = 'Not drawn';
    _boundaryValidationFeedback = 'Add at least 3 points (0/3).';
  }

  Future<void> _openBoundaryEditor() async {
    if (!_creatingZone) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFFAF5),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Zone boundary — local preview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the map to add polygon points. This preview stays in this screen only; it is not uploaded, verified, or saved.',
                style: TextStyle(height: 1.45, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ServiceBoundaryEditor(
                initialPoints: _boundaryPreviewPoints,
                onValidationFeedbackChanged: (feedback) {
                  if (!mounted) return;
                  setState(() => _boundaryValidationFeedback = feedback);
                },
                onBoundaryChanged: (points) {
                  if (!mounted) return;
                  setState(() {
                    _boundaryPreviewPoints = List<LatLng>.of(points);
                    _boundaryStatus = points.isEmpty
                        ? 'Not drawn'
                        : 'Local preview only — ${points.length} points; not saved';
                  });
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close preview'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? helper}) =>
      InputDecoration(labelText: label, helperText: helper);

  Widget _selector({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? helper,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label, helper: helper),
      items: options
          .map((option) =>
              DropdownMenuItem<String>(value: option, child: Text(option)))
          .toList(),
      onChanged: options.isEmpty ? null : onChanged,
      validator: (selected) =>
          selected == null ? 'Please select $label' : null,
    );
  }

  Future<void> _validateForm() async {
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid) return;

    // Existing mock Zones are reference-only and must never be treated as a
    // new Zone submission.
    final isCreatingNewZone = _creatingZone;
    final hasBasicGeometry =
        ServiceBoundaryPreviewValidator.isValid(_boundaryPreviewPoints);
    final validationMessage = isCreatingNewZone
        ? [
            hasBasicGeometry
                ? 'Local polygon shape check: passed (not GIS-verified).'
                : 'Local polygon shape check: failed — ' + _boundaryValidationFeedback,
            'Boundary evidence is not uploaded and GIS verification is pending.',
            'The State/UT → District → City options are still example catalog data.',
            'Save Draft and Submit for Review remain disabled. Nothing has been saved.',
          ].join(' | ')
        : 'Existing Zone options are mock records for preview only. '
            'Select “Create new Zone…” to validate a new Zone draft. '
            'Nothing has been edited or saved.';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCreatingNewZone ? 'Validation incomplete' : 'Example Zone selected',
        ),
        content: Text(validationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Add Service Zone'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Zone',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the administrative hierarchy, define a zone, '
                    'and submit its boundary for review. Only a Founder/CEO '
                    'approval can authorize launch.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Administrative hierarchy',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _selector(
                            label: 'State / UT',
                            value: _state,
                            options: _catalog.keys.toList(),
                            onChanged: (value) => setState(() {
                              _state = value;
                              _resetBelowState();
                            }),
                          ),
                          const SizedBox(height: 16),
                          _selector(
                            label: 'District',
                            value: _district,
                            options: _districts,
                            onChanged: (value) => setState(() {
                              _district = value;
                              _city = null;
                              _zoneSelection = null;
                              _zoneName.clear();
                              _clearBoundaryPreview();
                            }),
                          ),
                          const SizedBox(height: 16),
                          _selector(
                            label: 'City',
                            value: _city,
                            options: _cities,
                            onChanged: (value) => setState(() {
                              _city = value;
                              _zoneSelection = null;
                              _zoneName.clear();
                              _clearBoundaryPreview();
                            }),
                          ),
                          const SizedBox(height: 16),
                          _selector(
                            label: 'Zone',
                            value: _zoneSelection,
                            options: _zoneOptions,
                            helper: 'Fourth dependent selector. Any existing Zone options shown are clearly marked mock records; live catalog is not connected.',
                            onChanged: (value) => setState(() {
                              _zoneSelection = value;
                              if (value != 'Create new Zone…') {
                                _zoneName.clear();
                                _clearBoundaryPreview();
                              }
                            }),
                          ),
                          if (_zoneSelection != null && !_creatingZone) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0DF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Mock existing Zone selected. This form will not edit it; use Zone Details to review records. No live data is loaded.',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                          if (_creatingZone) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _zoneName,
                              decoration: _decoration(
                                'New Zone name',
                                helper: 'Use a stable Zone ID in the system; '
                                    'the display name is not the identity.',
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) => !_creatingZone ||
                                      (value != null && value.trim().length >= 2)
                                  ? null
                                  : 'Enter a zone name',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '2. Service boundary',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'A zone polygon must be drawn or uploaded and '
                            'checked before it can be submitted for approval. '
                            'A radius alone is not sufficient.',
                            style: TextStyle(height: 1.5, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFAF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE9D9CB)),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final status = Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.map_outlined, color: _orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Boundary status: $_boundaryStatus',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                                final editorButton = OutlinedButton.icon(
                                  onPressed: _creatingZone ? _openBoundaryEditor : null,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Open boundary editor'),
                                );

                                if (constraints.maxWidth < 500) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      status,
                                      const SizedBox(height: 12),
                                      editorButton,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: status),
                                    const SizedBox(width: 12),
                                    editorButton,
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Local geometry check: $_boundaryValidationFeedback',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Map drawing is available as an in-memory preview only. '
                            'Points are not uploaded or verified; authoritative GIS '
                            'checks, boundary hash, draft save, and review submission '
                            'remain unavailable.',
                            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '3. Review & approval',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.fact_check_outlined, color: _orange),
                            title: Text('Central Admin'),
                            subtitle: Text(
                              'Checks hierarchy, boundary evidence, coverage, '
                              'and readiness before submitting.',
                            ),
                          ),
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.verified_user_outlined, color: _orange),
                            title: Text('Founder / CEO'),
                            subtitle: Text(
                              'Final business approval is required before zone launch.',
                            ),
                          ),
                          const Text(
                            'Saving this UI preview does not create a Zone, '
                            'activate service, or send an approval request.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.maybePop(context),
                        child: const Text('Cancel'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const BoundaryReviewScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Preview Boundary Review'),
                      ),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Draft disabled'),
                      ),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Submit for Review disabled'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saving ? null : _validateForm,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Validate readiness'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Submit remains disabled until polygon evidence is drawn and verified, the boundary hash is recorded, and readiness blockers are cleared. No draft or approval request is saved in this UI-only preview.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
