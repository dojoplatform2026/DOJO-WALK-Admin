import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/customers/screens/customer_management_screen.dart';

void main() {
  testWidgets('shows masked example records and privacy safeguards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerManagementScreen()),
    );

    expect(find.text('Customer Management'), findsOneWidget);
    expect(find.textContaining('not connected to customer data'), findsOneWidget);
    expect(find.textContaining('Never request passwords, OTPs, PINs'), findsOneWidget);
    expect(find.text('CUS-EX-001'), findsOneWidget);
    expect(find.text('+91 ••••• ••104'), findsOneWidget);
    expect(find.text('Restrict disabled'), findsWidgets);
    expect(find.text('Close account disabled'), findsWidgets);
  });

  testWidgets('search and account status filter narrow example records',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerManagementScreen()),
    );

    await tester.enterText(find.byType(TextField).first, 'CUS-EX-002');
    await tester.pumpAndSettle();

    expect(find.text('Example Customer B'), findsOneWidget);
    expect(find.text('Example Customer A'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Under review'));
    await tester.pumpAndSettle();

    expect(find.text('Example Customer C'), findsOneWidget);
    expect(find.text('Example Customer A'), findsNothing);
    expect(find.text('Example Customer B'), findsNothing);
  });

  testWidgets('example profile dialog clearly states that data is not live',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerManagementScreen()),
    );

    final profileButton = find.text('View example profile').first;
    await tester.scrollUntilVisible(
      profileButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(profileButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('No live customer data was accessed'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
  testWidgets('remains usable on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CustomerManagementScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Management'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
