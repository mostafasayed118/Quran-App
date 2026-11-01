import '../domain/juz_summary.dart';

/// Cross-feature seam for the derived juz index.
///
/// Deliberately a new port: adding a member to the frozen `AyahSource` /
/// `SurahSource` would break their existing test doubles.
abstract interface class JuzIndexSource {
  /// The 30 juz starts, ordered by juz number.
  Stream<List<JuzSummary>> watchJuz();
}
