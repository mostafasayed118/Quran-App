import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_pack.dart';

/// Pure shape tests for the curated-pack gate. No Flutter widgets involved.
ReciterPack _pack({
  String id = 'basics',
  String reviewedBy = 'مراجع تجريبي',
  List<String> rowIds = const <String>['51-51', '118-118', '112-114'],
  String reason = 'مصحف كامل ١١٤ سورة',
}) {
  return ReciterPack(
    id: id,
    titleAr: 'أساسيات التلاوة',
    descriptionAr: 'حزمة تجريبية',
    reviewedBy: reviewedBy,
    entries: <ReciterPackEntry>[
      for (final rowId in rowIds)
        ReciterPackEntry(rowId: rowId, reasonAr: reason),
    ],
  );
}

void main() {
  test('a signed pack of three rows has no defects', () {
    expect(validateReciterPack(_pack()), isEmpty);
  });

  test('two entries are below the published minimum', () {
    final defects =
        validateReciterPack(_pack(rowIds: const <String>['51-51', '118-118']));
    expect(defects, contains(ReciterPackDefect.tooFewEntries));
  });

  test('eight entries are above the published maximum', () {
    final defects = validateReciterPack(
      _pack(rowIds: const <String>[
        '1-1',
        '2-2',
        '3-3',
        '4-4',
        '5-5',
        '6-6',
        '7-7',
        '8-8',
      ]),
    );
    expect(defects, contains(ReciterPackDefect.tooManyEntries));
  });

  test('a blank reviewer blocks publication', () {
    expect(
      validateReciterPack(_pack(reviewedBy: '   ')),
      contains(ReciterPackDefect.missingReviewer),
    );
  });

  test('an empty reviewer string is the same defect as whitespace', () {
    expect(
      validateReciterPack(_pack(reviewedBy: '')),
      contains(ReciterPackDefect.missingReviewer),
    );
  });

  test('an entry without a reason blocks publication', () {
    expect(
      validateReciterPack(_pack(reason: '')),
      contains(ReciterPackDefect.emptyReason),
    );
  });

  test('the same row twice blocks publication', () {
    final defects = validateReciterPack(
      _pack(rowIds: const <String>['51-51', '51-51', '118-118']),
    );
    expect(defects, contains(ReciterPackDefect.duplicateRow));
  });

  test('an unsafe pack id blocks publication', () {
    expect(
      validateReciterPack(_pack(id: 'Basic Pack!')),
      contains(ReciterPackDefect.invalidId),
    );
  });

  test('a row missing from the live catalog blocks publication', () {
    final defects = validateReciterPack(
      _pack(rowIds: const <String>['51-51', '118-118', '999-999']),
      knownRowIds: const <String>{'51-51', '118-118', '112-114'},
    );
    expect(defects, contains(ReciterPackDefect.unknownRow));
  });

  test('the candidate first pack cannot ship while its signature is empty', () {
    // Mirrors docs/decisions/2026-11-02-first-reciter-pack-candidate.md.
    final candidate = _pack(
      id: 'basics',
      reviewedBy: '',
      rowIds: const <String>[
        '51-51',
        '118-118',
        '112-114',
        '123-123',
        '102-102',
        '51-52'
      ],
    );
    expect(validateReciterPack(candidate),
        contains(ReciterPackDefect.missingReviewer));
  });

  test('nothing ships in kReciterPacks yet, and anything added must validate',
      () {
    expect(kReciterPacks, isEmpty, reason: 'no pack is signed yet');
    for (final pack in kReciterPacks) {
      expect(validateReciterPack(pack), isEmpty, reason: pack.id);
    }
  });
}
