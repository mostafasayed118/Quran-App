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

  // The buttons start outside the tab order; the SSR bytes stay lean and the
  // first Tab lands on the ayah, not on 4 hidden controls.
  ayahs?.querySelectorAll<HTMLButtonElement>('[data-ayah-action]').forEach((btn) => {
    btn.tabIndex = -1;
  });

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
        .catch(() => {
          /* clipboard unavailable */
        });
    } else if (action === 'share') {
      shareOrCopy(surahUrl(document.documentElement.lang === 'en' ? 'en' : 'ar', s, a), text)
        .then((outcome) => {
          if (outcome === 'copied') flashCopied(btn);
        })
        .catch(() => {
          /* clipboard unavailable */
        });
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

  // --- keyboard + focus: one tab stop per ayah; Enter/Space reveals that ayah's actions ---
  let activeAyah: HTMLElement | null = null;
  // A pointer press must not pre-select: the pages-layout click handler owns that toggle.
  let pointerFocus = false;
  const setActionTabStops = (ayah: HTMLElement, reachable: boolean): void => {
    ayah.querySelectorAll<HTMLButtonElement>('[data-ayah-action]').forEach((btn) => {
      btn.tabIndex = reachable ? 0 : -1;
    });
  };

  ayahs?.addEventListener(
    'pointerdown',
    () => {
      pointerFocus = true;
    },
    true,
  );

  ayahs?.addEventListener('click', () => {
    pointerFocus = false;
  });

  ayahs?.addEventListener('focusin', (e) => {
    const ayah = (e.target as HTMLElement | null)?.closest<HTMLElement>('.ayah') ?? null;
    if (!ayah) return;
    if (activeAyah && activeAyah !== ayah) {
      setActionTabStops(activeAyah, false);
      activeAyah.classList.remove('selected');
    }
    if (!pointerFocus) ayah.classList.add('selected');
    activeAyah = ayah;
  });

  ayahs?.addEventListener('focusout', (e) => {
    const ayah = (e.target as HTMLElement | null)?.closest<HTMLElement>('.ayah') ?? null;
    if (!ayah) return;
    const next = e.relatedTarget;
    if (next instanceof Node && ayah.contains(next)) return;
    setActionTabStops(ayah, false);
  });

  ayahs?.addEventListener('keydown', (e) => {
    pointerFocus = false;
    const target = e.target as HTMLElement | null;
    if (e.key === 'Escape') {
      const btn = target?.closest<HTMLElement>('[data-ayah-action]') ?? null;
      const ayah = btn?.closest<HTMLElement>('.ayah') ?? null;
      if (!btn || !ayah) return;
      e.preventDefault();
      setActionTabStops(ayah, false);
      ayah.focus();
      return;
    }
    if (!target || target.closest('button, a, input, select, textarea, [contenteditable]')) return;
    if (e.key !== 'Enter' && e.key !== ' ') return;
    const ayah = target.closest<HTMLElement>('.ayah');
    if (!ayah) return;
    e.preventDefault();
    ayah.classList.add('selected');
    setActionTabStops(ayah, true);
    ayah.querySelector<HTMLElement>('[data-ayah-action]')?.focus();
  });
}
