import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/add_zone_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: AddZoneScreen());

  testWidgets('shows the four dependent selectors and no Locality selector', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Add Service Zone'), findsOneWidget);
    expect(find.text('State / UT'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('New Zone name'), findsNothing);
    expect(find.text('Locality'), findsNothing);
  });

  testWidgets('fourth Zone selector reveals the new Zone name field',
      (tester) async {
    await tester.pumpWidget(app());

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    expect(dropdowns, findsNWidgets(4));

    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(3));
    await tester.pumpAndSettle();
    expect(find.text('Example Zone North (mock)'), findsOneWidget);
    expect(find.text('Example Zone Central (mock)'), findsOneWidget);
    await tester.tap(find.text('Create new Zone…').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsOneWidget);
    expect(find.text('Locality'), findsNothing);

    // Changing an upstream parent clears all downstream selections.
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delhi').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsNothing);
    expect(find.text('Please select Zone'), findsNothing);
  });

  testWidgets('selecting an example Zone never presents it as a new Zone',
      (tester) async {
    await tester.pumpWidget(app());

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Example Zone North (mock)').last);
    await tester.pumpAndSettle();

    final validateButton = find.text('Validate readiness');
    await tester.scrollUntilVisible(
      validateButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Example Zone selected'), findsOneWidget);
    expect(find.textContaining('Nothing has been edited or saved.'), findsOneWidget);
    expect(find.text('Validation incomplete'), findsNothing);
  });

  testWidgets('keeps draft save and review submission disabled without backend',
      (tester) async {
    await tester.pumpWidget(app());

    final saveDraft = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save Draft disabled'),
    );
    final submit = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Submit for Review disabled'),
    );
    expect(saveDraft.onPressed, isNull);
    expect(submit.onPressed, isNull);
    expect(
      find.textContaining('polygon evidence is drawn and verified'),
      findsOneWidget,
    );
  });

  testWidgets('opens Boundary Review preview without submitting a Zone',
      (tester) async {
    await tester.pumpWidget(app());

    final previewButton = find.text('Preview Boundary Review');
    await tester.scrollUntilVisible(
      previewButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(find.text('Boundary Review'), findsOneWidget);
    expect(find.textContaining('not connected to live records'), findsOneWidget);
  });

  testWidgets('Create Zone form remains usable on a narrow mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Add Service Zone'), findsOneWidget);
    expect(find.text('State / UT'), findsOneWidget);
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('Open boundary editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });


  testWidgets('shows local geometry feedback without implying verification',
      (tester) async {
    await tester.pumpWidget(app());

    expect(find.textContaining('Local geometry check: Add at least 3 points (0/3).'), findsOneWidget);
    expect(find.textContaining('not uploaded or verified'), findsOneWidget);
  });

  testWidgets('boundary editor entry is disabled until a new Zone is selected',
      (tester) async {
    await tester.pumpWidget(app());

    final editorButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Open boundary editor'),
    );
    expect(editorButton.onPressed, isNull);

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new Zone…').last);
    await tester.pumpAndSettle();

    final enabledEditorButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Open boundary editor'),
    );
    expect(enabledEditorButton.onPressed, isNotNull);
    expect(find.text('Boundary status: Not drawn'), findsOneWidget);
  });

  testWidgets('clearly states polygon is mandatory and radius alone is insufficient', (tester) async {
    await tester.pumpWidget(app());

    expect(find.textContaining('A radius alone is not sufficient.'), findsOneWidget);
    expect(find.textContaining('polygon'), findsWidgets);
    expect(find.textContaining('Nothing has been saved.'), findsNothing);
  });

  testWidgets('empty form is validated and does not create a Zone', (tester) async {
    await tester.pumpWidget(app());

    final validateButton = find.text('Validate readiness');
    await tester.scrollUntilVisible(
      validateButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Please select State / UT'), findsOneWidget);
    expect(find.text('Please select Zone'), findsOneWidget);
    expect(find.text('Enter a zone name'), findsNothing);
    expect(find.text('Validation incomplete'), findsNothing);
    expect(find.textContaining('Nothing has been saved.'), findsNothing);
  });

  testWidgets('valid new Zone name still cannot pass readiness without boundary evidence',
      (tester) async {
    await tester.pumpWidget(app());

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new Zone…').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Crossings West');
    final validateButton = find.text('Validate readiness');
    await tester.scrollUntilVisible(
      validateButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Validation incomplete'), findsOneWidget);
    expect(find.textContaining('Local polygon shape check: failed'), findsOneWidget);
    expect(find.textContaining('Boundary evidence is not uploaded and GIS verification is pending.'), findsOneWidget);
    expect(find.textContaining('example catalog data'), findsOneWidget);
    expect(find.textContaining('Nothing has been saved.'), findsOneWidget);
    expect(find.text('Boundary status: Not drawn'), findsOneWidget);
    expect(find.text('Save Draft disabled'), findsOneWidget);
    expect(find.text('Submit for Review disabled'), findsOneWidget);
  });

  testWidgets('changing District clears City, Zone and the new Zone name',
      (tester) async {
    await tester.pumpWidget(app());

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new Zone…').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Crossings West');

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghaziabad').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsNothing);
    expect(find.text('Noida'), findsNothing);
    expect(find.text('Create new Zone…'), findsNothing);
    expect(find.text('Please select City'), findsNothing);
  });

}
