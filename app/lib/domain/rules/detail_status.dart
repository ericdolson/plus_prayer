// The detail page's status line (detail-page.md "Status line"): the community
// card's carry logic, said about one subject.
//
// - Carried (the self always; a name or intention effectively carried):
//   covered → "Dad will be on List 53"; prayed with the list today but it
//   has flipped → "Your next prayer carries Dad onto List 54"; not prayed →
//   "Pray to carry Dad onto List 53". The self says "you", an intention
//   "it".
// - The closing notice replaces it under the card's rule (only if you haven't
//   prayed with the list today).
// - Not carried (private, or an intention under an uncarried name): no
//   line — mark presence, never absence.
// - An answered intention: "Answered · {date}" in its place.

import '../models/prayer_list.dart';
import '../models/subject.dart';
import 'card_carry.dart';
import 'carry.dart';
import 'subject_tree.dart';

/// Who the line speaks about.
enum StatusVoice { name, self, intention }

sealed class DetailStatus {
  const DetailStatus();
}

class DetailAnswered extends DetailStatus {
  const DetailAnswered(this.on);
  final DateTime on;
}

class DetailCarry extends DetailStatus {
  const DetailCarry({required this.status, required this.voice, required this.nextList});

  final TomorrowStatus status;
  final StatusVoice voice;

  /// The list the next prayer carries onto (the current list + 1).
  final int nextList;

  /// Covered: the line steps back to `inkMuted`; otherwise `ink`.
  bool get covered => status == TomorrowStatus.covered;
}

class DetailClosing extends DetailStatus {
  const DetailClosing({required this.voice, required this.list, required this.minutes});

  final StatusVoice voice;
  final int list;
  final int minutes;

  int get nextList => list + 1;
}

StatusVoice voiceOf(Subject s) => s.isSelf
    ? StatusVoice.self
    : s.isIntention
        ? StatusVoice.intention
        : StatusVoice.name;

DetailStatus? detailStatus(
  Subject s,
  SubjectTree tree, {
  required CurrentList? list,
  required TomorrowStatus? tomorrow,
  int? closingMinutes,
}) {
  if (s.resolution == Resolution.answered && s.resolvedAt != null) return DetailAnswered(s.resolvedAt!);
  final carried = s.isSelf || isEffectivelyCarried(s, tree);
  if (!carried || list == null || tomorrow == null) return null;
  final voice = voiceOf(s);
  if (closingMinutes != null) return DetailClosing(voice: voice, list: list.listNumber, minutes: closingMinutes);
  return DetailCarry(status: tomorrow, voice: voice, nextList: list.nextListNumber);
}
