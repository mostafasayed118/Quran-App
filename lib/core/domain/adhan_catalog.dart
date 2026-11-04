import 'prayer_name.dart';

/// One bundled adhan recording.
///
/// The catalog is DATA, not code: the shipping set is still subject to rights
/// clearance (REL-03), so a reciter must be droppable by deleting two asset
/// files and one entry here, with no change anywhere else.
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
const String kDefaultAdhanId = 'abdulbasit_abdulsamad';

/// Every bundled adhan, in picker order (the default first).
const List<AdhanTrack> kAdhanCatalog = <AdhanTrack>[
  AdhanTrack(
    id: kDefaultAdhanId,
    nameAr: 'عبد الباسط عبد الصمد',
    nameEn: 'Abdul Basit Abdulsamad',
    durationSeconds: 224,
  ),
  AdhanTrack(
    id: 'ali_ahmed_mulla',
    nameAr: 'علي أحمد ملا (الحرم المكي)',
    nameEn: 'Ali Ahmed Mulla (Makkah)',
    durationSeconds: 205,
  ),
  AdhanTrack(
    id: 'omar_hisham',
    nameAr: 'عمر هشام العربي',
    nameEn: 'Omar Hisham Al Arabi',
    durationSeconds: 180,
  ),
  AdhanTrack(
    id: 'mohamed_qassas',
    nameAr: 'محمد مروان قصاص',
    nameEn: 'Mohamed Marwan Qassas',
    durationSeconds: 227,
  ),
  AdhanTrack(
    id: 'khushu',
    nameAr: 'أذان تخشع له القلوب',
    nameEn: 'A Heart-Softening Adhan',
    durationSeconds: 211,
  ),
  AdhanTrack(
    id: 'mohamed_tarek',
    nameAr: 'محمد طارق',
    nameEn: 'Mohamed Tarek',
    durationSeconds: 172,
  ),
  AdhanTrack(
    id: 'islam_sobhy',
    nameAr: 'إسلام صبحي',
    nameEn: 'Islam Sobhy',
    durationSeconds: 172,
  ),
  AdhanTrack(
    id: 'nasser_alqatami_1',
    nameAr: 'ناصر القطامي (١)',
    nameEn: 'Nasser Al-Qatami (1)',
    durationSeconds: 128,
  ),
  AdhanTrack(
    id: 'nasser_alqatami_2',
    nameAr: 'ناصر القطامي (٢)',
    nameEn: 'Nasser Al-Qatami (2)',
    durationSeconds: 135,
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
