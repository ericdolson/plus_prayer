// Selection rules in prayer, through Home as the user (and a screen reader)
// meets them: rows become checks; checking an intention holds its name;
// a name with only some intentions held reads as mixed.

import 'dart:ui' show CheckedState;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

enum Check { off, on, mixed }

Check checkOf(SemanticsData d) => switch (d.flagsCollection.isChecked) {
      CheckedState.mixed => Check.mixed,
      CheckedState.isTrue => Check.on,
      _ => Check.off,
    };

SemanticsData rowSemantics(WidgetTester tester, String labelStart) {
  final node = tester
      .getSemantics(find.bySemanticsLabel(RegExp('^${RegExp.escape(labelStart)}')).first);
  return node.getSemanticsData();
}

Future<void> startPrayer(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Pray'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('checking an intention holds its name; the name reads as mixed', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    await startPrayer(tester);

    // Dad has two intentions; hold one of them.
    await tester.tap(find.text('Healing after his surgery'));
    await tester.pump(const Duration(milliseconds: 800));

    final intention = rowSemantics(tester, 'Healing after his surgery');
    expect(checkOf(intention), Check.on);

    final dad = rowSemantics(tester, 'Dad, Gary Olson');
    expect(checkOf(dad), Check.mixed);

    // Unchecking the name lets go of its intentions.
    await tester.tap(find.text('Dad'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(checkOf(rowSemantics(tester, 'Dad, Gary Olson')), Check.off);
    expect(checkOf(rowSemantics(tester, 'Healing after his surgery')), Check.off);
    handle.dispose();
  });

  testWidgets('checking a name does not check its intentions', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    await startPrayer(tester);

    await tester.tap(find.text('Dad'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(checkOf(rowSemantics(tester, 'Dad, Gary Olson')), Check.on);
    expect(checkOf(rowSemantics(tester, 'Healing after his surgery')), Check.off);
    expect(checkOf(rowSemantics(tester, 'Rest for his heart')), Check.off);
    handle.dispose();
  });

  testWidgets('screen readers hear every carried name on the list row', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester);
    // Seed: you + 5 carried names → 5 avatars shown; the rest folded into "+ N".
    expect(
      find.bySemanticsLabel(RegExp('You, Dad, Mom, Daniel Kim, Our parish, Ukraine are not yet carried on List 53')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
