// The seam between the UI and the backend. Screens only ever see these
// interfaces; the mock (data/mock) and the real implementations (SQL Connect
// in data/sqlconnect, RTDB in data/rtdb — build step 4) both satisfy them.
//
// Anything the UI watches is a Stream; commands are Futures.

import '../../domain/models/live.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_list.dart';
import '../../domain/models/subject.dart';
import '../../domain/models/user_header.dart';
import '../../domain/rules/validation.dart';

/// getMySubjects + the subject callables (addSubject, …).
abstract interface class SubjectRepository {
  /// ACTIVE subjects (answered intentions stay until archived), with each
  /// row's `lastPrayed` local date.
  Stream<List<Subject>> watchSubjects();

  /// addSubject callable: appended to the bottom of its level; carried
  /// automatically while the pool has room. Throws [SubjectInputError] for
  /// text the server rejects, [OfflineError] without a connection.
  Future<AddedSubject> addSubject(NewSubject input);
}

class NewSubject {
  const NewSubject({required this.kind, required this.publicName, this.parentId, this.alias});

  final SubjectKind kind;
  final String publicName;

  /// Required for an intention.
  final String? parentId;
  final String? alias;
}

class AddedSubject {
  const AddedSubject({required this.id, required this.isCarried, required this.sortOrder});

  final String id;

  /// False when the pool was full: saved for private prayer, not on the list.
  final bool isCarried;
  final int sortOrder;
}

/// getCurrentListMeta + RTDB `/lists/current` (live count, closesAt).
abstract interface class ListRepository {
  Stream<CurrentList?> watchCurrentList();
}

/// getMyHeader.
abstract interface class UserRepository {
  /// Null while the account isn't ready yet.
  Stream<UserHeader?> watchHeader();
}

/// logPrayer / updatePrayerNote, through the offline write queue.
abstract interface class PrayerRepository {
  /// Queues the prayer (persisted before returning) and sends it when it can.
  Future<void> logPrayer(NewPrayer prayer);

  /// Note-only edit; queued after its prayer, so it can't overtake it.
  Future<void> updateNote(String prayerId, String? note);

  /// Prayers logged on this device that the server may not reflect yet —
  /// folded into Home so the result shows at once, even offline.
  Stream<List<NewPrayer>> watchLocalPrayers();
}

/// RTDB: `/stats/live`, `/config`, and the user's own presence node, which
/// doubles as the in-progress prayer draft.
abstract interface class LiveRepository {
  Stream<LiveStats> watchStats();

  /// `/config` overlaid on the compiled-in defaults.
  Stream<AppConfig> watchConfig();

  /// Writes this device's presence/draft; null clears it (not in prayer).
  Future<void> writeDraft(PrayerDraft? draft);

  /// The draft this device left open, if any (crash / app killed).
  Future<PrayerDraft?> readDraft();
}

/// The server rejected the text (same rules as `domain/rules/validation`).
class SubjectInputError implements Exception {
  const SubjectInputError(this.issue);
  final TextIssue issue;

  @override
  String toString() => 'SubjectInputError($issue)';
}

/// The command needs a connection and there isn't one.
class OfflineError implements Exception {
  const OfflineError();
}

/// The ~500-subject abuse cap ("contact us"). Not a paywall.
class SubjectCapError implements Exception {
  const SubjectCapError();
}
