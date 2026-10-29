/**
 * Heritage page scenes: the living page and the horizontal track.
 *
 * Contract, same as the concept:
 *  - both pins require `min-width: 900px` AND `prefers-reduced-motion: no-preference`;
 *  - otherwise the markup already renders every layer and the track is a native
 *    `overflow-x` + scroll-snap strip, so nothing depends on this file;
 *  - vanilla, no dependency, transform/opacity only.
 *
 * Loaded as a bundled module (CSP `script-src 'self'`), and driven by
 * `astro:page-load` so it survives ClientRouter navigations.
 */

const WIDE = '(min-width: 900px)';
const REDUCE = '(prefers-reduced-motion: reduce)';

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const arabicDigits = (n: number) => String(n).replace(/\d/g, (d) => '٠١٢٣٤٥٦٧٨٩'[Number(d)]);

/* The page ships AR and EN; the counter must not switch the reader's numerals. */
const usesArabicDigits = (): boolean => document.documentElement.lang?.startsWith('ar') ?? true;
const formatIndex = (n: number) => (usesArabicDigits() ? arabicDigits(n) : String(n));

interface Cleanup {
  (): void;
}

function start(): Cleanup | undefined {
  const root = document.querySelector<HTMLElement>('[data-heritage]');
  if (!root) return;

  const journey = root.querySelector<HTMLElement>('[data-journey]');
  const journeyPin = root.querySelector<HTMLElement>('[data-journey-pin]');
  const steps = Array.from(root.querySelectorAll<HTMLElement>('[data-journey-step]'));
  const timeline = root.querySelector<HTMLElement>('[data-timeline]');
  const track = root.querySelector<HTMLElement>('[data-timeline-track]');
  const trackWrap = root.querySelector<HTMLElement>('[data-timeline-scroll]');
  const tlCurrent = root.querySelector<HTMLElement>('[data-timeline-current]');
  const tlFill = root.querySelector<HTMLElement>('[data-timeline-fill]');
  const eraCount = track ? track.children.length : 0;

  const motion = window.matchMedia(REDUCE);
  const wide = window.matchMedia(WIDE);

  let tlMax = 0;
  let ticking = false;
  let resizeTimer = 0;

  function setStage(stage: number) {
    if (!journeyPin) return;
    const next = String(stage);
    if (journeyPin.dataset.stage !== next) journeyPin.dataset.stage = next;
    steps.forEach((step, index) => {
      step.classList.toggle('is-active', index < stage);
    });
  }

  function updateEraMeter(progress: number) {
    if (tlFill) tlFill.style.transform = `scaleX(${Math.max(0.25, progress).toFixed(3)})`;
    if (tlCurrent && eraCount > 0) {
      const index = Math.min(eraCount, Math.floor(progress * eraCount) + 1);
      const label = formatIndex(index);
      if (tlCurrent.textContent !== label) tlCurrent.textContent = label;
    }
  }

  function layout() {
    const pinned = wide.matches && !motion.matches;

    if (journey) {
      journey.classList.toggle('is-pinned', pinned);
      journey.style.height = pinned ? `${Math.round(window.innerHeight * 3.4)}px` : '';
      if (!pinned) setStage(4);
    }

    if (timeline && track) {
      timeline.classList.toggle('is-pinned', pinned);
      tlMax = pinned ? Math.max(0, track.scrollWidth - window.innerWidth) : 0;
      timeline.style.height = pinned ? `${Math.round(window.innerHeight + tlMax)}px` : '';
      if (!pinned) track.style.transform = '';
    }
  }

  function update() {
    if (journey && journeyPin && journey.classList.contains('is-pinned')) {
      const rect = journey.getBoundingClientRect();
      const total = journey.offsetHeight - window.innerHeight;
      const progress = total > 0 ? clamp(-rect.top / total, 0, 1) : 0;
      setStage(clamp(Math.floor(progress * 4) + 1, 1, 4));
    }

    if (timeline && track && tlMax > 0 && timeline.classList.contains('is-pinned')) {
      const rect = timeline.getBoundingClientRect();
      const total = timeline.offsetHeight - window.innerHeight;
      const progress = total > 0 ? clamp(-rect.top / total, 0, 1) : 0;
      track.style.transform = `translate3d(${(-progress * tlMax).toFixed(1)}px, 0, 0)`;
      updateEraMeter(progress);
    }
  }

  function onScroll() {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      update();
      ticking = false;
    });
  }

  function onResize() {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(() => {
      layout();
      update();
    }, 150);
  }

  function onTrackScroll() {
    if (!trackWrap || timeline?.classList.contains('is-pinned')) return;
    const max = trackWrap.scrollWidth - trackWrap.clientWidth;
    const progress = max > 0 ? clamp(Math.abs(trackWrap.scrollLeft) / max, 0, 1) : 0;
    updateEraMeter(progress);
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onResize);
  trackWrap?.addEventListener('scroll', onTrackScroll, { passive: true });
  motion.addEventListener?.('change', layout);
  wide.addEventListener?.('change', layout);

  if (document.fonts) void document.fonts.ready.then(layout);
  layout();
  update();

  return () => {
    window.removeEventListener('scroll', onScroll);
    window.removeEventListener('resize', onResize);
    trackWrap?.removeEventListener('scroll', onTrackScroll);
    motion.removeEventListener?.('change', layout);
    wide.removeEventListener?.('change', layout);
    window.clearTimeout(resizeTimer);
  };
}

let cleanup: Cleanup | undefined;

function boot() {
  cleanup?.();
  cleanup = start();
}

document.addEventListener('astro:page-load', boot);
document.addEventListener('astro:before-swap', () => cleanup?.());
