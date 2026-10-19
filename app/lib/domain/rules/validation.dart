// Input rules for names and intentions (app-brief §3 "Input validation",
// list-lifecycle.md "Moderation for MVP / beta"). A port of the server's
// backend/functions/src/contact.ts and text.ts — keep the two in step; the
// server enforces the same rule, this gives the instant inline message.
//
// - Caps count visible characters (grapheme clusters), any script:
//   name 40, intention 80, alias 40, note 1,000.
// - Names and intentions (the printed text) can't contain a phone number
//   (7+ digits, allowing separators), an email, or a URL/domain.
// - Aliases are owner-only and never printed: capped, never checked.
// - Must pass: verse references ("John 3:16", "Isaiah 41:10-13", "Psalm 23"),
//   room / ward numbers, dates, memorial year ranges, and "St.".

import 'package:characters/characters.dart';

import '../models/subject.dart';

abstract final class TextCaps {
  static const name = 40;
  static const intention = 80;
  static const alias = 40;
  static const note = 1000;

  static int forKind(SubjectKind kind) => kind == SubjectKind.soul ? name : intention;
}

enum TextIssue {
  /// Nothing to save.
  empty,

  /// Over the grapheme cap.
  tooLong,

  /// Phone number, email, or link in printed text.
  contactInfo,
}

int graphemeLength(String text) => text.characters.length;

/// Trim and collapse whitespace runs (incl. newlines) to one space, as the
/// server stores it.
String cleanText(String text) => text.replaceAll(RegExp(r'\s+', unicode: true), ' ').trim();

/// A name or intention — the printed text.
TextIssue? validatePrinted(String raw, SubjectKind kind) {
  final text = cleanText(raw);
  if (text.isEmpty) return TextIssue.empty;
  if (graphemeLength(text) > TextCaps.forKind(kind)) return TextIssue.tooLong;
  if (hasContactInfo(text)) return TextIssue.contactInfo;
  return null;
}

/// The self name ("What's your name?") follows the name rules.
TextIssue? validateSelfName(String raw) => validatePrinted(raw, SubjectKind.soul);

/// An alias: optional, capped, never moderated.
TextIssue? validateAlias(String? raw) {
  if (raw == null) return null;
  return graphemeLength(cleanText(raw)) > TextCaps.alias ? TextIssue.tooLong : null;
}

final _email = RegExp(r'[^\s@]+@[^\s@]+\.[a-z]{2,}', caseSensitive: false);
final _urlPrefix = RegExp(r'\bhttps?://|\bwww\.', caseSensitive: false);

// A label followed by a real TLD, not followed by more letters ("St. Jude",
// "e.g." and initials don't qualify).
final _domain = RegExp(
  r'\b[a-z0-9][a-z0-9-]*\.(com|net|org|edu|gov|info|biz|io|co|me|ly|app|dev|ai|xyz|online|site|store|blog|page|link|tv|gg|us|uk|ca|au|nz|ie|in|de|fr|es|it|nl|be|ch|at|pt|br|mx|ph|za|ng|ke)(?![a-z])',
  caseSensitive: false,
);

// Things that look numeric but aren't phone numbers — removed before counting.
final _notPhone = [
  RegExp(r'\b\d{4}-\d{1,2}-\d{1,2}\b'), // 2026-10-18
  RegExp(r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b'), // 10/18/2026, 18.10.26, 10-18-2026
  RegExp(r'\b(1[89]|20)\d{2}\s*[-–—]\s*(1[89]|20)\d{2}\b'), // 1945-2023
  RegExp(r'\b\d{1,3}:\d{1,3}(\s*[-–]\s*\d{1,3}(:\d{1,3})?)?\b'), // 3:16, 41:10-13, 3:16-4:2
];

// A run of digits joined by phone separators (space, dot, dash, parens, plus).
final _digitRun = RegExp(r'\+?\(?\d[\d\s.()-]*\d');
final _digit = RegExp(r'\d');

bool hasPhoneNumber(String text) {
  var t = text;
  for (final re in _notPhone) {
    t = t.replaceAll(re, ' ');
  }
  for (final run in _digitRun.allMatches(t)) {
    if (_digit.allMatches(run[0]!).length >= 7) return true;
  }
  return false;
}

bool hasContactInfo(String text) =>
    _email.hasMatch(text) || _urlPrefix.hasMatch(text) || _domain.hasMatch(text) || hasPhoneNumber(text);
