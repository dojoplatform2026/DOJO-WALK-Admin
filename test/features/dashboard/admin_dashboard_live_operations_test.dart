import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/core/theme/admin_theme.dart';
import 'package:dojo_admin/features/dashboard/presentation/admin_dashboard_screen.dart';

void main() {
  testWidgets('Dashboard contains Live Operations and My Location controls',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AdminTheme.light(),
        home: const AdminDashboardScreen(
          onOpenServiceLocation: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live operations'), findsOneWidget);
    expect(find.text('My Location'), findsWidgets);
    expect(find.text('Possible Walker Nearby'), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);
    expect(find.text('Live walk feed'), findsOneWidget);
    expect(find.text('Open operations'), findsNothing);
  });
}

void _noop() {}
