---
layout: default
title: Search
permalink: /search/
lang: id
description: Silahkan cari konten yang kamu perlukan menggunakan form ini.
robots: noindex, nofollow
---

<input type="text" id="search-box" placeholder="Type to search...">
<ul id="results"></ul>

<script src="https://unpkg.com/lunr/lunr.js"></script>
<script>
  let index;
  let data;

  fetch('/search.json')
    .then(res => res.json())
    .then(json => {
      data = json;
      index = lunr(function () {
        this.ref('url');
        this.field('title');
        this.field('content');
        data.forEach(doc => this.add(doc));
      });
    });

  document.getElementById('search-box').addEventListener('input', function () {
    const query = this.value;
    const results = index.search(query);
    const resultList = document.getElementById('results');
    resultList.innerHTML = '';

    results.forEach(result => {
      const item = data.find(d => d.url === result.ref);
      const li = document.createElement('li');
      li.innerHTML = `<a href="${item.url}">${item.title}</a>`;
      resultList.appendChild(li);
    });
  });
</script>