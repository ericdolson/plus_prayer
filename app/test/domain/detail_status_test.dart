import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/domain/models/local_date.dart';
import 'package:plusprayer/domain/models/prayer_list.dart';
import 'package:plusprayer/domain/models/subject.dart';
import 'package:plusprayer/domain/rules/card_carry.dart';
import 'package:plusprayer/domain/rules/detail_status.dart';
import 'package:plusprayer/domain/rules/subject_tree.dart';

final _t0 = DateTime(2026, 9, 1);

Subject _name(String id, {bool carried = true, bool self = false}) => Subject(
      id: id,
      kind: SubjectKind.soul,
      publicName: id,
      sortOrder: 1,
      createdAt: _t0,
      isCarried: carried,
      isSelf: self,
    );

Subject _intention(String id, String parent, {bool carried = true, DateTime? answeredAt}) => Subject(
      id: id,
      kind: SubjectKind.intention,
      parentId: parent,
      publicName: id,
      sortOrder: 1,
      createdAt: _t0,
      isCarried: carried,
      resolution: answeredAt == null ? null : Resolution.answered,
      resolvedAt: answeredAt,
    );

void main() {
  final tree = SubjectTree.of([
    _name('me', self: true),
    _name('dad'),
    _intention('dad-1', 'dad'),
    _intention('dad-2', 'dad', carried: false),
    _name('bea', carried: false),
    _intention('bea-1', 'bea'),
    _intention('mom-1', 'dad', answeredAt: DateTime(2026, 10, 6)),
  ]);
  const list = CurrentList(
    id: 'list-52',
    listNumber: 52,
    listDate: LocalDate(2026, 10, 19),
    isPublished: true,
    soulCount: 1,
    intentionCount: 0,
    prayerCount: 0,
  );

  DetailStatus? status(String id, {TomorrowStatus tomorrow = TomorrowStatus.covered, int? closing}) =>
      detailStatus(tree[id]!, tree, list: list, tomorrow: tomorrow, closingMinutes: closing);

  test('carried items speak in their own voice, about the next list', () {
    final dad = status('dad') as DetailCarry;
    expect((dad.voice, dad.nextList, dad.covered), (StatusVoice.name, 53, true));
    expect((status('me') as DetailCarry).voice, StatusVoice.self);
    expect((status('dad-1', tomorrow: TomorrowStatus.prayToCarry) as DetailCarry).voice, StatusVoice.intention);
  });

  test('not carried — private, or under an uncarried name — has no line', () {
    expect(status('dad-2'), isNull);
    expect(status('bea'), isNull);
    expect(status('bea-1'), isNull);
  });

  test('answered replaces the status; the closing notice replaces a carried status', () {
    expect(status('mom-1'), isA<DetailAnswered>());
    final closing = status('dad', tomorrow: TomorrowStatus.prayToCarry, closing: 4) as DetailClosing;
    expect((closing.list, closing.minutes, closing.nextList), (52, 4, 53));
    expect(status('dad-2', closing: 4), isNull);
  });
}
