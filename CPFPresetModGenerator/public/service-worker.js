// Service Worker for BG3 CPF Preset Mod Generator
// Implements offline-first caching strategy

const CACHE_VERSION = 'v2';
const CACHE_NAME = `bg3-pmg-${CACHE_VERSION}`;

// Assets to precache on install
const PRECACHE_ASSETS = [
    '/',
    '/site.webmanifest',
    '/icon.png',
];

// Install event - precache critical assets
self.addEventListener('install', (event) => {
    console.log('[Service Worker] Installing...');
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            console.log('[Service Worker] Precaching assets');
            return cache.addAll(PRECACHE_ASSETS);
        }).then(() => {
            // Force the waiting service worker to become the active service worker
            return self.skipWaiting();
        })
    );
});

// Activate event - cleanup old caches
self.addEventListener('activate', (event) => {
    console.log('[Service Worker] Activating...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((cacheName) => {
                    if (cacheName !== CACHE_NAME) {
                        console.log('[Service Worker] Deleting old cache:', cacheName);
                        return caches.delete(cacheName);
                    }
                })
            );
        }).then(() => {
            // Take control of all pages immediately
            return self.clients.claim();
        })
    );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // Skip cross-origin requests
    if (url.origin !== location.origin) {
        return;
    }

    // Skip Sentry requests - these will be handled by the offline queue?
    if (url.pathname.includes('/monitoring') || url.hostname.includes('sentry.io')) {
        return;
    }

    event.respondWith(
        handleFetch(request)
    );
});

async function handleFetch(request) {
    const url = new URL(request.url);

    // Cache-first strategy for static assets (JS, CSS, WASM, images, fonts)
    if (
        request.destination === 'script' ||
        request.destination === 'style' ||
        request.destination === 'font' ||
        request.destination === 'image' ||
        url.pathname.endsWith('.wasm') ||
        url.pathname.startsWith('/_next/static/')
    ) {
        return cacheFirst(request);
    }

    // Network-first strategy for HTML pages
    if (
        request.destination === 'document' ||
        request.headers.get('accept')?.includes('text/html')
    ) {
        return networkFirst(request);
    }

    // Default: network-first with cache fallback
    return networkFirst(request);
}

// Cache-first strategy: try cache, fallback to network
async function cacheFirst(request) {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(request);

    if (cached) {
        console.log('[Service Worker] Cache hit:', request.url);
        return cached;
    }

    try {
        console.log('[Service Worker] Fetching:', request.url);
        const response = await fetch(request);

        // Cache successful responses (including dynamic chunks)
        if (response.ok) {
            cache.put(request, response.clone());
            console.log('[Service Worker] Cached:', request.url);
        }

        return response;
    } catch (error) {
        console.error('[Service Worker] Fetch failed:', request.url, error);

        // Return offline page for navigation requests
        if (request.destination === 'document') {
            const offlineResponse = await cache.match('/');
            if (offlineResponse) {
                return offlineResponse;
            }
        }

        throw error;
    }
}

// Network-first strategy: try network, fallback to cache
async function networkFirst(request) {
    const cache = await caches.open(CACHE_NAME);

    try {
        console.log('[Service Worker] Fetching:', request.url);
        const response = await fetch(request);

        // Cache successful responses
        if (response.ok) {
            cache.put(request, response.clone());
        }

        return response;
    } catch (error) {
        console.log('[Service Worker] Network failed, trying cache:', request.url);
        const cached = await cache.match(request);

        if (cached) {
            console.log('[Service Worker] Cache hit:', request.url);
            return cached;
        }

        console.error('[Service Worker] No cache available:', request.url);
        throw error;
    }
}

// Listen for messages from the client
self.addEventListener('message', (event) => {
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});
