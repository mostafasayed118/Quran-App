import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The share seam for an ayah: text and a rendered image card.
///
/// A separate interface keeps the preview sheet testable without the platform
/// share channel or the filesystem.
abstract interface class AyahSharer {
  /// Shares [text] through the system sheet.
  Future<void> shareText(String text);

  /// Writes [bytes] to a temporary PNG and shares it with [text].
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    required String text,
  });
}

/// The production sharer: `share_plus` plus the app's temporary directory.
class SharePlusAyahSharer implements AyahSharer {
  /// Creates the sharer.
  const SharePlusAyahSharer();

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    required String text,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }
}
