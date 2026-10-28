// Network-first: a reachable server always wins, so deploys are never shadowed by stale code.
// The cache only answers when the network fails, which keeps offline-capable pages (analysis
// board, preferences) usable. Only same-origin GETs are cached; REST/WS live on another origin.
const CACHE_NAME = "intellector-shell-v1";
const PRECACHE = ["./", "index.html", "bin/app.js", "bin/hxconda.js", "manifest.json", "assets/favicons/pwa-192.png", "assets/favicons/pwa-512.png"];

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => cache.addAll(PRECACHE))
            .then(() => self.skipWaiting())
    );
});

self.addEventListener("activate", (event) => {
    event.waitUntil(
        caches.keys()
            .then((names) => Promise.all(names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))))
            .then(() => self.clients.claim())
    );
});

self.addEventListener("fetch", (event) => {
    const request = event.request;
    if (request.method !== "GET" || new URL(request.url).origin !== self.location.origin)
        return;

    event.respondWith(
        fetch(request, {cache: "no-cache"})
            .then((response) => {
                if (response.ok) {
                    const copy = response.clone();
                    caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
                }
                return response;
            })
            .catch(() =>
                caches.match(request).then((cached) =>
                    cached || (request.mode === "navigate" ? caches.match("index.html") : Response.error())
                )
            )
    );
});
