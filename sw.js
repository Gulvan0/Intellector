// Network-first: a reachable server always wins, so deploys are never shadowed by stale code.
// The cache only answers when the network fails, which keeps offline-capable pages (analysis
// board, preferences) usable. Each API version's client lives under its own `v/<api>/` paths, so
// versions never mix in the cache; their files are cached as they get fetched. Only same-origin GETs are cached; REST/WS live on another origin.
// Images and sounds are the exception: the cache answers at once and the network refreshes it
// in the background, so icons never wait on a revalidation round trip.
// Fetching a version's app script makes it the current one, dropping the other versions' files.
const CACHE_NAME = "intellector-shell-v1";
const STATIC_ASSET_PATH = /\/assets\/(images|sounds)\//;
const VERSIONED_PATH = /\/v\/(\d+)\//;
const APP_SCRIPT_PATH = /\/v\/(\d+)\/bin\/app\.js$/;
const PRECACHE = ["./", "index.html", "manifest.json", "assets/favicons/pwa-192.png", "assets/favicons/pwa-512.png"];

function dropOtherVersions(cache, currentVersion) {
    return cache.keys().then((requests) => Promise.all(requests
        .filter((request) => {
            const match = VERSIONED_PATH.exec(new URL(request.url).pathname);
            return match !== null && match[1] !== currentVersion;
        })
        .map((request) => cache.delete(request))
    ));
}

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

    if (STATIC_ASSET_PATH.test(request.url))
    {
        event.respondWith(
            caches.open(CACHE_NAME).then((cache) =>
                cache.match(request).then((cached) => {
                    const refreshed = fetch(request, {cache: "no-cache"}).then((response) => {
                        if (response.ok)
                            cache.put(request, response.clone());
                        return response;
                    });
                    return cached || refreshed;
                })
            )
        );
        return;
    }

    event.respondWith(
        fetch(request, {cache: "no-cache"})
            .then((response) => {
                if (response.ok) {
                    const copy = response.clone();
                    const appScript = APP_SCRIPT_PATH.exec(new URL(request.url).pathname);
                    event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.put(request, copy)
                        .then(() => appScript !== null ? dropOtherVersions(cache, appScript[1]) : undefined)
                    ));
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
