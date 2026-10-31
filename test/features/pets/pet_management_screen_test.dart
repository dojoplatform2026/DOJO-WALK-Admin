import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/pets/screens/pet_management_screen.dart';

void main() {
  testWidgets('shows example pet records and safety safeguards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PetManagementScreen()),
    );

    expect(find.text('Pet Management'), findsOneWidget);
    expect(find.textContaining('No live pet, health or customer records are loaded'), findsOneWidget);
    expect(find.textContaining('do not treat missing or unverified health/handling information as safe'), findsOneWidget);
    expect(find.text('DOG-EX-001'), findsOneWidget);
    expect(find.text('Edit disabled'), findsWidgets);
    expect(find.text('Safety action disabled'), findsWidgets);
  });

  testWidgets('search filters the example pet directory', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PetManagementScreen()),
    );

    await tester.enterText(find.byType(TextField).first, 'DOG-EX-002');
    await tester.pumpAndSettle();

    expect(find.text('Example Dog B'), findsOneWidget);
    expect(find.text('Example Dog A'), findsNothing);
    expect(find.text('Example Dog C'), findsNothing);
  });

  testWidgets('profile dialog states that health data is not verified',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PetManagementScreen()),
    );

    final profileButton = find.text('View example profile').first;
    await tester.scrollUntilVisible(
      profileButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(profileButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Health status: not verified in preview'),
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
      const MaterialApp(home: PetManagementScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pet Management'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
