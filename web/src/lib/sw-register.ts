export function registerServiceWorker(): void {
  if (!('serviceWorker' in navigator)) return;
  const container = navigator.serviceWorker;
  window.addEventListener(
    'load',
    () => {
      container.register('/sw.js', { updateViaCache: 'none' }).catch(() => {});
    },
    { once: true },
  );
}
