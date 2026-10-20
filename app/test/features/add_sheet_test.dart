// Input validation in the add sheet (app-brief §3): blocked inline, as the
// user types; verse references and aliases pass.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const contactMessage = "Names and intentions can't include phone numbers, emails, or links.";

Finder field(String label) => find.widgetWithText(TextField, label);
Finder addButton() => find.widgetWithText(FilledButton, 'Add');

Future<void> openAddSheet(WidgetTester tester) async {
  await tester.tap(find.text('Add'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('contact info in a name shows the inline message and blocks Add', (tester) async {
    final backend = await pumpHome(tester);
    await openAddSheet(tester);

    await tester.enterText(field('Name'), 'Ana 555-123-4567');
    await tester.pump();
    expect(find.text(contactMessage), findsOneWidget);
    expect(tester.widget<FilledButton>(addButton()).onPressed, isNull);

    await tester.enterText(field('Name'), 'Ana');
    await tester.pump();
    expect(find.text(contactMessage), findsNothing);
    expect(tester.widget<FilledButton>(addButton()).onPressed, isNotNull);
    expect(backend.subjects.where((s) => s.publicName == 'Ana'), isEmpty);
  });

  testWidgets('an alias is never checked, and the name saves', (tester) async {
    final backend = await pumpHome(tester);
    await openAddSheet(tester);

    await tester.enterText(field('Name'), 'Beatrice Lane');
    await tester.enterText(field('Alias (optional)'), 'Bea 555-123-4567');
    await tester.pump();
    expect(find.text(contactMessage), findsNothing);

    await tester.tap(addButton());
    await settle(tester);
    final added = backend.subjects.singleWhere((s) => s.publicName == 'Beatrice Lane');
    expect(added.alias, 'Bea 555-123-4567');
    // Offered once after adding a name.
    expect(find.text('Add an intention for Bea 555-123-4567?'), findsOneWidget);
  });

  testWidgets('an intention with a verse reference saves under "Me" by default', (tester) async {
    final backend = await pumpHome(tester);
    await openAddSheet(tester);

    await tester.tap(find.text('Intention'));
    await tester.pump();
    await tester.enterText(field('Intention'), 'Strength — Isaiah 41:10');
    await tester.pump();
    expect(find.text(contactMessage), findsNothing);

    await tester.tap(addButton());
    await settle(tester);
    final added = backend.subjects.singleWhere((s) => s.publicName == 'Strength — Isaiah 41:10');
    expect(added.parentId, 'self');
  });

  testWidgets('contact info in an intention is blocked too', (tester) async {
    await pumpHome(tester);
    await openAddSheet(tester);

    await tester.tap(find.text('Intention'));
    await tester.pump();
    await tester.enterText(field('Intention'), 'Donate at example.org');
    await tester.pump();
    expect(find.text(contactMessage), findsOneWidget);
    expect(tester.widget<FilledButton>(addButton()).onPressed, isNull);
  });
}
