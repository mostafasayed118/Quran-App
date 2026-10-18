import { readSetting, writeSetting } from './settings';

export type ReaderView = 'mushaf' | 'imlaei';
export type FontStep = 0 | 1 | 2 | 3;
export interface ReaderSettings {
  fontStep: FontStep;
  view: ReaderView;
}

export const READER_DEFAULTS: ReaderSettings = { fontStep: 0, view: 'mushaf' };

const FONT_STEPS: readonly FontStep[] = [0, 1, 2, 3];

function coerce(raw: unknown): ReaderSettings {
  if (typeof raw !== 'object' || raw === null) return { ...READER_DEFAULTS };
  const r = raw as { fontStep?: unknown; view?: unknown };
  return {
    fontStep: FONT_STEPS.includes(r.fontStep as FontStep)
      ? (r.fontStep as FontStep)
      : READER_DEFAULTS.fontStep,
    view: r.view === 'mushaf' || r.view === 'imlaei' ? r.view : READER_DEFAULTS.view,
  };
}

export function readReaderSettings(): ReaderSettings {
  return coerce(readSetting<unknown>('reader', null));
}

export function writeReaderSettings(patch: Partial<ReaderSettings>): ReaderSettings {
  const next = coerce({ ...readReaderSettings(), ...patch });
  writeSetting('reader', next);
  return next;
}
