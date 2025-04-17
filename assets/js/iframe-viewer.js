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