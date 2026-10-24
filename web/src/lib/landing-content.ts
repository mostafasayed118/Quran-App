import { t, type Locale } from './strings';

const EN_PREFIX = '/en';

/** The app version the landing page shows; not copy, so it has no translation. */
export const APP_VERSION = '1.0.0';

/** The public contact address shown in the footer. */
export const CONTACT_EMAIL = 'mustafasayed20002@gmail.com';

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

/** Replaces the `{name}` placeholders of a string-table entry. */
function fill(text: string, vars: Record<string, string>): string {
  let out = text;
  for (const [key, value] of Object.entries(vars)) out = out.replace(`{${key}}`, value);
  return out;
}

/**
 * The landing copy of one locale, built from the site's single string table.
 *
 * Every user-visible string lives in `src/lib/strings.ts`; this module only
 * shapes it. Feature titles that repeat a chrome string (the reading card, the
 * recitations card, the Qibla card) reuse that string's key, so the wording
 * exists exactly once.
 */
function landingCopy(locale: Locale): LandingCopy {
  const app = t(locale, 'appName');
  return {
    hero: {
      ayah: t(locale, 'landingHeroAyah'),
      ayahRef: t(locale, 'landingHeroAyahRef'),
      kicker: t(locale, 'landingHeroKicker'),
      lead: t(locale, 'landingHeroLead'),
      ctaPrimary: t(locale, 'landingHeroCtaPrimary'),
      ctaSecondary: t(locale, 'landingHeroCtaSecondary'),
    },
    features: [
      { title: t(locale, 'landingFeatureHome'), desc: t(locale, 'landingFeatureHomeDesc') },
      { title: t(locale, 'landingFeatureIndex'), desc: t(locale, 'landingFeatureIndexDesc') },
      { title: t(locale, 'landingFeatureReader'), desc: t(locale, 'landingFeatureReaderDesc') },
      {
        title: t(locale, 'landingFeatureAyahSheet'),
        desc: t(locale, 'landingFeatureAyahSheetDesc'),
      },
      { title: t(locale, 'resumeTitle'), desc: t(locale, 'landingFeatureContinueDesc') },
      { title: t(locale, 'navReciters'), desc: t(locale, 'landingFeatureRecitationsDesc') },
      { title: t(locale, 'landingFeaturePlayer'), desc: t(locale, 'landingFeaturePlayerDesc') },
      {
        title: t(locale, 'landingFeaturePrayerTimes'),
        desc: t(locale, 'landingFeaturePrayerTimesDesc'),
      },
      { title: t(locale, 'qbTitle'), desc: t(locale, 'landingFeatureQiblaDesc') },
      { title: t(locale, 'landingFeatureAdhkar'), desc: t(locale, 'landingFeatureAdhkarDesc') },
      { title: t(locale, 'landingFeatureTasbih'), desc: t(locale, 'landingFeatureTasbihDesc') },
      { title: t(locale, 'landingFeatureDuas'), desc: t(locale, 'landingFeatureDuasDesc') },
      { title: t(locale, 'landingFeatureTracker'), desc: t(locale, 'landingFeatureTrackerDesc') },
      { title: t(locale, 'landingFeatureSettings'), desc: t(locale, 'landingFeatureSettingsDesc') },
    ],
    promise: [
      t(locale, 'landingPromise1'),
      t(locale, 'landingPromise2'),
      t(locale, 'landingPromise3'),
    ],
    about: {
      story: [fill(t(locale, 'landingStory1'), { app }), t(locale, 'landingStory2')],
      bullets: [
        t(locale, 'landingBullet1'),
        t(locale, 'landingBullet2'),
        t(locale, 'landingBullet3'),
        t(locale, 'landingBullet4'),
      ],
    },
    cta: {
      title: fill(t(locale, 'landingCtaTitle'), { app }),
      lead: fill(t(locale, 'landingCtaLead'), { v: APP_VERSION }),
      githubLabel: t(locale, 'landingCtaGithub'),
      playLabel: t(locale, 'landingCtaPlay'),
      version: APP_VERSION,
    },
  };
}

export const LANDING: { ar: LandingCopy; en: LandingCopy } = {
  ar: landingCopy('ar'),
  en: landingCopy('en'),
};

// Per-page meta descriptions (owner-approved 2026-10-19). EN pages must not inherit the AR default.
export const META_DESCRIPTIONS = {
  ar: {
    quran: t('ar', 'metaQuran'),
    reciters: t('ar', 'metaReciters'),
    privacy: fill(t('ar', 'metaPrivacy'), { app: t('ar', 'appName') }),
  },
  en: {
    quran: t('en', 'metaQuran'),
    reciters: t('en', 'metaReciters'),
    privacy: fill(t('en', 'metaPrivacy'), { app: t('en', 'appName') }),
  },
} as const;

export function enReaderDescription(n: number, nameEn: string): string {
  return `${fill(t('en', 'surahDescription'), { n: String(n), name: nameEn })} · ${t('en', 'appName')}`;
}

export function arReaderDescription(n: number, nameAr: string): string {
  return `${fill(t('ar', 'surahDescription'), { n: String(n), name: nameAr })} · ${t('ar', 'appName')}`;
}
