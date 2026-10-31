import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/zone_directory_screen.dart';

void main() {
  group('ZoneDirectoryScreen UI prototype', () {
    testWidgets('shows example records with readiness and audit metadata',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      expect(find.text('Zone Directory'), findsOneWidget);
      expect(find.textContaining('not connected to Firestore'), findsOneWidget);
      expect(find.text('ZONE-EX-001'), findsOneWidget);
      expect(find.text('ZONE-EX-003'), findsOneWidget);
      expect(find.text('Revision 3'), findsWidgets);
      expect(find.text('Parent path'), findsWidgets);
      expect(find.text('Boundary status'), findsWidgets);
      expect(find.text('Readiness blockers'), findsWidgets);
      expect(find.text('Last updated'), findsWidgets);
      expect(find.text('Updated by'), findsWidgets);
      expect(find.text('Lifecycle actions disabled'), findsWidgets);
      expect(find.textContaining('temporary emergency stop'), findsOneWidget);
      expect(find.textContaining('notify Founder promptly for review'), findsOneWidget);
    });

    testWidgets('small screen and enlarged text keep Zone cards readable', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: ZoneDirectoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone Directory'), findsOneWidget);
      expect(find.text('Example Zone A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search and status filters narrow the example directory',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      await tester.enterText(find.byType(TextField).first, 'ZONE-EX-002');
      await tester.pumpAndSettle();

      expect(find.text('Example Zone B'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);
      expect(find.text('Example Zone C'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Needs changes'));
      await tester.pumpAndSettle();

      expect(find.text('Example Zone B'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);
      expect(find.text('Example Zone C'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();
      expect(find.text('Example Zone F'), findsOneWidget);
      expect(find.text('Example Zone B'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Deactivated'));
      await tester.pumpAndSettle();
      expect(find.text('Example Zone G'), findsOneWidget);
      expect(find.text('Example Zone F'), findsNothing);
    });

    testWidgets('clear search restores examples and lifecycle controls stay disabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final search = find.byType(TextField).first;
      await tester.enterText(search, 'does-not-exist');
      await tester.pumpAndSettle();

      expect(find.textContaining('No example zones match'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Example Zone A'), findsOneWidget);
      expect(find.textContaining('No example zones match'), findsNothing);

      final lifecycleButtons = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Lifecycle actions disabled'),
      );
      expect(lifecycleButtons, isNotEmpty);
      expect(
        lifecycleButtons.every((button) => button.onPressed == null),
        isTrue,
      );
    });

    testWidgets('clear-search icon has an accessible label and 48px target', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      await tester.enterText(find.byType(TextField).first, 'ZONE-EX-001');
      await tester.pumpAndSettle();

      final clearButton = find.byTooltip('Clear search');
      expect(clearButton, findsOneWidget);
      expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
      final size = tester.getSize(clearButton);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      semantics.dispose();
    });

    testWidgets('Zone Directory remains readable on a narrow mobile viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zone Directory'), findsOneWidget);
      expect(find.text('Example Zone A'), findsOneWidget);
      expect(find.text('ZONE-EX-001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens Zone Details with hierarchy and readiness metadata',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final detailsButton = find.text('View details').first;
      await tester.scrollUntilVisible(
        detailsButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      expect(find.text('Zone Details'), findsOneWidget);
      expect(find.text('Example Zone A'), findsOneWidget);
      expect(find.text('ZONE-EX-001 · Revision 1'), findsOneWidget);
      expect(find.text('Example State/UT → Example District → Example City'),
          findsOneWidget);
      expect(find.text('Parent path'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Not verified'), findsOneWidget);
      expect(find.text('Polygon evidence pending'), findsOneWidget);
      expect(find.text('2026-10-28 09:15 IST'), findsOneWidget);
      expect(find.text('Central Admin (example)'), findsOneWidget);
      expect(find.text('Readiness blockers'), findsOneWidget);
      expect(find.textContaining('not connected to the Zone service'), findsOneWidget);
    });

    testWidgets('back navigation from Zone Details returns to Directory', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ZoneDirectoryScreen()));

      final detailsButton = find.text('View details').first;
      await tester.scrollUntilVisible(
        detailsButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      expect(find.text('Zone Details'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Zone Directory'), findsOneWidget);
      expect(find.text('Example Zone A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('verified Zone remains unactivated until separate Founder decision',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final zoneC = find.text('Example Zone C');
      await tester.scrollUntilVisible(
        zoneC,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final zoneCard = find.ancestor(of: zoneC, matching: find.byType(Card)).first;
      expect(find.descendant(of: zoneCard, matching: find.text('Not activated')),
          findsOneWidget);
      expect(find.descendant(of: zoneCard, matching: find.text('Verified (example)')),
          findsOneWidget);

      await tester.tap(find.descendant(
        of: zoneCard,
        matching: find.widgetWithText(OutlinedButton, 'View details'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Zone status'), findsOneWidget);
      expect(find.text('Not activated'), findsOneWidget);
      expect(find.text('Verified (example)'), findsOneWidget);

      final approvalQueueButton = find.text('Preview approval queue');
      await tester.scrollUntilVisible(
        approvalQueueButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(approvalQueueButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Founder Approval Queue · ZONE-EX-003'), findsOneWidget);
      expect(find.text('ZONE-EX-003'), findsOneWidget);
      expect(find.text('ZONE-EX-001'), findsNothing);
      expect(find.text('ZONE-EX-002'), findsNothing);
      expect(find.text('Example Zone C'), findsOneWidget);
      expect(find.text('Awaiting decision'), findsWidgets);
      expect(find.text('Verified (example)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('directory routes to boundary review preview',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final previewButton = find.text('View boundary preview').first;
      await tester.scrollUntilVisible(
        previewButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.text('Boundary Review'), findsOneWidget);
      expect(find.text('ZONE-EX-001'), findsOneWidget);
      expect(find.text('ZONE-EX-002'), findsNothing);
      expect(find.text('ZONE-EX-003'), findsNothing);
      expect(find.text('Boundary map preview'), findsOneWidget);
    });
  });
}
