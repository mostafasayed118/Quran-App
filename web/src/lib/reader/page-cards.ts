import { writeResume } from '../reader-resume';
import { toArabicDigits } from '../arabic-digits';
import { t } from '../strings';
import type { ReaderContext } from './context';
import type { KeyboardNav } from './keyboard-nav';

interface PageBlock {
  page: number;
  el: HTMLElement;
  ayahs: HTMLElement[];
}

export interface PageCards {
  /** Switches to the pages layout, showing the page that holds `target` (or the first). */
  enterPages(target: number | null, opts?: { scroll?: boolean; anchor?: boolean }): void;
  /** Leaves the pages layout and restores the verse flow. */
  exitPages(): void;
  /** The number of the topmost visible ayah, or null when there is none. */
  topmostVisibleAyah(): number | null;
  /** Steps one page forward (delta > 0) or back (delta < 0). */
  stepPage(delta: number): void;
}

export interface PageGroup<T> {
  page: number;
  items: T[];
}

/**
 * Groups ayahs into their mushaf pages: by page number, and by ayah number
 * inside a page. Ayahs without a page number are dropped.
 */
export function groupAyahsByPage<T extends { page: number; n: number }>(
  items: readonly T[],
): PageGroup<T>[] {
  const byPage = new Map<number, T[]>();
  for (const item of items) {
    if (!Number.isInteger(item.page)) continue;
    const list = byPage.get(item.page);
    if (list) list.push(item);
    else byPage.set(item.page, [item]);
  }
  return [...byPage.keys()]
    .sort((x, y) => x - y)
    .map((page) => ({ page, items: byPage.get(page)!.sort((a, b) => a.n - b.n) }));
}

export function initPageCards(ctx: ReaderContext, keyboard: KeyboardNav): PageCards {
  const L = ctx.locale;
  let pages: PageBlock[] | null = null;
  let currentIndex = 0;
  let nav: HTMLElement | null = null;
  let posEl: HTMLElement | null = null;
  let prevPageBtn: HTMLButtonElement | null = null;
  let nextPageBtn: HTMLButtonElement | null = null;

  const pageOf = (page: number, total: number): string => {
    const x = L === 'ar' ? toArabicDigits(page) : String(page);
    const y = L === 'ar' ? toArabicDigits(total) : String(total);
    return t(L, 'readerPageOf').replace('{x}', x).replace('{y}', y);
  };

  // --- pages layout: cards built in place from the SSR ayah elements; one page shown at a time ---
  const buildPages = (container: HTMLElement): PageBlock[] => {
    const entries = Array.from(container.querySelectorAll<HTMLElement>('.ayah')).map((el) => ({
      el,
      page: Number(el.dataset.page),
      n: Number(el.dataset.n),
    }));
    const built: PageBlock[] = [];
    for (const group of groupAyahsByPage(entries)) {
      const el = document.createElement('div');
      el.className = 'mushaf-page';
      el.setAttribute('data-page', String(group.page));
      for (const ayah of group.items) el.appendChild(ayah.el);
      const num = document.createElement('div');
      num.className = 'mushaf-page-num';
      num.setAttribute('aria-hidden', 'true');
      num.textContent = toArabicDigits(group.page);
      el.appendChild(num);
      container.appendChild(el);
      built.push({ page: group.page, el, ayahs: group.items.map((item) => item.el) });
    }
    return built;
  };

  const indexOfAyah = (n: number): number => {
    if (!pages) return 0;
    const i = pages.findIndex((block) => block.ayahs.some((el) => Number(el.dataset.n) === n));
    return i === -1 ? 0 : i;
  };

  const clearSelection = (): void => {
    ctx.ayahs?.querySelector<HTMLElement>('.ayah.selected')?.classList.remove('selected');
  };

  const showPage = (index: number, opts: { scroll?: boolean } = {}): void => {
    if (!pages || pages.length === 0) return;
    const i = Math.min(Math.max(index, 0), pages.length - 1);
    currentIndex = i;
    pages.forEach((block, j) => block.el.toggleAttribute('hidden', j !== i));
    const total = pages.length;
    if (posEl) posEl.textContent = pageOf(pages[i].page, total);
    if (prevPageBtn) {
      prevPageBtn.disabled = i === 0;
      prevPageBtn.setAttribute('aria-label', pageOf(pages[Math.max(i - 1, 0)].page, total));
    }
    if (nextPageBtn) {
      nextPageBtn.disabled = i === total - 1;
      nextPageBtn.setAttribute('aria-label', pageOf(pages[Math.min(i + 1, total - 1)].page, total));
    }
    if (nav) nav.hidden = false;
    clearSelection();
    const a = Number(pages[i].ayahs[0]?.dataset.n);
    if (Number.isInteger(a) && Number.isInteger(ctx.surahId)) {
      writeResume(localStorage, { s: ctx.surahId, a });
    }
    if (opts.scroll === true) ctx.reader?.scrollIntoView({ block: 'start' });
  };

  const stepPage = (delta: number): void => {
    if (!pages) return;
    const next = currentIndex + delta;
    if (next < 0 || next >= pages.length) return;
    showPage(next, { scroll: true });
  };

  const buildNav = (container: HTMLElement): void => {
    if (nav) return;
    nav = document.createElement('div');
    nav.className = 'mushaf-nav';
    nav.hidden = true;
    const makeBtn = (dir: 'prev' | 'next'): HTMLButtonElement => {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'rc-btn';
      b.setAttribute('data-mushaf', dir);
      b.textContent = dir === 'prev' ? (L === 'ar' ? '›' : '‹') : L === 'ar' ? '‹' : '›';
      b.addEventListener('click', () => stepPage(dir === 'prev' ? -1 : 1));
      return b;
    };
    prevPageBtn = makeBtn('prev');
    nextPageBtn = makeBtn('next');
    posEl = document.createElement('span');
    posEl.className = 'mushaf-pos';
    posEl.setAttribute('data-mushaf', 'pos');
    posEl.setAttribute('aria-live', 'polite');
    nav.append(prevPageBtn, posEl, nextPageBtn);
    container.appendChild(nav);
  };

  const enterPages = (
    target: number | null,
    opts: { scroll?: boolean; anchor?: boolean } = {},
  ): void => {
    const container = ctx.ayahs;
    if (!container) return;
    if (!pages) pages = buildPages(container);
    if (pages.length === 0) return;
    buildNav(container);
    showPage(target === null ? 0 : indexOfAyah(target), { scroll: opts.scroll === true });
    keyboard.set({ box: ctx.box, go: stepPage });
    if (opts.anchor === true && target !== null) {
      document.getElementById(`ayah-${target}`)?.scrollIntoView({ block: 'start' });
    }
  };

  const exitPages = (): void => {
    if (pages) for (const block of pages) block.el.removeAttribute('hidden');
    if (nav) nav.hidden = true;
    clearSelection();
    keyboard.set(null);
  };

  const topmostVisibleAyah = (): number | null => {
    const container = ctx.ayahs;
    if (!container) return null;
    const els = Array.from(container.querySelectorAll<HTMLElement>('.ayah'));
    const top = els.find((el) => el.getBoundingClientRect().bottom > 0);
    const n = Number((top ?? els[0])?.dataset.n);
    return Number.isInteger(n) ? n : null;
  };

  return { enterPages, exitPages, topmostVisibleAyah, stepPage };
}
