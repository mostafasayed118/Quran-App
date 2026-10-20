import type { Locale } from '../strings';
import type { ReaderSettings } from '../reader-settings';

/**
 * What every reader feature module needs: the page's elements, the active locale
 * and the settings store. The reader page owns the state; the modules read and
 * mutate it through these handles.
 */
export interface ReaderContext {
  /** The active locale of this reader page. */
  readonly locale: Locale;
  /** The .reader-controls bar; also the anchor the keyboard navigation watches. */
  readonly box: HTMLElement;
  /** The .ayahs container, or null when the page has no ayah blocks. */
  readonly ayahs: HTMLElement | null;
  /** The .reader article; scrolled back to the top when the page changes. */
  readonly reader: HTMLElement | null;
  /** The surah this reader shows; NaN when the play control is missing. */
  readonly surahId: number;
  /** The current reader settings. */
  settings(): ReaderSettings;
  /** Persists a settings patch and returns the merged result. */
  saveSettings(patch: Partial<ReaderSettings>): ReaderSettings;
  /** Re-renders the control buttons from the current settings. */
  render(): void;
}
