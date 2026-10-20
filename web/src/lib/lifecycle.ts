/**
 * Runs `init` now and again after every ClientRouter swap.
 *
 * Astro's client router replaces the page body without a reload, so a page script
 * has to re-bind to the new markup. Each init keeps its own `data-qy-ready` guard,
 * so the re-entry stays idempotent.
 *
 * One module-level dispatcher owns the single `astro:after-swap` listener: a page
 * that is visited twice must not leave a second listener behind, or the listener
 * count would grow with the session length.
 */
const initializers = new Set<() => void>();
let listening = false;

export function onPageReady(init: () => void): void {
  initializers.add(init);
  if (!listening) {
    listening = true;
    document.addEventListener('astro:after-swap', () => {
      for (const run of initializers) run();
    });
  }
  init();
}
