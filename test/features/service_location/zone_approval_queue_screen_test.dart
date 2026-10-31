import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/zone_approval_queue_screen.dart';

void main() {
  group('ZoneApprovalQueueScreen UI prototype', () {
    testWidgets('explains Founder authority and keeps server decisions disabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneApprovalQueueScreen()),
      );

      expect(find.textContaining('Founder Approval Queue'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Blocked — boundary pending'));
      await tester.pumpAndSettle();
      expect(find.text('ZONE-EX-001'), findsOneWidget);
      expect(find.text('Blocked — boundary pending'), findsWidgets);
      expect(find.textContaining('Founder decision must wait'), findsOneWidget);
      expect(find.text('Business approval gate'), findsOneWidget);
      expect(find.textContaining('Founder/CEO makes the final business decision'),
          findsOneWidget);
      expect(find.textContaining('Super Admin does not inherit Founder approval authority'),
          findsOneWidget);
      expect(find.textContaining('No server actions enabled'), findsOneWidget);
      expect(find.text('Decision disabled — not connected'), findsWidgets);

      final decisionButtons = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Decision disabled — not connected'),
      );
      expect(decisionButtons, isNotEmpty);
      expect(decisionButtons.every((button) => button.onPressed == null), isTrue);
    });

    testWidgets('deep link scopes approval queue to the selected Zone', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ZoneApprovalQueueScreen(focusZoneId: 'ZONE-EX-001')));
      expect(find.textContaining('ZONE-EX-001'), findsWidgets);
      expect(find.text('ZONE-EX-001'), findsOneWidget);
      expect(find.text('ZONE-EX-002'), findsNothing);
      expect(find.text('Blocked — boundary pending'), findsWidgets);
    });

    testWidgets('long focused Zone ID does not overflow narrow AppBar', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ZoneApprovalQueueScreen(
            focusZoneId: 'ZONE-WITH-A-VERY-LONG-IDENTIFIER-2026-AND-EXTRA-CONTEXT',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Founder Approval Queue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown Zone deep link shows an explicit empty state', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ZoneApprovalQueueScreen(focusZoneId: 'ZONE-UNKNOWN')));
      expect(find.textContaining('No example approval request exists for ZONE-UNKNOWN'), findsOneWidget);
      expect(find.text('ZONE-EX-001'), findsNothing);
    });

    testWidgets('filters blocked revisions and restores all examples',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneApprovalQueueScreen()),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Blocked — boundary pending'));
      await tester.pumpAndSettle();
      expect(find.text('Example Zone A'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Blocked — re-review'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Example Zone B'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example Zone B'), findsOneWidget);
      expect(find.text('ZONE-EX-002'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);
      expect(find.text('Revision 2'), findsOneWidget);
      expect(find.text('Hash changed'), findsWidgets);
      expect(find.text('EXAMPLE-HASH-CHANGED'), findsOneWidget);
      expect(find.textContaining('prior approval must not be reused'), findsOneWidget);
      expect(find.text('Decision disabled — not connected'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Example Zone A'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example Zone A'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Example Zone B'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example Zone B'), findsOneWidget);
    });
  });

  testWidgets('default Awaiting decision filter excludes blocked examples',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ZoneApprovalQueueScreen()),
    );

    expect(find.textContaining('Founder Approval Queue'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Awaiting decision'), findsOneWidget);
    expect(find.text('Example Zone C'), findsOneWidget);
    expect(find.text('ZONE-EX-003'), findsOneWidget);
    expect(find.text('Revision 3'), findsOneWidget);
    expect(find.text('Verified (example)'), findsOneWidget);
    expect(find.text('Example Zone A'), findsNothing);
    expect(find.text('Example Zone B'), findsNothing);
    expect(find.text('Decision disabled — not connected'), findsOneWidget);
    final decisionButtons = tester.widgetList<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Decision disabled — not connected'),
    );
    expect(decisionButtons.every((button) => button.onPressed == null), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approval details remain readable on a narrow mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ZoneApprovalQueueScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Founder Approval Queue'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Blocked — boundary pending'));
    await tester.pumpAndSettle();
    expect(find.text('Example Zone A'), findsOneWidget);
    expect(find.text('Boundary integrity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
