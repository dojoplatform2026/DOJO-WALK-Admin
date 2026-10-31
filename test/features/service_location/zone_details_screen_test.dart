import 'package:dojo_admin/features/service_location/screens/zone_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildScreen() => const MaterialApp(
        home: ZoneDetailsScreen(
          zoneId: 'ZONE-TEST-001',
          zoneName: 'Crossings Republik Central',
          parentPath: 'Uttar Pradesh → Ghaziabad → Ghaziabad',
          status: 'Awaiting Founder Approval',
          revision: 'Revision 2',
          boundaryStatus: 'Verified (example)',
          readinessBlocker: 'No live capacity evidence connected',
          updatedAt: '2026-10-30 10:00 IST',
          updatedBy: 'Central Admin (example)',
        ),
      );

  group('ZoneDetailsScreen UI prototype', () {
    testWidgets('shows Zone identity, hierarchy, readiness and audit metadata',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Zone Details'), findsOneWidget);
      expect(find.text('Crossings Republik Central'), findsOneWidget);
      expect(find.text('ZONE-TEST-001 · Revision 2'), findsOneWidget);
      expect(find.text('Parent path'), findsOneWidget);
      expect(find.text('Zone status'), findsOneWidget);
      expect(find.text('Boundary status'), findsOneWidget);
      expect(find.text('Readiness blockers'), findsOneWidget);
      expect(find.text('Last updated'), findsOneWidget);
      expect(find.text('Updated by'), findsOneWidget);
      expect(find.textContaining('Example record only'), findsOneWidget);
      expect(find.textContaining('Live hash not loaded'), findsOneWidget);
    });

    testWidgets('long Zone metadata remains scrollable on a narrow enlarged-text screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const ZoneDetailsScreen(
              zoneId: 'ZONE-WITH-A-VERY-LONG-IDENTIFIER-2026-001',
              zoneName: 'Crossings Republik North East Residential Service Zone',
              parentPath: 'Uttar Pradesh → Ghaziabad → Ghaziabad → Crossings Republik North East',
              status: 'Awaiting Founder Approval — operational activation remains blocked',
              revision: 'Revision 2026-10',
              boundaryStatus: 'Verified with polygon hash and manual map review pending',
              readinessBlocker: 'Live capacity, GPS entrance and supervisor assignment evidence are not connected',
              updatedAt: '2026-10-31 10:00 IST',
              updatedBy: 'Central Admin with a deliberately long display label',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone Details'), findsOneWidget);
      expect(find.textContaining('Crossings Republik North East Residential Service Zone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps edit and lifecycle actions disabled', (tester) async {
      await tester.pumpWidget(buildScreen());

      final edit = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Edit disabled'),
      );
      final lifecycle = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Lifecycle action disabled'),
      );

      expect(edit.onPressed, isNull);
      expect(lifecycle.onPressed, isNull);
    });

    testWidgets('renders without overflow on narrow mobile', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Crossings Republik Central'), findsOneWidget);
      expect(find.text('Zone Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
