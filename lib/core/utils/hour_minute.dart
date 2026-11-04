/// Parses the stored 'H:mm'/'HH:mm' 24-hour setting into `(hour, minute)`.
///
/// Whitespace is trimmed; the hour is 1-2 digits and the minutes are exactly
/// two digits. Null on missing, empty, malformed, out-of-range or
/// extra-segment input — callers supply their own fallback.
(int, int)? parseHourMinute(String? hm) {
  if (hm == null) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hm.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return (hour, minute);
}
