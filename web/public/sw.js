/*
 * Quran Yahdi service worker.
 *
 * VERSIONING: bump CACHE_VERSION (qy-v1 -> qy-v2) whenever the precache list or
 * the fetch policy changes. `activate` deletes every cache whose name does not
 * match the current version, so a bump is the only reliable way to evict
 * responses cached under the old policy.
 *
 * AUDIO: recitation requests carry a Range header; they are deliberately
 * bypassed so the browser keeps native streaming and seeking, and partial
 * responses never land in the cache.
 */
const CACHE_VERSION = 'qy-v1';
const PRECACHE = ['/', '/en/', '/offline/', '/en/offline/'];
const MAX_ENTRIES = 80;
const CACHE_FIRST = /^\/(_astro|fonts|og|data|icon-|logo-|favicon|apple-touch)/;
const BYPASS_PATHS = ['/sw.js', '/.well-known/', '/sitemap.xml', '/robots.txt'];

function isBypassed(pathname) {
  return BYPASS_PATHS.some((path) =>
    path.endsWith('/') ? pathname.startsWith(path) : pathname === path,
  );
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_VERSION)
      .then((cache) => Promise.all(PRECACHE.map((url) => cache.add(url).catch(() => {}))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== CACHE_VERSION).map((key) => caches.delete(key))),
      )
      .then(() => self.clients.claim()),
  );
});

function cacheResponse(event, request, response) {
  if (!response || !response.ok || response.type === 'opaque') return;
  const copy = response.clone();
  event.waitUntil(
    (async () => {
      try {
        const cache = await caches.open(CACHE_VERSION);
        await cache.put(request, copy);
        const keys = await cache.keys();
        const excess = keys.length - MAX_ENTRIES;
        if (excess > 0) {
          await Promise.all(keys.slice(0, excess).map((key) => cache.delete(key)));
        }
      } catch {
        // A failed cache write must never break the live response.
      }
    })(),
  );
}

async function networkFirst(event, request, fallbackUrl) {
  try {
    const response = await fetch(request);
    cacheResponse(event, request, response);
    return response;
  } catch {
    const cached = await caches.match(request);
    if (cached) return cached;
    if (fallbackUrl) {
      const offline = await caches.match(fallbackUrl);
      if (offline) return offline;
    }
    return Response.error();
  }
}

async function cacheFirst(event, request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  try {
    const response = await fetch(request);
    cacheResponse(event, request, response);
    return response;
  } catch {
    return Response.error();
  }
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (request.headers.has('range')) return;
  if (isBypassed(url.pathname)) return;

  if (request.mode === 'navigate') {
    const fallback =
      url.pathname === '/en' || url.pathname.startsWith('/en/') ? '/en/offline/' : '/offline/';
    event.respondWith(networkFirst(event, request, fallback));
    return;
  }

  if (CACHE_FIRST.test(url.pathname)) {
    event.respondWith(cacheFirst(event, request));
    return;
  }

  event.respondWith(networkFirst(event, request));
});
