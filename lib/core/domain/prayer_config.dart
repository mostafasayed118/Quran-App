/// Persisted prayer calculation preferences.
///
/// Lives in `core/domain` so the prayer data layer, the reminder planner and
/// the presentation layer can share it without importing each other.
library;

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

/// The user's prayer calculation preferences.
///
/// The defaults reproduce the shipped behaviour exactly: Egyptian method,
/// Shafi Asr.
class PrayerConfig {
  /// Creates a configuration; every field is optional so the default is the
  /// historical behaviour.
  const PrayerConfig({
    this.method = PrayerCalculationMethod.egyptian,
    this.madhab = PrayerMadhab.shafi,
  });

  /// The historical default (Egyptian, Shafi).
  static const egyptian = PrayerConfig();

  /// Persisted key for [method].
  static const methodKey = 'prayer_calc_method';

  /// Persisted key for [madhab].
  static const madhabKey = 'prayer_madhab';

  /// The selected calculation method.
  final PrayerCalculationMethod method;

  /// The selected Asr madhab.
  final PrayerMadhab madhab;

  /// A copy with the given fields replaced.
  PrayerConfig copyWith({
    PrayerCalculationMethod? method,
    PrayerMadhab? madhab,
  }) {
    return PrayerConfig(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
    );
  }

  /// The persisted map, using only string values.
  Map<String, String> toJson() => {
        methodKey: method.name,
        madhabKey: madhab.name,
      };

  /// Decodes a persisted map; unknown or missing values fall back to the
  /// historical defaults instead of throwing.
  factory PrayerConfig.fromJson(Map<String, String?> json) {
    return PrayerConfig(
      method: methodFromName(json[methodKey]),
      madhab: madhabFromName(json[madhabKey]),
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

  @override
  bool operator ==(Object other) =>
      other is PrayerConfig && other.method == method && other.madhab == madhab;

  @override
  int get hashCode => Object.hash(method, madhab);
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
