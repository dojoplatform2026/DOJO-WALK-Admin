import 'package:flutter/material.dart';

/// UI-only role matrix prototype aligned with POL-021. Policy remains Draft.
class AdminAccessControlScreen extends StatelessWidget {
  const AdminAccessControlScreen({super.key});

  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);

  static const roles = [
    _Role('Founder / CEO', 'Company-wide oversight',
        'Major policy, risk and city/zone expansion approval',
        'Routine booking dispatch is not the normal role'),
    _Role('Super Admin', 'Technical platform scope',
        'Admin account/role administration, technical configuration, security and audit access',
        'Does not automatically inherit Founder/CEO business approval authority'),
    _Role('Central Head / Central Operations', 'Cross-city operations',
        'Operational oversight, manager coordination, support escalation and consolidated reporting',
        'Cannot grant self Super Admin or approve own Zone submission'),
    _Role('City Manager', 'One assigned City and approved Zones beneath it',
        'City operations, assigned Zone Supervisors, capacity and complaints',
        'No access to another City without explicit scope grant'),
    _Role('Zone Supervisor', 'One named primary Service Zone',
        'Assigned Zone walkers, availability, booking readiness and local incidents',
        'No cross-zone access by default'),
    _Role('Support', 'Support records and permitted case actions',
        'Triage, communication and case documentation within scope',
        'No privileged role grants or unrestricted sensitive-data exports'),
    _Role('Finance', 'Approved payment/refund/reconciliation scope',
        'Payment review and permitted finance actions',
        'No self-approval; separate initiation, approval and reconciliation where practical'),
    _Role('Walker / Partner', 'Own profile and assigned work',
        'Own profile, availability, assigned/accepted walks and permitted evidence',
        'No access to other walkers or customer records outside assigned work'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFFFAF5),
        appBar: AppBar(
          title: const Text('Admin Users & Roles'),
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
                  const Text(
                    'Access Control & Role Matrix',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on POL-021. The policy is Draft — not approved, implemented or tested. This screen is a prototype; no real user roles are loaded or changed.',
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
                        Icon(Icons.security_outlined, color: orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Security rule: authorization requires active account + role + assigned scope + permitted action + current record state. Hiding a button is not a security boundary; backend rules must enforce every read/write.',
                            style: TextStyle(color: ink, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final role in roles) _roleCard(role),
                  const SizedBox(height: 8),
                  const Text(
                    'Role grants, scope changes, disable/revoke and MFA actions are disabled until the role matrix, server authorization and audit trail are approved and tested.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  static Widget _roleCard(_Role role) => Card(
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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.admin_panel_settings_outlined, color: orange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(role.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
                  ),
                  const Chip(label: Text('Draft role')),
                ],
              ),
              const SizedBox(height: 12),
              _detail('Scope', role.scope),
              _detail('Permitted responsibilities', role.permitted),
              _detail('Restriction / guardrail', role.restriction),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Grant role disabled'),
                  ),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Change scope disabled'),
                  ),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('MFA state not connected'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  static Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 190, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _Role {
  const _Role(this.name, this.scope, this.permitted, this.restriction);
  final String name;
  final String scope;
  final String permitted;
  final String restriction;
}
