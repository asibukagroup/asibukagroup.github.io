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
  // Wait for the DOM to load
  document.addEventListener('DOMContentLoaded', function() {
    const searchBox = document.getElementById('search-box');
    const resultsContainer = document.getElementById('results');

    // Ensure resultsContainer exists before proceeding
    if (!resultsContainer) {
      console.error('Results container not found.');
      return;
    }

    // Get the query parameter from the URL
    const params = new URLSearchParams(window.location.search);
    const query = params.get('q') || ''; // Default to empty string if no query

    // Set the search box value to the query
    searchBox.value = query;

    // Fetch the search data from search.json
    fetch('/search.json')
      .then(res => res.json())
      .then(json => {
        const data = json;

        // Create the Lunr index
        const index = lunr(function () {
          this.ref('url');
          this.field('title');
          this.field('content');
          data.forEach(doc => this.add(doc));
        });

        // Run the search if there's a query in the URL
        if (query.trim()) {
          runSearch(query, data, index);
        }

        // Add event listener for live search as the user types
        searchBox.addEventListener('input', function () {
          runSearch(this.value, data, index);
        });
      })
      .catch(err => {
        console.error('Error fetching search.json:', err);
      });

    // Function to run the search
    function runSearch(query, data, index) {
      const results = index.search(query);
      resultsContainer.innerHTML = ''; // Clear previous results

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
  });
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