import { readSetting, settingsKey, writeSetting } from './settings';

export type ReaderView = 'mushaf' | 'imlaei';
export type FontStep = 0 | 1 | 2 | 3;
export type ReaderLayout = 'verses' | 'pages';
export interface ReaderSettings {
  fontStep: FontStep;
  view: ReaderView;
  reciterRow: string;
  layout?: ReaderLayout;
}

export const READER_DEFAULTS: ReaderSettings = { fontStep: 0, view: 'mushaf', reciterRow: '' };

/**
 * The one source of truth for the reader settings.
 *
 * The reader page applies the stored settings before the first paint with an
 * inline script; that script cannot import this module, so it receives these
 * constants through Astro's `define:vars` instead of hardcoding them. The key
 * and the allowed values therefore exist exactly once.
 */
export const READER_SETTINGS_KEY = settingsKey('reader');
export const READER_FONT_STEPS: readonly number[] = [0, 1, 2, 3];
export const READER_VIEWS: readonly string[] = ['mushaf', 'imlaei'];
export const READER_LAYOUTS: readonly string[] = ['verses', 'pages'];

function coerce(raw: unknown): ReaderSettings {
  if (typeof raw !== 'object' || raw === null) return { ...READER_DEFAULTS };
  const r = raw as { fontStep?: unknown; view?: unknown; reciterRow?: unknown; layout?: unknown };
  const out: ReaderSettings = {
    fontStep: READER_FONT_STEPS.includes(r.fontStep as number)
      ? (r.fontStep as FontStep)
      : READER_DEFAULTS.fontStep,
    view: READER_VIEWS.includes(r.view as string) ? (r.view as ReaderView) : READER_DEFAULTS.view,
    reciterRow: typeof r.reciterRow === 'string' ? r.reciterRow : READER_DEFAULTS.reciterRow,
  };
  if (READER_LAYOUTS.includes(r.layout as string)) out.layout = r.layout as ReaderLayout;
  return out;
}

export function readReaderSettings(): ReaderSettings {
  return coerce(readSetting<unknown>('reader', null));
}

export function writeReaderSettings(patch: Partial<ReaderSettings>): ReaderSettings {
  const next = coerce({ ...readReaderSettings(), ...patch });
  writeSetting('reader', next);
  return next;
}
