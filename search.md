---
layout: default
title: Search
permalink: /search/
lang: id
description: Silahkan cari konten yang kamu perlukan menggunakan form ini.
robots: noindex, nofollow
---
<h1 class="main-heading">Hasil Pencarian</h1>
<div id="results" class="post-containers"></div>
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
      const wrapper = document.createElement('article');
      wrapper.className = 'post-container';
      wrapper.innerHTML = `
        ${item.image ? `<div class="post-image"><a href="${item.url}" title="${item.title}"><img src="${item.image}" alt="${item.title}" /></a></div>` : ''}
        <div class="result-content">
          <h2><a href="${item.url}" title="${item.title}">${item.title}</a></h2>
          ${item.author ? `<p class="author"><strong>Author:</strong> ${item.author}</p>` : ''}
          <p class="summary">${item.content}</p>
        </div>
      `;
      resultsContainer.appendChild(wrapper);
    }
  });
</script>


<style>
.post-containers {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  margin-top: 2rem;
}

.post-container {
  display: flex;
  gap: 1rem;
  border-bottom: 1px solid #ccc;
  padding-bottom: 1rem;
  flex-wrap: wrap;
}

.post-image {
  flex: 0 0 30%;
  max-width: 30%;
  position: relative;
  background-color: #eee;
  overflow: hidden;
}

.post-image::before {
  content: "";
  display: block;
  padding-top: 56.25%; /* This maintains the 16:9 aspect ratio */
}

.post-image img {
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
  .post-container {
    flex-direction: column;
  }

  .post-image {
    flex: 0 0 100%;
    max-width: 100%;
    padding-top: 56.25%; /* Maintain 16:9 aspect ratio */
  }

  .result-content {
    max-width: 100%;
    flex: 1;
  }
}

/* Dark mode */
body.dark .result-content a {
  color: #8ab4f8;
}

body.dark .author {
  color: #aaa;
}

body.dark .post-container {
  border-color: #444;
}

body.dark .summary {
  color: #ddd;
}

</style>