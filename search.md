---
layout: default
title: Search
permalink: /search/
lang: id
description: Silahkan cari konten yang kamu perlukan menggunakan form ini.
robots: noindex, nofollow
---
<h1 class="main-heading">Hasil Pencarian</h1>
<div id="results" class="search-results"></div>
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
        } else {
          showAll(data);
        }

        searchBox.addEventListener('input', function () {
          if (this.value.trim()) {
            runSearch(this.value, data, index);
          } else {
            showAll(data);
          }
        });
      })
      .catch(err => {
        console.error('Error fetching search.json:', err);
      });

    function runSearch(query, data, index) {
      const results = index.search(query);
      resultsContainer.innerHTML = '';

      if (results.length === 0) {
        resultsContainer.innerHTML = '<div class="no-results">No results found.</div>';
      } else {
        results.forEach(result => {
          const item = data.find(d => d.url === result.ref);
          if (item) renderResult(item);
        });
      }
    }

    function showAll(data) {
      resultsContainer.innerHTML = '';
      data.forEach(item => renderResult(item));
    }

    function renderResult(item) {
      const wrapper = document.createElement('div');
      wrapper.className = 'search-result';
      wrapper.innerHTML = `
        ${item.image ? `<div class="result-image"><img src="${item.image}" alt="${item.title}" /></div>` : ''}
        <div class="result-content">
          <h2><a href="${item.url}">${item.title}</a></h2>
          ${item.author ? `<p class="author"><strong>Author:</strong> ${item.author}</p>` : ''}
          <p class="summary">${item.content}</p>
        </div>
      `;
      resultsContainer.appendChild(wrapper);
    }
  });
</script>


<style>
  .main-heading {
  font-size: 2.2rem;
  font-weight: 700;
  text-align: center;
  margin: 2rem 0 1rem;
  color: #2c3e50;
  position: relative;
  z-index: 1;
  transition: color 0.3s ease, text-shadow 0.3s ease;
}

.main-heading::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  width: 80px;
  height: 4px;
  background: linear-gradient(90deg, #3498db, #9b59b6);
  transform: translateX(-50%);
  border-radius: 2px;
  z-index: -1;
  opacity: 0.7;
}

.main-heading:hover {
  text-shadow: 0 0 10px rgba(52, 152, 219, 0.6);
}

/* 🌙 Dark Mode: when body has .dark class */
body.dark .main-heading {
  color: #ecf0f1;
}

body.dark .main-heading::after {
  background: linear-gradient(90deg, #8e44ad, #2980b9);
  opacity: 0.9;
}

body.dark .main-heading:hover {
  text-shadow: 0 0 10px rgba(142, 68, 173, 0.8);
}
.search-results {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 2rem;
}

.search-result {
  display: flex;
  gap: 1rem;
  border-bottom: 1px solid #ccc;
  padding-bottom: 1rem;
  flex-wrap: wrap;
}

.result-image {
  flex: 0 0 30%;
  max-width: 30%;
  position: relative;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  background-color: #eee;
}

.result-image img {
  position: absolute;
  width: 100%;
  height: 100%;
  object-fit: cover;
  top: 0;
  left: 0;
  border-radius: 8px;
}

.result-content {
  flex: 1;
  min-width: 200px;
}

.result-content h2 {
  margin: 0 0 0.5rem;
  font-size: 1.3rem;
}

.result-content a {
  color: #3498db;
  text-decoration: none;
}

.result-content a:hover {
  text-decoration: underline;
}

.author {
  font-size: 0.9rem;
  color: #555;
}

.summary {
  margin-top: 0.5rem;
  line-height: 1.5;
}

/* Responsive for small screens */
@media (max-width: 768px) {
  .search-result {
    flex-direction: column;
  }

  .result-image,
  .result-content {
    max-width: 100%;
    flex: 100%;
  }
}

/* Dark mode */
body.dark .result-content a {
  color: #8ab4f8;
}

body.dark .author {
  color: #aaa;
}

body.dark .search-result {
  border-color: #444;
}

body.dark .summary {
  color: #ddd;
}

</style>