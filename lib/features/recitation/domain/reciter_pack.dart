/// Curated reciter packs — the executable form of the accepted decision in
/// `docs/decisions/2026-11-02-curated-reciter-packs.md`.
///
/// A pack is metadata only: it names existing catalog rows and says why. It
/// never carries audio and never changes how playback or downloads work.
///
/// The single rule this file exists to enforce: **a pack cannot ship without a
/// named human reviewer**. `reviewedBy` is a religious/tajweed attestation, so
/// it is never auto-filled — not by the owner's account and not by an agent.
library;

/// One curated entry: an existing catalog row plus the reason it was chosen.
class ReciterPackEntry {
  const ReciterPackEntry({required this.rowId, required this.reasonAr});

  /// `ReciterRow.id` in `<reciterId>-<moshafId>` form.
  final String rowId;

  /// Why this reciter belongs in the pack — shown to the user verbatim.
  final String reasonAr;
}

/// A curated pack of reciters presented as one list.
class ReciterPack {
  const ReciterPack({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.reviewedBy,
    required this.entries,
    this.technicalReview = '',
    this.updatedAt = '',
  });

  /// Safe slug used for storage and surfaces (`^[a-z0-9][a-z0-9-]{0,63}$`).
  final String id;
  final String titleAr;
  final String descriptionAr;

  /// Name of the human who reviewed tajweed accuracy and recordings.
  ///
  /// Empty means "not reviewed" and blocks publication — see [validateReciterPack].
  final String reviewedBy;

  /// Non-attesting check (ids exist, surah totals, no commercial ranking).
  final String technicalReview;

  /// ISO-8601 date of the last review.
  final String updatedAt;

  final List<ReciterPackEntry> entries;
}

/// Why a pack is not publishable. An empty list means it is.
enum ReciterPackDefect {
  tooFewEntries,
  tooManyEntries,
  missingReviewer,
  emptyReason,
  duplicateRow,
  invalidId,
  unknownRow,
}

/// Lower bound from the decision (D3).
const int kMinReciterPackEntries = 3;

/// Upper bound from the decision (D3): a pack must stay a short curated list.
const int kMaxReciterPackEntries = 7;

/// Storage-safe pack slug.
final RegExp kReciterPackIdPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Publishes nothing today: packs are added only after a reviewer signs one.
///
/// The candidate list lives in
/// `docs/decisions/2026-11-02-first-reciter-pack-candidate.md` and stays out of
/// this list until `reviewedBy` is filled by a human.
const List<ReciterPack> kReciterPacks = <ReciterPack>[];

/// Returns every reason [pack] may not be published.
///
/// [knownRowIds] optionally restricts entries to rows that exist in the
/// catalog; pass the live catalog ids when validating content, and omit it in
/// pure unit tests that only exercise the shape rules.
List<ReciterPackDefect> validateReciterPack(
  ReciterPack pack, {
  Set<String>? knownRowIds,
}) {
  final defects = <ReciterPackDefect>[];

  if (pack.entries.length < kMinReciterPackEntries) {
    defects.add(ReciterPackDefect.tooFewEntries);
  } else if (pack.entries.length > kMaxReciterPackEntries) {
    defects.add(ReciterPackDefect.tooManyEntries);
  }

  if (pack.reviewedBy.trim().isEmpty) {
    defects.add(ReciterPackDefect.missingReviewer);
  }

  if (!kReciterPackIdPattern.hasMatch(pack.id)) {
    defects.add(ReciterPackDefect.invalidId);
  }

  final seen = <String>{};
  for (final entry in pack.entries) {
    if (entry.reasonAr.trim().isEmpty) {
      defects.add(ReciterPackDefect.emptyReason);
    }
    if (!seen.add(entry.rowId)) {
      defects.add(ReciterPackDefect.duplicateRow);
    }
    if (knownRowIds != null && !knownRowIds.contains(entry.rowId)) {
      defects.add(ReciterPackDefect.unknownRow);
    }
  }

  // One defect per kind keeps the result readable and order-stable.
  return <ReciterPackDefect>{
    for (final defect in defects) defect,
  }.toList(growable: false);
}
