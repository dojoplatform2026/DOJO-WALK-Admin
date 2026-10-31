import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/suspended_zones_screen.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('SuspendedZonesScreen UI prototype', () {
    testWidgets('shows prototype warning and operational safeguards',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      expect(find.text('Suspended / Deactivated Zones'), findsOneWidget);
      expect(find.textContaining('PROTOTYPE ONLY'), findsOneWidget);
      expect(find.textContaining('narrowly scoped emergency safety suspension'), findsOneWidget);
      expect(find.textContaining('prompt Founder/CEO notification'), findsOneWidget);

      await scrollTo(tester, find.text('Required safeguards'));
      expect(find.text('Required safeguards'), findsOneWidget);
      expect(find.text('Existing bookings'), findsOneWidget);
      expect(find.text('Walk already in progress'), findsOneWidget);
      expect(find.text('Reactivation is a new approval gate'), findsOneWidget);
      expect(find.text('Append-only audit trail'), findsOneWidget);
    });

    testWidgets('filters example zones by status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      // The header and metric cards may place filter controls below the
      // initial viewport, so reveal the text before interacting with it.
      await scrollTo(tester, find.text('Deactivated'));
      await tester.tap(find.text('Deactivated').first);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Example Zone South'));
      expect(find.text('Example Zone South'), findsOneWidget);
      expect(find.text('Example Zone North'), findsNothing);
      expect(find.text('Example Zone Central'), findsNothing);

      // Return to the top of the list before selecting another filter.
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Suspended'));
      await tester.tap(find.text('Suspended').first);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Example Zone North'));
      expect(find.text('Example Zone North'), findsOneWidget);
      await scrollTo(tester, find.text('Example Zone Central'));
      expect(find.text('Example Zone Central'), findsOneWidget);
      expect(find.text('Example Zone South'), findsNothing);
    });

    testWidgets('keeps case and reactivation actions disabled in prototype',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      await scrollTo(tester, find.text('Example Zone North'));
      await scrollTo(tester, find.widgetWithText(OutlinedButton, 'View case'));
      final viewCase = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'View case').first,
      );
      final requestReactivation = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Request reactivation').first,
      );

      expect(viewCase.onPressed, isNull);
      expect(requestReactivation.onPressed, isNull);
    });

    testWidgets('shows audit history as example data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      await scrollTo(tester, find.text('Example Zone North'));
      await scrollTo(tester, find.text('Audit history').first);
      expect(find.textContaining('not live audit data'), findsWidgets);
      await tester.tap(find.text('Audit history').first);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Suspension requested'));
      expect(find.text('Suspension requested'), findsOneWidget);
      expect(find.text('Zone suspended'), findsOneWidget);
    });

    testWidgets('suspended zone screen remains usable on a narrow mobile viewport',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suspended / Deactivated Zones'), findsOneWidget);
      expect(find.textContaining('PROTOTYPE ONLY'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'The initial mobile viewport must not overflow.',
      );

      await scrollTo(tester, find.text('Example Zone North'));
      expect(find.text('Example Zone North'), findsOneWidget);
      final cardException = tester.takeException();
      if (cardException is FlutterError) {
        debugPrint('MOBILE_OVERFLOW_DIAGNOSTIC: ${cardException.toStringDeep()}');
        debugDumpRenderTree();
      }
      expect(
        cardException,
        isNull,
        reason: 'The suspended Zone card must not overflow on mobile.',
      );
    });
  });
}
