import '../../../core/db/app_database.dart';
import 'ayah_repository.dart';

/// Reader/ayah seam (DIP pilot): cubits depend on this contract; the
/// drift-backed `AyahRepository` is the v1 implementation.
///
/// Signatures mirror `AyahRepository` exactly — the frozen test doubles
/// extend that class, so the contract must not drift.
abstract class AyahSource {
  Future<List<Ayah>> surahAyahs(int surahId);

  Future<Surah?> surahById(int surahId);

  Future<Ayah?> ayahById(int ayahId);

  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah);

  Future<void> toggleBookmark(int ayahId);

  Stream<Set<int>> watchBookmarkedIds();

  Stream<List<BookmarkEntry>> watchBookmarkEntries();
}
