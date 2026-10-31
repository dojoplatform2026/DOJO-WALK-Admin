import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/reports/screens/reports_analytics_screen.dart';

void main() {
  testWidgets('shows policy-mapped report catalog without fabricated KPIs',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReportsAnalyticsScreen()),
    );

    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('Booking lifecycle'), findsOneWidget);
    expect(find.text('Walker performance'), findsOneWidget);
    expect(find.text('Zone readiness'), findsOneWidget);
    expect(find.text('Safety & incidents'), findsOneWidget);
    expect(find.text('Payments & refunds'), findsOneWidget);
    expect(find.text('Support resolution'), findsOneWidget);
    expect(find.text('Not connected'), findsWidgets);
    expect(find.text('Export disabled'), findsWidgets);
  });

  testWidgets('report period controls update selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReportsAnalyticsScreen()),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Last 30 days'));
    await tester.pumpAndSettle();

    final selected = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Last 30 days'),
    );
    expect(selected.selected, isTrue);
  });

  testWidgets('report catalog remains usable on a narrow mobile viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ReportsAnalyticsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking lifecycle'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support resolution'), findsOneWidget);
    expect(find.text('Export disabled'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
