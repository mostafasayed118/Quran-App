import '../../../core/db/app_database.dart';
import '../domain/surah_summary.dart';

/// Surah list seam (DIP pilot): cubits depend on this contract; the
/// drift-backed `SurahRepository` is the v1 implementation.
abstract class SurahSource {
  /// Row-typed view — the frozen test doubles override this one.
  Stream<List<Surah>> watchAll();

  /// Domain-typed view: the presentation layer never sees drift rows.
  Stream<List<SurahSummary>> watchSummaries();
}
