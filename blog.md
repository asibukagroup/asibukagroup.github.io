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
  <div id="EmbedContent" class='table-container hide-on-print'>Loading...</div>

  <script>
    const csvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vQffu-rraHetLPhZ9AUwsEJ-ppvxm6l6HAx20kZBI5nbAatkoTdH0U_vhrTgnHit4N3Dw34JN88MLCT/pub?gid=527953214&single=true&output=csv';

    fetch(csvUrl)
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
        document.getElementById('EmbedContent').innerHTML = '';
        document.getElementById('EmbedContent').appendChild(table);
      })
      .catch(err => {
        document.getElementById('EmbedContent').textContent = 'Failed to load data.';
        console.error('CSV fetch error:', err);
      });
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
