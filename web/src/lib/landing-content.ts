import type { Locale } from './strings';

const EN_PREFIX = '/en';

function homeFor(to: Locale): string {
  return to === 'en' ? '/en/' : '/';
}

export function altLocalePath(pathname: string, to: Locale): string {
  if (!pathname.startsWith('/')) return homeFor(to);
  const isEn = pathname === EN_PREFIX || pathname.startsWith(`${EN_PREFIX}/`);
  if (to === 'en') return isEn ? pathname : `${EN_PREFIX}${pathname}`;
  if (!isEn) return pathname;
  const stripped = pathname.slice(EN_PREFIX.length);
  return stripped === '' || stripped === '/' ? '/' : stripped;
}
