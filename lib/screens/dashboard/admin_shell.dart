import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

import 'dashboard_screen.dart';
import 'dashboard_data_source.dart';
import '../live/live_operations_screen.dart';
import '../bookings/bookings_screen.dart';

import '../../features/walkers/screens/walker_management_dashboard_screen.dart';
import '../../features/service_location/screens/service_location_screen.dart';
import '../../features/customers/screens/customer_management_screen.dart';
import '../../features/support/screens/support_center_screen.dart';
import '../../features/pets/screens/pet_management_screen.dart';
import '../../features/notifications/screens/notification_center_screen.dart';
import '../../features/access_control/screens/admin_access_control_screen.dart';
import '../../features/reports/screens/reports_analytics_screen.dart';
import '../../features/finance/screens/finance_operations_screen.dart';
import '../../features/audit/screens/admin_audit_logs_screen.dart';
import '../../features/settings/screens/settings_governance_screen.dart';

const Color adminOrange = Color(0xFFFF7900);
const Color adminBackground = Color(0xFFFFFAF5);
const Color adminText = Color(0xFF252525);

class AdminShell extends StatefulWidget {
  final DashboardDataSource? dashboardDataSource;
  final Widget Function(int index)? contentBuilder;

  const AdminShell({
    super.key,
    this.dashboardDataSource,
    this.contentBuilder,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  final List<_AdminMenuItem> _menuItems = const [
    _AdminMenuItem(
      title: 'Dashboard',
      subtitle: 'Overview and statistics',
      icon: Icons.dashboard_rounded,
    ),
    _AdminMenuItem(
      title: 'Bookings',
      subtitle: 'Manage customer bookings',
      icon: Icons.calendar_month_rounded,
    ),
    _AdminMenuItem(
      title: 'Walker Management',
      subtitle: 'Manage walkers and verification',
      icon: Icons.groups_rounded,
    ),
    _AdminMenuItem(
      title: 'Customers',
      subtitle: 'Customer management',
      icon: Icons.people_alt_rounded,
    ),
    _AdminMenuItem(
      title: 'Pets',
      subtitle: 'Registered dogs',
      icon: Icons.pets_rounded,
    ),
    _AdminMenuItem(
      title: 'Notifications',
      subtitle: 'System notifications',
      icon: Icons.notifications_active_rounded,
    ),
    _AdminMenuItem(
      title: 'Support',
      subtitle: 'Customer and walker support',
      icon: Icons.support_agent_rounded,
    ),
    _AdminMenuItem(
      title: 'Admin Users & Roles',
      subtitle: 'Access scope, role matrix and security',
      icon: Icons.admin_panel_settings_outlined,
    ),
    _AdminMenuItem(
      title: 'Audit Logs',
      subtitle: 'Security and activity trail',
      icon: Icons.history_rounded,
    ),
    _AdminMenuItem(
      title: 'Reports & Analytics',
      subtitle: 'Policy-mapped operational reporting',
      icon: Icons.analytics_outlined,
    ),
    _AdminMenuItem(
      title: 'Finance Operations',
      subtitle: 'Payments, refunds, payouts and reconciliation',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _AdminMenuItem(
      title: 'Settings',
      subtitle: 'Admin preferences',
      icon: Icons.settings_rounded,
    ),
    _AdminMenuItem(
      title: 'Service Locations',
      subtitle: 'State/UT, district, city and zone management',
      icon: Icons.location_city_rounded,
    ),
  ];

  Widget _buildContent() {
    final contentBuilder = widget.contentBuilder;
    if (contentBuilder != null) return contentBuilder(_selectedIndex);

    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          dataSource: widget.dashboardDataSource,
          onOpenLiveOperations: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LiveOperationsScreen(),
              ),
            );
          },
          onOpenServiceLocations: () {
            setState(() => _selectedIndex = 12);
          },
        );

      case 1:
        return const BookingsScreen();

      case 2:
        return const WalkerManagementDashboardScreen();

      case 3:
        return const CustomerManagementScreen();

      case 4:
        return const PetManagementScreen();

      case 5:
        return const NotificationCenterScreen();

      case 6:
        return const SupportCenterScreen();

      case 7:
        return const AdminAccessControlScreen();

      case 8:
        return const AdminAuditLogsScreen();

      case 9:
        return const ReportsAnalyticsScreen();

      case 10:
        return const FinanceOperationsScreen();

      case 11:
        return const SettingsGovernanceScreen();

      case 12:
        return const ServiceLocationScreen();

      default:
        return _buildComingSoonScreen(
          _menuItems[_selectedIndex].title,
          _menuItems[_selectedIndex].icon,
        );
    }
  }

  Widget _buildComingSoonScreen(String title, IconData icon) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFE0C2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: adminOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 38,
                color: adminOrange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: adminText,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This section is ready for the next development step.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: adminText,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of DOJO WALK Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: adminText),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: adminOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService().signOut();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
        ),
      );
    }

    // AuthGate should display the login screen after sign-out.
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 760;

    return Scaffold(
      backgroundColor: adminBackground,
      drawer: isMobile ? _buildSidebar(isDrawer: true) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: const Text(
                'DOJO WALK Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: adminText,
                ),
              ),
              iconTheme: const IconThemeData(
                color: adminOrange,
              ),
              elevation: 0,
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!isMobile) _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final item = _menuItems[_selectedIndex];

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: adminText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: adminOrange,
            size: 25,
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOJO Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                'Administration',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: adminOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    final sidebarWidth = _sidebarExpanded ? 252.0 : 82.0;

    return Container(
      width: isDrawer ? 280 : sidebarWidth,
      color: const Color(0xFF202126),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: adminOrange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  if (_sidebarExpanded || isDrawer) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOJO WALK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'ADMIN PANEL',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!isDrawer && _sidebarExpanded)
                    IconButton(
                      tooltip: 'Collapse sidebar',
                      onPressed: () {
                        setState(() {
                          _sidebarExpanded = false;
                        });
                      },
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            if (!isDrawer && !_sidebarExpanded)
              IconButton(
                tooltip: 'Expand sidebar',
                onPressed: () {
                  setState(() {
                    _sidebarExpanded = true;
                  });
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final selected = index == _selectedIndex;
                  final showTitle = _sidebarExpanded || isDrawer;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Tooltip(
                      message: item.title,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });

                          if (isDrawer) {
                            Navigator.pop(context);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: showTitle ? 13 : 0,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? adminOrange.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(
                                    color: adminOrange.withValues(
                                      alpha: 0.5,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: showTitle
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                size: 21,
                                color: selected
                                    ? adminOrange
                                    : Colors.white70,
                              ),
                              if (showTitle) ...[
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: adminOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(
              color: Colors.white12,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _logout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.white70,
                        size: 21,
                      ),
                      if (_sidebarExpanded || isDrawer) ...[
                        const SizedBox(width: 13),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
