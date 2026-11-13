import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/deep_links.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/verse.dart';

/// The shareable ayah card.
///
/// Fixed palette on purpose: the image must look the same regardless of the
/// phone's light/dark theme. Width is logical pixels; the capture runs at a
/// 2× pixel ratio, so the exported PNG is 720 px wide for the default 360.
class VerseCard extends StatelessWidget {
  /// Creates the card for [ayah].
  const VerseCard({
    super.key,
    required this.ayah,
    required this.surahName,
    this.width = 360,
  });

  /// The verse to render.
  final Verse ayah;

  /// The surah name shown above the verse.
  final String surahName;

  /// Logical width of the card.
  final double width;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final text = ayah.displayText;
    final fontSize = text.length > 400 ? 18.0 : 22.0;
    final host = Uri.parse(
      webSurahUrl(ayah.surahId, ayah.numberInSurah),
    ).host;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.mushafCardTop, AppColors.mushafCardBottom],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color: AppColors.mushafCardAccent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    loc.appName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mushafCardAccent,
                      fontFamily: QuranFonts.ui,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    surahName,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mushafCardInk,
                      fontFamily: QuranFonts.ui,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.mushafCardInk,
                fontFamily: QuranFonts.quran,
                fontSize: fontSize,
                height: 2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              loc.ornateBrackets(loc.number(ayah.numberInSurah)),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mushafCardAccent,
                fontFamily: QuranFonts.meQuran,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            Container(
                height: 1,
                color: AppColors.mushafCardAccent.withValues(alpha: 0.25)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'quran yahdi',
                  style: TextStyle(
                    color: AppColors.mushafCardMuted,
                    fontFamily: QuranFonts.ui,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    host,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mushafCardMuted,
                      fontFamily: QuranFonts.ui,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
