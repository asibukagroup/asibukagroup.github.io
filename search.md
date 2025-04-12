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
  function runSearch(query, data, index) {
  const results = index.search(query);
  resultsContainer.innerHTML = '';

  if (results.length === 0) {
    resultsContainer.innerHTML = '<li>No results found.</li>';
  } else {
    results.forEach(result => {
      const item = data.find(d => d.url === result.ref);
      const li = document.createElement('li');
      li.innerHTML = `
        <article class="search-result" style="margin-bottom: 1.5rem;">
          <h2><a href="${item.url}">${item.title}</a></h2>
          ${item.author ? `<p><strong>Author:</strong> ${item.author}</p>` : ''}
          ${item.image ? `<img src="${item.image}" alt="${item.title}" style="max-width:100%;height:auto;margin:0.5rem 0;" />` : ''}
          <p>${item.content}</p>
        </article>
      `;
      resultsContainer.appendChild(li);
    });
  }
}
</script>
<style>
  .search-result h2 {
    margin-bottom: 0.3rem;
  }
  .search-result img {
    border-radius: 8px;
  }
  .search-result p {
    margin: 0.3rem 0;
  }
</style>
