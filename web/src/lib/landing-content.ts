import type { Locale } from './strings';

const EN_PREFIX = '/en';

function homeFor(to: Locale): string {
  return to === 'en' ? '/en/' : '/';
}

export function altLocalePath(pathname: string, to: Locale): string {
  if (!pathname.startsWith('/')) return homeFor(to);
  const isEn = pathname === EN_PREFIX || pathname.startsWith(`${EN_PREFIX}/`);
  if (to === 'en') return isEn ? pathname : withTrailingSlash(`${EN_PREFIX}${pathname}`);
  if (!isEn) return pathname;
  const stripped = pathname.slice(EN_PREFIX.length);
  return stripped === '' || stripped === '/' ? '/' : withTrailingSlash(stripped);
}

// Canonical links point at the trailing-slash form (live pages 308 to it), so locale
// switches must emit that form too — a direct hit otherwise costs a redirect hop.
function withTrailingSlash(path: string): string {
  return path.endsWith('/') ? path : `${path}/`;
}

export interface LandingCopy {
  hero: {
    ayah: string;
    ayahRef: string;
    kicker: string;
    lead: string;
    ctaPrimary: string;
    ctaSecondary: string;
  };
  features: { title: string; desc: string }[];
  promise: string[];
  about: { story: string[]; bullets: string[] };
  cta: { title: string; lead: string; githubLabel: string; playLabel: string; version: string };
}

// Store URL swap place: wire playLabel to the Google Play listing URL once published ([OWNER] publish step).
export const GITHUB_RELEASES_URL = 'https://github.com/mostafasayed118/Quran-App/releases/latest';

export const LANDING: { ar: LandingCopy; en: LandingCopy } = {
  ar: {
    hero: {
      ayah: '﴿إِنَّ هَذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ﴾',
      ayahRef: 'الإسراء ٩',
      kicker: 'رفيق إسلامي متكامل يعمل بلا إنترنت أولًا',
      lead: 'مصحف كامل (114 سورة، 6236 آية) مضمّن داخل التطبيق، مع تلاوات صوتية تُبث أو تُنزَّل، أذكار وأدعية، مواقيت الصلاة والقبلة — بلا حسابات ولا إعلانات ولا تتبع.',
      ctaPrimary: 'افتح المصحف',
      ctaSecondary: 'تعرّف على التطبيق',
    },
    features: [
      { title: 'الرئيسية', desc: 'بطاقة الصلاة القادمة + متابعة القراءة + شبكة الميزات' },
      { title: 'فهرس السور', desc: '114 سورة مع بحث فوري بالاسم أو الرقم' },
      { title: 'قارئ القرآن', desc: 'قراءة آية-بآية أو وضع المصحف الصفحي التقليدي' },
      { title: 'شاشة الآية', desc: 'التفسير والترجمات وعلامة الحفظ من مكان واحد' },
      { title: 'متابعة القراءة', desc: 'حفظ آخر موضع وعلامات مرجعية متعددة' },
      { title: 'التلاوات', desc: 'أكثر من 240 قارئًا (خدمة mp3quran) — بث فوري أو تحميل كامل للأوفلاين' },
      { title: 'المشغّل والتنزيلات', desc: 'مشغّل مصغّر يلازمك + مدير تنزيلات بحالة كل ملف' },
      { title: 'مواقيت الصلاة', desc: 'أوقات دقيقة لاختيار مدينتك (أو أقرب مدينة تحديدًا على جهازك) + تنبيه صلاة اختياري' },
      { title: 'القبلة', desc: 'بوصلة بتوجيه حي من حساسات الهاتف' },
      { title: 'الأذكار', desc: 'أذكار مصنّفة مع عدّاد لكل ذكر' },
      { title: 'السبحة', desc: 'عدّاد إلكتروني دائري بأهداف قابلة للتبديل' },
      { title: 'الأدعية والرقية', desc: 'مختارات مرتبة من المصنفات التقليدية مع آيات النصوص' },
      { title: 'متتبع العبادات', desc: 'الصلوات الخمس اليومية وخطط الختمة' },
      { title: 'الإعدادات والإضافات', desc: 'وضع ليلي، أحجام خط وخط المصحف الأصلي، حساب الزكاة، التقويم الهجري، أسماء الله الحسنى' },
    ],
    promise: [
      'بلا إنترنت أولًا: المصحف كامل — 114 سورة و6236 آية — مضمّن داخل التطبيق.',
      'بلا حسابات، بلا إعلانات، بلا تتبع — ولا نجمع أي بيانات.',
      'مجاني بالكامل، عربي أولًا، مع وضع ليلي مريح وخط مصحف أصيل.',
    ],
    about: {
      story: [
        'قرآن يَهدي رفيق إسلامي متكامل يعمل بلا إنترنت أولًا: مصحف كامل (114 سورة، 6236 آية) مضمّن داخل التطبيق، تلاوات صوتية تُبث أو تُنزَّل، أذكار وأدعية، مواقيت الصلاة والقبلة — بلا حسابات ولا إعلانات ولا تتبع.',
        'بدأ المشروع كتطبيق أندرويد مكتمل الميزات (v1.0.0 قيد التحضير للمتجر)، وهذا الموقع هو واجهته الرسمية على الويب: تعريف بالتطبيق، وروابط التحميل، وسياسة خصوصية شفافة.',
      ],
      bullets: [
        '114 سورة و6236 آية مضمّنة — يعمل بلا إنترنت إطلاقًا',
        'أكثر من 240 قارئًا للتلاوة — بث فوري أو تحميل كامل',
        'مواقيت صلاة دقيقة وقبلة حية — الحساب يتم على جهازك',
        'بلا حسابات، بلا إعلانات، بلا تتبع، ولا جمع لأي بيانات',
      ],
    },
    cta: {
      title: 'حمّل قرآن يَهدي',
      lead: 'الإصدار 1.0.0 لأندرويد — نسخة كاملة تعمل بلا إنترنت.',
      githubLabel: 'حمّل من GitHub',
      playLabel: 'قريبًا على Google Play',
      version: '1.0.0',
    },
  },
  en: {
    hero: {
      ayah: '﴿إِنَّ هَذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ﴾',
      ayahRef: 'Al-Isra 9',
      kicker: 'Your complete offline-first Islamic companion',
      lead: 'The full Mushaf — 114 surahs, 6,236 ayahs — bundled inside the app, with audio recitations you can stream or download, adhkar, duas, prayer times and a Qibla compass; no accounts, no ads, and no tracking.',
      ctaPrimary: 'Open the Quran',
      ctaSecondary: 'About the app',
    },
    features: [
      { title: 'Home', desc: 'Next-prayer card, continue reading and the feature grid at a glance' },
      { title: 'Surah index', desc: '114 surahs with instant search by name or number' },
      { title: 'Quran reader', desc: 'Verse-by-verse reading or the traditional paginated Mushaf mode' },
      { title: 'Ayah sheet', desc: 'Tafsir, translations and a bookmark in one place' },
      { title: 'Continue reading', desc: 'Saves your last position and multiple bookmarks' },
      { title: 'Recitations', desc: '240+ reciters (mp3quran) — stream instantly or download for offline' },
      { title: 'Player & downloads', desc: 'A persistent mini player plus a download manager with per-file status' },
      { title: 'Prayer times', desc: 'Accurate times for your chosen city (or the nearest city, computed on-device) plus an optional prayer reminder' },
      { title: 'Qibla', desc: "A live compass driven by your phone's sensors" },
      { title: 'Adhkar', desc: 'Categorized adhkar with a counter for each' },
      { title: 'Tasbih', desc: 'A circular digital counter with switchable targets' },
      { title: 'Duas & ruqyah', desc: 'Organized selections from traditional collections with the source texts' },
      { title: 'Worship tracker', desc: 'The five daily prayers and khatma plans' },
      { title: 'Settings & extras', desc: 'Dark mode, font sizes and the authentic mushaf font, zakat calculator, Hijri calendar, the 99 names of Allah' },
    ],
    promise: [
      'Offline-first: the complete Mushaf — 114 surahs, 6,236 ayahs — bundled inside the app.',
      'No accounts, no ads, no tracking — and no data collection.',
      'Completely free, Arabic-first, with a comfortable dark mode and authentic mushaf typography.',
    ],
    about: {
      story: [
        'Quran Yahdi is a complete, offline-first Islamic companion: the full Mushaf (114 surahs, 6,236 ayahs) bundled inside the app, with audio recitations you can stream or download, adhkar, duas, prayer times and a Qibla compass — no accounts, no ads, no tracking.',
        'The project began as a feature-complete Android app (v1.0.0, being prepared for the store), and this site is its official home on the web: an introduction to the app, download links, and a transparent privacy policy.',
      ],
      bullets: [
        '114 surahs and 6,236 ayahs bundled — works fully offline',
        '240+ reciters to stream instantly or download for offline listening',
        'Accurate prayer times and a live Qibla compass — all computed on your device',
        'No accounts, no ads, no tracking, and no data collection',
      ],
    },
    cta: {
      title: 'Get Quran Yahdi',
      lead: 'Version 1.0.0 for Android — the complete offline app.',
      githubLabel: 'Download from GitHub',
      playLabel: 'Coming soon to Google Play',
      version: '1.0.0',
    },
  },
};
