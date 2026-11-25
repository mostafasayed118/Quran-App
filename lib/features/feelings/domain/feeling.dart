/// The eight feelings in display order, with their stable keys.
enum FeelingKey {
  qalaq('qalaq', 'قلق'),
  huzn('huzn', 'حزن'),
  wahda('wahda', 'وحدة'),
  hayra('hayra', 'حيرة'),
  khawf('khawf', 'خوف'),
  ghadab('ghadab', 'غضب'),
  imtinam('imtinam', 'امتنان'),
  amal('amal', 'أمل');

  const FeelingKey(this.value, this.nameAr);

  final String value;
  final String nameAr;

  static FeelingKey? fromValue(String? value) {
    for (final key in FeelingKey.values) {
      if (key.value == value) return key;
    }
    return null;
  }
}

/// One authoritative verse reference plus its source-derived excerpt.
///
/// [excerpt] is a contiguous substring of the full ayah in the app's Uthmani
/// asset; tests assert that property for every entry.
class FeelingVerse {
  const FeelingVerse({
    required this.surah,
    required this.ayah,
    required this.excerpt,
    this.hasTadabbur = false,
  });

  final int surah;
  final int ayah;
  final String excerpt;

  /// Whether Q45 shows the tadabbur section for this verse. A property of the
  /// canonical catalog entry, never a second literal in a widget.
  final bool hasTadabbur;

  String get reference => '$surah:$ayah';
}

/// A feeling and its two verses, in table order.
class Feeling {
  const Feeling({
    required this.key,
    required this.iconName,
    required this.verses,
  });

  final FeelingKey key;
  final String iconName;
  final List<FeelingVerse> verses;

  String get nameAr => key.nameAr;
}

/// Fixed content catalog. References are authoritative; excerpts were selected
/// from `assets/quran/uthmani/<surah>.json` and verified verbatim.
class FeelingsCatalog {
  static const Feeling qalaq = Feeling(
    key: FeelingKey.qalaq,
    iconName: 'air',
    verses: [
      FeelingVerse(
        surah: 13,
        ayah: 28,
        excerpt: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
        hasTadabbur: true,
      ),
      FeelingVerse(
        surah: 65,
        ayah: 2,
        excerpt: 'وَمَن يَتَّقِ ٱللَّهَ يَجْعَل لَّهُۥ مَخْرَجًۭا',
      ),
    ],
  );

  static const Feeling huzn = Feeling(
    key: FeelingKey.huzn,
    iconName: 'water_drop',
    verses: [
      FeelingVerse(
        surah: 3,
        ayah: 139,
        excerpt: 'وَلَا تَهِنُوا۟ وَلَا تَحْزَنُوا۟ وَأَنتُمُ ٱلْأَعْلَوْنَ',
      ),
      FeelingVerse(
        surah: 94,
        ayah: 6,
        excerpt: 'إِنَّ مَعَ ٱلْعُسْرِ يُسْرًۭا',
      ),
    ],
  );

  static const Feeling wahda = Feeling(
    key: FeelingKey.wahda,
    iconName: 'person_pin_circle',
    verses: [
      FeelingVerse(
        surah: 57,
        ayah: 4,
        excerpt: 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ',
      ),
      FeelingVerse(
        surah: 50,
        ayah: 16,
        excerpt: 'وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ ٱلْوَرِيدِ',
      ),
    ],
  );

  static const Feeling hayra = Feeling(
    key: FeelingKey.hayra,
    iconName: 'explore',
    verses: [
      FeelingVerse(
        surah: 2,
        ayah: 216,
        excerpt: 'وَٱللَّهُ يَعْلَمُ وَأَنتُمْ لَا تَعْلَمُونَ',
      ),
      FeelingVerse(
        surah: 1,
        ayah: 6,
        excerpt: 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
      ),
    ],
  );

  static const Feeling khawf = Feeling(
    key: FeelingKey.khawf,
    iconName: 'shield',
    verses: [
      FeelingVerse(
        surah: 10,
        ayah: 62,
        excerpt: 'أَلَآ إِنَّ أَوْلِيَآءَ ٱللَّهِ لَا خَوْفٌ عَلَيْهِمْ',
      ),
      FeelingVerse(
        surah: 9,
        ayah: 40,
        excerpt: 'لَا تَحْزَنْ إِنَّ ٱللَّهَ مَعَنَا',
      ),
    ],
  );

  static const Feeling ghadab = Feeling(
    key: FeelingKey.ghadab,
    iconName: 'whatshot',
    verses: [
      FeelingVerse(
        surah: 3,
        ayah: 134,
        excerpt: 'وَٱلْكَٰظِمِينَ ٱلْغَيْظَ وَٱلْعَافِينَ عَنِ ٱلنَّاسِ',
      ),
      FeelingVerse(
        surah: 42,
        ayah: 37,
        excerpt: 'وَإِذَا مَا غَضِبُوا۟ هُمْ يَغْفِرُونَ',
      ),
    ],
  );

  static const Feeling imtinam = Feeling(
    key: FeelingKey.imtinam,
    iconName: 'sunny',
    verses: [
      FeelingVerse(
        surah: 14,
        ayah: 7,
        excerpt: 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
      ),
      FeelingVerse(
        surah: 16,
        ayah: 18,
        excerpt: 'إِنَّ ٱللَّهَ لَغَفُورٌۭ رَّحِيمٌۭ',
      ),
    ],
  );

  static const Feeling amal = Feeling(
    key: FeelingKey.amal,
    iconName: 'auto_awesome',
    verses: [
      FeelingVerse(
        surah: 39,
        ayah: 53,
        excerpt: 'لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ',
      ),
      FeelingVerse(
        surah: 12,
        ayah: 87,
        excerpt: 'وَلَا تَا۟يْـَٔسُوا۟ مِن رَّوْحِ ٱللَّهِ',
      ),
    ],
  );

  static const List<Feeling> ordered = [
    qalaq,
    huzn,
    wahda,
    hayra,
    khawf,
    ghadab,
    imtinam,
    amal,
  ];

  /// The Q43 hero verse — Ar-Ra'd 28, the first verse of the qalaq entry.
  /// Every hero label, excerpt and navigation target derives from this one
  /// catalog entry; there is no second copy of the identity or the excerpt.
  static FeelingVerse get heroVerse => qalaq.verses.first;

  static String get heroReference => heroVerse.reference;

  static String get heroExcerpt => heroVerse.excerpt;

  static Feeling? byKey(FeelingKey key) {
    for (final feeling in ordered) {
      if (feeling.key == key) return feeling;
    }
    return null;
  }
}
