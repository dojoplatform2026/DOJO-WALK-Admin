import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dojo_admin/features/service_location/widgets/service_boundary_editor.dart';

const _tapPoints = <LatLng>[
  LatLng(0, 0),
  LatLng(0, 2),
  LatLng(2, 2),
  LatLng(2, 0),
];

Widget _fakeMap({
  required Set<Marker> markers,
  required Set<Polygon> polygons,
  required ValueChanged<LatLng> onTap,
}) {
  return GestureDetector(
    key: const ValueKey('fake-boundary-map'),
    behavior: HitTestBehavior.opaque,
    onTap: () => onTap(_tapPoints[markers.length]),
    child: Center(
      child: Text(
        'fake map: ${markers.length} markers, ${polygons.length} polygons',
      ),
    ),
  );
}

Widget _app({
  List<LatLng> initialPoints = const [],
  bool readOnly = false,
  ValueChanged<List<GeoPoint>>? onSaveRequested,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ServiceBoundaryEditor(
          initialPoints: initialPoints,
          readOnly: readOnly,
          onSaveRequested: onSaveRequested,
          mapBuilder: _fakeMap,
        ),
      ),
    ),
  );
}

void main() {
  group('ServiceBoundaryEditor interactions', () {
    testWidgets('adds points and emits immutable boundary snapshots',
        (tester) async {
      final snapshots = <List<LatLng>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceBoundaryEditor(
              mapBuilder: _fakeMap,
              onBoundaryChanged: snapshots.add,
            ),
          ),
        ),
      );

      final map = find.byKey(const ValueKey('fake-boundary-map'));
      await tester.tap(map);
      await tester.pump();
      await tester.tap(map);
      await tester.pump();

      expect(find.text('Boundary points: 2'), findsOneWidget);
      expect(snapshots, hasLength(2));
      expect(snapshots.last, hasLength(2));
      expect(() => snapshots.last.add(const LatLng(9, 9)), throwsUnsupportedError);
    });

    testWidgets('Undo removes only the last point and reports the change',
        (tester) async {
      final snapshots = <List<LatLng>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceBoundaryEditor(
              mapBuilder: _fakeMap,
              onBoundaryChanged: snapshots.add,
            ),
          ),
        ),
      );

      final map = find.byKey(const ValueKey('fake-boundary-map'));
      await tester.tap(map);
      await tester.pump();
      await tester.tap(map);
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Undo'));
      await tester.pump();

      expect(find.text('Boundary points: 1'), findsOneWidget);
      expect(snapshots, hasLength(3));
      expect(snapshots.last.single, _tapPoints.first);
    });

    testWidgets('Clear removes all points and reports an empty snapshot',
        (tester) async {
      final snapshots = <List<LatLng>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceBoundaryEditor(
              mapBuilder: _fakeMap,
              onBoundaryChanged: snapshots.add,
            ),
          ),
        ),
      );

      final map = find.byKey(const ValueKey('fake-boundary-map'));
      await tester.tap(map);
      await tester.pump();
      await tester.tap(map);
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
      await tester.pump();

      expect(find.text('Boundary points: 0'), findsOneWidget);
      expect(snapshots.last, isEmpty);
      expect(find.text('fake map: 0 markers, 0 polygons'), findsOneWidget);
    });

    testWidgets('read-only mode hides edit controls and ignores map taps',
        (tester) async {
      final snapshots = <List<LatLng>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceBoundaryEditor(
              readOnly: true,
              mapBuilder: _fakeMap,
              onBoundaryChanged: snapshots.add,
            ),
          ),
        ),
      );

      expect(find.text('Undo'), findsNothing);
      expect(find.text('Clear'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('fake-boundary-map')));
      await tester.pump();

      expect(find.text('Boundary points: 0'), findsOneWidget);
      expect(snapshots, isEmpty);
      expect(find.text('यह boundary केवल देखने के लिए है।'), findsOneWidget);
    });

    testWidgets('initial points render markers and a polygon when valid',
        (tester) async {
      await tester.pumpWidget(_app(initialPoints: _tapPoints));

      expect(find.text('Boundary points: 4'), findsOneWidget);
      expect(find.text('fake map: 4 markers, 1 polygons'), findsOneWidget);
    });

    testWidgets('save callback receives GeoPoints only for valid geometry',
        (tester) async {
      List<GeoPoint>? saved;
      await tester.pumpWidget(
        _app(
          onSaveRequested: (points) => saved = points,
        ),
      );

      final map = find.byKey(const ValueKey('fake-boundary-map'));
      for (var i = 0; i < 4; i++) {
        await tester.tap(map);
        await tester.pump();
      }

      final save = find.widgetWithText(FilledButton, 'Use This Boundary');
      expect(save, findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.tap(save);
      await tester.pump();

      expect(saved, hasLength(4));
      expect(saved!.first, const GeoPoint(0, 0));
      expect(saved!.last, const GeoPoint(2, 0));
    });

    testWidgets('save remains disabled when the polygon is invalid',
        (tester) async {
      await tester.pumpWidget(
        _app(
          initialPoints: const [LatLng(0, 0), LatLng(0, 2)],
          onSaveRequested: (_) => fail('Invalid geometry must not be saved'),
        ),
      );

      final save = find.widgetWithText(FilledButton, 'Use This Boundary');
      expect(save, findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });
  });
}
