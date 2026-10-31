import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/notifications/screens/notification_center_screen.dart';

void main() {
  testWidgets('shows example notifications and delivery safeguards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationCenterScreen()),
    );

    expect(find.text('Notification Center'), findsOneWidget);
    expect(find.textContaining('no notification will be sent'), findsOneWidget);
    expect(find.textContaining('Optional marketing requires separate consent'), findsOneWidget);
    expect(find.text('NOTICE-EX-001'), findsOneWidget);
    expect(find.text('Send disabled'), findsWidgets);
    expect(find.text('Retry disabled'), findsWidgets);
  });

  testWidgets('category filter narrows the example notification list',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationCenterScreen()),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Safety and emergency'));
    await tester.pumpAndSettle();

    expect(find.text('NOTICE-EX-003'), findsOneWidget);
    expect(find.text('NOTICE-EX-001'), findsNothing);
    expect(find.text('NOTICE-EX-002'), findsNothing);
    expect(find.text('NOTICE-EX-004'), findsNothing);
  });
  testWidgets('remains usable on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: NotificationCenterScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification Center'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps case and delivery mutations disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationCenterScreen()),
    );

    for (final label in ["Send disabled","Retry disabled"]) {
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
