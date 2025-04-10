---
layout: default
title: Search
permalink: /search/
lang: id
description: Silahkan cari konten yang kamu perlukan menggunakan form ini.
robots: noindex, nofollow
---

<input type="text" id="search-box" placeholder="Type to search..." />
<ul id="search-results"></ul>

<script src="https://unpkg.com/lunr/lunr.js"></script>
<script>
  let idx = null;
  let docs = [];

  function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
  }

  function performSearch(query) {
    const searchBox = document.getElementById("search-box");
    const resultsContainer = document.getElementById("search-results");
    searchBox.value = query;
    resultsContainer.innerHTML = "";

    if (query.length > 1 && idx) {
      const results = idx.search(query);
      results.forEach(result => {
        const matched = docs.find(d => d.url === result.ref);
        if (matched) {
          const li = document.createElement("li");
          li.innerHTML = `<a href="${matched.url}">${matched.title}</a>`;
          resultsContainer.appendChild(li);
        }
      });
    }
  }

  fetch("{{ '/search.json' | relative_url }}")
    .then(response => response.json())
    .then(json => {
      docs = json;
      idx = lunr(function () {
        this.ref('url');
        this.field('title');
        this.field('content');
        this.field('tags');
        this.field('categories');

        json.forEach(doc => this.add(doc));
      });

      const initialQuery = getQueryParam("q");
      if (initialQuery) {
        performSearch(initialQuery);
      }
    });

  document.getElementById("search-box").addEventListener("input", function () {
    performSearch(this.value.trim());
  });
</script>