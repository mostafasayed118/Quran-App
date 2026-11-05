/// The three daily windows in which a voluntary prayer is disliked.
enum ForbiddenWindowKind {
  /// After the Fajr prayer until sunrise.
  afterFajr,

  /// Around the sun's zenith, until Dhuhr.
  zenith,

  /// After the Asr prayer until Maghrib.
  afterAsr,
}

/// One forbidden window with its local start and end.
class ForbiddenWindow {
  /// Creates a window.
  const ForbiddenWindow({
    required this.kind,
    required this.start,
    required this.end,
  });

  /// Which of the three windows this is.
  final ForbiddenWindowKind kind;

  /// The first moment of the window (inclusive).
  final DateTime start;

  /// The first moment after the window (exclusive).
  final DateTime end;
}

/// The conventional lead for the zenith window.
const int kZenithLeadMinutes = 10;

/// Derives the three windows from the day's prayer times.
///
/// A window whose end is not after its start (a malformed or polar day) is
/// dropped instead of rendering a negative range.
List<ForbiddenWindow> forbiddenWindowsFor({
  required DateTime fajr,
  required DateTime sunrise,
  required DateTime dhuhr,
  required DateTime asr,
  required DateTime maghrib,
}) {
  final windows = [
    ForbiddenWindow(
      kind: ForbiddenWindowKind.afterFajr,
      start: fajr,
      end: sunrise,
    ),
    ForbiddenWindow(
      kind: ForbiddenWindowKind.zenith,
      start: dhuhr.subtract(const Duration(minutes: kZenithLeadMinutes)),
      end: dhuhr,
    ),
    ForbiddenWindow(
      kind: ForbiddenWindowKind.afterAsr,
      start: asr,
      end: maghrib,
    ),
  ];
  return [
    for (final window in windows)
      if (window.start.isBefore(window.end)) window,
  ];
}
