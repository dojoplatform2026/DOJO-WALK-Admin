import 'package:flutter/material.dart';

import '../../../core/theme/admin_theme.dart';
import '../../live_operations/presentation/live_operations_screen.dart';

/// Company-operations landing page using a light SaaS + Bento Grid layout.
///
/// Metrics intentionally remain unpopulated until their trusted data contracts
/// and permission checks are connected. Never show invented operational counts.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onOpenServiceLocation,
  });

  final VoidCallback onOpenServiceLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final medium = constraints.maxWidth < 1180;
            final horizontalPadding = compact ? 16.0 : 28.0;
            final metricColumns = compact ? 1 : (medium ? 2 : 4);
            final metricGap = 14.0;
            final contentWidth =
                (constraints.maxWidth - horizontalPadding * 2)
                    .clamp(0.0, 2000.0)
                    .toDouble();
            final metricWidth = compact
                ? contentWidth
                : (contentWidth - metricGap * (metricColumns - 1)) /
                    metricColumns;
            final featureColumns = compact ? 1 : 2;
            final featureWidth = compact
                ? contentWidth
                : (contentWidth - 16) / featureColumns;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 18 : 28,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good day, Admin',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AdminTheme.primaryText,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A clear view of DOJO WALK company operations.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: const Color(0xFF6D665F)),
                            ),
                          ],
                        ),
                      ),
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AdminTheme.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: AdminTheme.brandOrange, size: 19),
                              SizedBox(width: 8),
                              Text(
                                'Admin workspace',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ReadinessBanner(compact: compact),
                  const SizedBox(height: 26),
                  Text(
                    'Operations overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.primaryText,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Live counts will appear after their trusted data connections are verified.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6D665F),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: metricGap,
                    runSpacing: metricGap,
                    children: [
                      SizedBox(
                        width: metricWidth,
                        child: const _MetricCard(
                          title: 'Bookings',
                          value: '—',
                          caption: 'Data connection pending',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: const _MetricCard(
                          title: 'Active walks',
                          value: '—',
                          caption: 'Live feed not connected',
                          icon: Icons.route_outlined,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: const _MetricCard(
                          title: 'Walkers / Partners',
                          value: '—',
                          caption: 'Verified count pending',
                          icon: Icons.pets_outlined,
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: const _MetricCard(
                          title: 'Location approvals',
                          value: '—',
                          caption: 'Review queue not connected',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Workspace shortcuts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.primaryText,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: featureWidth,
                        child: _WorkspaceCard(
                          title: 'Service Location',
                          subtitle:
                              'Manage the India → State → District → City → Area → Locality hierarchy.',
                          detail: 'Boundary verification is required before City / Area activation.',
                          icon: Icons.map_outlined,
                          accent: const Color(0xFFFFF0E2),
                          onTap: onOpenServiceLocation,
                          actionLabel: 'Open locations',
                        ),
                      ),
                      SizedBox(
                        width: featureWidth,
                        child: const _WorkspaceCard(
                          title: 'Bookings',
                          subtitle:
                              'Booking states, customer requests and payment status.',
                          detail:
                              'Read-only preview until the booking and payment contracts are verified.',
                          icon: Icons.receipt_long_outlined,
                          accent: Color(0xFFEAF7EF),
                          actionLabel: 'Connection pending',
                        ),
                      ),
                      SizedBox(
                        width: featureWidth,
                        child: const _WorkspaceCard(
                          title: 'Walker / Partner management',
                          subtitle:
                              'Availability, onboarding and operational review.',
                          detail:
                              'No live status is displayed until the approved data source is connected.',
                          icon: Icons.pets_outlined,
                          accent: Color(0xFFF0ECFF),
                          actionLabel: 'Connection pending',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Live operations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.primaryText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Walker location and live booking data will appear only after trusted feeds are connected.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6D665F),
                        ),
                  ),
                  const SizedBox(height: 12),
                  const LiveOperationsScreen(embedded: true),
                  const SizedBox(height: 24),
                  const _GovernanceNote(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0E2), Color(0xFFFFFAF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD2AD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AdminTheme.brandOrange,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fresh Admin workspace',
                  style: TextStyle(
                    color: AdminTheme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'The new interface is being validated separately. '
                  'Operational totals and sensitive actions stay unavailable '
                  'until permissions, backend contracts and end-to-end tests are verified.',
                  style: TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6D665F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: AdminTheme.brandOrange, size: 21),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AdminTheme.primaryText,
              fontSize: 30,
              height: 1.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            caption,
            style: const TextStyle(
              color: Color(0xFF817970),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color accent;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: AdminTheme.brandOrange,
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: Color(0xFF817970),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AdminTheme.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6D665F),
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: onTap == null
                          ? const Color(0xFF817970)
                          : AdminTheme.brandOrange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AdminTheme.brandOrange,
                      size: 18,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GovernanceNote extends StatelessWidget {
  const _GovernanceNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_tree_outlined, color: AdminTheme.brandOrange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Company hierarchy: Founder / CEO → Central Admin → Area Manager → Supervisor → Walker / Partner. '
              'Geographic service coverage is a separate hierarchy: India → State / UT → District → City → Area → Locality.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
