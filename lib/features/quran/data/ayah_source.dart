import '../../../core/db/app_database.dart';
import '../../../core/domain/ayah_lookup.dart';
import 'ayah_repository.dart';

/// Reader/ayah seam (DIP pilot): cubits depend on this contract; the
/// drift-backed `AyahRepository` is the v1 implementation.
///
/// Signatures mirror `AyahRepository` exactly — the frozen test doubles
/// extend that class, so the contract must not drift.
abstract class AyahSource implements AyahLookup {
  /// All ayahs of a surah, in reading order.
  Future<List<Ayah>> surahAyahs(int surahId);

  @override
  Future<Surah?> surahById(int surahId);

  @override
  Future<Ayah?> ayahById(int ayahId);

  @override
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah);

  /// Adds the ayah to the bookmarks when absent, removes it when present.
  Future<void> toggleBookmark(int ayahId);

  /// Removes the bookmark of the ayah when present; never re-adds it.
  Future<void> deleteBookmark(int ayahId);

  /// Live set of bookmarked ayah ids; the caller holds the stream.
  Stream<Set<int>> watchBookmarkedIds();

  /// Live list of bookmarked ayahs; the caller holds the stream.
  Stream<List<BookmarkEntry>> watchBookmarkEntries();
}
