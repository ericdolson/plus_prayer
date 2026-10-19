import 'local_date.dart';

/// SOUL = any "name" (person, group, cause). INTENTION = a request under a name.
enum SubjectKind { soul, intention }

enum Resolution { answered, released }

/// A `PrayerSubject` as Home sees it (getMySubjects). Field names follow the
/// schema; `alias` is the schema's `personalLabel`.
class Subject {
  const Subject({
    required this.id,
    required this.kind,
    required this.publicName,
    required this.sortOrder,
    required this.createdAt,
    this.parentId,
    this.alias,
    this.note,
    this.isSelf = false,
    this.isCarried = false,
    this.avatarTone,
    this.avatarPath,
    this.resolution,
    this.resolvedAt,
    this.lastPrayed,
  }) : assert(kind == SubjectKind.intention ? parentId != null : parentId == null);

  final String id;
  final SubjectKind kind;

  /// Required for an intention (its name), null for a name.
  final String? parentId;

  /// The printed text.
  final String publicName;

  /// Owner-only alias (`personalLabel`); the self subject's alias is "Me".
  final String? alias;
  final String? note;
  final bool isSelf;

  /// The user's own choice to print it. Effective carry also needs the parent
  /// name carried — see `rules/carry.dart`.
  final bool isCarried;
  final int sortOrder;

  /// Palette index; null = default from the id hash (`rules/avatar.dart`).
  final int? avatarTone;

  /// Photo seam (unused at MVP).
  final String? avatarPath;
  final Resolution? resolution;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  /// Local date of the user's latest prayer that held this item.
  final LocalDate? lastPrayed;

  bool get isName => kind == SubjectKind.soul;
  bool get isIntention => kind == SubjectKind.intention;
  bool get isResolved => resolution != null;

  /// What the owner sees in their own list: the alias if set.
  String get label => (alias != null && alias!.trim().isNotEmpty) ? alias! : publicName;

  Subject copyWith({
    String? publicName,
    String? alias,
    bool? isCarried,
    int? sortOrder,
    int? avatarTone,
    Resolution? resolution,
    DateTime? resolvedAt,
    LocalDate? lastPrayed,
  }) =>
      Subject(
        id: id,
        kind: kind,
        parentId: parentId,
        publicName: publicName ?? this.publicName,
        alias: alias ?? this.alias,
        note: note,
        isSelf: isSelf,
        isCarried: isCarried ?? this.isCarried,
        sortOrder: sortOrder ?? this.sortOrder,
        avatarTone: avatarTone ?? this.avatarTone,
        avatarPath: avatarPath,
        resolution: resolution ?? this.resolution,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        createdAt: createdAt,
        lastPrayed: lastPrayed ?? this.lastPrayed,
      );
}
