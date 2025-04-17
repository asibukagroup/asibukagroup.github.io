---
layout: default
title: Pages
permalink: /page/
lang: id
description: Kumpulan artikel statis dari ASIBUKA Blog.
robots: index, follow
---
<h1 class="main-heading" id='EmbedTitle'>{{ page.title }}</h1>
<div class='media-container' hidden id='EmbedContent'></div>
<div id="EmbedDetails" hidden class='table-container hide-on-print'>Loading...</div>
<div id="EmbedResult" hidden class='table-container hide-on-print'>Loading...</div>
<p class='text-center hide-on-embed'>{{ page.description }}</p>
<div class='hide-on-embed' itemscope itemtype="https://schema.org/ItemList">
{% for post in site.pages %}
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
