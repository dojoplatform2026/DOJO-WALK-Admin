import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/audit_history_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: LocationAuditHistoryScreen());

  testWidgets('labels example entries and append-only audit expectations',
      (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Location Audit History'), findsOneWidget);
    expect(find.textContaining('not connected to live audit records'), findsOneWidget);
    expect(find.textContaining('append-only'), findsOneWidget);
    expect(find.text('Zone readiness submitted'), findsOneWidget);
    expect(find.text('Boundary revision updated'), findsOneWidget);
    expect(find.text('Emergency suspension'), findsOneWidget);
    expect(find.textContaining('Integration pending'), findsOneWidget);
  });

  testWidgets('outcome chips filter example entries and empty state recovers',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency suspension'), findsOneWidget);
    expect(find.text('Zone readiness submitted'), findsNothing);
    expect(find.text('Boundary revision updated'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Review required'));
    await tester.pumpAndSettle();

    expect(find.text('Boundary revision updated'), findsOneWidget);
    expect(find.text('Emergency suspension'), findsNothing);
    expect(find.text('Zone readiness submitted'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All events'));
    await tester.pumpAndSettle();

    expect(find.text('No example events match this filter.'), findsNothing);
    expect(find.text('Zone readiness submitted'), findsOneWidget);
    expect(find.text('Boundary revision updated'), findsOneWidget);
    expect(find.text('Emergency suspension'), findsOneWidget);
  });

  testWidgets('audit history exposes no edit or delete controls', (tester) async {
    await tester.pumpWidget(app());

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('audit history remains usable on a narrow mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Location Audit History'), findsOneWidget);
    expect(find.text('Service location audit trail'), findsOneWidget);
    expect(find.text('Zone readiness submitted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
