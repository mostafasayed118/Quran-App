export type Theme = 'day' | 'night';
export const THEME_KEY = 'qy:theme';
export function otherTheme(t: Theme): Theme { return t === 'day' ? 'night' : 'day'; }
export function readTheme(
  storage: Pick<Storage, 'getItem'> | null,
  prefersDark: boolean,
): Theme {
  const saved = storage?.getItem(THEME_KEY);
  if (saved === 'day' || saved === 'night') return saved;
  return prefersDark ? 'night' : 'day';
}
