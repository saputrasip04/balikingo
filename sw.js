const C = 'pinjam-v19';
const ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './vendor/jspdf.umd.min.js',
  './vendor/jspdf.plugin.autotable.min.js',
  './vendor/qrcode.min.js',
  'https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&display=swap',
  'https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js'
];

self.addEventListener('install', ev => {
  self.skipWaiting();
  ev.waitUntil(
    caches.open(C).then(cache => cache.addAll(ASSETS))
  );
});

self.addEventListener('activate', ev => {
  ev.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== C).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', ev => {
  // Lewatkan semua endpoint API ke jaringan langsung (no-cache)
  if (ev.request.url.includes('/api/')) {
    return;
  }

  // Navigasi / HTML requests: Network first so UI updates appear immediately
  if (ev.request.mode === 'navigate' || ev.request.headers.get('accept')?.includes('text/html')) {
    ev.respondWith(
      fetch(ev.request)
        .then(response => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(C).then(cache => cache.put(ev.request, clone));
          }
          return response;
        })
        .catch(() => caches.match('./index.html') || caches.match(ev.request))
    );
    return;
  }

  // Static assets lainnya: Cache first with network fallback
  ev.respondWith(
    caches.match(ev.request).then(cached => {
      if (cached) return cached;
      return fetch(ev.request).then(response => {
        if (!response || response.status !== 200 || response.type === 'opaque') return response;
        const clone = response.clone();
        caches.open(C).then(cache => cache.put(ev.request, clone));
        return response;
      });
    })
  );
});

// Respon klik notifikasi sistem di HP Android / Desktop
self.addEventListener('notificationclick', ev => {
  ev.notification.close();
  const urlToOpen = new URL('./', self.location.origin).href;
  ev.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(windowClients => {
      for (let client of windowClients) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
