import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_admin/features/walkers/services/walker_admin_service.dart';
import 'package:dojo_admin/features/walkers/widgets/kyc_document_viewer_dialog.dart';
import 'package:dojo_admin/features/walkers/widgets/walker_activity_history_dialog.dart';
import 'package:dojo_admin/features/walkers/widgets/walker_security_dialog.dart';

class _FakeWalkerAdminService implements WalkerAdminService {
  _FakeWalkerAdminService(this.logs);

  final Stream<List<Map<String, dynamic>>> logs;

  @override
  Stream<List<Map<String, dynamic>>> watchWalkerAuditLogs(
    String walkerId, {
    int limit = 50,
  }) => logs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const walkerData = {
    'status': 'approved',
    'verificationStatus': 'verified',
    'isApproved': true,
    'isActive': true,
    'applicationSubmitted': true,
    'decisionBy': 'admin-001',
    'decisionReason': 'Documents verified',
  };

  testWidgets('security dialog shows read-only account facts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WalkerSecurityDialog(
            walkerId: 'walker-001',
            walkerData: walkerData,
          ),
        ),
      ),
    );

    expect(find.text('Account Security'), findsOneWidget);
    expect(find.text('walker-001'), findsOneWidget);
    expect(find.text('Verification Status'), findsOneWidget);
    expect(find.text('Documents verified'), findsOneWidget);
    expect(find.textContaining('does not change login access'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity dialog shows loading then empty state', (tester) async {
    final controller = StreamController<List<Map<String, dynamic>>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkerActivityHistoryDialog(
            service: _FakeWalkerAdminService(controller.stream),
            walkerId: 'walker-001',
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('No activity found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity dialog renders audit action, actor and reason',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkerActivityHistoryDialog(
            service: _FakeWalkerAdminService(
              Stream.value([
                {
                  'action': 'walker_suspended',
                  'actorUid': 'admin-007',
                  'beforeStatus': 'approved',
                  'afterStatus': 'suspended',
                  'reason': 'Policy review required',
                  'createdAt': DateTime(2026, 10, 30),
                },
              ]),
            ),
            walkerId: 'walker-001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suspended'), findsWidgets);
    expect(find.text('admin-007'), findsOneWidget);
    expect(find.text('Policy review required'), findsOneWidget);
    expect(find.text('Previous status'), findsOneWidget);
    expect(find.text('New status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity dialog displays stream failure, not empty state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkerActivityHistoryDialog(
            service: _FakeWalkerAdminService(
              Stream.error(StateError('permission-denied')),
            ),
            walkerId: 'walker-001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load activity'), findsOneWidget);
    expect(find.text('No activity found'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('KYC viewer explains missing reference and offers retry',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KycDocumentViewerDialog(
            title: 'Aadhaar Front',
            document: <String, dynamic>{},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to load this document. Check its link and access permissions.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
