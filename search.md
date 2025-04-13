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
        <div class="post-content">
          <h2><a href="${item.url}" title="${item.title}">${item.title}</a></h2>
          ${item.author ? `<p class="author"><strong>Author:</strong> ${item.author}</p>` : ''}
          <p class="summary">${item.content}</p>
        </div>
      `;
      resultsContainer.appendChild(wrapper);
    }
  });
</script>