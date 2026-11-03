// The community card's rules (design-direction.md §6, 2026-11-02): the you
// block's avatars fill the width (+N only on measured overflow), and the
// status speaks about "you" when you're the only one carried.

import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/domain/models/local_date.dart';
import 'package:plusprayer/domain/models/prayer_list.dart';
import 'package:plusprayer/domain/models/subject.dart';
import 'package:plusprayer/domain/rules/avatar_cluster.dart';
import 'package:plusprayer/domain/rules/card_carry.dart';
import 'package:plusprayer/domain/rules/subject_tree.dart';

final _created = DateTime(2026, 10, 1);

Subject name(String id, {bool self = false, bool carried = true, int order = 0}) => Subject(
      id: id,
      kind: SubjectKind.soul,
      publicName: id,
      sortOrder: order,
      createdAt: _created,
      isSelf: self,
      isCarried: carried,
    );

void main() {
  group('discCapacity', () {
    test('counts overlapping discs that fit the width', () {
      // 24 pt discs, 16.8 pt apart: 24 + 16.8 × 3 = 74.4 ≤ 80 < 91.2.
      expect(discCapacity(80, 24, 16.8), 4);
    });

    test('is 0 when not even one disc fits', () {
      expect(discCapacity(20, 24, 16.8), 0);
    });
  });

  group('fillRow', () {
    test('everyone fits: no +N disc', () {
      expect(fillRow(10, 10), (shown: 10, overflow: 0));
      expect(fillRow(3, 10), (shown: 3, overflow: 0));
    });

    test('one more than fits: the last slot becomes the +N disc', () {
      expect(fillRow(11, 10), (shown: 9, overflow: 2));
    });
  });

  group('cardCarry', () {
    const today = LocalDate(2026, 11, 2);
    const list = CurrentList(
      id: 'list-52',
      listNumber: 52,
      listDate: today,
      isPublished: true,
      soulCount: 4345,
      intentionCount: 1212,
      prayerCount: 3881,
    );
    final tree = SubjectTree.of([
      name('me', self: true),
      name('dad', order: 1),
      name('bea', order: 2, carried: false),
    ]);

    CardCarry carry(SubjectTree tree, List<String> printed) => cardCarry(
          tree: tree,
          list: list,
          status: MyListStatus(listId: list.id, entries: [
            for (final id in printed) ListEntry(subjectId: id, publicName: id, isName: true, isSelf: id == 'me'),
          ]),
          localPrayers: const [],
          header: null,
          today: today,
        );

    test('the avatars are your carried people, you first', () {
      expect(carry(tree, ['me', 'bea']).carried.map((s) => s.id), ['me', 'dad']);
    });

    test('speaks about you when only you are carried, whoever was on today', () {
      final onlyMe = SubjectTree.of([name('me', self: true), name('bea', order: 1, carried: false)]);
      expect(carry(onlyMe, ['me', 'bea']).aboutYouOnly, isTrue);
      expect(carry(tree, ['me']).aboutYouOnly, isFalse);
    });
  });
}
