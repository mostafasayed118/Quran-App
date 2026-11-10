import 'package:quran_yahdi/core/utils/app_log.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/utils/deep_links.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/ayah_sharer.dart';
import '../../domain/verse.dart';
import 'verse_card.dart';

/// Captures the card behind [boundaryKey] as PNG bytes.
///
/// Injectable so the sheet can be tested without a real raster.
typedef VerseImageCapture = Future<Uint8List?> Function(GlobalKey boundaryKey);

/// Opens the share preview for [ayah].
Future<void> showVerseShareSheet(
  BuildContext context, {
  required Verse ayah,
  required String surahName,
  AyahSharer? sharer,
  VerseImageCapture? capture,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => VerseShareSheet(
      ayah: ayah,
      surahName: surahName,
      sharer: sharer,
      capture: capture,
    ),
  );
}

/// The preview: the card plus the image/text share actions.
class VerseShareSheet extends StatefulWidget {
  /// Creates the sheet; [sharer] and [capture] are test seams.
  const VerseShareSheet({
    super.key,
    required this.ayah,
    required this.surahName,
    this.sharer,
    this.capture,
  });

  /// The verse to render.
  final Verse ayah;

  /// The surah name shown on the card.
  final String surahName;

  /// The share seam; the production sharer is used when null.
  final AyahSharer? sharer;

  /// The capture seam; the real raster is used when null.
  final VerseImageCapture? capture;

  @override
  State<VerseShareSheet> createState() => _VerseShareSheetState();
}

class _VerseShareSheetState extends State<VerseShareSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;

  AyahSharer get _sharer => widget.sharer ?? const SharePlusAyahSharer();

  String _composeText(AppLocalizations loc) => loc.shareAyahText(
        widget.ayah.copyText,
        webSurahUrl(widget.ayah.surahId, widget.ayah.numberInSurah),
      );

  Future<void> _shareText() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _sharer.shareText(_composeText(AppLocalizations.of(context)));
    } on Object catch (error, stackTrace) {
      appLog('ayah text share failed',
          name: 'quran_yahdi/share', error: error, stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    final loc = AppLocalizations.of(context);
    final text = _composeText(loc);
    try {
      final bytes = await (widget.capture ?? _capture)(_boundaryKey);
      if (bytes == null) {
        await _sharer.shareText(text);
        return;
      }
      await _sharer.shareImage(
        bytes,
        fileName:
            'ayah-${widget.ayah.surahId}-${widget.ayah.numberInSurah}.png',
        text: text,
      );
    } on Object catch (error, stackTrace) {
      // A failed raster or share must never leave the user with nothing.
      appLog('ayah image share failed',
          name: 'quran_yahdi/share', error: error, stackTrace: stackTrace);
      try {
        await _sharer.shareText(text);
      } on Object catch (fallbackError, fallbackStack) {
        appLog('ayah text fallback failed',
            name: 'quran_yahdi/share',
            error: fallbackError,
            stackTrace: fallbackStack);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List?> _capture(GlobalKey key) async {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;
    final image = await object.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + appBottomInset(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: VerseCard(
              ayah: widget.ayah,
              surahName: widget.surahName,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _shareImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(loc.shareAsImage),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _shareText,
                  icon: const Icon(Icons.text_fields),
                  label: Text(loc.shareAsText),
                ),
              ),
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
