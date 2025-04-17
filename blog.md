---
layout: default
title: Blog
permalink: /blog/
lang: id
description: Kumpulan artikel dari ASIBUKA Blog.
robots: index, follow
---
<h1 class="main-heading">{{ page.title }}</h1>
<p class='text-center'>{{ page.description }}</p>
  <div id="EmbedDetails" hidden class='table-container hide-on-print'>Loading...</div>
  <div id="EmbedResult" hidden class='table-container hide-on-print'>Loading...</div>

  <script>
    (function () {
  const params = new URLSearchParams(window.location.search);
  const id1 = params.get('id1');
  const gid1 = params.get('gid1');
  const id2 = params.get('id2');
  const gid2 = params.get('gid2');
  const title = params.get('title');

  const embedDetails = document.getElementById('EmbedDetails');
  const embedResult = document.getElementById('EmbedResult');
  const embedTitle = document.getElementById('EmbedTitle');

  /* Check if 'title' parameter exists and set the document title */
  if (title) {
    document.title = title;
    if (embedTitle) {
      embedTitle.textContent = '';
      embedTitle.append(title);
    }
  }

  /* If id1 and gid1 exist and embedDetails is found, fetch the CSV for EmbedDetails */
  if (id1 && gid1 && embedDetails) {
    const csvDetails = `https://docs.google.com/spreadsheets/d/e/${id1}/pub?gid=${gid1}&single=true&output=csv`;
    fetch(csvDetails)
      .then(res => res.text())
      .then(csv => {
        const rows = csv.trim().split('\n').map(r => r.split(','));
        const table = document.createElement('table');
        rows.forEach((row, i) => {
          const tr = document.createElement('tr');
          row.forEach(cell => {
            const el = document.createElement(i === 0 ? 'th' : 'td');
            el.textContent = cell;
            tr.appendChild(el);
          });
          table.appendChild(tr);
        });
        embedDetails.removeAttribute('hidden');
        embedDetails.innerHTML = '';
        embedDetails.appendChild(table);
      })
      .catch(err => {
        embedDetails.textContent = 'Failed to load data.';
        console.error('CSV fetch error:', err);
      });
  }

  /* If id2 and gid2 exist and embedResult is found, fetch the CSV for EmbedResult */
  if (id2 && gid2 && embedResult) {
    const csvResult = `https://docs.google.com/spreadsheets/d/e/${id2}/pub?gid=${gid2}&single=true&output=csv`;
    fetch(csvResult)
      .then(res => res.text())
      .then(csv => {
        const rows = csv.trim().split('\n').map(r => r.split(','));
        const table = document.createElement('table');
        rows.forEach((row, i) => {
          const tr = document.createElement('tr');
          row.forEach(cell => {
            const el = document.createElement(i === 0 ? 'th' : 'td');
            el.textContent = cell;
            tr.appendChild(el);
          });
          table.appendChild(tr);
        });

        embedResult.innerHTML = '';
        embedResult.removeAttribute('hidden');

        /* Create and insert a heading above the EmbedResult */
        const heading = document.createElement('h2');
        heading.className = 'main-heading';
        heading.textContent = 'Detil Transaksi';
        embedResult.parentNode.insertBefore(heading, embedResult);

        embedResult.appendChild(table);
      })
      .catch(err => {
        embedResult.textContent = 'Failed to load data.';
        embedResult.removeAttribute('hidden');
        console.error('CSV fetch error:', err);
      });
  }

  /* Remove all elements with class "hide-on-embed" */
  document.querySelectorAll('.hide-on-embed').forEach(el => {
    el.remove();
  });

  /* Clean up the URL by removing query parameters */
  if (window.history.replaceState) {
    const cleanUrl = window.location.origin + window.location.pathname;
    window.history.replaceState({}, title || '', cleanUrl);
  }
})();

  </script>
<div itemscope itemtype="https://schema.org/ItemList">
{% for post in site.posts %}
<article class="post-container" itemscope itemtype="https://schema.org/ListItem" itemprop="itemListElement">
<meta itemprop="position" content="{{ forloop.index }}">
<div class="post-image">
<a href="{{ post.url }}" title="{{ post.title }}" itemprop="url">
<img  data-src="{{ post.image }}" src="{{ post.image }}" width="1600" height="900" loading="lazy"  class="lazy"  alt="{{ post.title }}" title="{{ post.title }}">
</a>
</div>
<div class="post-content">
<h2>
<a href="{{ post.url }}" title="{{ post.title }}" itemprop="name">{{ post.title }}</a>
</h2>
<p class="author">
<strong>Author:</strong> <span itemprop="author">{{ post.author }}</span>
</p>
<p class="summary" itemprop="description">{{ post.description }}</p>
</div>
</article>
{% endfor %}
</div>
