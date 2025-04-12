---
layout: default
title: Search
permalink: /search/
lang: id
description: Silahkan cari konten yang kamu perlukan menggunakan form ini.
robots: noindex, nofollow
---
<form action="/search" method="GET" class="search-bar">
  <input type="text" name="q" id="search-box" placeholder="Search..." />
  <button type="submit">🔍</button>
</form>

<ul id="results"></ul>

<script src="https://unpkg.com/lunr/lunr.js"></script>
<script>
  const params = new URLSearchParams(window.location.search);
  const query = params.get('q') || '';

  const searchBox = document.getElementById('search-box');
  const resultsContainer = document.getElementById('results');

  searchBox.value = query;

  fetch('/search.json')
    .then(res => res.json())
    .then(json => {
      const data = json;

      const index = lunr(function () {
        this.ref('url');
        this.field('title');
        this.field('content');
        data.forEach(doc => this.add(doc));
      });

      if (query.trim()) {
        runSearch(query, data, index);
      }

      searchBox.addEventListener('input', function () {
        runSearch(this.value, data, index);
      });
    });

  function runSearch(query, data, index) {
    const results = index.search(query);
    resultsContainer.innerHTML = '';

    if (results.length === 0) {
      resultsContainer.innerHTML = '<li>No results found.</li>';
    } else {
      results.forEach(result => {
        const item = data.find(d => d.url === result.ref);
        const li = document.createElement('li');
        li.innerHTML = `<a href="${item.url}">${item.title}</a>`;
        resultsContainer.appendChild(li);
      });
    }
  }
</script>