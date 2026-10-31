import 'package:flutter/material.dart';

/// UI-only pet profile prototype aligned with customer/dog safety policies.
class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  State<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);
  final search = TextEditingController();
  String filter = 'All';

  final pets = const [
    _Pet('DOG-EX-001', 'Example Dog A', 'CUS-EX-001', 'Not recorded in preview',
        'Handling review required', 'Not verified in preview', 'Care notes not loaded'),
    _Pet('DOG-EX-002', 'Example Dog B', 'CUS-EX-002', 'Not recorded in preview',
        'No live assessment', 'Not verified in preview', 'Care notes not loaded'),
    _Pet('DOG-EX-003', 'Example Dog C', 'CUS-EX-003', 'Not recorded in preview',
        'Safety review example', 'Not verified in preview', 'Care notes not loaded'),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final rows = pets.where((pet) {
      final matchesQuery = q.isEmpty ||
          '${pet.id} ${pet.name} ${pet.customerId}'.toLowerCase().contains(q);
      final matchesFilter = filter == 'All' ||
          (filter == 'Handling review' && pet.handling.contains('review')) ||
          (filter == 'Profile incomplete' && pet.vaccination.contains('Not verified')) ||
          (filter == 'Safety review' && pet.handling.contains('Safety review'));
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Pet Management'),
        backgroundColor: Colors.white,
        foregroundColor: ink,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dog Profiles & Safety Notes',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 8),
                const Text(
                  'Example profiles only. No live pet, health or customer records are loaded.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Safety guard: do not treat missing or unverified health/handling information as safe. Escalate credible urgent risks through the approved safety process. Only authorized staff may access sensitive care notes.',
                          style: TextStyle(color: ink, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search dog name, dog ID or customer ID',
                    prefixIcon: const Icon(Icons.search, color: orange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in ['All', 'Handling review', 'Profile incomplete', 'Safety review'])
                      ChoiceChip(
                        label: Text(value),
                        selected: filter == value,
                        selectedColor: orange.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() => filter = value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No example pet profiles match these filters. Live records are not connected.'),
                  ))
                else
                  for (final pet in rows) _petCard(pet),
                const Text(
                  'Editing, health-status confirmation and safety-flag changes are disabled until data access, authorization and audit controls are implemented.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _petCard(_Pet pet) => Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFECE5DE)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final identity = Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.pets_outlined, color: orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                            Text(
                              pet.id,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final handlingChip = Chip(label: Text(pet.handling));

                  if (constraints.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        const SizedBox(height: 8),
                        handlingChip,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 8),
                      handlingChip,
                    ],
                  );
                },
              ),
              const Divider(height: 24),
              _detail('Customer reference', pet.customerId),
              _detail('Breed / size', pet.breedSize),
              _detail('Health / vaccination', pet.vaccination),
              _detail('Handling instructions', pet.handling),
              _detail('Care notes', pet.careNotes),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(pet.name),
                      content: Text('Example record only.\nDog ID: ${pet.id}\nCustomer: ${pet.customerId}\nHealth status: not verified in preview.\nNo live pet data was accessed.'),
                      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View example profile'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit disabled'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Safety action disabled'),
                ),
              ]),
            ],
          ),
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _Pet {
  const _Pet(this.id, this.name, this.customerId, this.breedSize,
      this.handling, this.vaccination, this.careNotes);
  final String id, name, customerId, breedSize, handling, vaccination, careNotes;
}
