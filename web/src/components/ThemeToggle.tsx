import { useEffect, useState } from 'react';
import { otherTheme, readTheme, THEME_KEY, type Theme } from '../lib/theme';
import { t, type Locale } from '../lib/strings';

export default function ThemeToggle({ locale }: { locale: Locale }) {
  const [theme, setTheme] = useState<Theme>('day');
  useEffect(() => {
    setTheme(readTheme(localStorage, matchMedia('(prefers-color-scheme: dark)').matches));
  }, []);
  const label = theme === 'day' ? t(locale, 'themeToNight') : t(locale, 'themeToDay');
  return (
    <button
      className="theme-toggle"
      aria-label={label}
      onClick={() => {
        const next = otherTheme(theme);
        setTheme(next);
        document.documentElement.setAttribute('data-theme', next);
        try { localStorage.setItem(THEME_KEY, next); } catch { /* private mode */ }
      }}
    >
      {label}
    </button>
  );
}
