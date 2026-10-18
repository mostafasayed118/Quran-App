import '../../../core/db/app_database.dart';

/// Surah list seam (DIP pilot): cubits depend on this contract; the
/// drift-backed `SurahRepository` is the v1 implementation.
abstract class SurahSource {
  Stream<List<Surah>> watchAll();
}
