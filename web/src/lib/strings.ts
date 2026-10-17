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
  },
} as const;

export type StringKey = keyof (typeof dict)['ar'];
export const stringKeys = Object.keys(dict.ar) as StringKey[];

export function t(locale: Locale, key: StringKey): string {
  return dict[locale][key];
}
