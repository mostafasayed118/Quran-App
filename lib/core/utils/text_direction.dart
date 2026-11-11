/// Whether [text] contains Arabic script.
///
/// Used to pick the paragraph direction for user-facing text whose language
/// is not known at the type level: the shipped translation is English and
/// must be laid out LTR inside an otherwise RTL Arabic app.
final RegExp _arabicScript = RegExp(r'[\u0600-\u06FF]');

bool isArabicText(String text) => _arabicScript.hasMatch(text);
