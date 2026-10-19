// Input validation (app-brief §3). The BLOCKED / ALLOWED lists are the same as
// backend/functions/test/contact.test.ts so the app and the server agree.

import 'package:flutter_test/flutter_test.dart';
import 'package:plusprayer/domain/models/subject.dart';
import 'package:plusprayer/domain/rules/validation.dart';

const blocked = [
  'Call 555-123-4567',
  '555 1234',
  '(555) 123-4567',
  '555.123.4567',
  '+44 20 7946 0958',
  'Text me 5551234567',
  'Ana 0917 123 4567',
  'jane@example.com',
  'Write to jane.doe@mail.co.uk',
  'www.example.com',
  'example.com',
  'visit example.org/pray',
  'https://x.org/a',
  'See PrayForAna.net',
];

const allowed = [
  'John 3:16',
  'Psalm 23',
  'Isaiah 41:10-13',
  'Romans 8:28-39',
  'Mark 10:45 and Psalm 91',
  'Room 412',
  'Rm 1203, Bed 4',
  'Ward 7B',
  'Apt 12, Unit 5',
  'Flight 1234',
  '10/18/2026',
  '2026-10-18',
  '18.10.26',
  'Oct 18, 2026',
  'Jan 3 2026 surgery at 9',
  'Gary Olson 1945-2023',
  'Gary Olson (1945–2023)',
  'St. Jude',
  "St. Mary's Hospital",
  'Dr. Kim',
  'e.g. healing',
  'Mom (age 84)',
];

void main() {
  group('contact detection', () {
    for (final text in blocked) {
      test('blocks: $text', () => expect(hasContactInfo(text), isTrue));
    }
    for (final text in allowed) {
      test('allows: $text', () => expect(hasContactInfo(text), isFalse));
    }
  });

  group('names and intentions', () {
    test('contact info is blocked in both', () {
      expect(validatePrinted('Ana 555-123-4567', SubjectKind.soul), TextIssue.contactInfo);
      expect(validatePrinted('Donate at example.org', SubjectKind.intention), TextIssue.contactInfo);
    });

    test('verse references, years, rooms and "St." save', () {
      expect(validatePrinted('Strength — Isaiah 41:10', SubjectKind.intention), isNull);
      expect(validatePrinted('Gary Olson 1945-2023', SubjectKind.soul), isNull);
      expect(validatePrinted('St. Jude Room 412', SubjectKind.soul), isNull);
    });

    test('empty or whitespace-only is empty', () {
      expect(validatePrinted('', SubjectKind.soul), TextIssue.empty);
      expect(validatePrinted('  \n\t ', SubjectKind.intention), TextIssue.empty);
    });

    test('caps: 40 for a name, 80 for an intention', () {
      expect(validatePrinted('a' * 40, SubjectKind.soul), isNull);
      expect(validatePrinted('a' * 41, SubjectKind.soul), TextIssue.tooLong);
      expect(validatePrinted('a' * 80, SubjectKind.intention), isNull);
      expect(validatePrinted('a' * 81, SubjectKind.intention), TextIssue.tooLong);
    });

    test('caps count visible characters, not code units', () {
      // 40 family emoji (7 code points each) and 40 accented letters.
      expect(validatePrinted('👨‍👩‍👧' * 40, SubjectKind.soul), isNull);
      expect(validatePrinted('é' * 40, SubjectKind.soul), isNull);
      expect(validatePrinted('é' * 41, SubjectKind.soul), TextIssue.tooLong);
      // Other scripts.
      expect(graphemeLength('नमस्ते'), 3);
      expect(validatePrinted('王' * 40, SubjectKind.soul), isNull);
    });

    test('whitespace runs collapse before counting', () {
      expect(cleanText('  Gary \n  Olson  '), 'Gary Olson');
      expect(validatePrinted('${'a' * 20}     ${'b' * 19}', SubjectKind.soul), isNull);
    });

    test('the self name follows the name rules', () {
      expect(validateSelfName('Tom tom@example.com'), TextIssue.contactInfo);
      expect(validateSelfName('Tom (John 3:16)'), isNull);
    });
  });

  group('aliases', () {
    test('never checked for contact info (owner-only, never printed)', () {
      expect(validateAlias('Ana 555-123-4567'), isNull);
      expect(validateAlias('Bea www.bea.com'), isNull);
    });

    test('optional, capped at 40', () {
      expect(validateAlias(null), isNull);
      expect(validateAlias(''), isNull);
      expect(validateAlias('d' * 40), isNull);
      expect(validateAlias('d' * 41), TextIssue.tooLong);
    });
  });
}
