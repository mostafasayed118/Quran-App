import '../../../core/db/app_database.dart';

/// Reciter catalog seam (DIP rollout): cubits depend on this contract; the
/// drift-backed `ReciterRepository` is the v1 implementation.
///
/// Signatures mirror `ReciterRepository` exactly — the frozen test doubles
/// extend that class, so the contract must not drift.
abstract class ReciterSource {
  Future<void> refreshFromApi();

  Stream<List<ReciterRow>> watchAll();

  Future<ReciterRow?> byId(String rowId);

  Future<void> selectMoshaf(String rowId);

  Future<String?> loadSelectedMoshaf();

  Future<Map<int, String>> surahNamesFor(List<int> surahIds);

  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds);
}
