import '../../l10n/app_localizations.dart';
import '../utils/arabic_numbers.dart';

/// Locale-aware digit rendering for the app's generated copy.
///
/// The catalogue is authored with Arabic-Indic digits in `ar` and Western
/// digits in `en`, but most call sites format a number before handing it to
/// the catalogue. These helpers keep that decision in one place: Arabic gets
/// Arabic-Indic digits, every other locale gets Western digits.
///
/// [digits] converts in both directions, so a value composed before the
/// locale was known (a cubit-built header, a persisted label) still renders
/// correctly when the screen finally paints it.
extension AppLocalizationsDigits on AppLocalizations {
  /// Whether this locale renders numbers with Arabic-Indic digits.
  bool get usesArabicIndicDigits => localeName == 'ar';

  /// [value] with the digits this locale expects.
  String digits(String value) =>
      usesArabicIndicDigits ? value.toArabicIndicDigits : value.toWesternDigits;

  /// [value] with the digits this locale expects.
  String number(num value) => digits(value.toString());
}
