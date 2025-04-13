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
(()=>{document.addEventListener("DOMContentLoaded",()=>{const e=document.getElementById("search-box"),t=document.getElementById("results");if(!t)return console.error("Results container not found.");const n=new URLSearchParams(window.location.search).get("q")||"";e.value=n,fetch("/search.json").then(e=>e.json()).then(r=>{const a=lunr(function(){this.ref("url"),this.field("title"),this.field("content"),r.forEach(e=>this.add(e))}),d=e=>{const n=a.search(e);t.innerHTML=n.length?"":"<div class=\"no-results\">No results found.</div>",n.forEach(e=>{const n=r.find(t=>t.url===e.ref);n&&o(n)})},s=e=>{t.innerHTML="",e.forEach(o)},o=e=>{const n=document.createElement("article");n.className="post-container",n.innerHTML=`${e.image?`<div class="post-image"><a href="${e.url}" title="${e.title}"><img src="${e.image}" alt="${e.title}" /></a></div>`:""}<div class="post-content"><h2><a href="${e.url}" title="${e.title}">${e.title}</a></h2>${e.author?`<p class="author"><strong>Author:</strong> ${e.author}</p>`:""}<p class="summary">${e.content}</p></div>`,t.appendChild(n)};n.trim()?d(n):s(r),e.addEventListener("input",function(){this.value.trim()?d(this.value):s(r)})}).catch(e=>console.error("Error fetching search.json:",e))})})();
</script>