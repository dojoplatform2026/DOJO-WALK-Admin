import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_admin/features/walkers/models/walker_admin_model.dart';
import 'package:dojo_admin/features/walkers/screens/walker_details_screen.dart';

void main() {
  WalkerAdminModel walker() => WalkerAdminModel.fromMap(
        uid: 'walker-001',
        data: {
          'name': 'Test Walker',
          'phoneNumber': '9876543210',
          'email': 'walker@example.com',
          'status': 'approved',
          'verificationStatus': 'verified',
          'isApproved': true,
          'isActive': true,
          'applicationSubmitted': true,
          'area': 'Crossings Republik',
          'city': 'Ghaziabad',
          'state': 'Uttar Pradesh',
          'createdAt': DateTime(2026, 10, 1),
          'kyc': {'documents': <String, dynamic>{}},
        },
      );

  Widget buildScreen(Stream<WalkerAdminModel?> stream) {
    return MaterialApp(
      home: WalkerDetailsScreen(
        uid: 'walker-001',
        walkerData: const {},
        walkerStream: stream,
      ),
    );
  }

  testWidgets('shows loading state while walker stream is pending',
      (tester) async {
    await tester.pumpWidget(
      buildScreen(Stream<WalkerAdminModel?>.multi((_) {})),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Walker Details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows clear missing-record state when stream emits null',
      (tester) async {
    await tester.pumpWidget(
      buildScreen(Stream<WalkerAdminModel?>.value(null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Walker record not found.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows retry state when walker stream fails', (tester) async {
    await tester.pumpWidget(
      buildScreen(Stream<WalkerAdminModel?>.error(StateError('offline'))),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load walker details. Check your access and connection.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders full details when walker stream emits a record',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildScreen(Stream<WalkerAdminModel?>.value(walker())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Walker Details'), findsOneWidget);
    expect(find.text('Test Walker'), findsWidgets);
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('KYC Documents'), findsOneWidget);
    expect(find.text('Account Review'), findsOneWidget);
    expect(find.text('View Security Details'), findsOneWidget);
    expect(find.text('Activity History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps lifecycle decision actions unavailable', (tester) async {
    await tester.pumpWidget(
      buildScreen(Stream<WalkerAdminModel?>.value(walker())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verified • Active'), findsWidgets);
    expect(find.text('Suspend'), findsOneWidget);
    final suspendButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Suspend'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(suspendButton.onPressed, isNull);
    expect(find.text('Verify & Approve'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
