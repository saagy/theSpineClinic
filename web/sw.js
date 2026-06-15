/// Spine Clinic — Custom Service Worker
///
/// Replaces Flutter's default self-destructing SW with a proper
/// cache-first + network-update strategy that instantly activates
/// new versions and pushes them to all open clients.
///
/// Behaviour:
///   install -> skipWaiting (activate immediately)
///   activate -> claim all clients, purge old caches, broadcast update
///   fetch (navigate) -> network-first, cache on success
///   fetch (assets) -> cache-first, background network refresh
'use strict';

// BUILD_ID_PLACEHOLDER — replaced at deploy time so sw.js changes and the
// browser's SW update flow fires (install → skipWaiting → activate →
// controllerchange → reload), delivering the new build instantly.
const CACHE = 'spine-clinic-vBUILD_ID_PLACEHOLDER';

// ── Install ──────────────────────────────────────────────────────────
self.addEventListener('install', () => {
  self.skipWaiting();
});

// ── Activate ─────────────────────────────────────────────────────────
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.clients.claim();

    // Drop every cache that doesn't match the current name
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)));

    // Notify every open tab so they can reload
    const all = await self.clients.matchAll({ type: 'window' });
    all.forEach(c => c.postMessage({ type: 'SW_ACTIVATED' }));
  })());
});

// ── Fetch ────────────────────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  // Navigation: network first (so we always get the latest shell)
  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // Everything else: cache first, background refresh
  event.respondWith(staleWhileRevalidate(event.request));
});

async function networkFirst(request) {
  const cache = await caches.open(CACHE);
  try {
    const net = await fetch(request);
    if (net && net.ok) cache.put(request, net.clone());
    return net;
  } catch (_) {
    const hit = await cache.match(request);
    return hit || new Response('You are offline.', { status: 503 });
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE);
  const hit = await cache.match(request);

  fetch(request).then(net => {
    if (net && net.ok) cache.put(request, net.clone());
  }).catch(() => {});

  return hit || fetch(request);
}
