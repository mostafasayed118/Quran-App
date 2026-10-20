export interface KeyboardNavHandler {
  /** The element that has to be connected for the keys to act on this page. */
  box: HTMLElement;
  /** Steps one page forward (delta > 0) or back (delta < 0). */
  go: (delta: number) => void;
}

export interface KeyboardNav {
  /** Installs the page-stepping handler, or clears it with null. */
  set(handler: KeyboardNavHandler | null): void;
}

/**
 * The page step of an arrow key: +1 goes forward, -1 goes back, 0 means the key
 * does not page at all. The reading direction follows the document language
 * (RTL: left is forward).
 */
export function arrowStep(key: string, lang: string): -1 | 0 | 1 {
  if (key !== 'ArrowLeft' && key !== 'ArrowRight') return 0;
  const forward = lang === 'en' ? key === 'ArrowRight' : key === 'ArrowLeft';
  return forward ? 1 : -1;
}

// One keydown listener for pages navigation; the active reader sets the handler
// and the before-swap cleanup clears it (same lifecycle as the resume observer).
// The listener is installed on the first init() and lives at module scope, so a
// ClientRouter swap cannot register a second one.
let handler: KeyboardNavHandler | null = null;
let listening = false;

function onKeydown(e: KeyboardEvent): void {
  if (!handler || !handler.box.isConnected) return;
  if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey) return;
  const target = e.target as HTMLElement | null;
  if (target?.closest('input, select, textarea, [contenteditable]')) return;
  const step = arrowStep(e.key, document.documentElement.lang);
  if (step === 0) return;
  handler.go(step);
  e.preventDefault();
}

export function initKeyboardNav(): KeyboardNav {
  if (!listening) {
    listening = true;
    document.addEventListener('keydown', onKeydown);
  }
  return {
    set(next) {
      handler = next;
    },
  };
}
