// The carried pool (monetization.md, subjects.md). Mirrors the server's
// backend/functions/src/pool.ts so the app shows what the next list will print.
//
// - Effective carry: an intention is carried only if `isCarried &&
//   parent.isCarried` (or its parent is the self). The self name is always
//   carried and isn't part of the pool.
// - Resolved items are never list-eligible.
// - Effective entitlement: `includeLimit` while `entitlementExpiresAt` is in the
//   future; otherwise free = 1, which must be an intention under "Me".

import '../models/subject.dart';
import '../models/user_header.dart';
import 'subject_tree.dart';

const freeLimit = 1;

bool hasActiveEntitlement(UserHeader user, DateTime now) =>
    user.entitlementExpiresAt != null && user.entitlementExpiresAt!.isAfter(now);

/// Is [s] effectively carried (beyond the self name)?
bool isEffectivelyCarried(Subject s, SubjectTree tree) {
  if (s.isSelf || !s.isCarried || s.isResolved) return false;
  if (s.isName) return true;
  final parent = tree.parentOf(s.id);
  return parent != null && (parent.isSelf || parent.isCarried);
}

/// Whether the row shows the carried mark. The self is always carried.
bool showsCarriedMark(Subject s, SubjectTree tree) => s.isSelf || isEffectivelyCarried(s, tree);

List<Subject> effectiveCarried(SubjectTree tree) =>
    tree.all.where((s) => isEffectivelyCarried(s, tree)).toList();

class PoolCheck {
  const PoolCheck({required this.ok, required this.carried, required this.limit, required this.free});

  final bool ok;
  final int carried;

  /// The limit the carry is measured against (free → [freeLimit]).
  final int limit;
  final bool free;
}

/// Does the tree's carried set fit the user's EFFECTIVE entitlement now?
PoolCheck checkPool(SubjectTree tree, UserHeader user, DateTime now) {
  final carried = effectiveCarried(tree);
  if (hasActiveEntitlement(user, now)) {
    return PoolCheck(
      ok: carried.length <= user.includeLimit,
      carried: carried.length,
      limit: user.includeLimit,
      free: false,
    );
  }
  final selfId = tree.self?.id;
  final fitsFree = carried.length <= freeLimit &&
      carried.every((s) => s.isIntention && selfId != null && s.parentId == selfId);
  return PoolCheck(ok: fitsFree, carried: carried.length, limit: freeLimit, free: true);
}

/// The people named on the list row and the invitation: you first, then
/// effectively carried names in the user's order (intentions have no avatars).
List<Subject> carriedNames(SubjectTree tree) => [
      if (tree.self != null) tree.self!,
      ...tree.names.where((n) => isEffectivelyCarried(n, tree)),
    ];
