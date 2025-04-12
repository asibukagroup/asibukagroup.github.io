---
layout: default
title: Search
permalink: /search/
lang: id
description: Silahkan cari konten yang kamu perlukan menggunakan form ini.
robots: noindex, nofollow
---
<ul id="results"></ul>
<script src="https://unpkg.com/lunr/lunr.js"></script>
<script>
  document.addEventListener('DOMContentLoaded', function () {
    const searchBox = document.getElementById('search-box');
    const resultsContainer = document.getElementById('results');

    if (!resultsContainer) {
      console.error('Results container not found.');
      return;
    }

    const params = new URLSearchParams(window.location.search);
    const query = params.get('q') || '';
    searchBox.value = query; // ✅ Keep last query in input

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
      })
      .catch(err => {
        console.error('Error fetching search.json:', err);
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
          li.innerHTML = `
            <article class="search-result">
              ${item.image ? `<div class="result-image"><img src="${item.image}" alt="${item.title}" /></div>` : ''}
              <div class="result-content">
                <h2><a href="${item.url}">${item.title}</a></h2>
                ${item.author ? `<p class="author"><strong>Author:</strong> ${item.author}</p>` : ''}
                <p class="summary">${item.content}</p>
              </div>
            </article>
          `;
          resultsContainer.appendChild(li);
        });
      }
    }
  });
</script>

<style>
  ul#results {
    list-style: none;
    padding: 0;
    margin: 2rem 0;
  }

  .search-result {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    margin-bottom: 2rem;
    border-bottom: 1px solid #ccc;
    padding-bottom: 1rem;
  }

  .result-image {
    flex: 0 0 30%;
  }

  .result-image img {
    width: 100%;
    height: auto;
    border-radius: 8px;
  }

  .result-content {
    flex: 1;
  }

  .result-content h2 {
    margin: 0 0 0.5rem;
  }

  .result-content .author {
    margin: 0 0 0.5rem;
    font-size: 0.95rem;
    color: #555;
  }

  .result-content .summary {
    margin: 0;
    font-size: 1rem;
    line-height: 1.4;
  }

  @media (max-width: 768px) {
    .search-result {
      flex-direction: column;
    }

    .result-image {
      flex: 1 1 100%;
    }

    .result-content {
      flex: 1 1 100%;
    }
  }
</style>