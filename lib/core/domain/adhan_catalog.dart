import 'prayer_name.dart';

/// One bundled adhan recording.
///
/// The catalog is DATA, not code: the shipping set is one attribution-licensed
/// recording (CC BY 3.0), so swapping or removing it stays a data change —
/// delete the asset files and edit one entry here, with no change elsewhere.
/// The 1.25x speed is baked into the file itself so the Android notification
/// sound and the full playback match; see `assets/licenses/adhan-attribution.txt`.
///
/// Reciter names live in the data rather than in ARB, following the same
/// precedent as the city catalog (`selected_city` stores `nameAr`/`nameEn`):
/// a proper noun is content, not interface copy.
class AdhanTrack {
  /// Creates one catalog entry.
  const AdhanTrack({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.durationSeconds,
  });

  /// Stable identifier: lowercase, raw-resource safe, and the asset basename.
  ///
  /// It is also the persisted preference value, so it must never be renamed
  /// without a migration — a stored id that no longer exists resolves to the
  /// default, which would silently change the user's choice.
  final String id;

  /// The reciter's name in Arabic (picker title).
  final String nameAr;

  /// The reciter's name in Latin script (picker subtitle).
  final String nameEn;

  /// Full running time, used by the picker to set expectations.
  final int durationSeconds;

  /// The full adhan, played on demand.
  String get assetPath => 'assets/audio/adhan/$id.m4a';

  /// The short notification clip (first 25 s with a fade-out).
  String get clipPath => 'assets/audio/adhan/clips/${id}_clip.m4a';

  /// The Android raw-resource name of [clipPath], for the notification sound.
  ///
  /// `RawResourceAndroidNotificationSound` reads a `res/raw` entry, not a
  /// Flutter asset, so `tools/build_adhan_audio.ps1` copies every clip there
  /// under exactly this name.
  String get clipResource => '${id}_clip';
}

/// The reciter a fresh install starts with.
const String kDefaultAdhanId = 'madinah_ejaz215_x125';

/// Every bundled adhan, in picker order (the default first).
const List<AdhanTrack> kAdhanCatalog = <AdhanTrack>[
  AdhanTrack(
    id: kDefaultAdhanId,
    nameAr: 'أذان المسجد النبوي — المدينة',
    nameEn: 'Madinah (Masjid an-Nabawi) — 1.25x',
    durationSeconds: 149,
  ),
];

/// Resolves [id] to a catalog entry, never null.
///
/// This is the forward-compatibility seam: a backup written by a newer build,
/// a hand-edited file, or a reciter removed for rights reasons all resolve to
/// the default track instead of blanking the picker or crashing a notification.
AdhanTrack adhanById(String? id) {
  if (id == null || id.isEmpty) return kAdhanCatalog.first;
  for (final track in kAdhanCatalog) {
    if (track.id == id) return track;
  }
  return kAdhanCatalog.first;
}

/// Whether [id] names a track that this build actually ships.
bool _isKnownAdhanId(String id) => kAdhanCatalog.any((track) => track.id == id);

/// The adhan to use for [prayer]: the Fajr override when set and valid,
/// otherwise the global choice.
///
/// Resolution happens per prayer rather than per notification because the
/// planner emits a single "next prayer" reminder (`reminder_planner.dart`), so
/// the prayer is only known while the plan is being built.
String adhanIdForPrayer({
  required PrayerName prayer,
  required String globalId,
  String? fajrId,
}) {
  final global = adhanById(globalId).id;
  if (prayer != PrayerName.fajr) return global;
  if (fajrId == null || fajrId.isEmpty) return global;
  return _isKnownAdhanId(fajrId) ? fajrId : global;
}

/// The Android notification channel for [track].
///
/// One channel per track is deliberate: Android freezes a channel's sound at
/// creation, so a shared channel would leave every existing user stuck on the
/// first adhan they ever heard. Selecting an adhan selects a channel; no
/// channel is ever mutated. At most `kAdhanCatalog.length` channels can exist.
String adhanChannelId(AdhanTrack track) => 'quran_yahdi_adhan_${track.id}';
