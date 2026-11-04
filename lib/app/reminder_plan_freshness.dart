/// Whether the applied reminder plan still matches the device.
///
/// The plan is pinned to absolute instants, so it goes stale the moment the
/// local day rolls over (yesterday's alarms are all in the past) or the device
/// changes time zone (every fire instant now lands at the wrong wall clock).
/// Both are checked on resume — the first moment the app learns about a phone
/// that slept through midnight or travelled.
///
/// Pure on purpose: the resume hook is otherwise untestable widget state.
class ReminderPlanFreshness {
  /// Starts fresh at [now] (defaults to the current instant).
  ReminderPlanFreshness({DateTime? now, int? utcOffsetMinutes}) {
    mark(now ?? DateTime.now(), utcOffsetMinutes: utcOffsetMinutes);
  }

  int _day = 0;
  int _offsetMinutes = 0;

  /// Records [now] as the instant the current plan was composed for.
  ///
  /// [utcOffsetMinutes] defaults to [now]'s own zone; it exists so a test can
  /// model a traveller without a time-zone database.
  void mark(DateTime now, {int? utcOffsetMinutes}) {
    _day = _dayNumber(now);
    _offsetMinutes = utcOffsetMinutes ?? now.timeZoneOffset.inMinutes;
  }

  /// Whether a plan composed at the last [mark] must be recomposed at [now].
  bool needsReplan(DateTime now, {int? utcOffsetMinutes}) =>
      _day != _dayNumber(now) ||
      _offsetMinutes != (utcOffsetMinutes ?? now.timeZoneOffset.inMinutes);

  /// The local calendar day as a UTC-midnight epoch: DST-proof, and independent
  /// of the zone offset the plan was built in.
  static int _dayNumber(DateTime now) =>
      DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch;
}
