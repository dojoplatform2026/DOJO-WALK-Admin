import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/settings/screens/settings_governance_screen.dart';

void main() {
  testWidgets('shows policy-mapped settings without invented defaults',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsGovernanceScreen()),
    );

    expect(find.text('Settings & Governance'), findsOneWidget);
    expect(find.text('Language & accessibility'), findsOneWidget);
    expect(find.text('Security & sessions'), findsOneWidget);
    expect(find.text('Notification channels'), findsOneWidget);
    expect(find.text('Data privacy & retention'), findsOneWidget);
    expect(find.text('Company support channels'), findsOneWidget);
    expect(find.textContaining('rather than inventing a setting'), findsOneWidget);
  });

  testWidgets('keeps destructive and unconfigured controls disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsGovernanceScreen()),
    );

    final retention = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Retention controls disabled'),
    );
    final contact = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Edit contact channels disabled'),
    );
    expect(retention.onPressed, isNull);
    expect(contact.onPressed, isNull);
  });
}
