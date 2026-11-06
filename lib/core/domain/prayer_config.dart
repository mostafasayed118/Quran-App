/// Persisted prayer calculation preferences.
///
/// Lives in `core/domain` so the prayer data layer, the reminder planner and
/// the presentation layer can share it without importing each other.
library;

import 'prayer_name.dart';

/// The calculation methods the app exposes.
///
/// The names are the persisted identifiers; adding a value is additive, and an
/// unknown stored name falls back to [egyptian].
enum PrayerCalculationMethod {
  /// Egyptian General Authority of Survey.
  egyptian,

  /// Muslim World League.
  muslimWorldLeague,

  /// University of Islamic Sciences, Karachi.
  karachi,

  /// Umm al-Qura University, Makkah.
  ummAlQura,

  /// The Gulf Region (Dubai).
  dubai,

  /// Kuwait.
  kuwait,

  /// Qatar.
  qatar,

  /// Diyanet (Turkey).
  turkey,

  /// ISNA (North America).
  northAmerica,
}

/// The madhab used for the Asr shadow length.
enum PrayerMadhab {
  /// Shafi, Maliki and Hanbali.
  shafi,

  /// Hanafi.
  hanafi,
}

/// How the app resolves Fajr/Isha when the sun does not reach the twilight
/// angle at the user's latitude.
///
/// [none] keeps the method's own default, which is what every build before
/// this setting shipped. The other values map 1:1 to `adhan`'s
/// `HighLatitudeRule`.
enum PrayerHighLatitudeRule {
  /// Use the calculation method's default (no explicit override).
  none,

  /// Fajr is never earlier than the middle of the night.
  middleOfTheNight,

  /// Fajr is never earlier than the last seventh of the night.
  seventhOfTheNight,

  /// Uses the method's twilight angle as the night fraction.
  twilightAngle,
}

/// The user's prayer calculation preferences.
///
/// The defaults reproduce the shipped behaviour exactly: Egyptian method,
/// Shafi Asr, no per-prayer adjustment and the method's own high-latitude
/// rule.
class PrayerConfig {
  /// Creates a configuration; every field is optional so the default is the
  /// historical behaviour.
  const PrayerConfig({
    this.method = PrayerCalculationMethod.egyptian,
    this.madhab = PrayerMadhab.shafi,
    this.enabledPrayers = defaultEnabledPrayers,
    this.preAdhanMinutes = 0,
    this.fajrFollowUp = false,
    this.adjustments = const <PrayerName, int>{},
    this.highLatitude = PrayerHighLatitudeRule.none,
  });

  /// The historical default (Egyptian, Shafi, all five prayers, no pre-adhan).
  static const egyptian = PrayerConfig();

  /// Persisted key for [method].
  static const methodKey = 'prayer_calc_method';

  /// Persisted key for [madhab].
  static const madhabKey = 'prayer_madhab';

  /// Persisted key for [enabledPrayers].
  static const enabledPrayersKey = 'prayer_enabled_prayers';

  /// Persisted key for [preAdhanMinutes].
  static const preAdhanMinutesKey = 'prayer_pre_adhan_minutes';

  /// Persisted key for [fajrFollowUp].
  static const fajrFollowUpKey = 'prayer_fajr_follow_up';

  /// Persisted key for [adjustments].
  static const adjustmentsKey = 'prayer_adjustments';

  /// Persisted key for [highLatitude].
  static const highLatitudeKey = 'prayer_high_latitude';

  /// The widest manual correction a mosque-alignment convention needs.
  static const int minAdjustmentMinutes = -30;
  static const int maxAdjustmentMinutes = 30;

  /// The five prayers a reminder can target; sunrise is never included.
  static const defaultEnabledPrayers = <PrayerName>{
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  };

  /// The selected calculation method.
  final PrayerCalculationMethod method;

  /// The selected Asr madhab.
  final PrayerMadhab madhab;

  /// The prayers that may schedule the prayer reminder.
  ///
  /// Callers must treat this as immutable; the cubit replaces the set.
  final Set<PrayerName> enabledPrayers;

  /// Minutes before the chosen prayer for the optional early reminder.
  ///
  /// 0 disables the early reminder; stored values are clamped to 0..60.
  final int preAdhanMinutes;

  /// Whether the two extra Fajr follow-up nudges (+5 and +10 minutes) are
  /// scheduled. Off by default: the historical plan stays the shipped one.
  final bool fajrFollowUp;

  /// Per-prayer minute corrections applied after the calculation.
  ///
  /// Missing entries mean zero. Sunrise is never stored. Callers must treat
  /// this as immutable; the cubit replaces the map.
  final Map<PrayerName, int> adjustments;

  /// The high-latitude rule; [PrayerHighLatitudeRule.none] keeps the
  /// calculation method's default.
  final PrayerHighLatitudeRule highLatitude;

  /// The correction for [prayer], or zero when unset.
  int adjustmentFor(PrayerName prayer) => adjustments[prayer] ?? 0;

  /// A copy with the given fields replaced.
  PrayerConfig copyWith({
    PrayerCalculationMethod? method,
    PrayerMadhab? madhab,
    Set<PrayerName>? enabledPrayers,
    int? preAdhanMinutes,
    bool? fajrFollowUp,
    Map<PrayerName, int>? adjustments,
    PrayerHighLatitudeRule? highLatitude,
  }) {
    return PrayerConfig(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      preAdhanMinutes: preAdhanMinutes ?? this.preAdhanMinutes,
      fajrFollowUp: fajrFollowUp ?? this.fajrFollowUp,
      adjustments: adjustments ?? this.adjustments,
      highLatitude: highLatitude ?? this.highLatitude,
    );
  }

  /// The persisted map, using only string values.
  Map<String, String> toJson() => {
        methodKey: method.name,
        madhabKey: madhab.name,
        enabledPrayersKey:
            enabledPrayers.map((prayer) => prayer.name).join(','),
        preAdhanMinutesKey: '$preAdhanMinutes',
        fajrFollowUpKey: fajrFollowUp ? 'true' : 'false',
        adjustmentsKey: adjustments.entries
            .where(
                (entry) => entry.key != PrayerName.sunrise && entry.value != 0)
            .map((entry) => '${entry.key.name}:${entry.value}')
            .join(','),
        highLatitudeKey: highLatitude.name,
      };

  /// Decodes a persisted map; unknown or missing values fall back to the
  /// historical defaults instead of throwing.
  factory PrayerConfig.fromJson(Map<String, String?> json) {
    return PrayerConfig(
      method: methodFromName(json[methodKey]),
      madhab: madhabFromName(json[madhabKey]),
      enabledPrayers: json.containsKey(enabledPrayersKey)
          ? _prayersFromCsv(json[enabledPrayersKey])
          : defaultEnabledPrayers,
      preAdhanMinutes: _minutesFromString(json[preAdhanMinutesKey]),
      fajrFollowUp: json[fajrFollowUpKey] == 'true',
      adjustments: _adjustmentsFromCsv(json[adjustmentsKey]),
      highLatitude: highLatitudeFromName(json[highLatitudeKey]),
    );
  }

  /// Resolves a persisted method name; unknown names fall back to Egyptian.
  static PrayerCalculationMethod methodFromName(String? name) {
    for (final method in PrayerCalculationMethod.values) {
      if (method.name == name) return method;
    }
    return PrayerCalculationMethod.egyptian;
  }

  /// Resolves a persisted madhab name; unknown names fall back to Shafi.
  static PrayerMadhab madhabFromName(String? name) {
    for (final madhab in PrayerMadhab.values) {
      if (madhab.name == name) return madhab;
    }
    return PrayerMadhab.shafi;
  }

  /// Resolves a persisted high-latitude name; unknown names fall back to
  /// [PrayerHighLatitudeRule.none].
  static PrayerHighLatitudeRule highLatitudeFromName(String? name) {
    for (final rule in PrayerHighLatitudeRule.values) {
      if (rule.name == name) return rule;
    }
    return PrayerHighLatitudeRule.none;
  }

  static Set<PrayerName> _prayersFromCsv(String? csv) {
    if (csv == null || csv.trim().isEmpty) return <PrayerName>{};
    final names = csv.split(',').map((name) => name.trim());
    return <PrayerName>{
      for (final name in names)
        if (name != PrayerName.sunrise.name)
          for (final prayer in PrayerName.values)
            if (prayer.name == name && prayer != PrayerName.sunrise) prayer,
    };
  }

  static Map<PrayerName, int> _adjustmentsFromCsv(String? csv) {
    if (csv == null || csv.trim().isEmpty) return const <PrayerName, int>{};
    final result = <PrayerName, int>{};
    for (final pair in csv.split(',')) {
      final parts = pair.split(':');
      if (parts.length != 2) continue;
      final name = parts[0].trim();
      final parsed = int.tryParse(parts[1].trim());
      if (parsed == null) continue;
      final safe = _clampAdjustment(parsed);
      if (safe == 0) continue;
      for (final prayer in PrayerName.values) {
        if (prayer.name == name && prayer != PrayerName.sunrise) {
          result[prayer] = safe;
        }
      }
    }
    return result;
  }

  static int _minutesFromString(String? value) {
    final minutes = int.tryParse(value ?? '') ?? 0;
    if (minutes < 0) return 0;
    if (minutes > 60) return 60;
    return minutes;
  }

  static int clampAdjustment(int value) => _clampAdjustment(value);

  static int _clampAdjustment(int value) {
    if (value < minAdjustmentMinutes) return minAdjustmentMinutes;
    if (value > maxAdjustmentMinutes) return maxAdjustmentMinutes;
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerConfig &&
      other.method == method &&
      other.madhab == madhab &&
      other.preAdhanMinutes == preAdhanMinutes &&
      other.fajrFollowUp == fajrFollowUp &&
      other.highLatitude == highLatitude &&
      _samePrayers(other.enabledPrayers, enabledPrayers) &&
      _sameAdjustments(other.adjustments, adjustments);

  @override
  int get hashCode => Object.hash(
        method,
        madhab,
        preAdhanMinutes,
        fajrFollowUp,
        highLatitude,
        Object.hashAllUnordered(enabledPrayers),
        Object.hashAllUnordered(
          adjustments.entries
              .map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );

  static bool _samePrayers(Set<PrayerName> a, Set<PrayerName> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _sameAdjustments(
    Map<PrayerName, int> a,
    Map<PrayerName, int> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Cross-feature seam: read the current preferences synchronously (the
/// `PrayerTimesPort` methods are synchronous), load/save them, and observe
/// changes.
///
/// The synchronous [current] is a cache: until [load] completes it is the
/// historical Egyptian/Shafi default, so a degraded boot keeps the shipped
/// behaviour.
abstract interface class PrayerConfigSource {
  /// The last loaded or saved configuration; never null.
  PrayerConfig get current;

  /// Emits after a successful [load] that changed [current] and after every
  /// successful [save].
  Stream<PrayerConfig> get changes;

  /// Loads the persisted configuration; a missing or malformed row degrades to
  /// [PrayerConfig.egyptian].
  Future<PrayerConfig> load();

  /// Persists [config] and updates [current] only after the write succeeds.
  Future<void> save(PrayerConfig config);
}
