const CACHE_NAME = "jekyll-pwa-v1";

// Dynamically generate URLs to cache using Jekyll
const urlsToCache = [
    "{{ site.baseurl }}/",  // Home Page
    {% for post in site.posts %}
    "{{ site.baseurl }}{{ post.url }}",
    {% endfor %}
    "{{ site.baseurl }}/assets/css/style.css",
    "{{ site.baseurl }}/assets/js/main.js"
];

// Install Service Worker and Cache Files
self.addEventListener("install", event => {
    event.waitUntil(
        caches.open(CACHE_NAME).then(cache => {
            return cache.addAll(urlsToCache);
        })
    );
});

// Fetch from cache first, then update from network
self.addEventListener("fetch", event => {
    event.respondWith(
        caches.match(event.request).then(response => {
            return response || fetch(event.request);
        })
    );
});

// Activate & Remove Old Cache
self.addEventListener("activate", event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cache => {
                    if (cache !== CACHE_NAME) {
                        return caches.delete(cache);
                    }
                })
            );
        })
    );
});
