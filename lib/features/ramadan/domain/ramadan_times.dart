/// The two Ramadan anchors for one day.
class RamadanTimes {
  /// Creates the pair.
  const RamadanTimes({required this.imsak, required this.iftar});

  /// When the fast starts: Fajr minus the imsak lead.
  final DateTime imsak;

  /// When the fast ends: Maghrib.
  final DateTime iftar;
}

/// The conventional imsak lead used by the app.
const int kImsakLeadMinutes = 10;

/// The widest lead the calculator accepts.
const int kMaxImsakLeadMinutes = 30;

/// Derives the imsak/iftar pair from the day's Fajr and Maghrib.
///
/// The lead is clamped to 0..30; a negative or oversized value can never
/// move the fast into the previous prayer or past Maghrib.
RamadanTimes ramadanTimesFor({
  required DateTime fajr,
  required DateTime maghrib,
  int imsakLeadMinutes = kImsakLeadMinutes,
}) {
  final lead = imsakLeadMinutes < 0
      ? 0
      : (imsakLeadMinutes > kMaxImsakLeadMinutes
          ? kMaxImsakLeadMinutes
          : imsakLeadMinutes);
  return RamadanTimes(
    imsak: fajr.subtract(Duration(minutes: lead)),
    iftar: maghrib,
  );
}
