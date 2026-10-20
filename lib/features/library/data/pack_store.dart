import 'dart:io';

import 'pack_downloader.dart';

/// Filesystem store for installed library packs: the app-private folder,
/// safe pack-file resolution, and the part-file lifecycle (naming, promote,
/// delete) shared by the downloader's write paths.
///
/// Split out of [PackDownloader], which composes one; failures stay
/// [PackFailure] so callers observe the exact same errors.
class PackStore {
  PackStore({
    required Future<Directory> Function()? rootResolver,
    required this.folderName,
  }) : _rootResolver = rootResolver;

  final Future<Directory> Function()? _rootResolver;

  /// Folder under the app documents directory that holds the packs.
  final String folderName;

  Future<Directory> _root() async {
    final resolver = _rootResolver;
    if (resolver != null) return resolver();
    throw PackFailure(
        'libraryRootResolver not configured — register library bindings first');
  }

  /// Pack ids compose filesystem paths (see `library_catalog.dart`); the
  /// catalog already rejects unsafe ids, and this re-check keeps any future
  /// caller (or a tampered registry row) from steering a write/delete.
  static final RegExp _safePackId = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

  /// Path of the installed pack file for [packId].
  Future<File> packFile(String packId) async {
    if (!_safePackId.hasMatch(packId)) {
      throw PackFailure('unsafe pack id "$packId"');
    }
    final root = await _root();
    final dir = Directory('${root.path}${Platform.pathSeparator}$folderName');
    // Sync create: the read path must stay FakeAsync-safe for widget tests
    // (a real async mkdir never completes under the test zone) and is a
    // no-op when the folder already exists.
    dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}$packId.json');
  }

  /// The dot-part file a download streams into before promotion.
  File partFileFor(File finalFile) => File('${finalFile.path}.part');

  /// Promotes a fully-written part file to its final name.
  Future<File> promote(File partFile) => partFile.rename(
      partFile.path.substring(0, partFile.path.length - '.part'.length));

  /// Deletes [file] when it exists; missing files are not an error.
  Future<void> deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
