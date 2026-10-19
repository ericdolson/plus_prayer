// Selection rules in prayer (subjects.md, prayer-flow.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/domain/models/subject.dart';
import 'package:plusprayer/domain/rules/selection.dart';
import 'package:plusprayer/domain/rules/subject_tree.dart';

final _t0 = DateTime.utc(2026, 10, 1);

Subject name(String id, {int order = 1, bool self = false}) => Subject(
      id: id,
      kind: SubjectKind.soul,
      publicName: id,
      sortOrder: order,
      createdAt: _t0,
      isSelf: self,
    );

Subject intention(String id, String parent, {int order = 1}) => Subject(
      id: id,
      kind: SubjectKind.intention,
      parentId: parent,
      publicName: id,
      sortOrder: order,
      createdAt: _t0,
    );

void main() {
  // me ─ me.work
  // dad ─ dad.surgery, dad.sleep
  // mom (no intentions)
  final tree = SubjectTree.of([
    name('dad', order: 1),
    name('me', self: true),
    name('mom', order: 2),
    intention('me.work', 'me'),
    intention('dad.surgery', 'dad', order: 1),
    intention('dad.sleep', 'dad', order: 2),
  ]);
  const none = PrayerSelection.empty;

  group('checking', () {
    test('an intention also holds its name', () {
      final s = none.toggle('dad.surgery', tree);
      expect(s.held, {'dad.surgery', 'dad'});
    });

    test('a name does not check its intentions', () {
      final s = none.toggle('dad', tree);
      expect(s.held, {'dad'});
    });

    test('works under the self row too', () {
      expect(none.toggle('me.work', tree).held, {'me.work', 'me'});
    });

    test('unknown ids change nothing', () {
      expect(none.toggle('ghost', tree).held, isEmpty);
    });
  });

  group('unchecking', () {
    test('a name unchecks its intentions', () {
      final s = none.toggle('dad.surgery', tree).toggle('dad.sleep', tree).toggle('dad', tree);
      expect(s.held, isEmpty);
    });

    test('an intention leaves its name held', () {
      final s = none.toggle('dad.surgery', tree).toggle('dad.surgery', tree);
      expect(s.held, {'dad'});
    });

    test("a name's intentions only — other names are untouched", () {
      final s = none.toggle('dad.surgery', tree).toggle('me.work', tree).toggle('dad', tree);
      expect(s.held, {'me.work', 'me'});
    });
  });

  group('row state', () {
    test('partial when only some intentions are held', () {
      final s = none.toggle('dad.surgery', tree);
      expect(s.stateOf('dad', tree), HoldState.partial);
      expect(s.stateOf('dad.surgery', tree), HoldState.held);
      expect(s.stateOf('dad.sleep', tree), HoldState.none);
    });

    test('held when every intention is held', () {
      final s = none.toggle('dad.surgery', tree).toggle('dad.sleep', tree);
      expect(s.stateOf('dad', tree), HoldState.held);
    });

    test('held when the name alone is held', () {
      expect(none.toggle('dad', tree).stateOf('dad', tree), HoldState.held);
      expect(none.toggle('mom', tree).stateOf('mom', tree), HoldState.held);
    });

    test('a single held intention is the whole set — not partial', () {
      expect(none.toggle('me.work', tree).stateOf('me', tree), HoldState.held);
    });

    test('none when not held', () {
      expect(none.stateOf('dad', tree), HoldState.none);
    });
  });

  group('the list', () {
    test('is its own toggle and survives subject changes', () {
      final s = none.withList(true).toggle('dad', tree).toggle('dad', tree);
      expect(s.listIncluded, isTrue);
      expect(s.held, isEmpty);
      expect(s.isEmpty, isFalse);
    });
  });
}
