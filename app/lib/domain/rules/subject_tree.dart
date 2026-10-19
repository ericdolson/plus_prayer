// Home's personal list as a two-level tree (subjects.md): names as rows, each
// name's intentions indented beneath it. Order is manual (`sortOrder`, then
// creation); the self row ("Me") is pinned top.

import '../models/subject.dart';

class SubjectTree {
  SubjectTree._(this.names, this._intentions, this._byId);

  factory SubjectTree.of(Iterable<Subject> subjects) {
    final byId = {for (final s in subjects) s.id: s};
    int order(Subject a, Subject b) {
      final bySort = a.sortOrder.compareTo(b.sortOrder);
      return bySort != 0 ? bySort : a.createdAt.compareTo(b.createdAt);
    }

    final names = subjects.where((s) => s.isName).toList()
      ..sort((a, b) {
        if (a.isSelf != b.isSelf) return a.isSelf ? -1 : 1;
        return order(a, b);
      });
    final intentions = <String, List<Subject>>{};
    for (final s in subjects.where((s) => s.isIntention)) {
      // An intention whose name isn't loaded (archived, purged) isn't shown.
      if (!byId.containsKey(s.parentId)) continue;
      (intentions[s.parentId!] ??= []).add(s);
    }
    for (final list in intentions.values) {
      list.sort(order);
    }
    return SubjectTree._(names, intentions, byId);
  }

  /// Names in display order, self first.
  final List<Subject> names;
  final Map<String, List<Subject>> _intentions;
  final Map<String, Subject> _byId;

  Subject? operator [](String id) => _byId[id];

  Iterable<Subject> get all => _byId.values;

  Subject? get self => names.isNotEmpty && names.first.isSelf ? names.first : null;

  List<Subject> intentionsOf(String nameId) => _intentions[nameId] ?? const [];

  Subject? parentOf(String id) {
    final parentId = _byId[id]?.parentId;
    return parentId == null ? null : _byId[parentId];
  }
}
