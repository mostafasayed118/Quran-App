import { listBookmarks, toggleBookmark } from '../bookmarks';
import { shareOrCopy } from '../share';
import { surahUrl } from '../urls';
import { t } from '../strings';
import type { ReaderContext } from './context';

export interface AyahActionsOptions {
  context: ReaderContext;
  /** Starts playback of a surah with the picked reciter. */
  playSurah: (surah: number) => void;
}

export function initAyahActions({ context: ctx, playSurah }: AyahActionsOptions): void {
  const L = ctx.locale;
  const ayahs = ctx.ayahs;

  // --- per-ayah actions (delegated; copy/share always use the plain-Arabic `.ayah-i`) ---
  const saved = new Set(listBookmarks().map((b) => `${b.s}:${b.a}`));
  const setBookmarkState = (btn: HTMLButtonElement, pressed: boolean): void => {
    const label = t(L, pressed ? 'ayahBookmarked' : 'ayahBookmark');
    btn.setAttribute('aria-pressed', String(pressed));
    btn.setAttribute('aria-label', label);
    btn.textContent = label;
  };
  ayahs?.querySelectorAll<HTMLButtonElement>('[data-ayah-action="bookmark"]').forEach((btn) => {
    setBookmarkState(btn, saved.has(`${btn.dataset.surah}:${btn.dataset.ayah}`));
  });

  const flashTimers = new WeakMap<HTMLElement, number>();
  const flashCopied = (btn: HTMLElement): void => {
    if (btn.dataset.origLabel === undefined) btn.dataset.origLabel = btn.textContent ?? '';
    btn.textContent = t(L, 'ayahCopied');
    window.clearTimeout(flashTimers.get(btn));
    flashTimers.set(
      btn,
      window.setTimeout(() => {
        btn.textContent = btn.dataset.origLabel ?? '';
        delete btn.dataset.origLabel;
      }, 1500),
    );
  };

  ayahs?.addEventListener('click', (e) => {
    const btn = (e.target as HTMLElement | null)?.closest<HTMLButtonElement>('[data-ayah-action]');
    if (!btn) return;
    const s = Number(btn.dataset.surah);
    const a = Number(btn.dataset.ayah);
    const text = btn.closest('.ayah')?.querySelector('.ayah-i')?.textContent ?? '';
    const action = btn.dataset.ayahAction;
    if (action === 'copy') {
      navigator.clipboard
        .writeText(text)
        .then(() => flashCopied(btn))
        .catch(() => { /* clipboard unavailable */ });
    } else if (action === 'share') {
      shareOrCopy(surahUrl(document.documentElement.lang === 'en' ? 'en' : 'ar', s, a), text)
        .then((outcome) => {
          if (outcome === 'copied') flashCopied(btn);
        })
        .catch(() => { /* clipboard unavailable */ });
    } else if (action === 'bookmark') {
      setBookmarkState(btn, toggleBookmark(s, a));
    } else if (action === 'listen') {
      playSurah(s);
    }
  });

  // --- pages layout: tap an ayah to reveal its actions (one at a time; tap again/outside clears) ---
  ayahs?.addEventListener('click', (e) => {
    if (ctx.settings().layout !== 'pages') return;
    const target = e.target as HTMLElement | null;
    if (!target || target.closest('[data-ayah-action]')) return;
    const picked = target.closest<HTMLElement>('.ayah');
    const current = ayahs?.querySelector<HTMLElement>('.ayah.selected') ?? null;
    if (picked && picked !== current) {
      current?.classList.remove('selected');
      picked.classList.add('selected');
    } else {
      current?.classList.remove('selected');
    }
  });
}
