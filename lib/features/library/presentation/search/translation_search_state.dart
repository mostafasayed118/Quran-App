import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_search_state.freezed.dart';

/// One matching translation ayah.
class TranslationHit {
  /// Creates a hit.
  const TranslationHit({
    required this.surahId,
    required this.ayah,
    required this.text,
    required this.surahName,
  });

  /// The surah number (1..114).
  final int surahId;

  /// The ayah number inside the surah.
  final int ayah;

  /// The translated text.
  final String text;

  /// The Arabic surah name; empty when the lookup failed.
  final String surahName;
}

@freezed
sealed class TranslationSearchState with _$TranslationSearchState {
  const factory TranslationSearchState.loading() = TranslationSearchLoading;

  const factory TranslationSearchState.failed() = TranslationSearchFailed;

  const factory TranslationSearchState.ready({
    @Default(false) bool hasPacks,
    @Default('') String query,
    @Default(<TranslationHit>[]) List<TranslationHit> hits,
    @Default(0) int total,
  }) = TranslationSearchReady;
}
