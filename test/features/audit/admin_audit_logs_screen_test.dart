import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/audit/screens/admin_audit_logs_screen.dart';

void main() {
  testWidgets('shows example audit trail and integrity safeguards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminAuditLogsScreen()),
    );

    expect(find.text('Admin Audit Logs'), findsOneWidget);
    expect(find.textContaining('not live records'), findsOneWidget);
    expect(find.text('AUDIT-EX-001'), findsOneWidget);
    expect(find.text('Export disabled'), findsWidgets);
    expect(find.textContaining('must not edit or delete audit entries'), findsOneWidget);
  });

  testWidgets('result filter isolates denied example entries',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminAuditLogsScreen()),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Denied'));
    await tester.pumpAndSettle();

    expect(find.text('AUDIT-EX-003'), findsOneWidget);
    expect(find.text('AUDIT-EX-001'), findsNothing);
    expect(find.text('AUDIT-EX-002'), findsNothing);
  });
}
