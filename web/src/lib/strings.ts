export type Locale = 'ar' | 'en';
export const defaultLocale: Locale = 'ar';

const dict = {
  ar: {
    appName: 'قرآن يَهدي',
    navQuran: 'المصحف',
    navReciters: 'التلاوات',
    navAbout: 'عن التطبيق',
    themeToNight: 'الوضع الليلي',
    themeToDay: 'الوضع النهاري',
    surahIndexTitle: 'المصحف',
    indexSearchPlaceholder: 'ابحث بالاسم أو الرقم…',
    noResults: 'لا نتائج',
    readerPrev: 'السورة السابقة',
    readerNext: 'السورة التالية',
    chipMeccan: 'مكية',
    chipMedinan: 'مدنية',
    footerPrivacy: 'سياسة الخصوصية',
    footerAbout: 'عن التطبيق',
    backToIndex: 'كل السور',
    playerPlay: 'تشغيل',
    playerPause: 'إيقاف مؤقت',
    playerPrev: 'السابق',
    playerNext: 'التالي',
    playerSeek: 'شريط التقدم',
    playerClose: 'إغلاق المشغل',
    playerError: 'تعذّر التشغيل',
    readerViewMushaf: 'مصحفي',
    readerViewImlaei: 'إملائي',
    readerFontSmaller: 'تصغير الخط',
    readerFontBigger: 'تكبير الخط',
  },
  en: {
    appName: 'Quran Yahdi',
    navQuran: 'Quran',
    navReciters: 'Recitations',
    navAbout: 'About',
    themeToNight: 'Night mode',
    themeToDay: 'Day mode',
    surahIndexTitle: 'The Quran',
    indexSearchPlaceholder: 'Search by name or number…',
    noResults: 'No results',
    readerPrev: 'Previous surah',
    readerNext: 'Next surah',
    chipMeccan: 'Meccan',
    chipMedinan: 'Medinan',
    footerPrivacy: 'Privacy',
    footerAbout: 'About',
    backToIndex: 'All surahs',
    playerPlay: 'Play',
    playerPause: 'Pause',
    playerPrev: 'Previous',
    playerNext: 'Next',
    playerSeek: 'Seek',
    playerClose: 'Close player',
    playerError: 'Playback error',
    readerViewMushaf: 'Mushaf',
    readerViewImlaei: 'Imlaei',
    readerFontSmaller: 'Smaller text',
    readerFontBigger: 'Larger text',
  },
} as const;

export type StringKey = keyof (typeof dict)['ar'];
export const stringKeys = Object.keys(dict.ar) as StringKey[];

export function t(locale: Locale, key: StringKey): string {
  return dict[locale][key];
}
