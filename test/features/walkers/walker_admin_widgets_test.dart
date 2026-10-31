import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/walkers/widgets/walker_admin_widgets.dart';

void main() {
  group('WalkerAdminTabs', () {
    testWidgets('renders selected state and reports tab selection',
        (tester) async {
      var selected = -1;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WalkerAdminTabs(
            tabs: const ['Available', 'Running', 'All Walkers'],
            selectedIndex: 0,
            onChanged: (index) => selected = index,
          ),
        ),
      ));

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics &&
              widget.properties.label == 'Available',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('All Walkers'));
      await tester.tap(find.text('All Walkers'));
      expect(selected, 2);
      semantics.dispose();
    });

    testWidgets('supports narrow width without horizontal overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WalkerAdminTabs(
            tabs: const [
              'Available',
              'Running',
              'Verification',
              'Training Required',
              'Rejected',
              'Suspended',
              'Inactive / Offboarded',
              'All Walkers',
            ],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('All Walkers'));
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('WalkerAdminCard', () {
    testWidgets('shows walker details and running status', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WalkerAdminCard(
            name: 'Aman Walker',
            phone: '9876543210',
            location: 'Crossings Republik, Ghaziabad',
            status: 'approved',
            isActive: true,
            isRunning: true,
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('Aman Walker'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Crossings Republik, Ghaziabad'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('uses a safe avatar fallback and handles long text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WalkerAdminCard(
            name: 'A very long walker name that must wrap safely on a phone',
            phone: '919876543210919876543210',
            location: 'A very long area and city label for a narrow mobile screen',
            status: 'correction_required',
            photoUrl: 'not-a-valid-url',
            onTap: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('A very long walker name that must wrap safely on a phone'),
          findsOneWidget);
      expect(find.text('Correction Required'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('card tap invokes navigation callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WalkerAdminCard(
            name: 'Tap Walker',
            status: 'approved',
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Tap Walker'));
      expect(tapped, isTrue);
    });
  });

  group('WalkerAdminKycDocumentTile', () {
    testWidgets('enables View only when document is available',
        (tester) async {
      var views = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WalkerAdminKycDocumentTile(
                title: 'Identity document',
                isAvailable: true,
                onView: () => views++,
              ),
              WalkerAdminKycDocumentTile(
                title: 'Address document',
                isAvailable: false,
                onView: () => views++,
              ),
            ],
          ),
        ),
      ));

      final viewButtons = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'View'),
      ).toList();
      expect(viewButtons, hasLength(2));
      expect(viewButtons[0].onPressed, isNotNull);
      expect(viewButtons[1].onPressed, isNull);

      await tester.tap(find.widgetWithText(OutlinedButton, 'View').first);
      expect(views, 1);
    });
  });
}
