const PREFIX = 'qy:';

/** The localStorage namespace every setting of the site lives in. */
export const SETTINGS_PREFIX = PREFIX;

/** The full localStorage key of one setting, e.g. `qy:reader`. */
export function settingsKey(key: string): string {
  return `${PREFIX}${key}`;
}

export function readSetting<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(settingsKey(key));
    return raw === null ? fallback : (JSON.parse(raw) as T);
  } catch {
    return fallback;
  }
}
export function writeSetting(key: string, value: unknown): void {
  try {
    localStorage.setItem(settingsKey(key), JSON.stringify(value));
  } catch {
    /* private mode */
  }
}
