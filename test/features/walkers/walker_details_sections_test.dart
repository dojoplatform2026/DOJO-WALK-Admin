import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_admin/features/walkers/models/walker_admin_model.dart';
import 'package:dojo_admin/features/walkers/widgets/walker_details_sections.dart';

void main() {
  WalkerAdminModel makeWalker({
    Map<String, dynamic>? data,
  }) {
    return WalkerAdminModel.fromMap(
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
        'currentAddress': {
          'flatHouse': 'A-101',
          'area': 'Crossings Republik',
          'city': 'Ghaziabad',
          'state': 'Uttar Pradesh',
          'pincode': '201016',
        },
        'zoneIds': ['zone-crossings-01'],
        'kyc': {
          'documents': {
            'aadhaar_front': {
              'downloadUrl': 'https://example.com/aadhaar-front.pdf',
              'fileName': 'aadhaar-front.pdf',
            },
          },
        },
        ...?data,
      },
    );
  }

  Widget host(Widget child, {double width = 390}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
        ),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  testWidgets('renders walker profile, location, KYC and performance sections',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        WalkerDetailsSections(
          walker: makeWalker(),
          onOpenDocument: (_, __) {},
        ),
      ),
    );

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Current Address'), findsOneWidget);
    expect(find.text('Work Location'), findsOneWidget);
    expect(find.text('KYC Documents'), findsOneWidget);
    expect(find.text('Performance Snapshot'), findsOneWidget);
    expect(find.text('Account Information'), findsOneWidget);
    expect(find.text('Test Walker'), findsOneWidget);
    expect(
      find.text('A-101, Crossings Republik, Ghaziabad, Uttar Pradesh, 201016'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens only KYC documents that have a reference',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? openedTitle;
    dynamic openedDocument;

    await tester.pumpWidget(
      host(
        WalkerDetailsSections(
          walker: makeWalker(),
          onOpenDocument: (title, document) {
            openedTitle = title;
            openedDocument = document;
          },
        ),
      ),
    );

    final viewButtons = find.text('View');
    expect(viewButtons, findsNWidgets(3));
    await tester.ensureVisible(viewButtons.first);
    await tester.tap(viewButtons.first);
    expect(openedTitle, 'Aadhaar Front');
    expect(openedDocument, isA<Map>());
    expect(find.text('Aadhaar Back'), findsOneWidget);
    expect(find.text('PAN Card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows unavailable state for missing KYC documents',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        WalkerDetailsSections(
          walker: makeWalker(
            data: {
              'kyc': {'documents': <String, dynamic>{}},
            },
          ),
          onOpenDocument: (_, __) {},
        ),
      ),
    );

    expect(find.text('Document not uploaded'), findsNWidgets(3));
    expect(find.text('View'), findsNWidgets(3));
    final viewActions = tester.widgetList<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'View'),
    );
    expect(viewActions, everyElement(isA<OutlinedButton>().having(
      (button) => button.onPressed,
      'onPressed',
      isNull,
    )));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without layout exceptions on narrow and wide screens',
      (tester) async {
    for (final width in [320.0, 390.0, 768.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        host(
          WalkerDetailsSections(
            walker: makeWalker(
              data: {
                'name': 'A Very Long Walker Name For Responsive Layout Testing',
                'currentAddress': {
                  'flatHouse': 'Building 100, Apartment 9001',
                  'area': 'A Very Long Locality Name For Responsive Layout',
                  'city': 'Greater Noida West',
                  'state': 'Uttar Pradesh',
                  'pincode': '201306',
                },
              },
            ),
            onOpenDocument: (_, __) {},
          ),
          width: width,
        ),
      );

      expect(tester.takeException(), isNull, reason: 'Width: $width');
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
