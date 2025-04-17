---
layout: default
title: ASIBUKA Group
description: ASIBUKA Group adalah usaha yang bergerak di bidang investasi di bidang UMKM baik offline maupun online, berbasis teknologi ataupun konvensional.
author: ASIBUKA Group
url: https://asibuka.com
image: https://asibuka.com/assets/img/ASIBUKA-Blue.webp
permalink: /
keywords: ASIBUKA, ASIBUKA Group, Bisnis, Investasi, UMKM
robots: index, follow
lang: id
---
<h1 class='main-heading' id='EmbedTitle'>{{ page.title }}</h1>
<div class='media-container' id='EmbedContent'></div>
<div class='hide-on-embed'>
<p>{{ page.description }}</p>
<img src='https://asibuka.com/assets/img/ASIBUKA-Blue.webp' width='300' height='300' alt='Logo ASIUBKA' title='Logo ASIUBKA'>
</div>
<script>
    (function() {
    const params = new URLSearchParams(window.location.search);
    const title = params.get('title') || 'Embedded Content';
    const short = params.get('short') || '';
    const orientation = params.get('orientation') || 'landscape';
    const id = params.get('id');

    const embedContainer = document.getElementById('EmbedContent');
    const embedTitle = document.getElementById('EmbedTitle');

    // Set document title
    document.title = title;

    // Set visible title content
    if (embedTitle) {
      embedTitle.textContent = '';
      embedTitle.append(title);
    }

    // Apply orientation class (default to 'landscape')
    if (embedContainer) {
      embedContainer.classList.add(orientation);
    }

    // Create iframe only if both short and id are provided
    if (short && id && embedContainer) {
      const iframe = document.createElement('iframe');
      iframe.src = `https://${short}/${id}`;
      iframe.title = title;
      iframe.width = '100%';
      iframe.height = '400';
      iframe.style.border = 'none';
      iframe.setAttribute('class', 'media');
      iframe.setAttribute('allowfullscreen', '');
      iframe.setAttribute('frameborder', '0');
      iframe.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share');
      iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');

      embedContainer.appendChild(iframe);
    }

    // Remove elements with class .hide-on-embed entirely
    document.querySelectorAll('.hide-on-embed').forEach(el => {
      el.remove();
    });

    // Clear URL parameters from the address bar
    if (window.history.replaceState) {
      const cleanUrl = window.location.origin + window.location.pathname;
      window.history.replaceState({}, title, cleanUrl);
    }
  })();
  </script>