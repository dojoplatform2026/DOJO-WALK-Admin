import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/access_control/screens/admin_access_control_screen.dart';

void main() {
  testWidgets('keeps Founder and Super Admin authority distinct',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminAccessControlScreen()),
    );

    expect(find.text('Admin Users & Roles'), findsOneWidget);
    expect(find.text('Founder / CEO'), findsOneWidget);
    expect(find.text('Super Admin'), findsOneWidget);
    expect(find.textContaining('Does not automatically inherit Founder/CEO business approval authority'),
        findsOneWidget);
    expect(find.textContaining('policy is Draft'), findsOneWidget);
  });

  testWidgets('does not enable role grants or scope changes in prototype',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminAccessControlScreen()),
    );

    final grantButtons = tester.widgetList<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Grant role disabled'),
    );
    final scopeButtons = tester.widgetList<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Change scope disabled'),
    );
    expect(grantButtons, isNotEmpty);
    expect(scopeButtons, isNotEmpty);
    expect(grantButtons.every((button) => button.onPressed == null), isTrue);
    expect(scopeButtons.every((button) => button.onPressed == null), isTrue);
  });
  testWidgets('remains usable on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AdminAccessControlScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin Users & Roles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
