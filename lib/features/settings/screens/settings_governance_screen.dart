import 'package:flutter/material.dart';

import '../../access_control/screens/admin_access_control_screen.dart';
import '../../notifications/screens/notification_center_screen.dart';

/// Settings preview surfaces policy-defined configuration areas without
/// inventing defaults or claiming that a setting is live.
class SettingsGovernanceScreen extends StatelessWidget {
  const SettingsGovernanceScreen({super.key});

  static const orange = Color(0xFFFF7900);
  static const ink = Color(0xFF252525);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFFFAF5),
        appBar: AppBar(
          title: const Text('Settings & Governance'),
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
                    'System Settings',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Policy-mapped settings preview. No configuration changes are saved. Where Notion has no approved value, the UI shows “Not configured” rather than inventing a setting.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _settingCard(
                    icon: Icons.translate_outlined,
                    title: 'Language & accessibility',
                    policy: 'Unified UI/UX Design System',
                    status: 'Not connected',
                    description: 'Product localization includes English, Hindi and supported Indian languages. Admin language preference persistence is not configured.',
                    action: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.language_outlined),
                      label: const Text('Language preference disabled'),
                    ),
                  ),
                  _settingCard(
                    icon: Icons.security_outlined,
                    title: 'Security & sessions',
                    policy: 'POL-021 — Access Control',
                    status: 'Policy Draft',
                    description: 'Privileged MFA, session expiry, re-authentication and recovery requirements need approved values and server-side enforcement.',
                    action: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminAccessControlScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Open Admin Users & Roles'),
                    ),
                  ),
                  _settingCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notification channels',
                    policy: 'POL-032 — Notifications & Messaging',
                    status: 'Not configured',
                    description: 'In-app status is the authoritative view. Push, email, SMS and phone channels may only be shown as available after provisioning and verification.',
                    action: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationCenterScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Open Notification Center'),
                    ),
                  ),
                  _settingCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Data privacy & retention',
                    policy: 'POL-020 / POL-031',
                    status: 'Approval required',
                    description: 'Retention, deletion, account closure and access scopes must follow approved policies. No destructive data controls are available in this preview.',
                    action: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Retention controls disabled'),
                    ),
                  ),
                  _settingCard(
                    icon: Icons.support_agent_outlined,
                    title: 'Company support channels',
                    policy: 'POL-009 — Support & Complaints',
                    status: 'Not verified',
                    description: 'Only company-controlled, monitored channels with confirmed hours may be published. No phone number or 24/7 coverage is assumed.',
                    action: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit contact channels disabled'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save/apply, security changes, notification channel provisioning and privacy operations are disabled until source policies are approved and implementation is verified.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  static Widget _settingCard({
    required IconData icon,
    required String title,
    required String policy,
    required String status,
    required String description,
    required Widget action,
  }) =>
      Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                        child: Icon(icon, color: orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(status)),
                ],
              ),
              const SizedBox(height: 10),
              Text(description, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 6),
              Text('Policy source: $policy', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 10),
              action,
            ],
          ),
        ),
      );
}
