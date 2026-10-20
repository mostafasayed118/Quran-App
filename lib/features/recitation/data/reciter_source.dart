import '../../../core/db/app_database.dart';

/// Reciter catalog seam (DIP rollout): cubits depend on this contract; the
/// drift-backed `ReciterRepository` is the v1 implementation.
///
/// Signatures mirror `ReciterRepository` exactly — the frozen test doubles
/// extend that class, so the contract must not drift.
abstract class ReciterSource {
  /// Re-fetches the reciter catalog and stores it locally.
  Future<void> refreshFromApi();

  /// Live list of reciters; the caller holds the stream.
  Stream<List<ReciterRow>> watchAll();

  /// The reciter with the given id, or null when unknown.
  Future<ReciterRow?> byId(String rowId);

  /// Stores the moshaf the user selected.
  Future<void> selectMoshaf(String rowId);

  /// The stored moshaf id, or null when none is selected.
  Future<String?> loadSelectedMoshaf();

  /// Arabic names of the given surahs, keyed by surah number.
  Future<Map<int, String>> surahNamesFor(List<int> surahIds);

  /// Short first-ayah teasers of the given surahs, keyed by surah number.
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds);
}
