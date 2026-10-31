import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/support/screens/support_center_screen.dart';

void main() {
  testWidgets('shows example queue and prioritizes safety cases',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    expect(find.text('Support & Complaints'), findsOneWidget);
    expect(find.textContaining('not connected to live cases'), findsOneWidget);
    expect(find.text('CASE-EX-001'), findsOneWidget);
    expect(find.text('S0 — Critical safety/security'), findsOneWidget);
    expect(find.text('Transfer disabled'), findsWidgets);
    expect(find.text('Resolve disabled'), findsWidgets);
  });

  testWidgets('severity filter narrows the example support queue',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'S1'));
    await tester.pumpAndSettle();

    expect(find.text('CASE-EX-002'), findsOneWidget);
    expect(find.text('CASE-EX-001'), findsNothing);
    expect(find.text('CASE-EX-003'), findsNothing);
  });

  testWidgets('case detail dialog states that the record is an example',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    final caseButton = find.text('View example case').first;
    await tester.scrollUntilVisible(
      caseButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(caseButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('No live support or incident data was accessed'),
        findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
  testWidgets('remains usable on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support & Complaints'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps case and delivery mutations disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    for (final label in ["Transfer disabled","Resolve disabled"]) {
      final buttons = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, label),
      );
      expect(buttons, isNotEmpty, reason: 'Expected disabled control: $label');
      expect(
        buttons.every((button) => button.onPressed == null),
        isTrue,
        reason: '$label must remain disabled until authorized backend workflows exist',
      );
    }
  });

}
