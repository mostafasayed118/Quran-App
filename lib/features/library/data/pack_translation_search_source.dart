import 'library_catalog.dart' show LibraryPackKind;
import 'pack_downloader.dart';
import 'translation_search_source.dart';

/// Adapts the installed-pack registry and the pack reader to the search seam.
class PackTranslationSearchSource implements TranslationSearchSource {
  /// Creates the source over [downloader].
  PackTranslationSearchSource(this._downloader);

  final PackDownloader _downloader;

  @override
  Future<List<String>> installedTranslationIds() async {
    final rows = await _downloader.installedPacks();
    return [
      for (final row in rows)
        if (row.kind == LibraryPackKind.translation.name) row.packId,
    ];
  }

  @override
  Future<Map<int, String>> translationIndex(String packId) =>
      _downloader.translationIndex(packId);
}
